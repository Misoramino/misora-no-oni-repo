import 'firestore_room_blueprint.dart';

/// 観戦者（インスペクター）専用のライブ位置フィード。
///
/// `rooms/{roomId}/inspectorFeed/{uid}` — 参加者のみ書き込み、観戦者のみ読み取り。
class InspectorFeedSnapshot {
  const InspectorFeedSnapshot({
    required this.uid,
    required this.nickname,
    required this.role,
    required this.lat,
    required this.lng,
    required this.reportedAtUtc,
  });

  final String uid;
  final String nickname;
  final String role;
  final double lat;
  final double lng;
  final DateTime reportedAtUtc;

  static InspectorFeedSnapshot? tryParse(String uid, Map<String, dynamic> data) {
    final lat = data[InspectorFeedFields.lat];
    final lng = data[InspectorFeedFields.lng];
    if (lat is! num || lng is! num) return null;
    final rawTime = data[InspectorFeedFields.reportedAtUtc];
    DateTime? at;
    if (rawTime is String) {
      at = DateTime.tryParse(rawTime);
    }
    return InspectorFeedSnapshot(
      uid: uid,
      nickname: (data[InspectorFeedFields.nickname] as String?) ?? '',
      role: (data[InspectorFeedFields.role] as String?) ?? 'runner',
      lat: lat.toDouble(),
      lng: lng.toDouble(),
      reportedAtUtc: at ?? DateTime.now().toUtc(),
    );
  }
}
