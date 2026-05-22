import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../theme/world_launch_branding.dart';

/// タイトル画面用の控えめな世界観モチーフ（画面全体に散らす軽量版）。
class TitleAmbientOverlay extends StatelessWidget {
  const TitleAmbientOverlay({
    required this.branding,
    required this.progress,
    this.opacity = 0.32,
    super.key,
  });

  final WorldLaunchBranding branding;
  final double progress;
  final double opacity;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Opacity(
        opacity: opacity,
        child: CustomPaint(
          painter: _TitleAmbientPainter(
            branding: branding,
            progress: progress,
          ),
          size: Size.infinite,
        ),
      ),
    );
  }
}

class _TitleAmbientPainter extends CustomPainter {
  _TitleAmbientPainter({
    required this.branding,
    required this.progress,
  });

  final WorldLaunchBranding branding;
  final double progress;

  double get _beat => 0.5 + 0.5 * math.sin(progress * math.pi * 2);

  static Offset _n(Size size, double x, double y) =>
      Offset(size.width * x, size.height * y);

  @override
  void paint(Canvas canvas, Size size) {
    switch (branding.effect) {
      case LaunchEffectKind.cyber:
        _cyber(canvas, size);
      case LaunchEffectKind.horror:
        _horror(canvas, size);
      case LaunchEffectKind.pop:
        _pop(canvas, size);
      case LaunchEffectKind.tactical:
        _tactical(canvas, size);
      case LaunchEffectKind.magical:
        _magical(canvas, size);
      case LaunchEffectKind.astronomy:
        _astronomy(canvas, size);
    }
  }

  void _cyber(Canvas canvas, Size size) {
    final beat = _beat;
    final horizon = size.height * 0.42;
    canvas.drawRect(
      Rect.fromLTWH(0, horizon, size.width, 1),
      Paint()..color = branding.accent.withValues(alpha: 0.12 + beat * 0.05),
    );
    for (final x in [0.06, 0.94]) {
      canvas.drawLine(
        _n(size, x, 0.12),
        _n(size, x, 0.88),
        Paint()
          ..color = branding.particleColor.withValues(alpha: 0.08)
          ..strokeWidth = 0.7,
      );
    }
    const step = 48.0;
    final grid = Paint()
      ..color = branding.scanLineColor.withValues(alpha: 0.08)
      ..strokeWidth = 0.45;
    for (var y = horizon; y < size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), grid);
    }
    for (var i = 0; i < 6; i++) {
      final phase = (progress * 0.9 + i * 0.16) % 1.0;
      final anchor = [0.12, 0.88, 0.2, 0.8, 0.5, 0.15][i];
      final x = size.width * anchor;
      final y = size.height * (0.5 + phase * 0.4);
      canvas.drawLine(
        Offset(x, y - 14),
        Offset(x, y),
        Paint()
          ..color = branding.accent.withValues(alpha: 0.09)
          ..strokeWidth = 0.8
          ..strokeCap = StrokeCap.round,
      );
    }
  }

  void _horror(Canvas canvas, Size size) {
    final pulse = _beat;
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Paint()
        ..shader = RadialGradient(
          colors: [
            Colors.transparent,
            branding.secondaryAccent.withValues(alpha: 0.14 * pulse),
          ],
          stops: const [0.55, 1.0],
        ).createShader(Rect.fromLTWH(0, 0, size.width, size.height)),
    );
    final scanY = size.height * (0.15 + progress * 0.65);
    canvas.drawLine(
      Offset(0, scanY),
      Offset(size.width, scanY),
      Paint()..color = branding.accent.withValues(alpha: 0.06)..strokeWidth = 0.7,
    );
    const dust = [
      Offset(0.08, 0.12),
      Offset(0.92, 0.1),
      Offset(0.1, 0.88),
      Offset(0.9, 0.85),
      Offset(0.5, 0.08),
      Offset(0.18, 0.55),
      Offset(0.82, 0.48),
    ];
    for (var i = 0; i < dust.length; i++) {
      final tw = 0.4 + 0.6 * (0.5 + 0.5 * math.sin(progress * 5 + i));
      canvas.drawCircle(
        _n(size, dust[i].dx, dust[i].dy),
        1.2,
        Paint()..color = Colors.white.withValues(alpha: 0.03 + tw * 0.07),
      );
    }
    final hb = _n(size, 0.78, 0.28);
    canvas.drawCircle(
      hb,
      18 + pulse * 6,
      Paint()
        ..color = branding.pulseColor.withValues(alpha: 0.08 * pulse)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.8,
    );
    _cornerTicks(canvas, size, branding.accent.withValues(alpha: 0.12), 16);
  }

  void _pop(Canvas canvas, Size size) {
    final beat = _beat;
    final spots = [
      (0.14, 0.18, branding.accent),
      (0.86, 0.22, branding.secondaryAccent),
      (0.12, 0.78, branding.particleColor),
      (0.88, 0.72, branding.pulseColor),
      (0.5, 0.12, branding.coreGlow),
      (0.72, 0.58, branding.accent),
    ];
    for (final (x, y, c) in spots) {
      final drift = math.sin(progress * math.pi * 2 + x * 8) * 5;
      canvas.drawCircle(
        _n(size, x, y) + Offset(0, drift),
        28 + beat * 3,
        Paint()..color = c.withValues(alpha: 0.07),
      );
    }
  }

  void _tactical(Canvas canvas, Size size) {
    final line = Paint()
      ..color = branding.scanLineColor.withValues(alpha: 0.16)
      ..strokeWidth = 0.5;
    const step = 40.0;
    for (var x = 0.0; x < size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), line);
    }
    for (var y = 0.0; y < size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), line);
    }
    final y = size.height * (0.18 + progress * 0.6);
    canvas.drawLine(
      Offset(0, y),
      Offset(size.width, y),
      Paint()..color = branding.accent.withValues(alpha: 0.18)..strokeWidth = 0.7,
    );
    _cornerTicks(canvas, size, branding.pulseColor.withValues(alpha: 0.2), 14);
  }

  void _magical(Canvas canvas, Size size) {
    final cx = size.width * 0.5;
    final cy = size.height * 0.36;
    canvas.save();
    canvas.translate(cx, cy);
    canvas.rotate(progress * math.pi * 0.25);
    canvas.drawCircle(
      Offset.zero,
      64,
      Paint()
        ..color = branding.accent.withValues(alpha: 0.14)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.9,
    );
    canvas.restore();
    for (final (x, y) in [(0.12, 0.2), (0.88, 0.18), (0.15, 0.8), (0.85, 0.75)]) {
      canvas.drawArc(
        Rect.fromCircle(center: _n(size, x, y), radius: 22),
        progress * math.pi,
        math.pi * 0.6,
        false,
        Paint()
          ..color = branding.accent.withValues(alpha: 0.12)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 0.8,
      );
    }
    for (var i = 0; i < 8; i++) {
      final tw = 0.35 + 0.65 * (0.5 + 0.5 * math.sin(progress * 4 + i));
      final anchors = [0.08, 0.25, 0.75, 0.92, 0.5, 0.18, 0.82, 0.62];
      canvas.drawCircle(
        Offset(
          size.width * anchors[i],
          size.height * (0.2 + (i % 4) * 0.18),
        ),
        1.8,
        Paint()..color = branding.particleColor.withValues(alpha: 0.12 * tw),
      );
    }
  }

  void _astronomy(Canvas canvas, Size size) {
    final rng = math.Random(42);
    for (var i = 0; i < 40; i++) {
      final x = rng.nextDouble() * size.width;
      final y = rng.nextDouble() * size.height;
      final tw = 0.25 +
          0.75 * (0.5 + 0.5 * math.sin(progress * 3.5 + i * 0.45));
      canvas.drawCircle(
        Offset(x, y),
        0.5 + (i % 3) * 0.25,
        Paint()..color = branding.particleColor.withValues(alpha: 0.2 * tw),
      );
    }
    for (var i = 0; i < 8; i++) {
      final origin = _n(
        size,
        i.isEven ? 0.08 + (i % 4) * 0.02 : 0.92 - (i % 4) * 0.02,
        0.15 + (i % 3) * 0.25,
      );
      final ang = math.atan2(
        size.height * 0.42 - origin.dy,
        size.width * 0.5 - origin.dx,
      );
      final len = 36.0 + (i % 3) * 14;
      final end = origin + Offset(math.cos(ang) * len, math.sin(ang) * len * 0.5);
      canvas.drawLine(
        origin,
        end,
        Paint()
          ..color = branding.accent.withValues(alpha: 0.08)
          ..strokeWidth = 0.65
          ..strokeCap = StrokeCap.round,
      );
    }
  }

  void _cornerTicks(
    Canvas canvas,
    Size size,
    Color color,
    double inset,
  ) {
    final tick = Paint()
      ..color = color
      ..strokeWidth = 0.8
      ..strokeCap = StrokeCap.round;
    const len = 12.0;
    final corners = [
      (inset, inset, len, 0.0, 0.0, len),
      (size.width - inset, inset, -len, 0.0, 0.0, len),
      (inset, size.height - inset, len, 0.0, 0.0, -len),
      (size.width - inset, size.height - inset, -len, 0.0, 0.0, -len),
    ];
    for (final (x, y, dx, dy, ox, oy) in corners) {
      canvas.drawLine(Offset(x, y), Offset(x + dx, y + dy), tick);
      canvas.drawLine(Offset(x, y), Offset(x + ox, y + oy), tick);
    }
  }

  @override
  bool shouldRepaint(covariant _TitleAmbientPainter old) {
    return old.branding.effect != branding.effect ||
        (old.progress - progress).abs() > 0.004;
  }
}
