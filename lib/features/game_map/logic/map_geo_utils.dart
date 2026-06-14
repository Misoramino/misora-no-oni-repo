import 'dart:math' as math;

import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../../game/game_config.dart';

/// 地図・近接判定の純粋関数群。
abstract final class MapGeoUtils {
  static String formatClock(int seconds) {
    final min = (seconds ~/ 60).toString().padLeft(2, '0');
    final sec = (seconds % 60).toString().padLeft(2, '0');
    return '$min:$sec';
  }

  static String bearingToDirection(double bearing) {
    final b = (bearing + 360) % 360;
    if (b >= 337.5 || b < 22.5) return '北';
    if (b < 67.5) return '北東';
    if (b < 112.5) return '東';
    if (b < 157.5) return '南東';
    if (b < 202.5) return '南';
    if (b < 247.5) return '南西';
    if (b < 292.5) return '西';
    return '北西';
  }

  static String fragmentedCoarseCardinal(double bearingDegrees) {
    final b = (bearingDegrees + 360) % 360;
    if (b >= 315 || b < 45) return '北寄り';
    if (b < 135) return '東寄り';
    if (b < 225) return '南寄り';
    return '西寄り';
  }

  static int? firstPointWithinIndex(
    List<LatLng> points,
    double radiusMeters,
    LatLng origin,
  ) {
    for (var i = 0; i < points.length; i++) {
      final p = points[i];
      final d = Geolocator.distanceBetween(
        origin.latitude,
        origin.longitude,
        p.latitude,
        p.longitude,
      );
      if (d <= radiusMeters) return i;
    }
    return null;
  }

  static LatLng? firstPointWithin(
    List<LatLng> points,
    double radiusMeters,
    LatLng origin,
  ) {
    final index = firstPointWithinIndex(points, radiusMeters, origin);
    return index == null ? null : points[index];
  }

  static bool isPointInZone(
    LatLng point,
    List<LatLng> zoneCenters,
    double radiusMeters,
  ) =>
      firstPointWithin(zoneCenters, radiusMeters, point) != null;

  static bool isCommJammingWindowOpen({
    required LatLng playerPosition,
    required List<LatLng> jammingZoneCenters,
    required int elapsedSeconds,
  }) {
    if (!isPointInZone(
      playerPosition,
      jammingZoneCenters,
      GameConfig.commJammingZoneRadiusMeters,
    )) {
      return true;
    }
    final bucket = (elapsedSeconds ~/ GameConfig.commJammingCycleSeconds) % 2;
    return bucket == 0;
  }

  /// 通信障害地帯内のプレイヤー向けに、暴露位置へノイズを載せる。
  static LatLng displayRevealPositionWithJamming({
    required LatLng raw,
    required LatLng viewerPosition,
    required List<LatLng> jammingZoneCenters,
    math.Random? random,
  }) {
    if (!isPointInZone(
      viewerPosition,
      jammingZoneCenters,
      GameConfig.commJammingZoneRadiusMeters,
    )) {
      return raw;
    }
    final r = random ?? math.Random();
    final meters = 45 + r.nextDouble() * 70;
    final bearing = r.nextDouble() * 360;
    final latOffset = meters / 111111 * math.cos(bearing * math.pi / 180);
    final lngOffset =
        meters /
        (111111 * math.cos(raw.latitude * math.pi / 180)) *
        math.sin(bearing * math.pi / 180);
    return LatLng(raw.latitude + latOffset, raw.longitude + lngOffset);
  }

  /// 定期暴露など — 実位置から少しずらして表示する（全員同一座標を Firestore で共有）。
  static LatLng jitterRevealPosition({
    required LatLng raw,
    required int seed,
    double minMeters = 16,
    double maxMeters = 24,
  }) {
    final r = math.Random(seed);
    final span = (maxMeters - minMeters).clamp(1.0, 200.0);
    final meters = minMeters + r.nextDouble() * span;
    final bearing = r.nextDouble() * 360;
    final latOffset = meters / 111111 * math.cos(bearing * math.pi / 180);
    final lngOffset =
        meters /
        (111111 * math.cos(raw.latitude * math.pi / 180)) *
        math.sin(bearing * math.pi / 180);
    return LatLng(raw.latitude + latOffset, raw.longitude + lngOffset);
  }
}
