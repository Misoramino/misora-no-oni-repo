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
}
