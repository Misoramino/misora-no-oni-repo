import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

/// 監視カメラの新規トリガー判定（副作用なし）。
abstract final class CameraTriggerEvaluator {
  static List<int> newlyTriggeredIndices({
    required List<LatLng> cameraPositions,
    required Set<int> alreadyTriggered,
    required LatLng playerPosition,
    required double triggerRadiusMeters,
  }) {
    final out = <int>[];
    for (var i = 0; i < cameraPositions.length; i++) {
      if (alreadyTriggered.contains(i)) continue;
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
