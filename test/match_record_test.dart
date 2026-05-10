import 'package:flutter_test/flutter_test.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:oni_game/game/game_state.dart';
import 'package:oni_game/game/location_reveal_event.dart';
import 'package:oni_game/game/match_record.dart';
import 'package:oni_game/game/play_area.dart';

void main() {
  test('SavedMatchRecord encode/decode roundtrip', () {
    final t0 = DateTime.utc(2026, 1, 10, 10, 0, 0);
    final original = SavedMatchRecord(
      version: SavedMatchRecord.currentVersion,
      id: 'test_id',
      startedAtUtc: t0,
      endedAtUtc: t0.add(const Duration(minutes: 3)),
      outcome: GameState.runnerWin,
      consentedToTrajectory: true,
      playArea: const PlayArea.circle(
        center: LatLng(35.5, 139.75),
        radiusMeters: 400,
      ),
      tracks: {
        'runner_local': [
          TrajectorySample(atUtc: t0, position: const LatLng(35.5, 139.751)),
          TrajectorySample(
            atUtc: t0.add(const Duration(seconds: 10)),
            position: const LatLng(35.501, 139.752),
          ),
        ],
        'oni_local': [
          TrajectorySample(atUtc: t0, position: const LatLng(35.499, 139.749)),
        ],
      },
      reveals: [
        LocationRevealEvent(
          sequence: 1,
          timestamp: t0.add(const Duration(minutes: 1)),
          position: const LatLng(35.5, 139.75),
          overflowMeters: 30,
        ),
      ],
    );

    final back = SavedMatchRecord.fromJson(original.toJson());
    expect(back.id, original.id);
    expect(back.tracks.length, 2);
    expect(back.tracks['runner_local']!.length, 2);
    expect(back.reveals.length, 1);
    expect(back.outcome, GameState.runnerWin);
  });
}
