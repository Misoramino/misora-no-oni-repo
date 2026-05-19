import 'package:flutter_test/flutter_test.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:oni_game/features/game_map/match/camera_trigger_evaluator.dart';

void main() {
  test('detects camera within radius once', () {
    const player = LatLng(35.0, 139.0);
    final cameras = [const LatLng(35.0, 139.0001)];
    final first = CameraTriggerEvaluator.newlyTriggeredIndices(
      cameraPositions: cameras,
      alreadyTriggered: {},
      playerPosition: player,
      triggerRadiusMeters: 80,
    );
    expect(first, [0]);

    final second = CameraTriggerEvaluator.newlyTriggeredIndices(
      cameraPositions: cameras,
      alreadyTriggered: {0},
      playerPosition: player,
      triggerRadiusMeters: 80,
    );
    expect(second, isEmpty);
  });
}
