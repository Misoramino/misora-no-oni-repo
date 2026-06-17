import 'package:flutter_test/flutter_test.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:oni_game/game/game_state.dart';
import 'package:oni_game/game/match_event.dart';
import 'package:oni_game/game/match_record.dart';
import 'package:oni_game/game/play_area.dart';
import 'package:oni_game/services/match_archive_merger.dart';
import 'package:oni_game/services/match_recorder.dart';

SavedMatchRecord _minimalRecord({
  required String id,
  Map<String, List<TrajectorySample>> tracks = const {},
  List<MatchEvent> events = const [],
}) {
  final area = PlayArea.circle(center: const LatLng(35, 139), radiusMeters: 200);
  final t = DateTime.utc(2026, 1, 1, 12);
  return SavedMatchRecord(
    version: 1,
    id: id,
    startedAtUtc: t,
    endedAtUtc: t.add(const Duration(minutes: 10)),
    outcome: GameState.runnerWin,
    consentedToTrajectory: true,
    playArea: area,
    tracks: tracks,
    events: events,
  );
}

void main() {
  test('merge combines remote player tracks with local record', () {
    final t = DateTime.utc(2026, 1, 1, 12);
    final local = _minimalRecord(
      id: 'local',
      tracks: {
        MatchTrackIds.runnerLocal: [
          TrajectorySample(atUtc: t, position: const LatLng(35, 139)),
        ],
      },
    );
    final remote = _minimalRecord(
      id: 'remote',
      tracks: {
        'player_abc': [
          TrajectorySample(atUtc: t, position: const LatLng(35.001, 139.001)),
        ],
      },
      events: [
        MatchEvent(
          type: 'capture_zone_placed',
          atUtc: t.add(const Duration(minutes: 2)),
          message: '結界',
          position: const LatLng(35, 139),
        ),
      ],
    );

    final merged = MatchArchiveMerger.merge(local: local, remote: remote);
    expect(merged.tracks.containsKey(MatchTrackIds.runnerLocal), isTrue);
    expect(merged.tracks.containsKey('player_abc'), isTrue);
    expect(merged.events.length, 1);
    expect(merged.id, 'local');
  });
}
