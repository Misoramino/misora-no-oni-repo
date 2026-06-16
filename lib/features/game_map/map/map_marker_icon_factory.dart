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
  static const double baseSize = 72;

  static Future<BitmapDescriptor> create({
    required MapMarkerKind kind,
    required WorldProfileTokens tokens,
    String? profileAssetKey,
    double iconScale = 1.0,
  }) async {
    final size = baseSize * iconScale.clamp(0.5, 2.0);
    if (profileAssetKey != null) {
      final path = MapMarkerAssetLoader.assetPath(
        profileAssetKey,
        kind.assetFileName,
      );
      final png = await MapMarkerAssetLoader.tryLoadPng(path);
      if (png != null) {
        return BitmapDescriptor.bytes(
          png,
          width: size,
          height: size,
        );
      }
    }
    final bg = _backgroundFor(kind, tokens);
    final bytes = await _render(
      icon: _iconFor(kind),
      background: bg,
      foreground: _foregroundFor(kind, bg),
      ringColor: kind == MapMarkerKind.player || kind == MapMarkerKind.playerRevealed
          ? tokens.playerRingColor
          : null,
      showRing:
          kind == MapMarkerKind.player || kind == MapMarkerKind.playerRevealed,
      size: size,
    );
    return BitmapDescriptor.bytes(
      bytes,
      width: size,
      height: size,
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
        MapMarkerKind.anonymousReveal => Icons.help_outline,
        MapMarkerKind.oniIntel => Icons.radar,
        MapMarkerKind.fakePosition => Icons.flare,
        MapMarkerKind.bodyThrow => Icons.sports_martial_arts,
        MapMarkerKind.accusationFacility => Icons.account_balance,
      };

  static Color _backgroundFor(MapMarkerKind kind, WorldProfileTokens t) {
    final m = t.mapIcons;
    return switch (kind) {
      MapMarkerKind.player => m.player,
      MapMarkerKind.playerRevealed => m.player.withValues(alpha: 0.92),
      MapMarkerKind.oni || MapMarkerKind.remoteOni => m.hunter,
      MapMarkerKind.remoteRunner => m.runner,
      MapMarkerKind.remoteSpectator => m.werewolf,
      MapMarkerKind.safeZone => m.safeZone,
      MapMarkerKind.infoBroker => m.infoBroker,
      MapMarkerKind.camera || MapMarkerKind.oniIntel => m.camera,
      MapMarkerKind.commJamming => m.jamming,
      MapMarkerKind.trace => m.trace,
      MapMarkerKind.reveal || MapMarkerKind.anonymousReveal => m.accusation,
      MapMarkerKind.accusationFacility => m.accusation,
      MapMarkerKind.bodyThrow ||
      MapMarkerKind.fakePosition =>
        m.capture,
      _ => t.markerAccent.withValues(alpha: 0.85),
    };
  }

  static Color _foregroundFor(MapMarkerKind kind, Color background) {
    final lum = background.computeLuminance();
    return lum > 0.55 ? const Color(0xFF1A1A2E) : Colors.white;
  }

  static Future<Uint8List> _render({
    required IconData icon,
    required Color background,
    required Color foreground,
    required double size,
    Color? ringColor,
    bool showRing = false,
  }) async {
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
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
