import 'package:google_maps_flutter/google_maps_flutter.dart';

/// エリア外が続いた・罠・偽情報などによる「位置暴露」。将来 Firestore / FCM へそのまま載せやすい形。
class LocationRevealEvent {
  LocationRevealEvent({
    required this.sequence,
    required this.timestamp,
    required this.position,
    required this.overflowMeters,
    this.playerLabel = 'player1',
    this.reasonSummary,
  });

  final int sequence;
  final DateTime timestamp;
  final LatLng position;
  final double overflowMeters;
  final String playerLabel;

  /// プレイヤー向け短い説明（例: エリア外、監視カメラ、偽情報暴露）。
  final String? reasonSummary;

  Map<String, dynamic> toJson() => {
        'type': 'location_reveal',
        'sequence': sequence,
        'playerLabel': playerLabel,
        'at': timestamp.toUtc().toIso8601String(),
        'lat': position.latitude,
        'lng': position.longitude,
        'overflowMeters': overflowMeters,
        if (reasonSummary != null) 'reasonSummary': reasonSummary,
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
      reasonSummary: json['reasonSummary'] as String?,
    );
  }

  @override
  String toString() =>
      'LocationReveal(#$sequence ${overflowMeters.toStringAsFixed(0)}m @ $position)';
}
