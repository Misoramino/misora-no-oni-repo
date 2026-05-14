import 'firestore_room_blueprint.dart';
/// Firestore `members` ドキュメントのローカル表現。
class RemoteMemberSnapshot {
  const RemoteMemberSnapshot({
    required this.uid,
    required this.nickname,
    required this.role,
    required this.lat,
    required this.lng,
    required this.reportedAtUtc,
    this.proximityBand,
  });

  final String uid;
  final String nickname;
  final String role;
  final double lat;
  final double lng;
  final DateTime? reportedAtUtc;
  final String? proximityBand;

  static RemoteMemberSnapshot? tryParse(String uid, Map<String, dynamic> data) {
    final lat = data[MemberPresenceFields.lastLat];
    final lng = data[MemberPresenceFields.lastLng];
    if (lat is! num || lng is! num) return null;
    final rawTime = data[MemberPresenceFields.reportedAtUtc];
    DateTime? at;
    if (rawTime is String) {
      at = DateTime.tryParse(rawTime);
    }
    return RemoteMemberSnapshot(
      uid: uid,
      nickname: (data[MemberPresenceFields.nickname] as String?) ?? '',
      role: (data[MemberPresenceFields.role] as String?) ?? 'runner',
      lat: lat.toDouble(),
      lng: lng.toDouble(),
      reportedAtUtc: at,
      proximityBand: data[MemberPresenceFields.proximityBand] as String?,
    );
  }
}
