import 'package:flutter_test/flutter_test.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:oni_game/features/game_map/match/gimmick_pickup_evaluator.dart';

void main() {
  const player = LatLng(35.0, 139.0);
  final positions = [const LatLng(35.0, 139.0)];

  test('pickup blocked when unavailable', () {
    expect(
      GimmickPickupEvaluator.pickupIndexIfAllowed(
        available: false,
        positions: positions,
        radiusMeters: 50,
        playerPosition: player,
        lastPickupAt: null,
        cooldownSeconds: 10,
        now: DateTime(2026, 1, 1),
      ),
      isNull,
    );
  });

  test('pickup blocked during cooldown', () {
    final now = DateTime(2026, 1, 1, 12, 0, 5);
    expect(
      GimmickPickupEvaluator.pickupIndexIfAllowed(
        available: true,
        positions: positions,
        radiusMeters: 50,
        playerPosition: player,
        lastPickupAt: DateTime(2026, 1, 1, 12, 0, 0),
        cooldownSeconds: 10,
        now: now,
      ),
      isNull,
    );
  });

  test('respawn when timer elapsed', () {
    final now = DateTime(2026, 1, 1, 12, 1, 0);
    expect(
      GimmickPickupEvaluator.shouldRespawn(
        available: false,
        respawnAt: DateTime(2026, 1, 1, 12, 0, 30),
        now: now,
      ),
      isTrue,
    );
  });
}
