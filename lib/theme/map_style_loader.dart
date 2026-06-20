import 'dart:convert';

import 'package:flutter/services.dart';

/// Google Maps 用スタイル JSON を assets から読み込む。
abstract final class MapStyleLoader {
  static final Map<String, String> _cache = {};

  static Future<String?> load(String assetPath) async {
    final cached = _cache[assetPath];
    if (cached != null) return cached;
    try {
      final json = await rootBundle.loadString(assetPath);
      _cache[assetPath] = json;
      return json;
    } catch (_) {
      return null;
    }
  }

  static void clearCache() => _cache.clear();

  /// エリアスキャン演出中など、地図ラベルだけ一時的に隠す。
  static String? withLabelsHidden(String? json) {
    if (json == null) return null;
    try {
      final list = (jsonDecode(json) as List).cast<Map<String, dynamic>>();
      return jsonEncode([
        ...list,
        {
          'elementType': 'labels',
          'stylers': [
            {'visibility': 'off'},
          ],
        },
      ]);
    } catch (_) {
      return json;
    }
  }
}
