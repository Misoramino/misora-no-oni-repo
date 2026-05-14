import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'firebase_bootstrap.dart';
import 'firestore_room_blueprint.dart';
import 'presence_throttle.dart';
import 'remote_member_snapshot.dart';
import 'room_session_port.dart';

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

  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _membersSub;
  final StreamController<Map<String, RemoteMemberSnapshot>> _remoteCtrl =
      StreamController<Map<String, RemoteMemberSnapshot>>.broadcast();

  Stream<Map<String, RemoteMemberSnapshot>> get remoteMembers =>
      _remoteCtrl.stream;

  @override
  String? get roomId => _roomId;

  @override
  String get modeLabel =>
      _roomId == null ? 'Firebase（未参加）' : 'online: $_roomId';

  @override
  Future<void> connectLocalDemo() async {}

  String? get myUid => _uid;

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

      final memberRef =
          _db.collection('rooms').doc(_roomId).collection('members').doc(_uid!);
      await memberRef.set(
        {
          MemberPresenceFields.nickname: _nickname,
          MemberPresenceFields.role: _role,
        },
        SetOptions(merge: true),
      );

      await _membersSub?.cancel();
      _membersSub = _db
          .collection('rooms')
          .doc(_roomId)
          .collection('members')
          .snapshots()
          .listen((snap) {
        final out = <String, RemoteMemberSnapshot>{};
        for (final d in snap.docs) {
          if (d.id == _uid) continue;
          final m = RemoteMemberSnapshot.tryParse(d.id, d.data());
          if (m != null) out[d.id] = m;
        }
        if (!_remoteCtrl.isClosed) {
          _remoteCtrl.add(out);
        }
      });
      return null;
    } on FirebaseAuthException catch (e) {
      return '認証エラー: ${e.message ?? e.code}';
    } on FirebaseException catch (e) {
      return 'Firestore: ${e.message ?? e.code}';
    } catch (e) {
      return '接続エラー: $e';
    }
  }

  Future<void> publishPresence({
    required double lat,
    required double lng,
    required bool tension,
    String? proximityBandName,
  }) async {
    if (_roomId == null || _uid == null) return;
    final throttle = tension ? _tense : _calm;
    if (!throttle.requestSlot()) return;
    final ref =
        _db.collection('rooms').doc(_roomId).collection('members').doc(_uid!);
    final payload = <String, dynamic>{
      MemberPresenceFields.lastLat: lat,
      MemberPresenceFields.lastLng: lng,
      MemberPresenceFields.reportedAtUtc: DateTime.now().toUtc().toIso8601String(),
      MemberPresenceFields.role: _role,
      MemberPresenceFields.nickname: _nickname,
    };
    if (proximityBandName != null && proximityBandName.isNotEmpty) {
      payload[MemberPresenceFields.proximityBand] = proximityBandName;
    }
    await ref.set(payload, SetOptions(merge: true));
  }

  @override
  Future<void> disconnect() async {
    await _membersSub?.cancel();
    _membersSub = null;
    final rid = _roomId;
    final uid = _uid;
    _roomId = null;
    _uid = null;
    _nickname = null;
    _role = 'runner';
    try {
      if (rid != null && uid != null) {
        await _db.collection('rooms').doc(rid).collection('members').doc(uid).delete();
      }
    } catch (_) {}
    try {
      await FirebaseAuth.instance.signOut();
    } catch (_) {}
  }
}
