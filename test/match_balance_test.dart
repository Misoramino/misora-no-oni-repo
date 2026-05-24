import 'package:flutter_test/flutter_test.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:oni_game/features/game_map/match/match_geo_helpers.dart';
import 'package:oni_game/game/game_config.dart';
import 'package:oni_game/game/play_area.dart';

void main() {
  const area500 = PlayArea.circle(
    center: LatLng(35, 139),
    radiusMeters: 500,
  );

  test('infection ring is wider than touch ring on typical area', () {
    final touch = MatchGeoHelpers.scaledTouchRadiusMeters(area500);
    final infection = MatchGeoHelpers.scaledInfectionTriggerMeters(area500);
    expect(infection, greaterThan(touch));
  });

  test('restraint radius scales and exceeds touch radius', () {
    final touch = MatchGeoHelpers.scaledTouchRadiusMeters(area500);
    final restraint = MatchGeoHelpers.scaledRestraintRadiusMeters(area500);
    expect(restraint, greaterThan(touch));
    expect(restraint, lessThanOrEqualTo(GameConfig.scaledRestraintRadiusMaxMeters));
  });

  test('touch lock duration covers run from center to edge', () {
    const area = PlayArea.circle(
      center: LatLng(35, 139),
      radiusMeters: 500,
    );
    final r = MatchGeoHelpers.scaledRestraintRadiusMeters(area);
    final bind = MatchGeoHelpers.touchLockDurationSeconds(area);
    final runToEdge = r / GameConfig.restraintEscapeRunMps;
    expect(bind, greaterThanOrEqualTo(runToEdge.round()));
    expect(bind, lessThanOrEqualTo(GameConfig.touchLockDurationMaxSeconds));
  });

  test('skill zone uses fixed radius for escape', () {
    expect(
      MatchGeoHelpers.lockZoneEscapeRadiusMeters(
        placedBySkill: true,
        playArea: area500,
      ),
      GameConfig.captureZoneSkillRadiusMeters,
    );
  });
}
