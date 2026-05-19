import 'package:google_maps_flutter/google_maps_flutter.dart';

/// 地図オーバーレイ用の座標・時間フォーマット。
abstract final class MapGeoFormat {
  static int secondsUntil(DateTime? target, [DateTime? now]) {
    if (target == null) return 0;
    final clock = now ?? DateTime.now();
    final diff = target.difference(clock).inSeconds;
    return diff < 0 ? 0 : diff;
  }

  static String traceAge(DateTime timestamp, [DateTime? now]) {
    final ageSeconds = (now ?? DateTime.now()).difference(timestamp).inSeconds;
    if (ageSeconds < 60) return '$ageSeconds秒前の暴露地点';
    return '${ageSeconds ~/ 60}分前の暴露地点';
  }

  static String intelTraceAge(DateTime timestamp, [DateTime? now]) {
    final ageSeconds = (now ?? DateTime.now()).difference(timestamp).inSeconds;
    if (ageSeconds < 60) return '$ageSeconds秒前の鬼情報';
    return '${ageSeconds ~/ 60}分前の鬼情報';
  }

  static String latLng(LatLng p) =>
      '${p.latitude.toStringAsFixed(5)}, ${p.longitude.toStringAsFixed(5)}';

  static List<LatLng> closedPolygonRing(List<LatLng> points) {
    if (points.length < 3) return points;
    final first = points.first;
    final last = points.last;
    if (first.latitude == last.latitude && first.longitude == last.longitude) {
      return points;
    }
    return [...points, first];
  }
}
