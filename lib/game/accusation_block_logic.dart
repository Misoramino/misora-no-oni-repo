import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import 'game_config.dart';

/// 生存中の本鬼が告発施設付近にいる間、その施設での告発を一時不可にする。
abstract final class AccusationBlockLogic {
  static bool isHunterBlockingSite({
    required LatLng facilityPosition,
    required LatLng? hunterPosition,
    required bool hunterPositionKnown,
  }) {
    if (!hunterPositionKnown || hunterPosition == null) return false;
    final d = Geolocator.distanceBetween(
      facilityPosition.latitude,
      facilityPosition.longitude,
      hunterPosition.latitude,
      hunterPosition.longitude,
    );
    return d <= GameConfig.accusationHunterBlockRadiusMeters;
  }
}
