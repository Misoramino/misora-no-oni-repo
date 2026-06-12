import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:oni_game/game/generated_gimmicks.dart';
import 'package:oni_game/game/play_area.dart';

void main() {
  const area = PlayArea.circle(
    center: LatLng(35.68, 139.76),
    radiusMeters: 500,
  );

  test('GeneratedGimmicks same seed+density is deterministic', () {
    const seed = 424242;
    final a = GeneratedGimmicks.create(area, seed: seed, density: 1.0);
    final b = GeneratedGimmicks.create(area, seed: seed, density: 1.0);
    expect(a.safeZones.length, b.safeZones.length);
    expect(a.infoBrokers.length, b.infoBrokers.length);
    expect(a.cameras.length, b.cameras.length);
    expect(a.eventAreas.length, b.eventAreas.length);
    expect(a.safeZones.first, b.safeZones.first);
  });

  test('large circle gimmicks spread away from center', () {
    const seed = 777;
    const large = PlayArea.circle(
      center: LatLng(35.68, 139.76),
      radiusMeters: 1200,
    );
    final g = GeneratedGimmicks.create(large, seed: seed, density: 1.2);
    final center = GeneratedGimmicks.centerOf(large);
    double minDist(List<LatLng> pts) {
      if (pts.isEmpty) return double.infinity;
      var min = double.infinity;
      for (final p in pts) {
        final d = Geolocator.distanceBetween(
          center.latitude,
          center.longitude,
          p.latitude,
          p.longitude,
        );
        if (d < min) min = d;
      }
      return min;
    }

    final all = [
      ...g.safeZones,
      ...g.infoBrokers,
      ...g.cameras,
      ...g.eventAreas,
      ...g.accusationFacilities,
    ];
    expect(all.length, greaterThan(4));
    // 広い円でも、少なくとも一部は中心から十分離れる（中心固まり防止）。
    expect(minDist(all), greaterThan(180));
  });

  test('higher gimmick density yields at least as many placements', () {
    const seed = 1001;
    final sparse = GeneratedGimmicks.create(area, seed: seed, density: 0.45);
    final dense = GeneratedGimmicks.create(area, seed: seed, density: 1.55);
    int total(GeneratedGimmicks g) =>
        g.safeZones.length +
        g.infoBrokers.length +
        g.cameras.length +
        g.eventAreas.length;
    expect(total(dense), greaterThanOrEqualTo(total(sparse)));
  });
}
