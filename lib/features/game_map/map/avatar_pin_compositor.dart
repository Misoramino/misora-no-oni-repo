import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../../session/avatar_thumb_codec.dart';
import '../../../theme/world_profile_tokens.dart';

/// 端末ローカル写真から丸枠付きプレイヤーピンを生成（Firestore には送らない）。
abstract final class AvatarPinCompositor {
  static const double baseSize = 112;

  static Future<BitmapDescriptor?> fromFilePath({
    required String? path,
    required WorldProfileTokens tokens,
    required bool revealedStyle,
    double iconScale = 1.0,
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
        iconScale: iconScale,
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
    double iconScale = 1.0,
  }) async {
    final size = baseSize * iconScale.clamp(0.5, 2.0);
    try {
      final codec = await ui.instantiateImageCodec(
        imageBytes,
        targetWidth: AvatarThumbCodec.localPinDecodePx,
        targetHeight: AvatarThumbCodec.localPinDecodePx,
      );
      final frame = await codec.getNextFrame();
      final photo = frame.image;

      final out = await _compose(photo, tokens, revealedStyle, size: size);
      photo.dispose();
      return BitmapDescriptor.bytes(
        out,
        width: size,
        height: size,
      );
    } catch (_) {
      return null;
    }
  }

  static Future<Uint8List> _compose(
    ui.Image photo,
    WorldProfileTokens tokens,
    bool revealedStyle, {
    required double size,
  }) async {
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
