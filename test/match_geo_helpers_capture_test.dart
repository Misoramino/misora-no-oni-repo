import 'package:flutter_test/flutter_test.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:oni_game/features/game_map/match/match_geo_helpers.dart';
import 'package:oni_game/game/game_config.dart';
import 'package:oni_game/proximity/proximity_signal.dart';

void main() {
  test('capture triggers on BLE contact when bound', () {
    expect(
      MatchGeoHelpers.isCaptureTriggered(
        running: true,
        testMode: false,
        oniKnown: true,
        isHunterNow: false,
        captureZoneBoundIds: {'self'},
        proximityBand: ProximityBand.contact,
        gpsDistanceToOniMeters: 80,
      ),
      isTrue,
    );
  });

  test('capture triggers on GPS when bound and BLE off', () {
    expect(
      MatchGeoHelpers.isCaptureTriggered(
        running: true,
        testMode: false,
        oniKnown: true,
        isHunterNow: false,
        captureZoneBoundIds: {'self'},
        proximityBand: ProximityBand.none,
        gpsDistanceToOniMeters: GameConfig.captureDistanceMeters,
      ),
      isTrue,
    );
  });

  test('capture does not trigger when not bound', () {
    expect(
      MatchGeoHelpers.isCaptureTriggered(
        running: true,
        testMode: false,
        oniKnown: true,
        isHunterNow: false,
        captureZoneBoundIds: {},
        proximityBand: ProximityBand.contact,
        gpsDistanceToOniMeters: 10,
      ),
      isFalse,
    );
  });

  test('distanceToOni finite when oni known', () {
    final d = MatchGeoHelpers.distanceToOni(
      player: const LatLng(35, 139),
      oni: const LatLng(35.0003, 139.0003),
      oniKnown: true,
      testMode: false,
    );
    expect(d, lessThan(200));
  });
}
