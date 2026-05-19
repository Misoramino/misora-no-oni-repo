import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'firebase_bootstrap.dart';
import 'firestore_room_blueprint.dart';
import 'presence_throttle.dart';
import 'remote_member_snapshot.dart';
import 'room_member_view.dart';
import '../game/game_state.dart';
import 'room_phase.dart';
import 'room_session_port.dart';
import 'shared_match_snapshot.dart';

/// Firestore ルームの最小プレゼンス同期（匿名 UID + members ドキュメント）。
///
/// セキュリティルールは必ず本番用に差し替えてください（現状は開発向け想定）。
class FirestoreRoomSession implements RoomSessionPort {
  FirestoreRoomSession();

  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final PresenceThrottle _calm = calmPresenceThrottle();
  final PresenceThrottle _tense = tensionPresenceThrottle();

  String? _roomId;
  String? _uid;
  String? _nickname;
  String _role = 'runner';
  Timer? _heartbeatTimer;
  List<RoomMemberView> _latestLobby = const [];

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

  RoomMatchState _latestRoomMatch = const RoomMatchState(phase: RoomPhase.lobby);
  SharedMatchSnapshot? _latestMatchStart;

  Stream<Map<String, RemoteMemberSnapshot>> get remoteMembers =>
      _remoteCtrl.stream;

  /// ルーム内の全メンバー（自分を含む）。ロビー UI 用。
  Stream<List<RoomMemberView>> get lobbyMembers => _lobbyCtrl.stream;
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

  /// 現在のルームフェーズ（lobby / running / ended）。
  String get currentPhase => _phase;

  /// フェーズ変更の通知（参加・再接続時に現在値も流れる）。
  Stream<String> get roomPhase => _phaseCtrl.stream;

  /// phase + 共有試合開始/終了データ。
  Stream<RoomMatchState> get roomMatchState => _roomMatchCtrl.stream;

  RoomMatchState get currentRoomMatch => _latestRoomMatch;

  SharedMatchSnapshot? get currentMatchStart => _latestMatchStart;

  /// エラー時はメッセージを返す。
  Future<String?> join({
    required String roomId,
    required String nickname,
    String role = 'runner',
  }) async {
    if (!FirebaseBootstrap.isReady) {
      return 'Firebase が初期化されていません。\n'
          'Android: android/app/google-services.json を置いてフル再ビルドするか、'
          'dart-define で FIREBASE_* を指定してください。';
    }
    try {
      await disconnect();
      await FirebaseAuth.instance.signInAnonymously();
      _uid = FirebaseAuth.instance.currentUser?.uid;
      if (_uid == null) return '匿名ログインに失敗しました';
      _roomId = roomId.trim();
      _nickname = nickname.trim();
      _role = role.trim().isEmpty ? 'runner' : role.trim();

      final roomRef = _db.collection('rooms').doc(_roomId);
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

      final memberRef = roomRef.collection('members').doc(_uid!);
      await memberRef.set({
        MemberPresenceFields.nickname: _nickname,
        MemberPresenceFields.role: _role,
        MemberPresenceFields.reportedAtUtc: DateTime.now()
            .toUtc()
            .toIso8601String(),
        MemberPresenceFields.locationVisibility: 'hidden',
      });
      _startHeartbeat();
      _bindRoomAndMembers();
      return null;
    } on FirebaseAuthException catch (e) {
      return '認証エラー: ${e.message ?? e.code}';
    } on FirebaseException catch (e) {
      return 'Firestore: ${e.message ?? e.code}';
    } catch (e) {
      return '接続エラー: $e';
    }
  }

  void _bindRoomAndMembers() {
    if (_roomId == null) return;
    final rid = _roomId!;
    _roomSub?.cancel();
    _roomSub = _db.collection('rooms').doc(rid).snapshots().listen((roomSnap) {
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
  }

  QuerySnapshot<Map<String, dynamic>>? _lastMemberSnap;

  void _emitLobbyFromSnapshot(
    QuerySnapshot<Map<String, dynamic>> snap,
  ) {
    _lastMemberSnap = snap;
    _emitLobbyFromLastMembers();
  }

  void _emitLobbyFromLastMembers() {
    final snap = _lastMemberSnap;
    if (snap == null) return;
    final host = _hostUid;
    final out = <String, RemoteMemberSnapshot>{};
    final lobby = <RoomMemberView>[];
    final now = DateTime.now().toUtc();
    for (final d in snap.docs) {
      final isSelf = d.id == _uid;
      final view = RoomMemberView.parse(
        uid: d.id,
        data: d.data(),
        isSelf: isSelf,
        isHost: host != null && d.id == host,
      );
      if (!isSelf && view.isStale(now)) continue;
      lobby.add(view);
      final remote = RemoteMemberSnapshot.tryParse(d.id, d.data());
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
    if (!_remoteCtrl.isClosed) _remoteCtrl.add(out);
    if (!_lobbyCtrl.isClosed) _lobbyCtrl.add(_latestLobby);
  }

  /// ホストのみ。試合開始データと phase=running を 1 回で書く。
  Future<String?> publishMatchStart(SharedMatchSnapshot snapshot) async {
    if (_roomId == null) return 'ルームに参加していません';
    if (!isHost) return 'ホストのみ開始できます';
    try {
      final started = snapshot.startedAtUtc ??
          DateTime.now().toUtc().toIso8601String();
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
      return null;
    } on FirebaseException catch (e) {
      return e.message ?? e.code;
    } catch (e) {
      return '$e';
    }
  }

  /// ホストのみ。ロビーへ戻す（共有試合データをクリア）。
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
      }
      await _db.collection('rooms').doc(_roomId).update(patch);
      _phase = RoomPhase.normalize(phase);
      if (!_phaseCtrl.isClosed) _phaseCtrl.add(_phase);
      _latestRoomMatch = RoomMatchState(
        phase: _phase,
        matchStart: _latestMatchStart,
        matchEnd: phase == RoomPhase.ended
            ? _latestRoomMatch.matchEnd
            : null,
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

  Future<void> publishPresence({
    required bool tension,
    String? proximityBandName,
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
    await ref.set(payload);
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
    _hostUid = null;
    _phase = RoomPhase.lobby;
    _latestMatchStart = null;
    _latestRoomMatch = const RoomMatchState(phase: RoomPhase.lobby);
    _lastMemberSnap = null;
    _latestLobby = const [];
    if (!_lobbyCtrl.isClosed) _lobbyCtrl.add([]);
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
