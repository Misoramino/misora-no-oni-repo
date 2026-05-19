import 'package:flutter_test/flutter_test.dart';
import 'package:oni_game/features/game_map/match/match_runtime_state.dart';
import 'package:oni_game/game/game_config.dart';
import 'package:oni_game/game/generated_gimmicks.dart';
import 'package:oni_game/game/play_area.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

void main() {
  test('applyStartGimmicks resets and loads positions', () {
    const area = PlayArea.circle(
      center: LatLng(35.68, 139.76),
      radiusMeters: 400,
    );
    final gimmicks = GeneratedGimmicks.create(area);
    final rt = MatchRuntimeState();
    rt.revealCount = 3;
    rt.safeZoneCharges = 2;

    rt.applyStartGimmicks(
      gimmicks: gimmicks,
      matchDurationSeconds: 120,
    );

    expect(rt.remainingSeconds, 120);
    expect(rt.revealCount, 0);
    expect(rt.safeZoneCharges, 0);
    expect(rt.safeZonePositions, gimmicks.safeZones);
    expect(rt.cameraPositions, gimmicks.cameras);
  });

  test('resetToLobby restores duration', () {
    final rt = MatchRuntimeState(
      remainingSeconds: 10,
      elapsedSeconds: 50,
    );
    rt.resetToLobby(matchDurationSeconds: GameConfig.matchDurationSeconds);
    expect(rt.remainingSeconds, GameConfig.matchDurationSeconds);
    expect(rt.elapsedSeconds, 0);
  });
}
