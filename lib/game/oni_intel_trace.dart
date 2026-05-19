import 'package:google_maps_flutter/google_maps_flutter.dart';

class OniIntelTrace {
  const OniIntelTrace({
    required this.timestamp,
    required this.position,
    required this.text,
  });

  final DateTime timestamp;
  final LatLng position;
  final String text;
}
