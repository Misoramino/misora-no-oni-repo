import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../match/match_geo_helpers.dart';

/// 情報屋など「本鬼（役割割当の hunter）」専用の位置・距離。
///
/// 接近判定の最寄り鬼（鬼化人狼含む）とは別に、割当 hunter のみを参照する。
abstract final class AssignedHunterIntel {
  static LatLng? position({
    required String? hunterUid,
    required String? myUid,
    required bool localIsHunter,
    required LatLng playerPosition,
    required Map<String, LatLng> lastKnownByUid,
  }) {
    if (hunterUid == null) return null;
    if (localIsHunter || hunterUid == myUid) return playerPosition;
    return lastKnownByUid[hunterUid];
  }

  static bool positionKnown({
    required bool testMode,
    required String? hunterUid,
    required bool localIsHunter,
    required Map<String, LatLng> lastKnownByUid,
  }) {
    if (testMode) return hunterUid != null;
    if (hunterUid == null) return false;
    if (localIsHunter) return true;
    return lastKnownByUid.containsKey(hunterUid);
  }

  static double distanceMeters({
    required LatLng playerPosition,
    required LatLng? hunterPosition,
    required bool known,
    required bool testMode,
    LatLng? testFallbackOni,
  }) {
    if (!known) return double.infinity;
    final hunter = hunterPosition ?? (testMode ? testFallbackOni : null);
    if (hunter == null) return double.infinity;
    if (testMode) {
      return MatchGeoHelpers.distanceToOni(
        player: playerPosition,
        oni: hunter,
        oniKnown: true,
        testMode: true,
      );
    }
    return Geolocator.distanceBetween(
      playerPosition.latitude,
      playerPosition.longitude,
      hunter.latitude,
      hunter.longitude,
    );
  }
}
