import 'dart:math' as math;

import 'package:google_maps_flutter/google_maps_flutter.dart';

/// 自己交差する閉路から、有限面積の領域（始点を含む連結成分）の境界を求める。
class PolygonAreaResolver {
  const PolygonAreaResolver._();

  /// 開いた頂点列を閉じ、必要なら有限領域だけを抽出する。
  static List<LatLng> resolveBoundedRing(
    List<LatLng> openVertices, {
    LatLng? seed,
  }) {
    if (openVertices.length < 3) {
      throw ArgumentError('多角形は3点以上必要です');
    }
    final anchor = seed ?? openVertices.first;
    if (!_hasSelfIntersectionClosed(openVertices)) {
      return _dedupeAdjacent(openVertices);
    }
    return _extractBoundedRegionByGrid(openVertices, anchor);
  }

  static bool _hasSelfIntersectionClosed(List<LatLng> pts) {
    final n = pts.length;
    if (n < 4) return false;
    for (var i = 0; i < n; i++) {
      final a1 = pts[i];
      final a2 = pts[(i + 1) % n];
      for (var j = i + 2; j < n; j++) {
        if (i == 0 && j == n - 1) continue;
        final b1 = pts[j];
        final b2 = pts[(j + 1) % n];
        if (_segmentsIntersectProper(a1, a2, b1, b2)) return true;
      }
    }
    return false;
  }

  static bool _segmentsIntersectProper(
    LatLng a,
    LatLng b,
    LatLng c,
    LatLng d,
  ) {
    final o1 = _orient(a, b, c);
    final o2 = _orient(a, b, d);
    final o3 = _orient(c, d, a);
    final o4 = _orient(c, d, b);
    return o1 != o2 && o3 != o4;
  }

  static double _orient(LatLng a, LatLng b, LatLng c) {
    return (b.longitude - a.longitude) * (c.latitude - a.latitude) -
        (b.latitude - a.latitude) * (c.longitude - a.longitude);
  }

  static List<LatLng> _extractBoundedRegionByGrid(
    List<LatLng> openVertices,
    LatLng seed,
  ) {
    const grid = 80;
    var minLat = openVertices.first.latitude;
    var maxLat = minLat;
    var minLng = openVertices.first.longitude;
    var maxLng = minLng;
    for (final p in openVertices) {
      minLat = math.min(minLat, p.latitude);
      maxLat = math.max(maxLat, p.latitude);
      minLng = math.min(minLng, p.longitude);
      maxLng = math.max(maxLng, p.longitude);
    }
    final padLat = math.max((maxLat - minLat) * 0.1, 0.0002);
    final padLng = math.max((maxLng - minLng) * 0.1, 0.0002);
    minLat -= padLat;
    maxLat += padLat;
    minLng -= padLng;
    maxLng += padLng;

    final ring = _dedupeAdjacent(openVertices);
    final inside = List.generate(grid, (_) => List.filled(grid, false));

    int? seedI;
    int? seedJ;
    for (var i = 0; i < grid; i++) {
      final lat = minLat + (maxLat - minLat) * (i + 0.5) / grid;
      for (var j = 0; j < grid; j++) {
        final lng = minLng + (maxLng - minLng) * (j + 0.5) / grid;
        final p = LatLng(lat, lng);
        if (_pointInsideEvenOdd(p, ring)) {
          inside[i][j] = true;
          if (seedI == null && _near(p, seed)) {
            seedI = i;
            seedJ = j;
          }
        }
      }
    }

    final nearest = _nearestInsideCell(
      inside,
      seed,
      minLat,
      maxLat,
      minLng,
      maxLng,
      grid,
    );
    if (seedI == null && nearest != null) {
      seedI = nearest.$1;
      seedJ = nearest.$2;
    }
    if (seedI == null || seedJ == null) return ring;

    final si = seedI;
    final sj = seedJ;
    final component = List.generate(grid, (_) => List.filled(grid, false));
    final q = <(int, int)>[(si, sj)];
    component[si][sj] = true;
    while (q.isNotEmpty) {
      final (ci, cj) = q.removeLast();
      for (final (di, dj) in const [(0, 1), (0, -1), (1, 0), (-1, 0)]) {
        final ni = ci + di;
        final nj = cj + dj;
        if (ni < 0 || nj < 0 || ni >= grid || nj >= grid) continue;
        if (!inside[ni][nj] || component[ni][nj]) continue;
        component[ni][nj] = true;
        q.add((ni, nj));
      }
    }

    final traced = _traceComponentBoundaryMoore(
      component,
      grid,
      minLat,
      maxLat,
      minLng,
      maxLng,
    );
    if (traced.length >= 3) return _simplifyRing(traced, 48);
    return ring;
  }

  /// 4 連結成分の外周をたどる（凸包ではない）。
  static List<LatLng> _traceComponentBoundaryMoore(
    List<List<bool>> component,
    int grid,
    double minLat,
    double maxLat,
    double minLng,
    double maxLng,
  ) {
    int? startI;
    int? startJ;
    for (var j = 0; j < grid; j++) {
      for (var i = 0; i < grid; i++) {
        if (component[i][j]) {
          startI = i;
          startJ = j;
          break;
        }
      }
      if (startI != null) break;
    }
    if (startI == null || startJ == null) return const [];
    final startIVal = startI;
    final startJVal = startJ;

    LatLng cellCenter(int i, int j) => LatLng(
          minLat + (maxLat - minLat) * (i + 0.5) / grid,
          minLng + (maxLng - minLng) * (j + 0.5) / grid,
        );

    bool isInside(int i, int j) =>
        i >= 0 && j >= 0 && i < grid && j < grid && component[i][j];

    const moore = [
      (0, 1),
      (1, 1),
      (1, 0),
      (1, -1),
      (0, -1),
      (-1, -1),
      (-1, 0),
      (-1, 1),
    ];

    var ci = startIVal;
    var cj = startJVal;
    var backDir = 0;
    final path = <LatLng>[cellCenter(ci, cj)];
    var guard = 0;
  loop:
    while (guard++ < grid * grid * 16) {
      for (var k = 0; k < 8; k++) {
        final dir = (backDir + k) % 8;
        final (di, dj) = moore[dir];
        final ni = ci + di;
        final nj = cj + dj;
        if (!isInside(ni, nj)) continue;
        if (path.length > 2 &&
            ni == startIVal &&
            nj == startJVal &&
            path.length > 4) {
          break loop;
        }
        path.add(cellCenter(ni, nj));
        ci = ni;
        cj = nj;
        backDir = (dir + 6) % 8;
        continue loop;
      }
      break;
    }
    return path;
  }

  static List<LatLng> _simplifyRing(List<LatLng> ring, int maxPoints) {
    if (ring.length <= maxPoints) return _dedupeAdjacent(ring);
    final step = ring.length / maxPoints;
    final out = <LatLng>[];
    for (var i = 0; i < maxPoints; i++) {
      out.add(ring[(i * step).floor() % ring.length]);
    }
    return _dedupeAdjacent(out);
  }

  static (int, int)? _nearestInsideCell(
    List<List<bool>> inside,
    LatLng target,
    double minLat,
    double maxLat,
    double minLng,
    double maxLng,
    int grid,
  ) {
    (int, int)? best;
    var bestD = double.infinity;
    for (var i = 0; i < grid; i++) {
      final lat = minLat + (maxLat - minLat) * (i + 0.5) / grid;
      for (var j = 0; j < grid; j++) {
        if (!inside[i][j]) continue;
        final lng = minLng + (maxLng - minLng) * (j + 0.5) / grid;
        final d = _dist2(lat, lng, target.latitude, target.longitude);
        if (d < bestD) {
          bestD = d;
          best = (i, j);
        }
      }
    }
    return best;
  }

  static List<LatLng> _dedupeAdjacent(List<LatLng> pts) {
    if (pts.length < 2) return pts;
    final out = <LatLng>[pts.first];
    for (var i = 1; i < pts.length; i++) {
      final p = pts[i];
      final q = out.last;
      if (p.latitude != q.latitude || p.longitude != q.longitude) {
        out.add(p);
      }
    }
    return out;
  }

  static bool _near(LatLng a, LatLng b) =>
      _dist2(a.latitude, a.longitude, b.latitude, b.longitude) < 1e-10;

  static double _dist2(double lat1, double lng1, double lat2, double lng2) {
    final dlat = lat1 - lat2;
    final dlng = lng1 - lng2;
    return dlat * dlat + dlng * dlng;
  }

  /// 自己交差する閉路でも、有限領域を even-odd で塗り分ける。
  static bool _pointInsideEvenOdd(LatLng p, List<LatLng> ring) {
    final n = ring.length;
    if (n < 3) return false;
    var inside = false;
    for (var i = 0, j = n - 1; i < n; j = i++) {
      final yi = ring[i].latitude;
      final yj = ring[j].latitude;
      final xi = ring[i].longitude;
      final xj = ring[j].longitude;
      if ((yi > p.latitude) != (yj > p.latitude)) {
        final atX = (xj - xi) * (p.latitude - yi) / (yj - yi) + xi;
        if (p.longitude < atX) inside = !inside;
      }
    }
    return inside;
  }
}
