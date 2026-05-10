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
}
