import 'package:flutter_test/flutter_test.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:oni_game/features/game_map/match/match_geo_helpers.dart';
import 'package:oni_game/game/play_area.dart';
import 'package:oni_game/proximity/proximity_signal.dart';

void main() {
  test('distanceToOni is infinite when oni unknown offline', () {
    expect(
      MatchGeoHelpers.distanceToOni(
        player: const LatLng(35, 139),
        oni: const LatLng(35.01, 139.01),
        oniKnown: false,
        testMode: false,
      ),
      double.infinity,
    );
  });

  test('effectiveInfectionDistance uses proximity band', () {
    expect(
      MatchGeoHelpers.effectiveInfectionDistance(
        gpsDistance: 50,
        proximityBand: ProximityBand.contact,
      ),
      0,
    );
    expect(
      MatchGeoHelpers.effectiveInfectionDistance(
        gpsDistance: 50,
        proximityBand: ProximityBand.near,
      ),
      40,
    );
  });

  test('scaledTouchRadius clamps for circle area', () {
    const area = PlayArea.circle(
      center: LatLng(35, 139),
      radiusMeters: 500,
    );
    final r = MatchGeoHelpers.scaledTouchRadiusMeters(area);
    expect(r, greaterThan(35));
    expect(r, lessThanOrEqualTo(95));
  });
}
