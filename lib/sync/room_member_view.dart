import 'firestore_room_blueprint.dart';

/// ロビー一覧用（自分／他プレイヤーを UI で区別）。
class RoomMemberView {
  const RoomMemberView({
    required this.uid,
    required this.nickname,
    required this.role,
    required this.isSelf,
    this.isHost = false,
    this.reportedAtUtc,
    this.proximityBand,
  });

  final String uid;
  final String nickname;
  final String role;
  final bool isSelf;
  final bool isHost;
  final DateTime? reportedAtUtc;
  final String? proximityBand;

  bool get hasHeartbeat => reportedAtUtc != null;

  bool isStale(DateTime nowUtc) {
    final at = reportedAtUtc;
    if (at == null) return false;
    return nowUtc.difference(at.toUtc()) > const Duration(minutes: 3);
  }

  static RoomMemberView parse({
    required String uid,
    required Map<String, dynamic> data,
    required bool isSelf,
    bool isHost = false,
  }) {
    final rawTime = data[MemberPresenceFields.reportedAtUtc];
    DateTime? at;
    if (rawTime is String) {
      at = DateTime.tryParse(rawTime);
    }
    return RoomMemberView(
      uid: uid,
      nickname: (data[MemberPresenceFields.nickname] as String?) ?? '',
      role: (data[MemberPresenceFields.role] as String?) ?? 'runner',
      isSelf: isSelf,
      isHost: isHost,
      reportedAtUtc: at,
      proximityBand: data[MemberPresenceFields.proximityBand] as String?,
    );
  }
}
