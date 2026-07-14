import 'package:flutter_test/flutter_test.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:oni_game/game/play_area.dart';

void main() {
  test('PlayArea JSON roundtrip (circle)', () {
    const original = PlayArea.circle(
      center: LatLng(35.5, 139.7),
      radiusMeters: 300,
    );
    final json = original.toJson();
    final restored = PlayArea.fromJson(json);
    expect(restored.type, PlayAreaType.circle);
    expect(restored.center.latitude, original.center.latitude);
    expect(restored.center.longitude, original.center.longitude);
    expect(restored.radiusMeters, original.radiusMeters);
  });

  test('GeoJSON export/import (circle)', () {
    const area = PlayArea.circle(
      center: LatLng(35.5, 139.7),
      radiusMeters: 400,
    );
    final raw = area.toGeoJsonFeatureString();
    final back = PlayArea.fromGeoJsonString(raw);
    expect(back.type, PlayAreaType.circle);
    expect(back.radiusMeters, 400);
  });

  test('GeoJSON polygon string', () {
    const sample = '''
{
  "type": "Feature",
  "geometry": {
    "type": "Polygon",
    "coordinates": [[[139.76,35.68],[139.77,35.68],[139.77,35.69],[139.76,35.69],[139.76,35.68]]]
  },
  "properties": {}
}
''';
    final area = PlayArea.fromGeoJsonString(sample);
    expect(area.type, PlayAreaType.polygon);
    expect(area.points.length, greaterThanOrEqualTo(3));
  });

  test('shapeSummary labels', () {
    const circle = PlayArea.circle(
      center: LatLng(35.5, 139.7),
      radiusMeters: 420,
    );
    expect(circle.shapeSummary(), '円 · 半径 420 m');

    const polygon = PlayArea.polygon(
      points: [
        LatLng(35.68, 139.76),
        LatLng(35.68, 139.77),
        LatLng(35.69, 139.77),
      ],
    );
    expect(polygon.shapeSummary(), '多角形 · 3 頂点');
  });

  test('alignedCircleToPositionIfFar recenters when far enough', () {
    const area = PlayArea.circle(
      center: LatLng(35.0, 139.0),
      radiusMeters: 100,
    );
    // ~111m north → overflow ~11m (< 80) → no align
    final near = area.alignedCircleToPositionIfFar(
      const LatLng(35.001, 139.0),
      minOverflowMeters: 80,
    );
    expect(near, isNull);

    // Far position: overflow well over 80m
    final farPos = const LatLng(35.01, 139.0);
    final aligned = area.alignedCircleToPositionIfFar(
      farPos,
      minOverflowMeters: 80,
    );
    expect(aligned, isNotNull);
    expect(aligned!.center.latitude, farPos.latitude);
    expect(aligned.radiusMeters, 100);

    final poly = PlayArea.polygon(
      points: const [
        LatLng(35.0, 139.0),
        LatLng(35.0, 139.01),
        LatLng(35.01, 139.01),
      ],
    );
    expect(
      poly.alignedCircleToPositionIfFar(
        const LatLng(36, 140),
        minOverflowMeters: 80,
      ),
      isNull,
    );
  });
}
