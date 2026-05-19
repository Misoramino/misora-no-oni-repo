import 'package:flutter/services.dart';

/// 世界観別 PNG マーカー（任意）。無ければ null。
abstract final class MapMarkerAssetLoader {
  static String assetPath(String assetKey, String fileName) =>
      'assets/map_markers/$assetKey/$fileName.png';

  static Future<Uint8List?> tryLoadPng(String path) async {
    try {
      final data = await rootBundle.load(path);
      return data.buffer.asUint8List();
    } catch (_) {
      return null;
    }
  }
}
