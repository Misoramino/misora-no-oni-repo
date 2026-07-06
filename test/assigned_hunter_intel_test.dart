import 'package:flutter_test/flutter_test.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:oni_game/features/game_map/logic/assigned_hunter_intel.dart';

void main() {
  const player = LatLng(35.0, 135.0);
  const hunter = LatLng(35.001, 135.001);
  const werewolf = LatLng(35.0005, 135.0005);

  group('AssignedHunterIntel.position', () {
    test('returns local position when player is assigned hunter', () {
      expect(
        AssignedHunterIntel.position(
          hunterUid: 'h1',
          myUid: 'h1',
          localIsHunter: true,
          playerPosition: player,
          lastKnownByUid: {'w1': werewolf},
        ),
        player,
      );
    });

    test('returns synced hunter position not nearest oni', () {
      expect(
        AssignedHunterIntel.position(
          hunterUid: 'h1',
          myUid: 'r1',
          localIsHunter: false,
          playerPosition: player,
          lastKnownByUid: {'h1': hunter, 'w1': werewolf},
        ),
        hunter,
      );
    });
  });

  group('AssignedHunterIntel.distanceMeters', () {
    test('uses hunter position even when werewolf is closer', () {
      final toHunter = AssignedHunterIntel.distanceMeters(
        playerPosition: player,
        hunterPosition: hunter,
        known: true,
        testMode: false,
      );
      final toWolf = AssignedHunterIntel.distanceMeters(
        playerPosition: player,
        hunterPosition: werewolf,
        known: true,
        testMode: false,
      );
      expect(toHunter, greaterThan(toWolf));
    });

    test('returns infinity when hunter unknown', () {
      expect(
        AssignedHunterIntel.distanceMeters(
          playerPosition: player,
          hunterPosition: null,
          known: false,
          testMode: false,
        ),
        double.infinity,
      );
    });
  });
}
