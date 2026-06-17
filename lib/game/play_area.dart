import 'dart:convert';

import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

enum PlayAreaType { circle, polygon }

class PlayArea {
  const PlayArea.circle({
    required this.center,
    required this.radiusMeters,
  })  : type = PlayAreaType.circle,
        points = const [];

  const PlayArea.polygon({
    required this.points,
  })  : type = PlayAreaType.polygon,
        center = const LatLng(0, 0),
        radiusMeters = 0;

  final PlayAreaType type;
  final LatLng center;
  final double radiusMeters;
  final List<LatLng> points;

  Map<String, dynamic> toJson() {
    switch (type) {
      case PlayAreaType.circle:
        return {
          'type': 'circle',
          'center': _latLngToMap(center),
          'radiusMeters': radiusMeters,
        };
      case PlayAreaType.polygon:
        return {
          'type': 'polygon',
          'points': points.map(_latLngToMap).toList(),
        };
    }
  }

  static PlayArea fromJson(Map<String, dynamic> json) {
    final t = json['type'];
    if (t == 'circle') {
      return PlayArea.circle(
        center: _latLngFromMap(json['center'] as Map<String, dynamic>),
        radiusMeters: (json['radiusMeters'] as num).toDouble(),
      );
    }
    if (t == 'polygon') {
      final list = json['points'] as List<dynamic>;
      return PlayArea.polygon(
        points: list
            .map((e) => _latLngFromMap(e as Map<String, dynamic>))
            .toList(),
      );
    }
    throw FormatException('Unknown play area type: $t');
  }

  /// GeoJSON Polygon の1リング（閉じた座標列）から [PlayArea] を作る。
  /// `coordinates` は `[[lng,lat], [lng,lat], ...]`（最後の点が最初と同じでも可）。
  factory PlayArea.fromGeoJsonPolygonCoordinates(List<dynamic> ring) {
    if (ring.length < 3) {
      throw ArgumentError('Polygon needs at least 3 positions');
    }
    final pts = <LatLng>[];
    for (var i = 0; i < ring.length; i++) {
      final pair = ring[i] as List<dynamic>;
      final lng = (pair[0] as num).toDouble();
      final lat = (pair[1] as num).toDouble();
      if (pts.isNotEmpty &&
          pts.last.latitude == lat &&
          pts.last.longitude == lng) {
        continue;
      }
      pts.add(LatLng(lat, lng));
    }
    while (pts.length >= 2) {
      final a = pts.first;
      final b = pts.last;
      if (a.latitude == b.latitude && a.longitude == b.longitude) {
        pts.removeLast();
      } else {
        break;
      }
    }
    if (pts.length < 3) {
      throw ArgumentError('Polygon needs at least 3 unique points');
    }
    return PlayArea.polygon(points: pts);
  }

  /// 単一 Feature（Polygon / Point+radius）または FeatureCollection の先頭をパース。
  static PlayArea fromGeoJsonString(String raw) {
    final root = jsonDecode(raw) as Map<String, dynamic>;
    final type = root['type'];
    if (type == 'Feature') {
      final geom = root['geometry'] as Map<String, dynamic>? ?? {};
      final props = root['properties'] as Map<String, dynamic>? ?? {};
      return _fromGeoJsonFeature(geom, props);
    }
    if (type == 'FeatureCollection') {
      final features = root['features'] as List<dynamic>?;
      if (features == null || features.isEmpty) {
        throw FormatException('FeatureCollection has no features');
      }
      final first = features.first as Map<String, dynamic>;
      final geom = first['geometry'] as Map<String, dynamic>? ?? {};
      final props = first['properties'] as Map<String, dynamic>? ?? {};
      return _fromGeoJsonFeature(geom, props);
    }
    if (type == 'Polygon') {
      return _fromGeoJsonGeometry(root);
    }
    throw FormatException('Unsupported GeoJSON root type: $type');
  }

  static PlayArea _fromGeoJsonFeature(
    Map<String, dynamic> geom,
    Map<String, dynamic> properties,
  ) {
    final gtype = geom['type'];
    if (gtype == 'Point') {
      final r = properties['radiusMeters'];
      if (r != null) {
        final c = geom['coordinates'] as List<dynamic>;
        final lng = (c[0] as num).toDouble();
        final lat = (c[1] as num).toDouble();
        return PlayArea.circle(
          center: LatLng(lat, lng),
          radiusMeters: (r as num).toDouble(),
        );
      }
      throw FormatException(
        'Point geometry requires properties.radiusMeters (exported by this app)',
      );
    }
    return _fromGeoJsonGeometry(geom);
  }

  static PlayArea _fromGeoJsonGeometry(Map<String, dynamic> geom) {
    final gtype = geom['type'];
    if (gtype != 'Polygon') {
      throw FormatException('Geometry must be Polygon, got $gtype');
    }
    final coords = geom['coordinates'] as List<dynamic>;
    if (coords.isEmpty) {
      throw FormatException('Polygon has no rings');
    }
    final ring = coords.first as List<dynamic>;
    return PlayArea.fromGeoJsonPolygonCoordinates(ring);
  }

  /// このプレイエリアを GeoJSON Feature として出力（外部ツール連携用）。
  String toGeoJsonFeatureString({String id = 'play-area'}) {
    Map<String, dynamic> geometry;
    switch (type) {
      case PlayAreaType.circle:
        geometry = {
          'type': 'Point',
          'coordinates': [center.longitude, center.latitude],
        };
        break;
      case PlayAreaType.polygon:
        final closed = [...points, points.first];
        geometry = {
          'type': 'Polygon',
          'coordinates': [
            closed.map((p) => [p.longitude, p.latitude]).toList(),
          ],
        };
        break;
    }
    final feature = {
      'type': 'Feature',
      'id': id,
      'properties': {
        'playAreaType': type.name,
        if (type == PlayAreaType.circle) 'radiusMeters': radiusMeters,
      },
      'geometry': geometry,
    };
    return const JsonEncoder.withIndent('  ').convert(feature);
  }

  static Map<String, double> _latLngToMap(LatLng p) => {
        'lat': p.latitude,
        'lng': p.longitude,
      };

  static LatLng _latLngFromMap(Map<String, dynamic> m) => LatLng(
        (m['lat'] as num).toDouble(),
        (m['lng'] as num).toDouble(),
      );

  /// 表示用の代表座標（円は中心、多角形は頂点の平均）。
  LatLng get anchorCenter {
    switch (type) {
      case PlayAreaType.circle:
        return center;
      case PlayAreaType.polygon:
        if (points.isEmpty) return center;
        var lat = 0.0;
        var lng = 0.0;
        for (final p in points) {
          lat += p.latitude;
          lng += p.longitude;
        }
        return LatLng(lat / points.length, lng / points.length);
    }
  }

  /// ざっくりした位置ラベル（ジオコーディングなし）。
  String coarseLocationLabel() {
    final c = anchorCenter;
    final lat = c.latitude;
    final lng = c.longitude;
    final ns = lat >= 0 ? '北緯' : '南緯';
    final ew = lng >= 0 ? '東経' : '西経';
    return '$ns${lat.abs().toStringAsFixed(2)}° $ew${lng.abs().toStringAsFixed(2)}°';
  }

  LatLngBounds get bounds {
    switch (type) {
      case PlayAreaType.circle:
        final d = radiusMeters / 111320;
        return LatLngBounds(
          southwest: LatLng(center.latitude - d, center.longitude - d),
          northeast: LatLng(center.latitude + d, center.longitude + d),
        );
      case PlayAreaType.polygon:
        if (points.isEmpty) {
          return LatLngBounds(
            southwest: center,
            northeast: center,
          );
        }
        var minLat = points.first.latitude;
        var maxLat = minLat;
        var minLng = points.first.longitude;
        var maxLng = minLng;
        for (final p in points) {
          if (p.latitude < minLat) minLat = p.latitude;
          if (p.latitude > maxLat) maxLat = p.latitude;
          if (p.longitude < minLng) minLng = p.longitude;
          if (p.longitude > maxLng) maxLng = p.longitude;
        }
        return LatLngBounds(
          southwest: LatLng(minLat, minLng),
          northeast: LatLng(maxLat, maxLng),
        );
    }
  }

  /// 準備画面・マップパネル向けの形状サマリー。
  String shapeSummary() {
    switch (type) {
      case PlayAreaType.circle:
        return '円 · 半径 ${radiusMeters.toStringAsFixed(0)} m';
      case PlayAreaType.polygon:
        final n = points.length;
        if (n < 3) return '多角形 · 未確定（$n点）';
        return '多角形 · $n 頂点';
    }
  }

  bool contains(LatLng position) {
    switch (type) {
      case PlayAreaType.circle:
        final d = Geolocator.distanceBetween(
          position.latitude,
          position.longitude,
          center.latitude,
          center.longitude,
        );
        return d <= radiusMeters;
      case PlayAreaType.polygon:
        return _isInsidePolygon(position, points);
    }
  }

  double overflowDistanceMeters(LatLng position) {
    switch (type) {
      case PlayAreaType.circle:
        final d = Geolocator.distanceBetween(
          position.latitude,
          position.longitude,
          center.latitude,
          center.longitude,
        );
        return d - radiusMeters;
      case PlayAreaType.polygon:
        if (_isInsidePolygon(position, points)) return 0;
        final minEdgeDistance = _minDistanceToPolygonEdges(position, points);
        return minEdgeDistance;
    }
  }

  static bool _isInsidePolygon(LatLng p, List<LatLng> poly) {
    if (poly.length < 3) return false;
    var inside = false;
    for (var i = 0, j = poly.length - 1; i < poly.length; j = i++) {
      final xi = poly[i].longitude;
      final yi = poly[i].latitude;
      final xj = poly[j].longitude;
      final yj = poly[j].latitude;

      final intersect = ((yi > p.latitude) != (yj > p.latitude)) &&
          (p.longitude < (xj - xi) * (p.latitude - yi) / (yj - yi) + xi);
      if (intersect) inside = !inside;
    }
    return inside;
  }

  static double _minDistanceToPolygonEdges(LatLng p, List<LatLng> poly) {
    var minDistance = double.infinity;
    for (var i = 0; i < poly.length; i++) {
      final a = poly[i];
      final b = poly[(i + 1) % poly.length];
      final d = _distancePointToSegmentMeters(p, a, b);
      if (d < minDistance) minDistance = d;
    }
    return minDistance;
  }

  static double _distancePointToSegmentMeters(LatLng p, LatLng a, LatLng b) {
    final ax = a.longitude;
    final ay = a.latitude;
    final bx = b.longitude;
    final by = b.latitude;
    final px = p.longitude;
    final py = p.latitude;

    final abx = bx - ax;
    final aby = by - ay;
    final abLen2 = abx * abx + aby * aby;
    if (abLen2 == 0) {
      return Geolocator.distanceBetween(py, px, ay, ax);
    }

    final apx = px - ax;
    final apy = py - ay;
    final t = (apx * abx + apy * aby) / abLen2;
    final clampedT = t.clamp(0.0, 1.0);

    final cx = ax + abx * clampedT;
    final cy = ay + aby * clampedT;
    return Geolocator.distanceBetween(py, px, cy, cx);
  }
}
