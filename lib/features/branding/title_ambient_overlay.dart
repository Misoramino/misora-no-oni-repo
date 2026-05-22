import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../theme/world_launch_branding.dart';

/// タイトル画面用の控えめな世界観モチーフ（起動演出の軽量版）。
///
/// 粒子数・描画レイヤーを抑え、1本の [AnimationController] のみで回す想定。
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
    final horizon = size.height * 0.4;
    final beat = _beat;
    canvas.drawRect(
      Rect.fromLTWH(0, horizon, size.width, 1),
      Paint()..color = branding.accent.withValues(alpha: 0.14 + beat * 0.06),
    );
    final grid = Paint()
      ..color = branding.scanLineColor.withValues(alpha: 0.1)
      ..strokeWidth = 0.5;
    const step = 44.0;
    for (var y = horizon; y < size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), grid);
    }
    for (var i = 0; i < 5; i++) {
      final phase = (progress * 1.0 + i * 0.18) % 1.0;
      final x = size.width * (0.15 + i * 0.16);
      final y = size.height * (0.55 + phase * 0.35);
      canvas.drawLine(
        Offset(x, y - 16),
        Offset(x, y),
        Paint()
          ..color = branding.particleColor.withValues(alpha: 0.1)
          ..strokeWidth = 0.8
          ..strokeCap = StrokeCap.round,
      );
    }
  }

  void _horror(Canvas canvas, Size size) {
    final pulse = 0.5 + 0.5 * math.sin(progress * math.pi * 2);
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Paint()
        ..shader = RadialGradient(
          colors: [
            Colors.transparent,
            branding.secondaryAccent.withValues(alpha: 0.12 * pulse),
          ],
          stops: const [0.5, 1.0],
        ).createShader(Rect.fromLTWH(0, 0, size.width, size.height)),
    );
  }

  void _pop(Canvas canvas, Size size) {
    final beat = _beat;
    final orbs = [
      (Offset(size.width * 0.2, size.height * 0.25), branding.accent),
      (Offset(size.width * 0.78, size.height * 0.3), branding.secondaryAccent),
      (Offset(size.width * 0.55, size.height * 0.7), branding.particleColor),
    ];
    for (final (o, c) in orbs) {
      canvas.drawCircle(
        o + Offset(0, math.sin(progress * math.pi * 2 + o.dx) * 6),
        36 + beat * 4,
        Paint()..color = c.withValues(alpha: 0.08),
      );
    }
  }

  void _tactical(Canvas canvas, Size size) {
    final line = Paint()
      ..color = branding.scanLineColor.withValues(alpha: 0.22)
      ..strokeWidth = 0.55;
    const step = 36.0;
    for (var x = 0.0; x < size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), line);
    }
    for (var y = 0.0; y < size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), line);
    }
    final y = size.height * (0.2 + progress * 0.55);
    canvas.drawLine(
      Offset(0, y),
      Offset(size.width, y),
      Paint()..color = branding.accent.withValues(alpha: 0.25)..strokeWidth = 0.8,
    );
  }

  void _magical(Canvas canvas, Size size) {
    final cx = size.width * 0.5;
    final cy = size.height * 0.38;
    canvas.save();
    canvas.translate(cx, cy);
    canvas.rotate(progress * math.pi * 0.4);
    canvas.drawCircle(
      Offset.zero,
      72,
      Paint()
        ..color = branding.accent.withValues(alpha: 0.2)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1,
    );
    for (var i = 0; i < 8; i++) {
      final a = i * math.pi / 4;
      canvas.drawLine(
        Offset(math.cos(a) * 60, math.sin(a) * 60),
        Offset(math.cos(a) * 52, math.sin(a) * 52),
        Paint()
          ..color = branding.pulseColor.withValues(alpha: 0.3)
          ..strokeWidth = 0.8,
      );
    }
    canvas.restore();
    for (var i = 0; i < 6; i++) {
      final tw = 0.4 + 0.6 * (0.5 + 0.5 * math.sin(progress * 5 + i));
      canvas.drawCircle(
        Offset(
          size.width * (0.2 + i * 0.12),
          size.height * (0.55 + math.sin(i + progress * 3) * 0.08),
        ),
        2,
        Paint()..color = branding.particleColor.withValues(alpha: 0.2 * tw),
      );
    }
  }

  void _astronomy(Canvas canvas, Size size) {
    final cx = size.width * 0.5;
    final cy = size.height * 0.4;
    final rng = math.Random(42);
    for (var i = 0; i < 36; i++) {
      final x = rng.nextDouble() * size.width;
      final y = rng.nextDouble() * size.height;
      final tw = 0.3 +
          0.7 * (0.5 + 0.5 * math.sin(progress * 4 + i * 0.5));
      canvas.drawCircle(
        Offset(x, y),
        0.6 + (i % 3) * 0.3,
        Paint()..color = branding.particleColor.withValues(alpha: 0.25 * tw),
      );
    }
    for (var i = 0; i < 10; i++) {
      final ang = i * 0.55 + progress * 0.25;
      final len = 40.0 + (i % 4) * 18;
      final start = Offset(cx, cy);
      final end = Offset(
        cx + math.cos(ang) * len,
        cy + math.sin(ang) * len * 0.45,
      );
      canvas.drawLine(
        start,
        end,
        Paint()
          ..color = branding.accent.withValues(alpha: 0.1)
          ..strokeWidth = 0.7
          ..strokeCap = StrokeCap.round,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _TitleAmbientPainter old) {
    return old.branding.effect != branding.effect ||
        (old.progress - progress).abs() > 0.004;
  }
}
