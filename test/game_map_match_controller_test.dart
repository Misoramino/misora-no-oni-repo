import 'package:flutter_test/flutter_test.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:oni_game/features/game_map/match/game_map_match_controller.dart';
import 'package:oni_game/features/game_map/match/match_tick_effects.dart';
import 'package:oni_game/game/game_config.dart';
import 'package:oni_game/game/game_state.dart';
import 'package:oni_game/game/play_area.dart';
import 'package:oni_game/proximity/proximity_signal.dart';

void main() {
  test('running tick ends match on timer', () {
    const area = PlayArea.circle(
      center: LatLng(35.68, 139.76),
      radiusMeters: 500,
    );
    final ctrl = GameMapMatchController();
    ctrl.runtime.remainingSeconds = 0;

    final effects = ctrl.evaluateRunningTick(
      playArea: area,
      playerPosition: const LatLng(35.68, 139.76),
      oniPosition: const LatLng(35.69, 139.77),
      testMode: true,
      oniKnown: true,
      isHunterNow: false,
      runnerProximityActive: true,
      applyOutsideAreaRules: true,
      oniOutsideEndsMatch: false,
      proximityBand: ProximityBand.none,
      proximityCapturePermitted: true,
      now: DateTime(2026, 1, 1),
    );

    expect(effects.whereType<MatchEndEffect>().length, 1);
    expect(
      effects.whereType<MatchEndEffect>().first.state,
      GameState.runnerWin,
    );
  });

  test('outside area consumes safe charge', () {
    const area = PlayArea.circle(
      center: LatLng(35.68, 139.76),
      radiusMeters: 100,
    );
    final ctrl = GameMapMatchController();
    ctrl.runtime.remainingSeconds = 60;
    ctrl.runtime.safeZoneCharges = 1;
    ctrl.runtime.outsideAreaSince =
        DateTime(2026, 1, 1).subtract(
          Duration(seconds: GameConfig.outsideAreaGraceSeconds + 1),
        );

    final far = const LatLng(35.70, 139.80);
    final effects = ctrl.evaluateRunningTick(
      playArea: area,
      playerPosition: far,
      oniPosition: const LatLng(35.68, 139.76),
      testMode: true,
      oniKnown: true,
      isHunterNow: false,
      runnerProximityActive: true,
      applyOutsideAreaRules: true,
      oniOutsideEndsMatch: false,
      proximityBand: ProximityBand.none,
      proximityCapturePermitted: true,
      now: DateTime(2026, 1, 1),
    );

    expect(effects.whereType<MatchConsumeSafeChargeEffect>().length, 1);
    expect(ctrl.runtime.safeZoneCharges, 0);
  });

  test('no self-capture when no runners to chase', () {
    const area = PlayArea.circle(
      center: LatLng(35.68, 139.76),
      radiusMeters: 500,
    );
    final ctrl = GameMapMatchController();
    ctrl.runtime.remainingSeconds = 60;
    ctrl.runtime.lockZoneBoundIds = const {'self'};
    const pos = LatLng(35.68, 139.76);

    final effects = ctrl.evaluateRunningTick(
      playArea: area,
      playerPosition: pos,
      oniPosition: pos,
      testMode: false,
      oniKnown: true,
      isHunterNow: true,
      runnerProximityActive: false,
      applyOutsideAreaRules: false,
      oniOutsideEndsMatch: false,
      proximityBand: ProximityBand.contact,
      proximityCapturePermitted: true,
      now: DateTime(2026, 1, 1),
    );

    expect(effects.whereType<MatchEndEffect>(), isEmpty);
    expect(effects.whereType<MatchInfectionExposureWarnEffect>(), isEmpty);
  });
}
