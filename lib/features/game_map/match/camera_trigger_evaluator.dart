import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

/// 監視カメラのトリガー判定（副作用なし）。
///
/// 各カメラは [cooldownSeconds] 経過後に同じ地点で再検知できる。
abstract final class CameraTriggerEvaluator {
  static List<int> newlyTriggeredIndices({
    required List<LatLng> cameraPositions,
    required Map<int, DateTime> lastTriggeredAt,
    required LatLng playerPosition,
    required double triggerRadiusMeters,
    required int cooldownSeconds,
    required DateTime now,
  }) {
    final out = <int>[];
    for (var i = 0; i < cameraPositions.length; i++) {
      final last = lastTriggeredAt[i];
      if (last != null &&
          now.difference(last).inSeconds < cooldownSeconds) {
        continue;
      }
      final p = cameraPositions[i];
      final d = Geolocator.distanceBetween(
        playerPosition.latitude,
        playerPosition.longitude,
        p.latitude,
        p.longitude,
      );
      if (d <= triggerRadiusMeters) out.add(i);
    }
    return out;
  }
}
