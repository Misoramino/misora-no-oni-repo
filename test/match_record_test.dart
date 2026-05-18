import 'package:flutter_test/flutter_test.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:oni_game/game/game_state.dart';
import 'package:oni_game/game/location_reveal_event.dart';
import 'package:oni_game/game/match_event.dart';
import 'package:oni_game/game/match_record.dart';
import 'package:oni_game/game/play_area.dart';
import 'package:oni_game/services/match_recorder.dart';

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
      events: [
        MatchEvent(
          type: 'camera_spotted',
          atUtc: t0.add(const Duration(minutes: 2)),
          message: '監視カメラ: spotted',
          position: const LatLng(35.5006, 139.7504),
        ),
      ],
    );

    final back = SavedMatchRecord.fromJson(original.toJson());
    expect(back.id, original.id);
    expect(back.tracks.length, 2);
    expect(back.tracks['runner_local']!.length, 2);
    expect(back.reveals.length, 1);
    expect(back.events.length, 1);
    expect(back.outcome, GameState.runnerWin);
  });

  test(
    'MatchRecorder keeps local replay data independent from Firestore presence',
    () {
      final recorder = MatchRecorder(
        playAreaSnapshot: const PlayArea.circle(
          center: LatLng(35.5, 139.75),
          radiusMeters: 400,
        ),
        consentedToTrajectory: true,
        initialRunner: const LatLng(35.5001, 139.7501),
        initialOni: const LatLng(35.4991, 139.7491),
      );

      final revealAt = DateTime.utc(2026, 1, 10, 10, 1);
      final eventAt = DateTime.utc(2026, 1, 10, 10, 2);
      final record = recorder.finalize(
        outcome: GameState.caughtByOni,
        reveals: [
          LocationRevealEvent(
            sequence: 1,
            timestamp: revealAt,
            position: const LatLng(35.5002, 139.7502),
            overflowMeters: 24,
          ),
        ],
        events: [
          MatchEvent(
            type: 'capture',
            atUtc: eventAt,
            message: '捕獲',
            position: const LatLng(35.5003, 139.7503),
          ),
        ],
      );

      expect(record, isNotNull);
      expect(
        record!.tracks.keys,
        containsAll([MatchTrackIds.runnerLocal, MatchTrackIds.oniLocal]),
      );
      expect(record.tracks[MatchTrackIds.runnerLocal], isNotEmpty);
      expect(record.tracks[MatchTrackIds.oniLocal], isNotEmpty);
      expect(record.reveals.single.position.latitude, 35.5002);
      expect(record.events.single.type, 'capture');
    },
  );
}
