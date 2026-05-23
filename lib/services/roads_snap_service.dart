import 'dart:convert';

import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;

/// Google Roads API（Nearest Roads）で候補座標を道路上に寄せる。
///
/// 試合開始時のイベントエリア生成だけで使う想定（リクエスト数は少ない）。
abstract final class RoadsSnapService {
  static const _nearestRoadsUrl = 'https://roads.googleapis.com/v1/nearestRoads';

  /// [apiKey] が空のときは [candidates] をそのまま返す。
  static Future<List<LatLng>> snapToNearestRoads({
    required List<LatLng> candidates,
    required String apiKey,
    double maxSnapDistanceMeters = 85,
  }) async {
    if (apiKey.isEmpty || candidates.isEmpty) return candidates;

    final out = List<LatLng>.from(candidates);
    for (var start = 0; start < candidates.length; start += 100) {
      final end = (start + 100 > candidates.length)
          ? candidates.length
          : start + 100;
      final chunk = candidates.sublist(start, end);
      final snapped = await _snapChunk(
        chunk: chunk,
        apiKey: apiKey,
        maxSnapDistanceMeters: maxSnapDistanceMeters,
      );
      for (var i = 0; i < snapped.length; i++) {
        out[start + i] = snapped[i];
      }
    }
    return out;
  }

  static Future<List<LatLng>> _snapChunk({
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
      if (res.statusCode != 200) return chunk;
      final body = jsonDecode(res.body);
      if (body is! Map<String, dynamic>) return chunk;
      final raw = body['snappedPoints'];
      if (raw is! List) return chunk;

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

      final out = <LatLng>[];
      for (var i = 0; i < chunk.length; i++) {
        final original = chunk[i];
        final snapped = byIndex[i];
        if (snapped == null) {
          out.add(original);
          continue;
        }
        final moved = Geolocator.distanceBetween(
          original.latitude,
          original.longitude,
          snapped.latitude,
          snapped.longitude,
        );
        out.add(moved <= maxSnapDistanceMeters ? snapped : original);
      }
      return out;
    } catch (_) {
      return chunk;
    }
  }
}
