import 'dart:convert';

import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;

/// 1 点の道路スナップ結果。
class RoadSnapPoint {
  const RoadSnapPoint({required this.position, required this.onRoad});

  final LatLng position;

  /// 85m 以内の道路上へ寄せられたか。
  final bool onRoad;
}

/// Google Roads API（Nearest Roads）で候補座標を道路上に寄せる。
///
/// 試合開始時のギミック生成で使う（リクエスト数は少ない）。
abstract final class RoadsSnapService {
  static const _nearestRoadsUrl = 'https://roads.googleapis.com/v1/nearestRoads';

  /// [apiKey] が空のときは [candidates] をそのまま返す。
  static Future<List<LatLng>> snapToNearestRoads({
    required List<LatLng> candidates,
    required String apiKey,
    double maxSnapDistanceMeters = 85,
  }) async {
    final results = await snapWithStatus(
      candidates: candidates,
      apiKey: apiKey,
      maxSnapDistanceMeters: maxSnapDistanceMeters,
    );
    return results.map((r) => r.position).toList();
  }

  /// 道路上へ寄せられたかどうかも返す。
  static Future<List<RoadSnapPoint>> snapWithStatus({
    required List<LatLng> candidates,
    required String apiKey,
    double maxSnapDistanceMeters = 85,
  }) async {
    if (apiKey.isEmpty || candidates.isEmpty) {
      return [
        for (final p in candidates) RoadSnapPoint(position: p, onRoad: false),
      ];
    }

    final out = <RoadSnapPoint>[];
    for (var start = 0; start < candidates.length; start += 100) {
      final end = (start + 100 > candidates.length)
          ? candidates.length
          : start + 100;
      final chunk = candidates.sublist(start, end);
      final snapped = await _snapChunkWithStatus(
        chunk: chunk,
        apiKey: apiKey,
        maxSnapDistanceMeters: maxSnapDistanceMeters,
      );
      out.addAll(snapped);
    }
    return out;
  }

  static Future<List<RoadSnapPoint>> _snapChunkWithStatus({
    required List<LatLng> chunk,
    required String apiKey,
    required double maxSnapDistanceMeters,
  }) async {
    final points = chunk
        .map((p) => '${p.latitude},${p.longitude}')
        .join('|');
    final uri = Uri.parse(_nearestRoadsUrl).replace(
      queryParameters: {'points': points, 'key': apiKey},
    );
    try {
      final res = await http
          .get(uri)
          .timeout(const Duration(seconds: 12));
      if (res.statusCode != 200) {
        return [
          for (final p in chunk) RoadSnapPoint(position: p, onRoad: false),
        ];
      }
      final body = jsonDecode(res.body);
      if (body is! Map<String, dynamic>) {
        return [
          for (final p in chunk) RoadSnapPoint(position: p, onRoad: false),
        ];
      }
      final raw = body['snappedPoints'];
      if (raw is! List) {
        return [
          for (final p in chunk) RoadSnapPoint(position: p, onRoad: false),
        ];
      }

      final byIndex = <int, LatLng>{};
      for (final item in raw) {
        if (item is! Map<String, dynamic>) continue;
        final idx = item['originalIndex'];
        final loc = item['location'];
        if (idx is! num || loc is! Map) continue;
        final lat = loc['latitude'];
        final lng = loc['longitude'];
        if (lat is! num || lng is! num) continue;
        byIndex[idx.toInt()] = LatLng(lat.toDouble(), lng.toDouble());
      }

      final out = <RoadSnapPoint>[];
      for (var i = 0; i < chunk.length; i++) {
        final original = chunk[i];
        final snapped = byIndex[i];
        if (snapped == null) {
          out.add(RoadSnapPoint(position: original, onRoad: false));
          continue;
        }
        final moved = Geolocator.distanceBetween(
          original.latitude,
          original.longitude,
          snapped.latitude,
          snapped.longitude,
        );
        if (moved <= maxSnapDistanceMeters) {
          out.add(RoadSnapPoint(position: snapped, onRoad: true));
        } else {
          out.add(RoadSnapPoint(position: original, onRoad: false));
        }
      }
      return out;
    } catch (_) {
      return [
        for (final p in chunk) RoadSnapPoint(position: p, onRoad: false),
      ];
    }
  }
}
