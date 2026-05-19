import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../../theme/world_profile_tokens.dart';

/// 端末ローカル写真から丸枠付きプレイヤーピンを生成（Firestore には送らない）。
abstract final class AvatarPinCompositor {
  static const double _size = 112;

  static Future<BitmapDescriptor?> fromFilePath({
    required String? path,
    required WorldProfileTokens tokens,
    required bool revealedStyle,
  }) async {
    if (path == null || path.isEmpty) return null;
    final file = File(path);
    if (!await file.exists()) return null;
    try {
      final bytes = await file.readAsBytes();
      final descriptor = await fromBytes(
        imageBytes: bytes,
        tokens: tokens,
        revealedStyle: revealedStyle,
      );
      return descriptor;
    } catch (_) {
      return null;
    }
  }

  static Future<BitmapDescriptor?> fromBytes({
    required Uint8List imageBytes,
    required WorldProfileTokens tokens,
    required bool revealedStyle,
  }) async {
    try {
      final codec = await ui.instantiateImageCodec(
        imageBytes,
        targetWidth: 128,
        targetHeight: 128,
      );
      final frame = await codec.getNextFrame();
      final photo = frame.image;

      final out = await _compose(photo, tokens, revealedStyle);
      photo.dispose();
      return BitmapDescriptor.bytes(
        out,
        width: _size,
        height: _size,
      );
    } catch (_) {
      return null;
    }
  }

  static Future<Uint8List> _compose(
    ui.Image photo,
    WorldProfileTokens tokens,
    bool revealedStyle,
  ) async {
    const size = _size;
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    final center = Offset(size / 2, size / 2);
    final ringColor = revealedStyle ? tokens.markerAccent : tokens.playerRingColor;

    final ringPaint = Paint()
      ..color = ringColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = revealedStyle ? 8 : 5;
    canvas.drawCircle(center, size * 0.48, ringPaint);

    final clipPath = Path()..addOval(Rect.fromCircle(center: center, radius: size * 0.4));
    canvas.save();
    canvas.clipPath(clipPath);
    final src = Rect.fromLTWH(0, 0, photo.width.toDouble(), photo.height.toDouble());
    final dst = Rect.fromCircle(center: center, radius: size * 0.4);
    canvas.drawImageRect(photo, src, dst, Paint());
    canvas.restore();

    final border = Paint()
      ..color = Colors.white.withValues(alpha: 0.9)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5;
    canvas.drawCircle(center, size * 0.4, border);

    final picture = recorder.endRecording();
    final image = await picture.toImage(size.toInt(), size.toInt());
    final data = await image.toByteData(format: ui.ImageByteFormat.png);
    image.dispose();
    return data!.buffer.asUint8List();
  }
}
