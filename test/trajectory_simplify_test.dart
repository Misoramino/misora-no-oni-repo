import 'package:flutter_test/flutter_test.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:oni_game/game/match_record.dart';
import 'package:oni_game/game/trajectory_simplify.dart';

void main() {
  test('minimumSeparation keeps ends and thins middle', () {
    final t0 = DateTime.utc(2026, 2, 1, 12, 0, 0);
    final samples = <TrajectorySample>[
      TrajectorySample(atUtc: t0, position: const LatLng(35.0, 139.0)),
      TrajectorySample(
        atUtc: t0.add(const Duration(seconds: 1)),
        position: const LatLng(35.00001, 139.00001),
      ),
      TrajectorySample(
        atUtc: t0.add(const Duration(seconds: 2)),
        position: const LatLng(35.0008, 139.0008),
      ),
      TrajectorySample(
        atUtc: t0.add(const Duration(seconds: 3)),
        position: const LatLng(35.0015, 139.0015),
      ),
    ];
    final out = TrajectorySimplify.minimumSeparation(
      samples: samples,
      minSeparationMeters: 50,
      maxPoints: 100,
    );
    expect(out.first, samples.first);
    expect(out.last, samples.last);
    expect(out.length, lessThan(samples.length));
  });
}
