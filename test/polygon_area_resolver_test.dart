import 'package:flutter_test/flutter_test.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:oni_game/game/polygon_area_resolver.dart';
import 'package:oni_game/game/play_area.dart';

void main() {
  test('simple L-shape passes through without self-intersection', () {
    final pts = [
      const LatLng(0, 0),
      const LatLng(0, 0.001),
      const LatLng(0.0005, 0.001),
      const LatLng(0.0005, 0),
    ];
    final out = PolygonAreaResolver.resolveBoundedRing(pts);
    expect(out.length, greaterThanOrEqualTo(3));
    expect(PlayArea.polygon(points: out).contains(const LatLng(0.00025, 0.0005)), isTrue);
  });

  test('self-intersecting walk resolves to finite ring', () {
    final pts = [
      const LatLng(0, 0),
      const LatLng(0.001, 0.001),
      const LatLng(0, 0.001),
      const LatLng(0.001, 0),
    ];
    final out = PolygonAreaResolver.resolveBoundedRing(pts, seed: pts.first);
    expect(out.length, greaterThanOrEqualTo(3));
    final area = PlayArea.polygon(points: out);
    // 8 の字の片方の葉（中心付近は even-odd では外）
    expect(area.contains(const LatLng(0.0002, 0.00002)), isTrue);
  });
}
