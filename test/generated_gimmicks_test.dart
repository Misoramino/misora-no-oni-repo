import 'package:flutter_test/flutter_test.dart';
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
