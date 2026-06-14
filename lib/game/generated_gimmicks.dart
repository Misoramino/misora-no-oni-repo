import 'dart:math' as math;

import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../services/roads_snap_service.dart';
import 'game_config.dart';
import 'play_area.dart';

/// プレイエリア内にランダム配置するギミック座標群。
class GeneratedGimmicks {
  const GeneratedGimmicks({
    required this.safeZones,
    required this.infoBrokers,
    required this.cameras,
    required this.eventAreas,
    required this.accusationFacilities,
    required this.cameraJackSites,
  });

  final List<LatLng> safeZones;
  final List<LatLng> infoBrokers;
  final List<LatLng> cameras;
  final List<LatLng> eventAreas;
  final List<LatLng> accusationFacilities;
  final List<LatLng> cameraJackSites;

  GeneratedGimmicks copyWith({
    List<LatLng>? eventAreas,
    List<LatLng>? accusationFacilities,
    List<LatLng>? cameraJackSites,
  }) =>
      GeneratedGimmicks(
        safeZones: safeZones,
        infoBrokers: infoBrokers,
        cameras: cameras,
        eventAreas: eventAreas ?? this.eventAreas,
        accusationFacilities:
            accusationFacilities ?? this.accusationFacilities,
        cameraJackSites: cameraJackSites ?? this.cameraJackSites,
      );

  /// 試合開始用。道路上へ寄せ、寄せられない点は既存ギミックから離れた位置へ再配置。
  static Future<GeneratedGimmicks> createForMatchStart({
    required PlayArea area,
    required int seed,
    required double density,
    String googleMapsApiKey = '',
  }) async {
    final base = GeneratedGimmicks.create(
      area,
      seed: seed,
      density: density,
    );
    if (googleMapsApiKey.isEmpty) return base;

    final placed = <LatLng>[];

    Future<List<LatLng>> placeGroup(List<LatLng> candidates, int groupSeed) async {
      final snaps = await RoadsSnapService.snapWithStatus(
        candidates: candidates,
        apiKey: googleMapsApiKey,
      );
      final out = <LatLng>[];
      for (var i = 0; i < snaps.length; i++) {
        final LatLng p;
        if (snaps[i].onRoad) {
          p = snaps[i].position;
        } else {
          p = relocateFarFromOthers(
            area: area,
            placed: [...placed, ...out],
            seed: seed + groupSeed + i * 37,
          );
        }
        out.add(p);
      }
      placed.addAll(out);
      return out;
    }

    final safeZones = await placeGroup(base.safeZones, 11);
    final infoBrokers = await placeGroup(base.infoBrokers, 22);
    final eventAreas = await placeGroup(base.eventAreas, 33);
    final accusationFacilities = await placeGroup(base.accusationFacilities, 44);
    final cameras = await placeGroup(base.cameras, 55);
    final cameraJackSites = <LatLng>[];
    for (var i = 0; i < cameras.length; i += 2) {
      cameraJackSites.add(cameras[i]);
    }
    if (cameraJackSites.isEmpty && cameras.isNotEmpty) {
      cameraJackSites.add(cameras.first);
    }
    return GeneratedGimmicks(
      safeZones: safeZones,
      infoBrokers: infoBrokers,
      cameras: cameras,
      eventAreas: eventAreas,
      accusationFacilities: accusationFacilities,
      cameraJackSites: cameraJackSites,
    );
  }

  /// [seed] を指定すると全端末で同じ配置になる。
  /// [density] はギミック個数の倍率（0.5〜1.5 程度推奨、既定 1.0）。
  factory GeneratedGimmicks.create(
    PlayArea area, {
    int? seed,
    double density = 1.0,
  }) {
    final d = density.clamp(0.45, 1.55);
    final s = seed ?? DateTime.now().millisecondsSinceEpoch;
    final center = centerOf(area);
    final radius = effectiveRadiusMeters(area, center).clamp(180.0, 2400.0);
    int densify(int count, int minC, int maxC) {
      return (count * d).round().clamp(minC, maxC);
    }
    final safeCount = densify(
      _scaledCount(
        radius,
        GameConfig.safeZoneMinCount,
        GameConfig.safeZoneMaxCount,
      ),
      GameConfig.safeZoneMinCount,
      GameConfig.safeZoneMaxCount,
    );
    final brokerCount = densify(
      _scaledCount(
        radius,
        GameConfig.infoBrokerMinCount,
        GameConfig.infoBrokerMaxCount,
      ),
      GameConfig.infoBrokerMinCount,
      GameConfig.infoBrokerMaxCount,
    );
    final cameraBase =
        (GameConfig.cameraMinCount + ((radius - 250) / 180).floor())
            .clamp(GameConfig.cameraMinCount, GameConfig.cameraMaxCount)
            .toInt();
    final cameraCount = densify(
      cameraBase,
      GameConfig.cameraMinCount,
      GameConfig.cameraMaxCount,
    );
    final eventCount = densify(
      _scaledCount(
        radius,
        GameConfig.commJammingZoneMinCount,
        GameConfig.commJammingZoneMaxCount,
      ),
      GameConfig.commJammingZoneMinCount,
      GameConfig.commJammingZoneMaxCount,
    );
    final accusationCount = densify(
      _scaledCount(
        radius,
        GameConfig.accusationFacilityMinCount,
        GameConfig.accusationFacilityMaxCount,
      ),
      GameConfig.accusationFacilityMinCount,
      GameConfig.accusationFacilityMaxCount,
    );
    final minGap = (radius * 0.14).clamp(48.0, 150.0);

    final used = <LatLng>[];
    List<LatLng> group({
      required int count,
      required double angleSeed,
      required double radiusFactor,
      double? minGapOverride,
      int sectorOffset = 0,
    }) {
      final out = <LatLng>[];
      final gap = minGapOverride ?? minGap;
      final sector = 360.0 / math.max(1, count);
      final bands = <double>[
        (radiusFactor + 0.28).clamp(0.42, 0.94),
        (radiusFactor + 0.10).clamp(0.34, 0.78),
        (radiusFactor - 0.08).clamp(0.28, 0.62),
        (radiusFactor - 0.20).clamp(0.22, 0.52),
      ];
      for (var i = 0; i < count; i++) {
        final jitter = ((s + i * 17 + sectorOffset * 7) % 37) - 18;
        final angle = angleSeed + sectorOffset * 41 + i * sector + jitter * 0.35;
        final dist = math.max(
          radius * bands[i % bands.length],
          radius * 0.25,
        );
        final p = pointInArea(
          area: area,
          center: center,
          angleDegrees: angle,
          distanceMeters: dist,
          avoid: used,
          minGapMeters: gap,
          seed: s + i * 31 + sectorOffset * 13,
        );
        out.add(p);
        used.add(p);
      }
      return out;
    }

    final eventAreas = group(
      count: eventCount,
      angleSeed: 315 + ((s ~/ 19) % 360),
      radiusFactor: 0.50,
      sectorOffset: 0,
    );
    final accusationFacilities = group(
      count: accusationCount,
      angleSeed: 90 + ((s ~/ 23) % 360),
      radiusFactor: 0.30,
      minGapOverride: minGap * 1.1,
      sectorOffset: 2,
    );
    final cameras = group(
      count: cameraCount,
      angleSeed: 245 + ((s ~/ 13) % 360),
      radiusFactor: 0.48,
      minGapOverride: (radius * 0.10).clamp(40.0, 110.0),
      sectorOffset: 4,
    );
    final cameraJackSites = <LatLng>[];
    for (var i = 0; i < cameras.length; i += 2) {
      cameraJackSites.add(cameras[i]);
    }
    if (cameraJackSites.isEmpty && cameras.isNotEmpty) {
      cameraJackSites.add(cameras.first);
    }

    return GeneratedGimmicks(
      safeZones: group(
        count: safeCount,
        angleSeed: 35 + (s % 360),
        radiusFactor: 0.42,
        sectorOffset: 1,
      ),
      infoBrokers: group(
        count: brokerCount,
        angleSeed: 150 + ((s ~/ 7) % 360),
        radiusFactor: 0.58,
        sectorOffset: 3,
      ),
      cameras: cameras,
      eventAreas: eventAreas,
      accusationFacilities: accusationFacilities,
      cameraJackSites: cameraJackSites,
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
    int seed = 0,
  }) {
    final scales = <double>[1.0, 0.88, 0.76, 0.64, 0.52, 0.40];
    for (var attempt = 0; attempt < scales.length; attempt++) {
      final angleJitter = (seed + attempt * 47) % 360;
      final p = _offset(
        center,
        angleDegrees + angleJitter * 0.15,
        distanceMeters * scales[attempt],
      );
      if (area.contains(p) && _farEnough(p, avoid, minGapMeters)) return p;
    }
    // 最後の手段: 中心ではなく、少しずらした地点を試す（中心固まり防止）。
    for (var k = 0; k < 8; k++) {
      final fallback = _offset(
        center,
        angleDegrees + k * 45 + (seed % 30),
        math.max(40.0, distanceMeters * 0.35),
      );
      if (area.contains(fallback) && _farEnough(fallback, avoid, minGapMeters * 0.7)) {
        return fallback;
      }
    }
    return _offset(center, angleDegrees, math.min(distanceMeters * 0.3, 120));
  }

  /// 道路スナップ失敗時 — 既存ギミックからできるだけ離れたエリア内地点。
  static LatLng relocateFarFromOthers({
    required PlayArea area,
    required List<LatLng> placed,
    required int seed,
  }) {
    final center = centerOf(area);
    final radius = effectiveRadiusMeters(area, center);
    final minGap = (radius * 0.12).clamp(40.0, 120.0);
    var best = pointInArea(
      area: area,
      center: center,
      angleDegrees: (seed % 360).toDouble(),
      distanceMeters: radius * 0.55,
      avoid: placed,
      minGapMeters: minGap,
      seed: seed,
    );
    var bestMinDist = _minDistanceMeters(best, placed);
    for (var attempt = 1; attempt < 24; attempt++) {
      final angle = (seed + attempt * 73) % 360.0;
      final dist = radius * (0.30 + (attempt % 7) * 0.08).clamp(0.30, 0.90);
      final candidate = pointInArea(
        area: area,
        center: center,
        angleDegrees: angle,
        distanceMeters: dist,
        avoid: placed,
        minGapMeters: minGap,
        seed: seed + attempt * 19,
      );
      final minD = _minDistanceMeters(candidate, placed);
      if (minD > bestMinDist) {
        bestMinDist = minD;
        best = candidate;
      }
    }
    return best;
  }

  static double _minDistanceMeters(LatLng p, List<LatLng> others) {
    if (others.isEmpty) return double.infinity;
    var min = double.infinity;
    for (final o in others) {
      final d = Geolocator.distanceBetween(
        p.latitude,
        p.longitude,
        o.latitude,
        o.longitude,
      );
      if (d < min) min = d;
    }
    return min;
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
