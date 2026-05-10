import 'package:google_maps_flutter/google_maps_flutter.dart';

/// エリア外猶予超過による「位置暴露」。将来 Firestore / FCM へそのまま載せやすい形。
class LocationRevealEvent {
  LocationRevealEvent({
    required this.sequence,
    required this.timestamp,
    required this.position,
    required this.overflowMeters,
    this.playerLabel = 'player1',
  });

  final int sequence;
  final DateTime timestamp;
  final LatLng position;
  final double overflowMeters;
  final String playerLabel;

  Map<String, dynamic> toJson() => {
        'type': 'location_reveal',
        'sequence': sequence,
        'playerLabel': playerLabel,
        'at': timestamp.toUtc().toIso8601String(),
        'lat': position.latitude,
        'lng': position.longitude,
        'overflowMeters': overflowMeters,
      };

  factory LocationRevealEvent.fromJson(Map<String, dynamic> json) {
    return LocationRevealEvent(
      sequence: (json['sequence'] as num).toInt(),
      timestamp: DateTime.parse(json['at'] as String).toUtc(),
      position: LatLng(
        (json['lat'] as num).toDouble(),
        (json['lng'] as num).toDouble(),
      ),
      overflowMeters: (json['overflowMeters'] as num).toDouble(),
      playerLabel: json['playerLabel'] as String? ?? 'player1',
    );
  }

  @override
  String toString() => 'LocationReveal(#$sequence ${overflowMeters.toStringAsFixed(0)}m @ $position)';
}
