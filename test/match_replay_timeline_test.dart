import 'package:flutter_test/flutter_test.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:oni_game/features/game_map/replay/replay_timeline_utils.dart';
import 'package:oni_game/game/location_reveal_event.dart';
import 'package:oni_game/game/match_event.dart';
import 'package:oni_game/game/match_record.dart';

void main() {
  group('ReplayTimelineUtils', () {
    test('samplesUpTo clips track at playback time', () {
      final t0 = DateTime.utc(2026, 6, 16, 12, 0);
      final samples = [
        TrajectorySample(atUtc: t0, position: const LatLng(35, 139)),
        TrajectorySample(
          atUtc: t0.add(const Duration(minutes: 5)),
          position: const LatLng(35.01, 139.01),
        ),
        TrajectorySample(
          atUtc: t0.add(const Duration(minutes: 10)),
          position: const LatLng(35.02, 139.02),
        ),
      ];
      final clipped = ReplayTimelineUtils.samplesUpTo(
        samples,
        t0.add(const Duration(minutes: 6)),
      );
      expect(clipped, hasLength(2));
    });

    test('computeSpan includes reveals and events beyond tracks', () {
      final start = DateTime.utc(2026, 6, 16, 12, 0);
      final end = start.add(const Duration(minutes: 30));
      final reveal = LocationRevealEvent(
        sequence: 1,
        timestamp: start.add(const Duration(minutes: 28)),
        position: const LatLng(35, 139),
        overflowMeters: 12,
        playerLabel: 'A',
      );
      final event = MatchEvent(
        type: 'accusation_unlocked',
        atUtc: start.add(const Duration(minutes: 32)),
        message: '告発解禁',
        position: const LatLng(35, 139),
      );
      final span = ReplayTimelineUtils.computeSpan(
        recordStart: start,
        recordEnd: end,
        tracks: const {},
        reveals: [reveal],
        events: [event],
      );
      expect(span.$2, start.add(const Duration(minutes: 32)));
    });

    test('isRevealFlashAt detects reveal list', () {
      final t0 = DateTime.utc(2026, 6, 16, 12, 0);
      final reveal = LocationRevealEvent(
        sequence: 1,
        timestamp: t0,
        position: const LatLng(35, 139),
        overflowMeters: 0,
      );
      expect(
        ReplayTimelineUtils.isRevealFlashAt(
          reveals: [reveal],
          events: const [],
          tNow: t0.add(const Duration(milliseconds: 200)),
        ),
        isTrue,
      );
    });
  });
}
