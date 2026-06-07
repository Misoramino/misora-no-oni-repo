import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'firebase_bootstrap.dart';
import 'firestore_room_blueprint.dart';
import 'presence_throttle.dart';
import 'inspector_feed_snapshot.dart';
import 'remote_member_snapshot.dart';
import 'room_member_view.dart';
import '../game/game_state.dart';
import '../game/player_role.dart';
import '../game/play_area.dart';
import 'room_match_event.dart';
import 'room_phase.dart';
import 'room_session_port.dart';
import 'shared_match_snapshot.dart';

String _describeFirebaseException(FirebaseException e) {
  final code = e.code;
  final raw = e.message ?? '';
  final buf = StringBuffer(code);
  if (raw.isNotEmpty) {
    buf.write(': ');
    buf.write(raw);
  }
  final lower = raw.toLowerCase();
  if (code == 'permission-denied' || lower.contains('permission')) {
    buf.write(
      '\n（Firestore ルールで拒否されている可能性。コンソールに firestore.rules を '
      'デプロイ済みか確認してください）',
    );
  } else if (code == 'unavailable' || lower.contains('network')) {
    buf.write('\n（ネットワーク・オフラインの可能性）');
  } else if (code == 'failed-precondition' || raw.contains('index')) {
    buf.write('\n（インデックス不足の可能性 — コンソールのエラーに出るリンクを確認）');
  } else if (raw.contains('Unknown error') ||
      raw.contains('different error domain')) {
    buf.write(
      '\n（デスクトップ(Windows/macOS/Linux)で Firebase オプション未設定、'
      'または App Check 強制などで出ることがあります）',
    );
  }
  return buf.toString();
}

/// 試合前の共有イベント（プレイエリア適用など）用 sessionKey。
const int lobbySessionKey = 0;

/// ロビーでホストが共有したプレイエリア。
class LobbyPlayAreaSnapshot {
  const LobbyPlayAreaSnapshot({required this.area, this.slotName});

  final PlayArea area;
  final String? slotName;

  static LobbyPlayAreaSnapshot? tryParseRoomDoc(Map<String, dynamic>? data) {
    if (data == null) return null;
    final raw = data[RoomDocFields.lobbyPlayArea];
    if (raw is! Map) return null;
    try {
      return LobbyPlayAreaSnapshot(
        area: PlayArea.fromJson(Map<String, dynamic>.from(raw)),
        slotName: data[RoomDocFields.lobbyPlayAreaSlotName] as String?,
      );
    } catch (_) {
      return null;
    }
  }

  static LobbyPlayAreaSnapshot? tryParseEvent(RoomMatchEvent ev) {
    if (ev.type != RoomMatchEventTypes.lobbyPlayArea) return null;
    final raw = ev.payload['playArea'];
    if (raw is! Map<String, dynamic>) return null;
    try {
      return LobbyPlayAreaSnapshot(
        area: PlayArea.fromJson(raw),
        slotName: ev.payload['slotName'] as String?,
      );
    } catch (_) {
      return null;
    }
  }
}

/// Firestore ルームの接続状態（HUD 表示用）。
enum RoomConnectionStatus {
  connected,
  offline,
}

String? _validateRoomDocId(String id) {
  if (id.isEmpty) return 'ルームIDを入力してください';
  if (id.contains('/') || id.contains('\\')) {
    return 'ルームIDに / や \\ は使えません';
  }
  if (id.startsWith('.') || id.endsWith('.')) {
    return 'ルームIDを . で始めたり終わったりできません';
  }
  if (id.codeUnits.length > 200) {
    return 'ルームIDは200文字以内にしてください';
  }
  return null;
}

/// Firestore ルームの最小プレゼンス同期（匿名 UID + members ドキュメント）。
///
/// セキュリティルールは必ず本番用に差し替えてください（現状は開発向け想定）。
class FirestoreRoomSession implements RoomSessionPort {
  FirestoreRoomSession();

  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final PresenceThrottle _calm = calmPresenceThrottle();
  final PresenceThrottle _tense = tensionPresenceThrottle();
  final PresenceThrottle _inspectorFeedThrottle = PresenceThrottle(
    minIntervalMs: PresenceSyncBudget.inspectorFeedMinIntervalMs,
  );

  String? _roomId;
  String? _uid;
  String? _nickname;
  String _role = 'runner';
  Timer? _heartbeatTimer;
  List<RoomMemberView> _latestLobby = const [];
  Map<String, RemoteMemberSnapshot> _latestRemoteMembers = const {};
  Map<String, bool> _werewolfOniFormByUid = const {};

  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _membersSub;
  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>? _roomSub;
  String? _hostUid;
  String _phase = RoomPhase.lobby;
  final StreamController<Map<String, RemoteMemberSnapshot>> _remoteCtrl =
      StreamController<Map<String, RemoteMemberSnapshot>>.broadcast();
  final StreamController<List<RoomMemberView>> _lobbyCtrl =
      StreamController<List<RoomMemberView>>.broadcast();
  final StreamController<String> _phaseCtrl =
      StreamController<String>.broadcast();
  final StreamController<RoomMatchState> _roomMatchCtrl =
      StreamController<RoomMatchState>.broadcast();
  final StreamController<RoomConnectionStatus> _connectionCtrl =
      StreamController<RoomConnectionStatus>.broadcast();
  RoomConnectionStatus _connectionStatus = RoomConnectionStatus.connected;
  final StreamController<RoomMatchEvent> _roomEventCtrl =
      StreamController<RoomMatchEvent>.broadcast();

  RoomMatchState _latestRoomMatch = const RoomMatchState(
    phase: RoomPhase.lobby,
  );
  SharedMatchSnapshot? _latestMatchStart;
  LobbyPlayAreaSnapshot? _latestLobbyPlayArea;
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _eventsSub;
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _inspectorFeedSub;
  Map<String, InspectorFeedSnapshot> _latestInspectorFeed = const {};
  final StreamController<Map<String, InspectorFeedSnapshot>> _inspectorFeedCtrl =
      StreamController<Map<String, InspectorFeedSnapshot>>.broadcast();

  /// 他プレイヤーの最新プレゼンス。購読時に直近値を再送する。
  Stream<Map<String, RemoteMemberSnapshot>> get remoteMembers =>
      Stream<Map<String, RemoteMemberSnapshot>>.multi((controller) {
        controller.add(_latestRemoteMembers);
        final sub = _remoteCtrl.stream.listen(
          controller.add,
          onError: controller.addError,
          onDone: controller.close,
        );
        controller.onCancel = () => sub.cancel();
      }, isBroadcast: true);

  /// ルーム内の全メンバー（自分を含む）。ロビー UI 用。
  ///
  /// 購読直後に [currentLobbyMembers] を再送する（Firestore 初回スナップショットが
  /// リスナー登録より先に届いた端末での一覧取りこぼし対策）。
  Stream<List<RoomMemberView>> get lobbyMembers =>
      Stream<List<RoomMemberView>>.multi((controller) {
        controller.add(_latestLobby);
        final sub = _lobbyCtrl.stream.listen(
          controller.add,
          onError: controller.addError,
          onDone: controller.close,
        );
        controller.onCancel = () => sub.cancel();
      }, isBroadcast: true);

  Map<String, RemoteMemberSnapshot> get currentRemoteMembers =>
      Map<String, RemoteMemberSnapshot>.unmodifiable(_latestRemoteMembers);
  Map<String, InspectorFeedSnapshot> get currentInspectorFeed =>
      Map<String, InspectorFeedSnapshot>.unmodifiable(_latestInspectorFeed);

  /// 観戦者向けライブ GPS フィード（`inspectorFeed` サブコレクション）。
  Stream<Map<String, InspectorFeedSnapshot>> get inspectorFeed =>
      Stream<Map<String, InspectorFeedSnapshot>>.multi((controller) {
        controller.add(_latestInspectorFeed);
        final sub = _inspectorFeedCtrl.stream.listen(
          controller.add,
          onError: controller.addError,
          onDone: controller.close,
        );
        controller.onCancel = () => sub.cancel();
      }, isBroadcast: true);

  Map<String, bool> get werewolfOniFormByUid =>
      Map<String, bool>.unmodifiable(_werewolfOniFormByUid);
  List<RoomMemberView> get currentLobbyMembers =>
      List.unmodifiable(_latestLobby);

  String? get nickname => _nickname;
  String get role => _role;

  @override
  String? get roomId => _roomId;

  @override
  String get modeLabel =>
      _roomId == null ? 'Firebase（未参加）' : 'online: $_roomId';

  @override
  Future<void> connectLocalDemo() async {}

  String? get myUid => _uid;
  String? get hostUid => _hostUid;
  bool get isHost => _uid != null && _hostUid != null && _uid == _hostUid;

  RoomMemberView? get hostMember {
    final h = _hostUid;
    if (h == null) return null;
    for (final m in _latestLobby) {
      if (m.uid == h) return m;
    }
    return null;
  }

  /// ホストがメンバー一覧にいない、またはハートビートが古い。
  bool isHostAbsent(DateTime nowUtc) {
    final h = _hostUid;
    if (h == null) return true;
    final member = hostMember;
    if (member == null) return true;
    return member.isStale(nowUtc);
  }

  RoomConnectionStatus get currentConnectionStatus => _connectionStatus;

  Stream<RoomConnectionStatus> get connectionStatus => _connectionCtrl.stream;

  void _setConnectionStatus(RoomConnectionStatus status) {
    if (_connectionStatus == status) return;
    _connectionStatus = status;
    if (!_connectionCtrl.isClosed) _connectionCtrl.add(status);
  }

  /// 現在のルームフェーズ（lobby / running / ended）。
  String get currentPhase => _phase;

  /// フェーズ変更の通知（参加・再接続時に現在値も流れる）。
  Stream<String> get roomPhase => _phaseCtrl.stream;

  /// phase + 共有試合開始/終了データ。
  Stream<RoomMatchState> get roomMatchState => _roomMatchCtrl.stream;

  RoomMatchState get currentRoomMatch => _latestRoomMatch;

  LobbyPlayAreaSnapshot? get currentLobbyPlayArea => _latestLobbyPlayArea;

  SharedMatchSnapshot? get currentMatchStart => _latestMatchStart;

  /// 試合中の共有イベント（append-only events サブコレクション）。
  Stream<RoomMatchEvent> get roomMatchEvents => _roomEventCtrl.stream;

  /// エラー時はメッセージを返す。
  Future<String?> join({
    required String roomId,
    required String nickname,
    String role = 'runner',
  }) async {
    if (!FirebaseBootstrap.isReady) {
      return 'Firebase が初期化されていません。\n'
          'Android / iOS: android/app/google-services.json 等を置いてフル再ビルドするか、'
          'Windows / macOS / Linux: dart-define で FIREBASE_API_KEY 等を指定してください。';
    }
    final trimmedId = roomId.trim();
    final idErr = _validateRoomDocId(trimmedId);
    if (idErr != null) return idErr;
    final nick = nickname.trim();
    if (nick.isEmpty) return '表示名を入力してください';

    try {
      await disconnect();
      try {
        await FirebaseAuth.instance.signInAnonymously();
      } on FirebaseAuthException catch (e) {
        return '認証エラー（匿名ログイン）: ${e.code} ${e.message ?? ''}';
      }
      _uid = FirebaseAuth.instance.currentUser?.uid;
      if (_uid == null) return '匿名ログインに失敗しました（UID なし）';

      _roomId = trimmedId;
      _nickname = nick;

      final roomRef = _db.collection('rooms').doc(_roomId);
      try {
        await _db.runTransaction((tx) async {
          final roomSnap = await tx.get(roomRef);
          if (!roomSnap.exists) {
            tx.set(roomRef, {
              RoomDocFields.hostUid: _uid,
              RoomDocFields.phase: 'lobby',
            });
          } else {
            final data = roomSnap.data();
            final existingHost = data?[RoomDocFields.hostUid] as String?;
            if (existingHost == null || existingHost.isEmpty) {
              tx.update(roomRef, {RoomDocFields.hostUid: _uid});
            }
          }
        });
      } on FirebaseException catch (e) {
        return 'ルーム情報の作成/更新に失敗: ${_describeFirebaseException(e)}';
      }

      final roomData = (await roomRef.get()).data();
      _role = _resolveMemberRoleForJoin(
        role,
        roomData,
      );

      final memberRef = roomRef.collection('members').doc(_uid!);
      try {
        await memberRef.set(
          {
            MemberPresenceFields.nickname: _nickname,
            MemberPresenceFields.role: _role,
            MemberPresenceFields.reportedAtUtc: DateTime.now()
                .toUtc()
                .toIso8601String(),
            MemberPresenceFields.locationVisibility: 'hidden',
          },
          SetOptions(merge: true),
        );
      } on FirebaseException catch (e) {
        return 'メンバー登録に失敗: ${_describeFirebaseException(e)}';
      }
      _startHeartbeat();
      _bindRoomAndMembers();
      try {
        final rid = _roomId;
        if (rid != null) {
          final snap = await _db
              .collection('rooms')
              .doc(rid)
              .collection('members')
              .get();
          if (_roomId == rid) {
            _emitLobbyFromSnapshot(snap);
          }
        }
      } catch (_) {
        // 一覧は snapshots 購読で追いつく。ここは初回表示のベストエフォート。
      }
      return null;
    } on FirebaseAuthException catch (e) {
      return '認証エラー: ${e.message ?? e.code}';
    } on FirebaseException catch (e) {
      return 'Firestore: ${_describeFirebaseException(e)}';
    } catch (e) {
      return '接続エラー: $e';
    }
  }

  /// 暴露ピン用サムネ（PNG Base64）。null でフィールド削除。
  Future<String?> updateAvatarThumb(String? avatarThumbB64) async {
    if (_roomId == null || _uid == null) return null;
    try {
      final ref = _db
          .collection('rooms')
          .doc(_roomId!)
          .collection('members')
          .doc(_uid!);
      if (avatarThumbB64 == null || avatarThumbB64.isEmpty) {
        await ref.set(
          {MemberPresenceFields.avatarThumbB64: FieldValue.delete()},
          SetOptions(merge: true),
        );
      } else {
        await ref.set(
          {MemberPresenceFields.avatarThumbB64: avatarThumbB64},
          SetOptions(merge: true),
        );
      }
      return null;
    } on FirebaseException catch (e) {
      return 'アバター同期に失敗: ${_describeFirebaseException(e)}';
    }
  }

  /// 表示名のみ更新（ルーム参加済みのとき）。
  Future<String?> updateNickname(String nickname) async {
    final nick = nickname.trim();
    if (nick.isEmpty) return '表示名を入力してください';
    if (_roomId == null || _uid == null) return null;
    _nickname = nick;
    try {
      await _db
          .collection('rooms')
          .doc(_roomId!)
          .collection('members')
          .doc(_uid!)
          .set(
        {
          MemberPresenceFields.nickname: nick,
          MemberPresenceFields.reportedAtUtc: DateTime.now()
              .toUtc()
              .toIso8601String(),
        },
        SetOptions(merge: true),
      );
      return null;
    } on FirebaseException catch (e) {
      return '名前の更新に失敗: ${_describeFirebaseException(e)}';
    }
  }

  void _bindRoomAndMembers() {
    if (_roomId == null) return;
    final rid = _roomId!;
    _roomSub?.cancel();
    _roomSub = _db.collection('rooms').doc(rid).snapshots().listen(
      (roomSnap) {
        _setConnectionStatus(RoomConnectionStatus.connected);
        final data = roomSnap.data();
      _hostUid = data?[RoomDocFields.hostUid] as String?;
      final nextPhase = RoomPhase.normalize(
        data?[RoomDocFields.phase] as String?,
      );
      final matchStartRaw = data?[RoomDocFields.matchStart];
      _latestMatchStart = matchStartRaw is Map<String, dynamic>
          ? SharedMatchSnapshot.tryParse(matchStartRaw)
          : matchStartRaw is Map
          ? SharedMatchSnapshot.tryParse(
              Map<String, dynamic>.from(matchStartRaw),
            )
          : null;
      final matchEnd = nextPhase == RoomPhase.ended
          ? SharedMatchEnd.tryParse(data)
          : null;
      _latestLobbyPlayArea = LobbyPlayAreaSnapshot.tryParseRoomDoc(data);
      if (nextPhase != _phase) {
        _phase = nextPhase;
        if (!_phaseCtrl.isClosed) _phaseCtrl.add(_phase);
      }
      _latestRoomMatch = RoomMatchState(
        phase: nextPhase,
        matchStart: _latestMatchStart,
        matchEnd: matchEnd,
      );
      if (!_roomMatchCtrl.isClosed) _roomMatchCtrl.add(_latestRoomMatch);
      _emitLobbyFromLastMembers();
    }, onError: (_) {
      _setConnectionStatus(RoomConnectionStatus.offline);
    });
    if (!_phaseCtrl.isClosed) _phaseCtrl.add(_phase);
    if (!_roomMatchCtrl.isClosed) _roomMatchCtrl.add(_latestRoomMatch);

    _membersSub?.cancel();
    _membersSub = _db
        .collection('rooms')
        .doc(rid)
        .collection('members')
        .snapshots()
        .listen((snap) {
          _emitLobbyFromSnapshot(snap);
        });
    // 購読直後にキャッシュ同期（初回イベントが遅い端末向け）
    unawaited(
      _db.collection('rooms').doc(rid).collection('members').get().then((snap) {
        if (_roomId != rid) return;
        _emitLobbyFromSnapshot(snap);
      }),
    );
  }

  QuerySnapshot<Map<String, dynamic>>? _lastMemberSnap;

  void _emitLobbyFromSnapshot(QuerySnapshot<Map<String, dynamic>> snap) {
    _lastMemberSnap = snap;
    _emitLobbyFromLastMembers();
  }

  void _emitLobbyFromLastMembers() {
    final snap = _lastMemberSnap;
    if (snap == null) return;
    final host = _hostUid;
    final out = <String, RemoteMemberSnapshot>{};
    final werewolfForms = <String, bool>{};
    final lobby = <RoomMemberView>[];
    for (final d in snap.docs) {
      final isSelf = d.id == _uid;
      final data = d.data();
      final view = RoomMemberView.parse(
        uid: d.id,
        data: data,
        isSelf: isSelf,
        isHost: host != null && d.id == host,
      );
      // ロビーでは全員表示（stale は UI でグレー表示）。iOS 等でハートビート遅延があると
      // 他端末が一覧から消える問題を避ける。
      lobby.add(view);
      final rawWolf = data[MemberPresenceFields.werewolfOniForm];
      if (rawWolf is bool) {
        werewolfForms[d.id] = rawWolf;
      }
      final remote = RemoteMemberSnapshot.tryParse(d.id, data);
      if (!isSelf && remote != null) out[d.id] = remote;
    }
    lobby.sort((a, b) {
      if (a.isHost != b.isHost) return a.isHost ? -1 : 1;
      if (a.isSelf != b.isSelf) return a.isSelf ? -1 : 1;
      final ar = a.role;
      final br = b.role;
      if (ar == 'oni' && br != 'oni') return -1;
      if (br == 'oni' && ar != 'oni') return 1;
      return a.nickname.compareTo(b.nickname);
    });
    _latestLobby = List.unmodifiable(lobby);
    _latestRemoteMembers = Map<String, RemoteMemberSnapshot>.unmodifiable(out);
    _werewolfOniFormByUid = Map<String, bool>.unmodifiable(werewolfForms);
    if (!_remoteCtrl.isClosed) _remoteCtrl.add(out);
    if (!_lobbyCtrl.isClosed) _lobbyCtrl.add(_latestLobby);
  }

  /// 参加者: 共有イベントを 1 件追加（append-only）。
  Future<String?> publishRoomEvent({
    required String type,
    required Map<String, dynamic> payload,
    required int sessionKey,
  }) async {
    if (_roomId == null || _uid == null) return 'ルームに参加していません';
    try {
      await _db.collection('rooms').doc(_roomId).collection('events').add({
        RoomEventsFields.type: type,
        RoomEventsFields.emittedAtUtc: DateTime.now().toUtc().toIso8601String(),
        RoomEventsFields.emittedAtMs: DateTime.now().millisecondsSinceEpoch,
        RoomEventsFields.actorUid: _uid,
        RoomEventsFields.sessionKey: sessionKey,
        RoomEventsFields.payload: payload,
      });
      return null;
    } on FirebaseException catch (e) {
      return e.message ?? e.code;
    } catch (e) {
      return '$e';
    }
  }

  /// ホストのみの共有イベント（中身は [publishRoomEvent] と同じ）。
  Future<String?> publishHostRoomEvent({
    required String type,
    required Map<String, dynamic> payload,
    required int sessionKey,
  }) async {
    if (!isHost) return 'ホストのみ書けます';
    return publishRoomEvent(
      type: type,
      payload: payload,
      sessionKey: sessionKey,
    );
  }

  /// 現在の試合 sessionKey（gimmickSeed）で events を購読（ルーム doc / members に加えて 1 本）。
  void startRoomEventsListener(int sessionKey) {
    if (_roomId == null) return;
    final rid = _roomId!;
    _eventsSub?.cancel();
    _eventsSub = _db
        .collection('rooms')
        .doc(rid)
        .collection('events')
        .where(RoomEventsFields.sessionKey, isEqualTo: sessionKey)
        .orderBy(RoomEventsFields.emittedAtMs)
        .snapshots()
        .listen((snap) {
          for (final change in snap.docChanges) {
            if (change.type == DocumentChangeType.removed) continue;
            final data = change.doc.data();
            if (data == null) continue;
            final ev = RoomMatchEvent.tryParse(change.doc.id, data);
            if (ev != null && !_roomEventCtrl.isClosed) {
              _roomEventCtrl.add(ev);
            }
          }
        });
  }

  void stopRoomEventsListener() {
    _eventsSub?.cancel();
    _eventsSub = null;
  }

  /// ロビー参加前にホストが適用したエリア（events フォールバック）。
  Future<LobbyPlayAreaSnapshot?> fetchLatestLobbyPlayAreaEvent() async {
    if (_roomId == null) return null;
    try {
      final snap = await _db
          .collection('rooms')
          .doc(_roomId!)
          .collection('events')
          .where(RoomEventsFields.sessionKey, isEqualTo: lobbySessionKey)
          .orderBy(RoomEventsFields.emittedAtMs, descending: true)
          .limit(24)
          .get();
      for (final doc in snap.docs) {
        final data = doc.data();
        final ev = RoomMatchEvent.tryParse(doc.id, data);
        if (ev == null) continue;
        final parsed = LobbyPlayAreaSnapshot.tryParseEvent(ev);
        if (parsed != null) return parsed;
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  /// ホストのみ。ルーム doc + events でロビーエリアを共有。
  Future<String?> publishLobbyPlayArea({
    required PlayArea area,
    required String slotName,
    required String slotId,
  }) async {
    if (_roomId == null || _uid == null) return 'ルームに参加していません';
    if (!isHost) return 'ホストのみ適用できます';
    try {
      await _db.collection('rooms').doc(_roomId!).update({
        RoomDocFields.lobbyPlayArea: area.toJson(),
        RoomDocFields.lobbyPlayAreaSlotName: slotName,
      });
      _latestLobbyPlayArea = LobbyPlayAreaSnapshot(
        area: area,
        slotName: slotName,
      );
      return publishRoomEvent(
        type: RoomMatchEventTypes.lobbyPlayArea,
        payload: {
          'slotId': slotId,
          'slotName': slotName,
          'playArea': area.toJson(),
        },
        sessionKey: lobbySessionKey,
      );
    } on FirebaseException catch (e) {
      return _describeFirebaseException(e);
    } catch (e) {
      return '$e';
    }
  }

  /// 再参加時に過去イベントを再生するための一括取得。
  Future<List<RoomMatchEvent>> fetchMatchEvents(int sessionKey) async {
    if (_roomId == null) return const [];
    try {
      final snap = await _db
          .collection('rooms')
          .doc(_roomId!)
          .collection('events')
          .where(RoomEventsFields.sessionKey, isEqualTo: sessionKey)
          .orderBy(RoomEventsFields.emittedAtMs)
          .get();
      final out = <RoomMatchEvent>[];
      for (final doc in snap.docs) {
        final data = doc.data();
        final ev = RoomMatchEvent.tryParse(doc.id, data);
        if (ev != null) out.add(ev);
      }
      return out;
    } catch (_) {
      return const [];
    }
  }

  String _resolveMemberRoleForJoin(
    String requestedRole,
    Map<String, dynamic>? roomData,
  ) {
    var memberRole =
        requestedRole.trim().isEmpty ? 'runner' : requestedRole.trim();
    if (roomData == null) return memberRole;
    final phase = RoomPhase.normalize(
      roomData[RoomDocFields.phase] as String?,
    );
    if (phase != RoomPhase.running) return memberRole;
    final matchRaw = roomData[RoomDocFields.matchStart];
    final matchStart = matchRaw is Map<String, dynamic>
        ? SharedMatchSnapshot.tryParse(matchRaw)
        : matchRaw is Map
        ? SharedMatchSnapshot.tryParse(Map<String, dynamic>.from(matchRaw))
        : null;
    if (matchStart == null || _uid == null) return 'spectator';
    final mine = matchStart.assignmentFor(_uid);
    if (mine == null) return 'spectator';
    return mine.role == PlayerRole.hunter ? 'oni' : 'runner';
  }

  /// ホストのみ。試合開始データと phase=running を 1 回で書く。
  Future<String?> publishMatchStart(SharedMatchSnapshot snapshot) async {
    if (_roomId == null) return 'ルームに参加していません';
    if (!isHost) return 'ホストのみ開始できます';
    try {
      final started =
          snapshot.startedAtUtc ?? DateTime.now().toUtc().toIso8601String();
      final payload = snapshot.toMap()
        ..[RoomDocFields.matchStartStartedAtUtc] = started;
      await _db.collection('rooms').doc(_roomId).update({
        RoomDocFields.matchStart: payload,
        RoomDocFields.phase: RoomPhase.running,
        RoomDocFields.endReason: FieldValue.delete(),
        RoomDocFields.matchOutcome: FieldValue.delete(),
        RoomDocFields.endMessage: FieldValue.delete(),
        RoomDocFields.endedAtUtc: FieldValue.delete(),
      });
      _latestMatchStart = snapshot;
      _phase = RoomPhase.running;
      if (!_phaseCtrl.isClosed) _phaseCtrl.add(_phase);
      _latestRoomMatch = RoomMatchState(
        phase: _phase,
        matchStart: _latestMatchStart,
      );
      if (!_roomMatchCtrl.isClosed) _roomMatchCtrl.add(_latestRoomMatch);
      final err = await publishHostRoomEvent(
        type: RoomMatchEventTypes.matchStart,
        payload: {'gimmickSeed': snapshot.gimmickSeed, 'startedAtUtc': started},
        sessionKey: snapshot.gimmickSeed,
      );
      if (err != null) return err;
      startRoomEventsListener(snapshot.gimmickSeed);
      return null;
    } on FirebaseException catch (e) {
      return e.message ?? e.code;
    } catch (e) {
      return '$e';
    }
  }

  /// ホストのみ。試合終了と結果を書く。
  Future<String?> publishMatchEnd({
    required GameState outcome,
    required String endReason,
    required String message,
  }) async {
    if (_roomId == null) return 'ルームに参加していません';
    if (!isHost) return 'ホストのみ終了できます';
    try {
      final endedAt = DateTime.now().toUtc().toIso8601String();
      await _db.collection('rooms').doc(_roomId).update({
        RoomDocFields.phase: RoomPhase.ended,
        RoomDocFields.endedAtUtc: endedAt,
        RoomDocFields.endReason: endReason,
        RoomDocFields.matchOutcome: outcome.name,
        RoomDocFields.endMessage: message,
      });
      _phase = RoomPhase.ended;
      if (!_phaseCtrl.isClosed) _phaseCtrl.add(_phase);
      _latestRoomMatch = RoomMatchState(
        phase: _phase,
        matchStart: _latestMatchStart,
        matchEnd: SharedMatchEnd(
          endReason: endReason,
          outcome: outcome,
          message: message,
          endedAtUtc: endedAt,
        ),
      );
      if (!_roomMatchCtrl.isClosed) _roomMatchCtrl.add(_latestRoomMatch);
      final sk = _latestMatchStart?.gimmickSeed;
      if (sk != null) {
        final err = await publishHostRoomEvent(
          type: RoomMatchEventTypes.matchEnd,
          payload: {
            'endReason': endReason,
            'outcome': outcome.name,
            'message': message,
          },
          sessionKey: sk,
        );
        if (err != null) return err;
      }
      return null;
    } on FirebaseException catch (e) {
      return e.message ?? e.code;
    } catch (e) {
      return '$e';
    }
  }

  Future<String?> updateRoomPhase(String phase) async {
    if (_roomId == null) return 'ルームに参加していません';
    if (!isHost) return 'ホストのみ変更できます';
    try {
      final patch = <String, dynamic>{RoomDocFields.phase: phase};
      if (phase == RoomPhase.lobby) {
        patch[RoomDocFields.matchStart] = FieldValue.delete();
        patch[RoomDocFields.endReason] = FieldValue.delete();
        patch[RoomDocFields.matchOutcome] = FieldValue.delete();
        patch[RoomDocFields.endMessage] = FieldValue.delete();
        patch[RoomDocFields.endedAtUtc] = FieldValue.delete();
        _latestMatchStart = null;
        stopRoomEventsListener();
      }
      await _db.collection('rooms').doc(_roomId).update(patch);
      _phase = RoomPhase.normalize(phase);
      if (!_phaseCtrl.isClosed) _phaseCtrl.add(_phase);
      _latestRoomMatch = RoomMatchState(
        phase: _phase,
        matchStart: _latestMatchStart,
        matchEnd: phase == RoomPhase.ended ? _latestRoomMatch.matchEnd : null,
      );
      if (!_roomMatchCtrl.isClosed) _roomMatchCtrl.add(_latestRoomMatch);
      return null;
    } on FirebaseException catch (e) {
      return e.message ?? e.code;
    } catch (e) {
      return '$e';
    }
  }

  /// ホストのみ。エラー時はメッセージを返す。
  Future<String?> transferHost(String targetUid) async {
    if (_roomId == null || _uid == null) return 'ルームに参加していません';
    if (!isHost) return 'ホストのみ譲渡できます';
    if (targetUid == _uid) return null;
    final exists = _latestLobby.any((m) => m.uid == targetUid);
    if (!exists) return 'そのメンバーはルームにいません';
    try {
      await _db.collection('rooms').doc(_roomId).update({
        RoomDocFields.hostUid: targetUid,
      });
      return null;
    } on FirebaseException catch (e) {
      return e.message ?? e.code;
    } catch (e) {
      return '$e';
    }
  }

  /// ホストが不在のとき、参加メンバーがホストを引き継ぐ。
  Future<String?> claimHostIfAbsent() async {
    if (_roomId == null || _uid == null) return 'ルームに参加していません';
    if (isHost) return null;
    if (!isHostAbsent(DateTime.now().toUtc())) {
      return 'ホストはオンラインです';
    }
    try {
      await _db.collection('rooms').doc(_roomId).update({
        RoomDocFields.hostUid: _uid,
      });
      _hostUid = _uid;
      _emitLobbyFromLastMembers();
      return null;
    } on FirebaseException catch (e) {
      return _describeFirebaseException(e);
    } catch (e) {
      return '$e';
    }
  }

  /// カスタムモードの希望ロール/スキル（試合確定前。自分の members のみ）。
  Future<String?> publishRulePreferences({
    required PlayerRole preferredRole,
    required List<String> preferredSkills,
  }) async {
    if (_roomId == null || _uid == null) return null;
    try {
      final ref = _db
          .collection('rooms')
          .doc(_roomId)
          .collection('members')
          .doc(_uid!);
      await ref.set({
        MemberPresenceFields.nickname: _nickname,
        MemberPresenceFields.role: _role,
        MemberPresenceFields.reportedAtUtc: DateTime.now()
            .toUtc()
            .toIso8601String(),
        MemberPresenceFields.locationVisibility: 'hidden',
        MemberPresenceFields.preferredRole: preferredRole.name,
        MemberPresenceFields.preferredSkills: preferredSkills,
      }, SetOptions(merge: true));
      return null;
    } on FirebaseException catch (e) {
      return e.message ?? e.code;
    } catch (e) {
      return '$e';
    }
  }

  Future<void> publishPresence({
    required bool tension,
    String? proximityBandName,
    bool? werewolfOniForm,
  }) async {
    if (_roomId == null || _uid == null) return;
    final throttle = tension ? _tense : _calm;
    if (!throttle.requestSlot()) return;
    final ref = _db
        .collection('rooms')
        .doc(_roomId)
        .collection('members')
        .doc(_uid!);
    final payload = <String, dynamic>{
      MemberPresenceFields.reportedAtUtc: DateTime.now()
          .toUtc()
          .toIso8601String(),
      MemberPresenceFields.role: _role,
      MemberPresenceFields.nickname: _nickname,
      MemberPresenceFields.locationVisibility: 'hidden',
    };
    if (proximityBandName != null && proximityBandName.isNotEmpty) {
      payload[MemberPresenceFields.proximityBand] = proximityBandName;
    }
    if (werewolfOniForm != null) {
      payload[MemberPresenceFields.werewolfOniForm] = werewolfOniForm;
    }
    await ref.set(payload, SetOptions(merge: true));
  }

  /// 試合参加者が観戦者向けにライブ GPS を送信（スロットルあり）。
  Future<void> publishInspectorFeedPosition({
    required double lat,
    required double lng,
  }) async {
    if (_roomId == null || _uid == null) return;
    if (_role == 'spectator') return;
    if (_phase != RoomPhase.running) return;
    if (!_inspectorFeedThrottle.requestSlot()) return;
    final ref = _db
        .collection('rooms')
        .doc(_roomId!)
        .collection('inspectorFeed')
        .doc(_uid!);
    await ref.set({
      InspectorFeedFields.lat: lat,
      InspectorFeedFields.lng: lng,
      InspectorFeedFields.nickname: _nickname ?? '',
      InspectorFeedFields.role: _role,
      InspectorFeedFields.reportedAtUtc: DateTime.now()
          .toUtc()
          .toIso8601String(),
    }, SetOptions(merge: true));
  }

  Future<void> clearInspectorFeedPosition() async {
    if (_roomId == null || _uid == null) return;
    try {
      await _db
          .collection('rooms')
          .doc(_roomId!)
          .collection('inspectorFeed')
          .doc(_uid!)
          .delete();
    } catch (_) {}
  }

  void startInspectorFeedListener() {
    if (_roomId == null) return;
    _inspectorFeedSub?.cancel();
    _inspectorFeedSub = _db
        .collection('rooms')
        .doc(_roomId!)
        .collection('inspectorFeed')
        .snapshots()
        .listen(
      (snap) {
        final map = <String, InspectorFeedSnapshot>{};
        for (final doc in snap.docs) {
          final parsed = InspectorFeedSnapshot.tryParse(doc.id, doc.data());
          if (parsed != null) map[doc.id] = parsed;
        }
        _latestInspectorFeed = map;
        if (!_inspectorFeedCtrl.isClosed) _inspectorFeedCtrl.add(map);
      },
      onError: (_) {},
    );
  }

  void stopInspectorFeedListener() {
    _inspectorFeedSub?.cancel();
    _inspectorFeedSub = null;
    _latestInspectorFeed = const {};
    if (!_inspectorFeedCtrl.isClosed) _inspectorFeedCtrl.add(const {});
  }

  void _startHeartbeat() {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = Timer.periodic(const Duration(seconds: 60), (_) {
      unawaited(publishPresence(tension: false));
    });
  }

  @override
  Future<void> disconnect() async {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = null;
    await _membersSub?.cancel();
    _membersSub = null;
    await _roomSub?.cancel();
    _roomSub = null;
    stopRoomEventsListener();
    stopInspectorFeedListener();
    _hostUid = null;
    _phase = RoomPhase.lobby;
    _latestMatchStart = null;
    _latestRoomMatch = const RoomMatchState(phase: RoomPhase.lobby);
    _lastMemberSnap = null;
    _latestLobby = const [];
    _latestRemoteMembers = const {};
    _werewolfOniFormByUid = const {};
    _latestInspectorFeed = const {};
    if (!_lobbyCtrl.isClosed) _lobbyCtrl.add([]);
    if (!_remoteCtrl.isClosed) _remoteCtrl.add({});
    if (!_phaseCtrl.isClosed) _phaseCtrl.add(_phase);
    if (!_roomMatchCtrl.isClosed) _roomMatchCtrl.add(_latestRoomMatch);
    final rid = _roomId;
    final uid = _uid;
    _roomId = null;
    _uid = null;
    _nickname = null;
    _role = 'runner';
    try {
      if (rid != null && uid != null) {
        await clearInspectorFeedPosition();
        await _db
            .collection('rooms')
            .doc(rid)
            .collection('members')
            .doc(uid)
            .delete();
      }
    } catch (_) {}
    // 匿名 Auth は維持する。signOut すると再参加のたびに別 UID になり別人扱いになる。
  }
}
