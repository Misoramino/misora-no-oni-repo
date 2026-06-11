import 'package:flutter_test/flutter_test.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:oni_game/game/game_state.dart';
import 'package:oni_game/game/location_reveal_event.dart';
import 'package:oni_game/game/match_event.dart';
import 'package:oni_game/game/play_area.dart';
import 'package:oni_game/services/spectator_match_recorder.dart';
import 'package:oni_game/sync/inspector_feed_snapshot.dart';

void main() {
  test('SpectatorMatchRecorder builds multi-player record from feed and reveals', () {
    final t0 = DateTime.utc(2026, 6, 1, 12, 0, 0);
    final recorder = SpectatorMatchRecorder(matchStartedAtUtc: t0);
    recorder.ingestInspectorFeed({
      'u1': InspectorFeedSnapshot(
        uid: 'u1',
        nickname: 'Alice',
        role: 'runner',
        lat: 35.5,
        lng: 139.75,
        reportedAtUtc: t0,
      ),
      'u2': InspectorFeedSnapshot(
        uid: 'u2',
        nickname: 'Bob',
        role: 'oni',
        lat: 35.501,
        lng: 139.751,
        reportedAtUtc: t0.add(const Duration(seconds: 12)),
      ),
    });

    final record = recorder.finalize(
      outcome: GameState.runnerWin,
      playArea: const PlayArea.circle(
        center: LatLng(35.5, 139.75),
        radiusMeters: 500,
      ),
      reveals: [
        LocationRevealEvent(
          sequence: 1,
          timestamp: t0.add(const Duration(minutes: 1)),
          position: const LatLng(35.5005, 139.7505),
          overflowMeters: 20,
          playerLabel: 'Alice',
          subjectUid: 'u1',
        ),
      ],
      events: [
        MatchEvent(
          type: 'capture_zone_placed',
          atUtc: t0.add(const Duration(minutes: 2)),
          message: '結界設置',
          position: const LatLng(35.5002, 139.7502),
        ),
      ],
    );

    expect(record, isNotNull);
    expect(record!.tracks.keys, contains('player_u1'));
    expect(record.trackLabels['player_u1'], 'Alice（逃走者）');
    expect(record.trackLabels['player_u2'], 'Bob（鬼）');
    expect(record.reveals, hasLength(1));
    expect(record.events, hasLength(1));
  });
}
