import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

/// 写真の自動リサイズ（ピン・ルーム共有用）。
abstract final class AvatarThumbCodec {
  /// 他プレイヤーへ送る暴露ピン用（地図上はこれを拡大表示）。
  static const int syncThumbPx = 96;

  /// 端末内の自分ピン用デコード目安（共有より少し大きめ）。
  static const int localPinDecodePx = 128;

  /// 端末保存用（ギャラリー原寸を避ける）。
  static const int localStorePx = 256;

  /// Firestore 1 フィールド向けの上限（超えたら null＝送らない）。
  static const int maxEncodedChars = 24_000;

  static Future<String?> encodeFile(String path) async {
    try {
      final file = File(path);
      if (!await file.exists()) return null;
      final bytes = await file.readAsBytes();
      return encodeBytesForSync(bytes);
    } catch (_) {
      return null;
    }
  }

  /// ルーム共有用 PNG → Base64。
  static Future<String?> encodeBytesForSync(Uint8List bytes) async {
    final png = await resizeToPng(bytes, syncThumbPx);
    if (png == null) return null;
    final encoded = base64Encode(png);
    if (encoded.length > maxEncodedChars) return null;
    return encoded;
  }

  /// 端末保存用にリサイズした PNG バイト列。
  static Future<Uint8List?> resizeForLocalStore(Uint8List bytes) =>
      resizeToPng(bytes, localStorePx);

  static Future<Uint8List?> resizeToPng(Uint8List bytes, int targetPx) async {
    try {
      final codec = await ui.instantiateImageCodec(
        bytes,
        targetWidth: targetPx,
        targetHeight: targetPx,
      );
      final frame = await codec.getNextFrame();
      final image = frame.image;
      final data = await image.toByteData(format: ui.ImageByteFormat.png);
      image.dispose();
      if (data == null) return null;
      return data.buffer.asUint8List();
    } catch (_) {
      return null;
    }
  }

  static Uint8List? decode(String? base64Thumb) {
    if (base64Thumb == null || base64Thumb.isEmpty) return null;
    try {
      return base64Decode(base64Thumb);
    } catch (_) {
      return null;
    }
  }
}
