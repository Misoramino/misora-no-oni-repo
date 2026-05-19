import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../logic/map_geo_utils.dart';

/// ギミック拾得・再出現の純粋判定。
abstract final class GimmickPickupEvaluator {
  /// 拾得可能なら地点インデックス。不可なら null。
  static int? pickupIndexIfAllowed({
    required bool available,
    required List<LatLng> positions,
    required double radiusMeters,
    required LatLng playerPosition,
    required DateTime? lastPickupAt,
    required int cooldownSeconds,
    required DateTime now,
  }) {
    if (!available) return null;
    if (lastPickupAt != null &&
        now.difference(lastPickupAt).inSeconds < cooldownSeconds) {
      return null;
    }
    return MapGeoUtils.firstPointWithinIndex(
      positions,
      radiusMeters,
      playerPosition,
    );
  }

  static bool shouldRespawn({
    required bool available,
    required DateTime? respawnAt,
    required DateTime now,
  }) =>
      !available && respawnAt != null && !now.isBefore(respawnAt);
}
