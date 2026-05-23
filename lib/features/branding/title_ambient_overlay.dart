import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../theme/world_launch_branding.dart';

/// タイトル画面用の世界観モチーフ（画面全体・起動演出より控えめだが視認できる強さ）。
class TitleAmbientOverlay extends StatelessWidget {
  const TitleAmbientOverlay({
    required this.branding,
    required this.progress,
    this.strength = 0.85,
    super.key,
  });

  final WorldLaunchBranding branding;
  final double progress;

  /// 0..1。描画アルファ全体の倍率（以前は二重 Opacity で薄くなりすぎていた）。
  final double strength;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: CustomPaint(
        painter: _TitleAmbientPainter(
          branding: branding,
          progress: progress,
          strength: strength,
        ),
        size: Size.infinite,
      ),
    );
  }
}

class _TitleAmbientPainter extends CustomPainter {
  _TitleAmbientPainter({
    required this.branding,
    required this.progress,
    required this.strength,
  });

  final WorldLaunchBranding branding;
  final double progress;
  final double strength;

  double get _beat => 0.5 + 0.5 * math.sin(progress * math.pi * 2);

  Color _a(Color c, double alpha) =>
      c.withValues(alpha: (alpha * strength).clamp(0.0, 1.0));

  static Offset _n(Size size, double x, double y) =>
      Offset(size.width * x, size.height * y);

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Paint()
        ..shader = RadialGradient(
          center: const Alignment(0, -0.2),
          radius: 1.1,
          colors: [
            _a(branding.accent, 0.06),
            _a(branding.secondaryAccent, 0.04),
            Colors.transparent,
          ],
          stops: const [0.0, 0.35, 1.0],
        ).createShader(Rect.fromLTWH(0, 0, size.width, size.height)),
    );

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
      Rect.fromLTWH(0, horizon, size.width, 1.5),
      Paint()..color = _a(branding.accent, 0.22 + beat * 0.08),
    );
    for (final x in [0.06, 0.94]) {
      canvas.drawLine(
        _n(size, x, 0.1),
        _n(size, x, 0.9),
        Paint()
          ..color = _a(branding.particleColor, 0.18)
          ..strokeWidth = 0.9,
      );
    }
    final grid = Paint()
      ..color = _a(branding.scanLineColor, 0.14)
      ..strokeWidth = 0.5;
    const step = 44.0;
    for (var y = horizon; y < size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), grid);
    }
    for (var i = 0; i < 7; i++) {
      final phase = (progress * 0.9 + i * 0.14) % 1.0;
      final x = size.width * [0.1, 0.88, 0.22, 0.75, 0.5, 0.14, 0.65][i];
      final y = size.height * (0.52 + phase * 0.38);
      canvas.drawLine(
        Offset(x, y - 18),
        Offset(x, y),
        Paint()
          ..color = _a(branding.accent, 0.2)
          ..strokeWidth = 1
          ..strokeCap = StrokeCap.round,
      );
    }
    _cornerTicks(canvas, size, _a(branding.accent, 0.2), 14);
  }

  void _horror(Canvas canvas, Size size) {
    final pulse = _beat;
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Paint()
        ..shader = RadialGradient(
          colors: [
            Colors.transparent,
            _a(branding.secondaryAccent, 0.28 * pulse),
            _a(branding.accent, 0.12 * pulse),
          ],
          stops: const [0.45, 0.82, 1.0],
        ).createShader(Rect.fromLTWH(0, 0, size.width, size.height)),
    );
    final vhs = Paint()..color = _a(Colors.black, 0.12);
    for (var y = 0.0; y < size.height; y += 6) {
      if ((y.toInt() + (progress * 50).toInt()) % 11 == 0) {
        canvas.drawLine(Offset(0, y), Offset(size.width, y), vhs);
      }
    }
    final scanY = size.height * (0.14 + progress * 0.68);
    canvas.drawLine(
      Offset(0, scanY),
      Offset(size.width, scanY),
      Paint()..color = _a(branding.accent, 0.18)..strokeWidth = 1,
    );
    final glitchY = (progress * 37) % size.height;
    canvas.drawRect(
      Rect.fromLTWH(0, glitchY, size.width, 2.5),
      Paint()..color = _a(branding.accent, 0.1 + pulse * 0.06),
    );
    const dust = [
      Offset(0.08, 0.12),
      Offset(0.92, 0.1),
      Offset(0.1, 0.88),
      Offset(0.9, 0.85),
      Offset(0.5, 0.08),
      Offset(0.18, 0.55),
      Offset(0.82, 0.48),
      Offset(0.28, 0.22),
    ];
    for (var i = 0; i < dust.length; i++) {
      final tw = 0.45 + 0.55 * (0.5 + 0.5 * math.sin(progress * 5 + i));
      canvas.drawCircle(
        _n(size, dust[i].dx, dust[i].dy),
        1.4 + (i % 2) * 0.5,
        Paint()..color = _a(Colors.white, 0.06 + tw * 0.12),
      );
    }
    final center = Offset(size.width * 0.5, size.height * 0.38);
    for (var ring = 1; ring <= 2; ring++) {
      canvas.drawCircle(
        center,
        36.0 * ring + pulse * 10,
        Paint()
          ..color = _a(branding.pulseColor, (0.2 - ring * 0.05) * pulse)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1,
      );
    }
    _cornerTicks(canvas, size, _a(branding.accent, 0.26), 16);
  }

  void _pop(Canvas canvas, Size size) {
    final beat = _beat;
    final spots = [
      (0.12, 0.16, branding.accent),
      (0.88, 0.2, branding.secondaryAccent),
      (0.1, 0.8, branding.particleColor),
      (0.9, 0.74, branding.pulseColor),
      (0.5, 0.1, branding.coreGlow),
      (0.72, 0.55, branding.accent),
      (0.22, 0.42, branding.secondaryAccent),
    ];
    for (final (x, y, c) in spots) {
      final drift = math.sin(progress * math.pi * 2 + x * 8) * 6;
      canvas.drawCircle(
        _n(size, x, y) + Offset(0, drift),
        32 + beat * 4,
        Paint()..color = _a(c, 0.16),
      );
      canvas.drawCircle(
        _n(size, x, y) + Offset(0, drift),
        14,
        Paint()..color = _a(Colors.white, 0.12),
      );
    }
  }

  void _tactical(Canvas canvas, Size size) {
    final line = Paint()
      ..color = _a(branding.scanLineColor, 0.2)
      ..strokeWidth = 0.55;
    const step = 36.0;
    for (var x = 0.0; x < size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), line);
    }
    for (var y = 0.0; y < size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), line);
    }
    final y = size.height * (0.16 + progress * 0.62);
    canvas.drawLine(
      Offset(0, y),
      Offset(size.width, y),
      Paint()..color = _a(branding.accent, 0.28)..strokeWidth = 0.85,
    );
    _cornerTicks(canvas, size, _a(branding.pulseColor, 0.28), 14);
  }

  void _magical(Canvas canvas, Size size) {
    final cx = size.width * 0.5;
    final cy = size.height * 0.36;
    canvas.save();
    canvas.translate(cx, cy);
    canvas.rotate(progress * math.pi * 0.25);
    canvas.drawCircle(
      Offset.zero,
      70,
      Paint()
        ..color = _a(branding.accent, 0.22)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1,
    );
    for (var i = 0; i < 8; i++) {
      final a = i * math.pi / 4;
      canvas.drawLine(
        Offset(math.cos(a) * 62, math.sin(a) * 62),
        Offset(math.cos(a) * 54, math.sin(a) * 54),
        Paint()
          ..color = _a(branding.pulseColor, 0.24)
          ..strokeWidth = 0.9,
      );
    }
    canvas.restore();
    for (final (x, y) in [(0.1, 0.18), (0.9, 0.16), (0.14, 0.82), (0.86, 0.78)]) {
      canvas.drawArc(
        Rect.fromCircle(center: _n(size, x, y), radius: 24),
        progress * math.pi,
        math.pi * 0.55,
        false,
        Paint()
          ..color = _a(branding.accent, 0.2)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 0.9,
      );
    }
    for (var i = 0; i < 10; i++) {
      final tw = 0.4 + 0.6 * (0.5 + 0.5 * math.sin(progress * 4 + i));
      final anchors = [0.08, 0.22, 0.78, 0.92, 0.5, 0.16, 0.84, 0.62, 0.35, 0.7];
      canvas.drawCircle(
        Offset(size.width * anchors[i], size.height * (0.18 + (i % 5) * 0.15)),
        2.2,
        Paint()..color = _a(branding.particleColor, 0.22 * tw),
      );
    }
  }

  void _astronomy(Canvas canvas, Size size) {
    final rng = math.Random(42);
    for (var i = 0; i < 48; i++) {
      final x = rng.nextDouble() * size.width;
      final y = rng.nextDouble() * size.height;
      final tw = 0.3 +
          0.7 * (0.5 + 0.5 * math.sin(progress * 3.5 + i * 0.45));
      canvas.drawCircle(
        Offset(x, y),
        0.6 + (i % 3) * 0.35,
        Paint()..color = _a(branding.particleColor, 0.32 * tw),
      );
    }
    for (var i = 0; i < 10; i++) {
      final origin = _n(
        size,
        i.isEven ? 0.07 + (i % 4) * 0.02 : 0.93 - (i % 4) * 0.02,
        0.12 + (i % 3) * 0.22,
      );
      final ang = math.atan2(
        size.height * 0.42 - origin.dy,
        size.width * 0.5 - origin.dx,
      );
      final len = 42.0 + (i % 3) * 16;
      final end = origin + Offset(math.cos(ang) * len, math.sin(ang) * len * 0.5);
      canvas.drawLine(
        origin,
        end,
        Paint()
          ..color = _a(branding.accent, 0.18)
          ..strokeWidth = 0.8
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
      ..strokeWidth = 1
      ..strokeCap = StrokeCap.round;
    const len = 14.0;
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
        (old.progress - progress).abs() > 0.004 ||
        (old.strength - strength).abs() > 0.01;
  }
}
