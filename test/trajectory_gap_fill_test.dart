import 'package:flutter_test/flutter_test.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:oni_game/game/match_record.dart';
import 'package:oni_game/game/trajectory_gap_fill.dart';

void main() {
  test('densifyForReplay inserts points across long GPS gaps', () {
    final t0 = DateTime.utc(2026, 1, 1, 12);
    final samples = [
      TrajectorySample(atUtc: t0, position: const LatLng(35.0, 139.0)),
      TrajectorySample(
        atUtc: t0.add(const Duration(minutes: 5)),
        position: const LatLng(35.01, 139.01),
      ),
    ];
    final dense = TrajectoryGapFill.densifyForReplay(
      samples,
      maxGap: const Duration(seconds: 60),
      step: const Duration(seconds: 30),
    );
    expect(dense.length, greaterThan(2));
    expect(dense.first.position.latitude, closeTo(35.0, 0.0001));
    expect(dense.last.position.latitude, closeTo(35.01, 0.0001));
  });
}
