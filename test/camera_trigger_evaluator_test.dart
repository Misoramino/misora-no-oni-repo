import 'package:flutter_test/flutter_test.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:oni_game/features/game_map/match/camera_trigger_evaluator.dart';

void main() {
  test('detects camera within radius', () {
    const player = LatLng(35.0, 139.0);
    final cameras = [const LatLng(35.0, 139.0001)];
    final now = DateTime.utc(2026, 6, 6, 12);
    final first = CameraTriggerEvaluator.newlyTriggeredIndices(
      cameraPositions: cameras,
      lastTriggeredAt: {},
      playerPosition: player,
      triggerRadiusMeters: 80,
      cooldownSeconds: 90,
      now: now,
    );
    expect(first, [0]);
  });

  test('same camera retriggers after cooldown', () {
    const player = LatLng(35.0, 139.0);
    final cameras = [const LatLng(35.0, 139.0001)];
    final firstAt = DateTime.utc(2026, 6, 6, 12);
    final lastTriggered = {0: firstAt};

    final duringCd = CameraTriggerEvaluator.newlyTriggeredIndices(
      cameraPositions: cameras,
      lastTriggeredAt: lastTriggered,
      playerPosition: player,
      triggerRadiusMeters: 80,
      cooldownSeconds: 90,
      now: firstAt.add(const Duration(seconds: 30)),
    );
    expect(duringCd, isEmpty);

    final afterCd = CameraTriggerEvaluator.newlyTriggeredIndices(
      cameraPositions: cameras,
      lastTriggeredAt: lastTriggered,
      playerPosition: player,
      triggerRadiusMeters: 80,
      cooldownSeconds: 90,
      now: firstAt.add(const Duration(seconds: 91)),
    );
    expect(afterCd, [0]);
  });
}
