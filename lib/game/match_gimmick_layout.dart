import 'package:google_maps_flutter/google_maps_flutter.dart';

/// 試合開始時のギミック配置（リプレイ地図表示用）。
class MatchGimmickLayout {
  const MatchGimmickLayout({
    this.safeZones = const [],
    this.infoBrokers = const [],
    this.cameras = const [],
    this.cameraJacks = const [],
    this.accusationFacilities = const [],
    this.commJammingZones = const [],
  });

  final List<LatLng> safeZones;
  final List<LatLng> infoBrokers;
  final List<LatLng> cameras;
  final List<LatLng> cameraJacks;
  final List<LatLng> accusationFacilities;
  final List<LatLng> commJammingZones;

  Map<String, dynamic> toJson() => {
        'safeZones': safeZones.map(_latLng).toList(),
        'infoBrokers': infoBrokers.map(_latLng).toList(),
        'cameras': cameras.map(_latLng).toList(),
        'cameraJacks': cameraJacks.map(_latLng).toList(),
        'accusationFacilities': accusationFacilities.map(_latLng).toList(),
        'commJammingZones': commJammingZones.map(_latLng).toList(),
      };

  factory MatchGimmickLayout.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const MatchGimmickLayout();
    List<LatLng> readList(String key) =>
        (json[key] as List<dynamic>? ?? const [])
            .map((e) => _fromMap(e as Map<String, dynamic>))
            .toList();
    return MatchGimmickLayout(
      safeZones: readList('safeZones'),
      infoBrokers: readList('infoBrokers'),
      cameras: readList('cameras'),
      cameraJacks: readList('cameraJacks'),
      accusationFacilities: readList('accusationFacilities'),
      commJammingZones: readList('commJammingZones'),
    );
  }

  static Map<String, double> _latLng(LatLng p) => {
        'lat': p.latitude,
        'lng': p.longitude,
      };

  static LatLng _fromMap(Map<String, dynamic> m) => LatLng(
        (m['lat'] as num).toDouble(),
        (m['lng'] as num).toDouble(),
      );
}
