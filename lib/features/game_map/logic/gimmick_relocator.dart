import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../../game/generated_gimmicks.dart';
import '../../../game/play_area.dart';

/// ギミック地点の再配置（副作用なし）。
abstract final class GimmickRelocator {
  static LatLng relocate({
    required PlayArea area,
    required List<LatLng> avoid,
    required double angleSeed,
    required double radiusFactor,
  }) {
    final center = GeneratedGimmicks.centerOf(area);
    final radius = GeneratedGimmicks.effectiveRadiusMeters(
      area,
      center,
    ).clamp(180.0, 2400.0);
    final minGap = (radius * 0.16).clamp(45.0, 160.0);
    return GeneratedGimmicks.pointInArea(
      area: area,
      center: center,
      angleDegrees: angleSeed % 360,
      distanceMeters: radius * radiusFactor,
      avoid: avoid,
      minGapMeters: minGap,
    );
  }
}
