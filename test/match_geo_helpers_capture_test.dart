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
        lockZoneBoundIds: {'self'},
        proximityBand: ProximityBand.contact,
        gpsDistanceToOniMeters: 80,
        proximityCapturePermitted: true,
        lockZoneCapturePermitted: true,
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
        lockZoneBoundIds: {'self'},
        proximityBand: ProximityBand.none,
        gpsDistanceToOniMeters: GameConfig.captureDistanceMeters,
        proximityCapturePermitted: true,
        lockZoneCapturePermitted: true,
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
        lockZoneBoundIds: {},
        proximityBand: ProximityBand.contact,
        gpsDistanceToOniMeters: 10,
        proximityCapturePermitted: true,
        lockZoneCapturePermitted: true,
      ),
      isFalse,
    );
  });

  test('BLE-only capture blocked when proximity capture not permitted', () {
    expect(
      MatchGeoHelpers.isCaptureTriggered(
        running: true,
        testMode: false,
        oniKnown: true,
        isHunterNow: false,
        lockZoneBoundIds: {'self'},
        proximityBand: ProximityBand.contact,
        gpsDistanceToOniMeters: 80,
        proximityCapturePermitted: false,
        lockZoneCapturePermitted: true,
      ),
      isFalse,
    );
  });

  test('capture blocked when lock zone is non-lethal', () {
    expect(
      MatchGeoHelpers.isCaptureTriggered(
        running: true,
        testMode: false,
        oniKnown: true,
        isHunterNow: false,
        lockZoneBoundIds: {'self'},
        proximityBand: ProximityBand.contact,
        gpsDistanceToOniMeters: 5,
        proximityCapturePermitted: true,
        lockZoneCapturePermitted: false,
      ),
      isFalse,
    );
  });

  test('bound proximity capture requires bind before GPS or BLE', () {
    expect(
      MatchGeoHelpers.isBoundProximityCapture(
        proximityBand: ProximityBand.contact,
        gpsDistanceToOniMeters: 80,
        proximityCapturePermitted: true,
      ),
      isTrue,
    );
    expect(
      MatchGeoHelpers.isBoundProximityCapture(
        proximityBand: ProximityBand.none,
        gpsDistanceToOniMeters: GameConfig.captureDistanceMeters,
        proximityCapturePermitted: true,
      ),
      isTrue,
    );
    expect(
      MatchGeoHelpers.isBoundProximityCapture(
        proximityBand: ProximityBand.none,
        gpsDistanceToOniMeters: GameConfig.captureDistanceMeters + 1,
        proximityCapturePermitted: true,
      ),
      isFalse,
    );
  });

  test('captureZoneTargetIds includes self and remotes in radius', () {
    const center = LatLng(35.0, 139.0);
    final ids = MatchGeoHelpers.captureZoneTargetIds(
      center: center,
      selfDistanceMeters: 10,
      radiusMeters: 55,
      remotePositions: {
        'a': const LatLng(35.0002, 139.0), // ~22m
        'b': const LatLng(35.01, 139.0), // far
      },
    );
    expect(ids.contains('self'), isTrue);
    expect(ids.contains('a'), isTrue);
    expect(ids.contains('b'), isFalse);
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
