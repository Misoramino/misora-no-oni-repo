import 'dart:math' as math;

import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import 'game_config.dart';
import 'play_area.dart';

/// プレイエリア内にランダム配置するギミック座標群。
class GeneratedGimmicks {
  const GeneratedGimmicks({
    required this.safeZones,
    required this.infoBrokers,
    required this.cameras,
    required this.eventAreas,
  });

  final List<LatLng> safeZones;
  final List<LatLng> infoBrokers;
  final List<LatLng> cameras;
  final List<LatLng> eventAreas;

  /// [seed] を指定すると全端末で同じ配置になる。
  factory GeneratedGimmicks.create(PlayArea area, {int? seed}) {
    final s = seed ?? DateTime.now().millisecondsSinceEpoch;
    final center = centerOf(area);
    final radius = effectiveRadiusMeters(area, center).clamp(180.0, 2400.0);
    final safeCount = _scaledCount(
      radius,
      GameConfig.safeZoneMinCount,
      GameConfig.safeZoneMaxCount,
    );
    final brokerCount = _scaledCount(
      radius,
      GameConfig.infoBrokerMinCount,
      GameConfig.infoBrokerMaxCount,
    );
    final cameraCount =
        (GameConfig.cameraMinCount + ((radius - 250) / 180).floor())
            .clamp(GameConfig.cameraMinCount, GameConfig.cameraMaxCount)
            .toInt();
    final eventCount = _scaledCount(
      radius,
      GameConfig.commJammingZoneMinCount,
      GameConfig.commJammingZoneMaxCount,
    );
    final minGap = (radius * 0.18).clamp(60.0, 180.0);

    final used = <LatLng>[];
    List<LatLng> group({
      required int count,
      required double angleSeed,
      required double radiusFactor,
      double? minGapOverride,
    }) {
      final out = <LatLng>[];
      final gap = minGapOverride ?? minGap;
      for (var i = 0; i < count; i++) {
        final angle = angleSeed + i * (360 / math.max(1, count));
        final dist = radius * (radiusFactor + 0.08 * (i % 2));
        final p = pointInArea(
          area: area,
          center: center,
          angleDegrees: angle,
          distanceMeters: dist,
          avoid: used,
          minGapMeters: gap,
        );
        out.add(p);
        used.add(p);
      }
      return out;
    }

    return GeneratedGimmicks(
      safeZones: group(
        count: safeCount,
        angleSeed: 35 + (s % 360),
        radiusFactor: 0.42,
      ),
      infoBrokers: group(
        count: brokerCount,
        angleSeed: 150 + ((s ~/ 7) % 360),
        radiusFactor: 0.58,
      ),
      cameras: group(
        count: cameraCount,
        angleSeed: 245 + ((s ~/ 13) % 360),
        radiusFactor: 0.68,
        minGapOverride: (radius * 0.08).clamp(30.0, 90.0),
      ),
      eventAreas: group(
        count: eventCount,
        angleSeed: 315 + ((s ~/ 19) % 360),
        radiusFactor: 0.50,
      ),
    );
  }

  static int _scaledCount(double radius, int min, int max) {
    final extra = ((radius - 240) / 320).round();
    return (min + extra).clamp(min, max).toInt();
  }

  static LatLng centerOf(PlayArea area) {
    switch (area.type) {
      case PlayAreaType.circle:
        return area.center;
      case PlayAreaType.polygon:
        if (area.points.isEmpty) return const LatLng(35.681236, 139.767125);
        final lat =
            area.points.map((p) => p.latitude).reduce((a, b) => a + b) /
                area.points.length;
        final lng =
            area.points.map((p) => p.longitude).reduce((a, b) => a + b) /
                area.points.length;
        final center = LatLng(lat, lng);
        return area.contains(center) ? center : area.points.first;
    }
  }

  static double effectiveRadiusMeters(PlayArea area, LatLng center) {
    switch (area.type) {
      case PlayAreaType.circle:
        return area.radiusMeters;
      case PlayAreaType.polygon:
        var maxDistance = 240.0;
        for (final p in area.points) {
          maxDistance = math.max(
            maxDistance,
            Geolocator.distanceBetween(
              center.latitude,
              center.longitude,
              p.latitude,
              p.longitude,
            ),
          );
        }
        return maxDistance;
    }
  }

  static LatLng pointInArea({
    required PlayArea area,
    required LatLng center,
    required double angleDegrees,
    required double distanceMeters,
    required List<LatLng> avoid,
    required double minGapMeters,
  }) {
    for (final scale in const [1.0, 0.75, 0.55, 0.35]) {
      final p = _offset(center, angleDegrees, distanceMeters * scale);
      if (area.contains(p) && _farEnough(p, avoid, minGapMeters)) return p;
    }
    return center;
  }

  static bool _farEnough(LatLng p, List<LatLng> avoid, double minGapMeters) {
    for (final other in avoid) {
      final d = Geolocator.distanceBetween(
        p.latitude,
        p.longitude,
        other.latitude,
        other.longitude,
      );
      if (d < minGapMeters) return false;
    }
    return true;
  }

  static LatLng _offset(LatLng origin, double angleDegrees, double meters) {
    final rad = angleDegrees * math.pi / 180;
    final north = math.cos(rad) * meters;
    final east = math.sin(rad) * meters;
    final lat = origin.latitude + north / 111111;
    final lng =
        origin.longitude +
        east / (111111 * math.cos(origin.latitude * math.pi / 180));
    return LatLng(lat, lng);
  }
}
