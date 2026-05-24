import 'package:flutter_test/flutter_test.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:oni_game/game/oni_path_trail.dart';

void main() {
  test('visible trail only includes delayed window', () {
    final now = DateTime.utc(2026, 1, 1, 12, 0);
    final samples = [
      OniPathSample(
        recordedAt: now.subtract(const Duration(minutes: 1)),
        position: const LatLng(1, 1),
      ),
      OniPathSample(
        recordedAt: now.subtract(const Duration(minutes: 4)),
        position: const LatLng(2, 2),
      ),
      OniPathSample(
        recordedAt: now.subtract(const Duration(minutes: 11)),
        position: const LatLng(3, 3),
      ),
      OniPathSample(
        recordedAt: now.subtract(const Duration(minutes: 14)),
        position: const LatLng(4, 4),
      ),
    ];
    final visible = OniPathTrailLogic.visibleTrailPoints(
      samples: samples,
      now: now,
      minAgeSeconds: 600,
      maxAgeSeconds: 780,
    );
    expect(visible.length, 1);
    expect(visible.first.latitude, 3);
  });
}
