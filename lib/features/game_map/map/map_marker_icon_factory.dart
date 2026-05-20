import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../../theme/world_profile_tokens.dart';
import 'map_marker_asset_loader.dart';
import 'map_marker_kind.dart';
import 'map_marker_kind_assets.dart';

/// 世界観ごとのマーカー Bitmap（PNG があれば優先、なければプログラム生成）。
abstract final class MapMarkerIconFactory {
  static const double _size = 72;

  static Future<BitmapDescriptor> create({
    required MapMarkerKind kind,
    required WorldProfileTokens tokens,
    String? profileAssetKey,
  }) async {
    if (profileAssetKey != null) {
      final path = MapMarkerAssetLoader.assetPath(
        profileAssetKey,
        kind.assetFileName,
      );
      final png = await MapMarkerAssetLoader.tryLoadPng(path);
      if (png != null) {
        return BitmapDescriptor.bytes(
          png,
          width: _size,
          height: _size,
        );
      }
    }
    final bytes = await _render(
      icon: _iconFor(kind),
      background: _backgroundFor(kind, tokens),
      foreground: _foregroundFor(kind),
      ringColor: kind == MapMarkerKind.player || kind == MapMarkerKind.playerRevealed
          ? tokens.playerRingColor
          : null,
      showRing:
          kind == MapMarkerKind.player || kind == MapMarkerKind.playerRevealed,
    );
    return BitmapDescriptor.bytes(
      bytes,
      width: _size,
      height: _size,
    );
  }

  static IconData _iconFor(MapMarkerKind kind) => switch (kind) {
        MapMarkerKind.player || MapMarkerKind.playerRevealed => Icons.person,
        MapMarkerKind.oni || MapMarkerKind.remoteOni => Icons.whatshot,
        MapMarkerKind.remoteRunner => Icons.directions_run,
        MapMarkerKind.remoteSpectator => Icons.visibility,
        MapMarkerKind.camera => Icons.videocam,
        MapMarkerKind.infoBroker => Icons.cell_tower,
        MapMarkerKind.safeZone => Icons.shield,
        MapMarkerKind.commJamming => Icons.wifi_off,
        MapMarkerKind.trace => Icons.linear_scale,
        MapMarkerKind.reveal => Icons.location_on,
        MapMarkerKind.oniIntel => Icons.radar,
        MapMarkerKind.fakePosition => Icons.flare,
        MapMarkerKind.bodyThrow => Icons.sports_martial_arts,
      };

  static Color _backgroundFor(MapMarkerKind kind, WorldProfileTokens t) =>
      switch (kind) {
        MapMarkerKind.safeZone => t.safeColor,
        MapMarkerKind.infoBroker => t.infoColor,
        MapMarkerKind.camera || MapMarkerKind.oniIntel => t.alertColor,
        MapMarkerKind.reveal => t.alertColor.withValues(alpha: 0.9),
        MapMarkerKind.playerRevealed => t.markerAccent,
        MapMarkerKind.player => const Color(0xFF37474F),
        _ => t.markerAccent.withValues(alpha: 0.85),
      };

  static Color _foregroundFor(MapMarkerKind kind) {
    if (kind == MapMarkerKind.player) return Colors.white70;
    return Colors.white;
  }

  static Future<Uint8List> _render({
    required IconData icon,
    required Color background,
    required Color foreground,
    Color? ringColor,
    bool showRing = false,
  }) async {
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    const size = _size;
    final center = Offset(size / 2, size / 2);

    if (showRing && ringColor != null) {
      final ringPaint = Paint()
        ..color = ringColor.withValues(alpha: 0.9)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 6;
      canvas.drawCircle(center, size * 0.46, ringPaint);
    }

    final bgPaint = Paint()..color = background;
    canvas.drawCircle(center, size * 0.38, bgPaint);

    final border = Paint()
      ..color = Colors.white.withValues(alpha: 0.85)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;
    canvas.drawCircle(center, size * 0.38, border);

    final textPainter = TextPainter(textDirection: TextDirection.ltr);
    textPainter.text = TextSpan(
      text: String.fromCharCode(icon.codePoint),
      style: TextStyle(
        fontSize: size * 0.34,
        fontFamily: icon.fontFamily,
        package: icon.fontPackage,
        color: foreground,
      ),
    );
    textPainter.layout();
    textPainter.paint(
      canvas,
      Offset(
        center.dx - textPainter.width / 2,
        center.dy - textPainter.height / 2,
      ),
    );

    final picture = recorder.endRecording();
    final image = await picture.toImage(size.toInt(), size.toInt());
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    return byteData!.buffer.asUint8List();
  }
}
