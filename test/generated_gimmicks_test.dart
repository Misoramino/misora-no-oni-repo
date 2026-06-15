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

  int totalGimmicks(GeneratedGimmicks g) =>
      g.safeZones.length +
      g.infoBrokers.length +
      g.cameras.length +
      g.eventAreas.length +
      g.accusationFacilities.length;

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

  test('large circle grows gimmick count with area', () {
    const seed = 777;
    const large = PlayArea.circle(
      center: LatLng(35.68, 139.76),
      radiusMeters: 1200,
    );
    final small = GeneratedGimmicks.create(area, seed: seed, density: 1.0);
    final big = GeneratedGimmicks.create(large, seed: seed, density: 1.0);
    // 面積比 (1200/500)^2 ≈ 5.76 — 個数もおおよそ増える。
    expect(totalGimmicks(big), greaterThan(totalGimmicks(small) * 3));
  });

  test('gimmicks spread across inner and outer area', () {
    const seed = 777;
    const large = PlayArea.circle(
      center: LatLng(35.68, 139.76),
      radiusMeters: 1200,
    );
    final g = GeneratedGimmicks.create(large, seed: seed, density: 1.0);
    final center = GeneratedGimmicks.centerOf(large);
    final all = [
      ...g.safeZones,
      ...g.infoBrokers,
      ...g.cameras,
      ...g.eventAreas,
      ...g.accusationFacilities,
    ];
    expect(all.length, greaterThan(12));

    var hasInner = false;
    var hasOuter = false;
    for (final p in all) {
      final dist = Geolocator.distanceBetween(
        center.latitude,
        center.longitude,
        p.latitude,
        p.longitude,
      );
      if (dist < 1200 * 0.45) hasInner = true;
      if (dist > 1200 * 0.55) hasOuter = true;
    }
    expect(hasInner, isTrue, reason: '中心付近にもギミックがある');
    expect(hasOuter, isTrue, reason: '外周付近にもギミックがある');
  });

  test('higher gimmick density yields at least as many placements', () {
    const seed = 1001;
    final sparse = GeneratedGimmicks.create(area, seed: seed, density: 0.45);
    final dense = GeneratedGimmicks.create(area, seed: seed, density: 1.55);
    expect(totalGimmicks(dense), greaterThanOrEqualTo(totalGimmicks(sparse)));
  });

  test('relocateFarFromOthers keeps distance from existing gimmicks', () {
    const seed = 555;
    final existing = GeneratedGimmicks.create(area, seed: seed, density: 1.0);
    final placed = [
      ...existing.safeZones,
      ...existing.cameras,
    ];
    final relocated = GeneratedGimmicks.relocateFarFromOthers(
      area: area,
      placed: placed,
      seed: seed + 99,
    );
    expect(area.contains(relocated), isTrue);
    for (final p in placed) {
      expect(
        Geolocator.distanceBetween(
          relocated.latitude,
          relocated.longitude,
          p.latitude,
          p.longitude,
        ),
        greaterThan(30),
      );
    }
  });
}
