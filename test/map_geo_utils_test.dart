import 'package:flutter_test/flutter_test.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:oni_game/features/game_map/logic/map_geo_utils.dart';

void main() {
  test('formatClock pads minutes and seconds', () {
    expect(MapGeoUtils.formatClock(125), '02:05');
  });

  test('bearingToDirection maps quadrants', () {
    expect(MapGeoUtils.bearingToDirection(0), '北');
    expect(MapGeoUtils.bearingToDirection(90), '東');
  });

  test('firstPointWithinIndex finds nearby point', () {
    const origin = LatLng(0, 0);
    const near = LatLng(0, 0.0001);
    final i = MapGeoUtils.firstPointWithinIndex([near], 50, origin);
    expect(i, 0);
  });
}
