import 'package:google_maps_flutter/google_maps_flutter.dart';

class MatchEvent {
  const MatchEvent({
    required this.type,
    required this.atUtc,
    required this.message,
    required this.position,
  });

  final String type;
  final DateTime atUtc;
  final String message;
  final LatLng position;

  Map<String, dynamic> toJson() => {
        'type': type,
        'atUtc': atUtc.toIso8601String(),
        'message': message,
        'lat': position.latitude,
        'lng': position.longitude,
      };

  factory MatchEvent.fromJson(Map<String, dynamic> json) {
    return MatchEvent(
      type: json['type'] as String,
      atUtc: DateTime.parse(json['atUtc'] as String).toUtc(),
      message: json['message'] as String,
      position: LatLng(
        (json['lat'] as num).toDouble(),
        (json['lng'] as num).toDouble(),
      ),
    );
  }
}
