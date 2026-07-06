import 'firestore_room_blueprint.dart';
/// Firestore `members` ドキュメントのローカル表現。
///
/// 試合中はスロットル付きで [lat]/[lng] が載る（地図ピンは出さない・
/// `locationVisibility: hidden`）。鬼側の距離判定・バックグラウンド捕獲の補助に使う。
class RemoteMemberSnapshot {
  const RemoteMemberSnapshot({
    required this.uid,
    required this.nickname,
    required this.role,
    required this.reportedAtUtc,
    this.lat,
    this.lng,
    this.proximityBand,
    this.avatarThumbB64,
  });

  final String uid;
  final String nickname;
  final String role;
  final double? lat;
  final double? lng;
  final DateTime? reportedAtUtc;
  final String? proximityBand;
  final String? avatarThumbB64;

  /// 座標が両方とも揃っているときのみ true。
  bool get hasCoords => lat != null && lng != null;

  /// members ドキュメントから生成。座標が無くても（顔写真等のため）生成する。
  static RemoteMemberSnapshot? tryParse(String uid, Map<String, dynamic> data) {
    final rawLat = data[MemberPresenceFields.lastLat];
    final rawLng = data[MemberPresenceFields.lastLng];
    final rawTime = data[MemberPresenceFields.reportedAtUtc];
    DateTime? at;
    if (rawTime is String) {
      at = DateTime.tryParse(rawTime);
    }
    return RemoteMemberSnapshot(
      uid: uid,
      nickname: (data[MemberPresenceFields.nickname] as String?) ?? '',
      role: (data[MemberPresenceFields.role] as String?) ?? 'runner',
      lat: rawLat is num ? rawLat.toDouble() : null,
      lng: rawLng is num ? rawLng.toDouble() : null,
      reportedAtUtc: at,
      proximityBand: data[MemberPresenceFields.proximityBand] as String?,
      avatarThumbB64: data[MemberPresenceFields.avatarThumbB64] as String?,
    );
  }
}
