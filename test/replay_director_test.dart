import 'package:flutter_test/flutter_test.dart';
import 'package:oni_game/features/game_map/replay/replay_director.dart';
import 'package:oni_game/services/match_recorder.dart';

void main() {
  test('trailWidth pulses when idle', () {
    final idleW = ReplayDirector.trailWidth(
      trackId: MatchTrackIds.runnerLocal,
      baseWidth: 4,
      speedMps: 0.1,
      idle: true,
      captureEmphasis: false,
      pulsePhase: 0,
    );
    final idleW2 = ReplayDirector.trailWidth(
      trackId: MatchTrackIds.runnerLocal,
      baseWidth: 4,
      speedMps: 0.1,
      idle: true,
      captureEmphasis: false,
      pulsePhase: 1.5,
    );
    expect(idleW, isNot(equals(idleW2)));
  });

  test('capture emphasis widens oni track', () {
    final normal = ReplayDirector.trailWidth(
      trackId: MatchTrackIds.oniLocal,
      baseWidth: 5,
      speedMps: 1,
      idle: false,
      captureEmphasis: false,
      pulsePhase: 0,
    );
    final capture = ReplayDirector.trailWidth(
      trackId: MatchTrackIds.oniLocal,
      baseWidth: 5,
      speedMps: 1,
      idle: false,
      captureEmphasis: true,
      pulsePhase: 0,
    );
    expect(capture, greaterThan(normal));
  });

  test('progressForTime maps within span', () {
    final start = DateTime.utc(2026, 1, 1, 12);
  final t = start.add(const Duration(minutes: 5));
    final p = ReplayDirector.progressForTime(
      t: t,
      start: start,
      spanMs: 10 * 60 * 1000,
    );
    expect(p, closeTo(0.5, 0.01));
  });
}
