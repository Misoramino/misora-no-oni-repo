import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../theme/world_launch_branding.dart';

/// WorldProfile 別の起動オーバーレイ（CustomPainter、軽量だが世界観ごとに凝った描写）。
class LaunchEffectOverlay extends StatelessWidget {
  const LaunchEffectOverlay({
    required this.branding,
    required this.progress,
    super.key,
  });

  final WorldLaunchBranding branding;
  final double progress;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: CustomPaint(
        painter: _LaunchEffectPainter(
          branding: branding,
          progress: progress,
        ),
        size: Size.infinite,
      ),
    );
  }
}

class _LaunchEffectPainter extends CustomPainter {
  _LaunchEffectPainter({
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
        _paintCyber(canvas, size);
      case LaunchEffectKind.horror:
        _paintHorror(canvas, size);
      case LaunchEffectKind.pop:
        _paintPop(canvas, size);
      case LaunchEffectKind.tactical:
        _paintTactical(canvas, size);
      case LaunchEffectKind.magical:
        _paintMagical(canvas, size);
      case LaunchEffectKind.astronomy:
        _paintAstronomy(canvas, size);
    }
  }

  // ── Cyber Night: マップ同系のネオン都市（シアン×深紺、控えめ）────────
  void _paintCyber(Canvas canvas, Size size) {
    final cx = size.width * 0.5;
    final horizon = size.height * 0.38;
    final beat = _beat;

    _ambientWash(
      canvas,
      size,
      [
        branding.secondaryAccent.withValues(alpha: 0.07),
        branding.accent.withValues(alpha: 0.05),
        Colors.transparent,
      ],
      const [0.0, 0.4, 1.0],
    );

    canvas.drawRect(
      Rect.fromLTWH(0, horizon - 1, size.width, 2),
      Paint()
        ..shader = LinearGradient(
          colors: [
            Colors.transparent,
            branding.accent.withValues(alpha: 0.28 + beat * 0.12),
            branding.secondaryAccent.withValues(alpha: 0.18),
            Colors.transparent,
          ],
        ).createShader(Rect.fromLTWH(0, horizon - 6, size.width, 12)),
    );

    final road = Paint()
      ..color = branding.accent.withValues(alpha: 0.1 + beat * 0.05)
      ..strokeWidth = 0.9;
    for (var i = -4; i <= 4; i++) {
      final spread = i * 0.1;
      canvas.drawLine(
        Offset(cx + spread * size.width * 0.14, size.height),
        Offset(cx + spread * size.width * 0.02, horizon),
        road,
      );
    }

    final grid = Paint()
      ..color = branding.scanLineColor.withValues(alpha: 0.14)
      ..strokeWidth = 0.5;
    const step = 28.0;
    for (var x = 0.0; x < size.width; x += step) {
      canvas.drawLine(Offset(x, horizon), Offset(x, size.height), grid);
    }
    for (var y = horizon; y < size.height; y += step * 0.7) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), grid);
    }

    for (var col = 0; col < 9; col++) {
      final phase = (progress * 1.6 + col * 0.15) % 1.0;
      final x = size.width * (0.08 + col * 0.1);
      final trailLen = size.height * 0.07;
      final headY = size.height * phase;
      canvas.drawLine(
        Offset(x, (headY - trailLen).clamp(0.0, size.height)),
        Offset(x, headY.clamp(0.0, size.height)),
        Paint()
          ..color = branding.particleColor.withValues(alpha: 0.12 + phase * 0.18)
          ..strokeWidth = 0.9
          ..strokeCap = StrokeCap.round,
      );
    }

    _cornerBrackets(canvas, size, branding.accent.withValues(alpha: 0.14), 18);
    _dualScan(canvas, size, branding.accent, branding.secondaryAccent, progress);
  }

  // ── Urban Horror: VHS・ビネット・控えめな心拍（マップ同系）──────────────
  void _paintHorror(Canvas canvas, Size size) {
    final center = Offset(size.width * 0.5, size.height * 0.42);
    final beat = 0.5 + 0.5 * math.sin(progress * math.pi * 2.5);

    _ambientWash(
      canvas,
      size,
      [
        branding.accent.withValues(alpha: 0.06),
        branding.secondaryAccent.withValues(alpha: 0.08),
        Colors.transparent,
      ],
      const [0.0, 0.45, 1.0],
    );

    _vignette(canvas, size, branding.secondaryAccent.withValues(alpha: 0.4));

    final glitchY = (progress * 31) % size.height;
    canvas.drawRect(
      Rect.fromLTWH(0, glitchY, size.width, 3),
      Paint()..color = branding.accent.withValues(alpha: 0.08 + beat * 0.05),
    );

    final vhs = Paint()..color = Colors.black.withValues(alpha: 0.08);
    for (var y = 0.0; y < size.height; y += 5) {
      if ((y.toInt() + (progress * 40).toInt()) % 9 == 0) {
        canvas.drawLine(Offset(0, y), Offset(size.width, y), vhs);
      }
    }

    const horrorDust = <Offset>[
      Offset(0.1, 0.14),
      Offset(0.9, 0.18),
      Offset(0.14, 0.82),
      Offset(0.86, 0.76),
      Offset(0.5, 0.1),
      Offset(0.72, 0.62),
    ];
    for (var i = 0; i < horrorDust.length; i++) {
      final tw = 0.5 + 0.5 * math.sin(progress * 6 + i * 1.7);
      final p = horrorDust[i];
      canvas.drawCircle(
        Offset(p.dx * size.width, p.dy * size.height),
        0.7 + (i % 2) * 0.4,
        Paint()..color = Colors.white.withValues(alpha: 0.04 + tw * 0.08),
      );
    }

    for (var ring = 1; ring <= 2; ring++) {
      final r = 22.0 * ring + beat * 8;
      canvas.drawCircle(
        center,
        r,
        Paint()
          ..color = branding.pulseColor.withValues(
            alpha: (0.22 - ring * 0.06) * beat,
          )
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1,
      );
    }
  }

  // ── Pop City: マカロン・お菓子・やさしいパステル ─────────────────────────
  void _paintPop(Canvas canvas, Size size) {
    final beat = _beat;
    final candy = [
      branding.accent,
      branding.secondaryAccent,
      branding.particleColor,
      branding.pulseColor,
      branding.coreGlow,
    ];

    _ambientWash(
      canvas,
      size,
      [
        branding.accent.withValues(alpha: 0.06),
        branding.secondaryAccent.withValues(alpha: 0.05),
        Colors.transparent,
      ],
      const [0.0, 0.5, 1.0],
    );

    final orbs = [
      (Offset(size.width * 0.14, size.height * 0.22), 48.0, branding.accent),
      (Offset(size.width * 0.86, size.height * 0.26), 42.0, branding.secondaryAccent),
      (Offset(size.width * 0.68, size.height * 0.72), 38.0, branding.particleColor),
    ];
    for (final (o, r, c) in orbs) {
      canvas.drawCircle(
        o,
        r + beat * 4,
        Paint()..color = c.withValues(alpha: 0.1 + beat * 0.04),
      );
      canvas.drawCircle(
        o,
        r * 0.55,
        Paint()..color = Colors.white.withValues(alpha: 0.25),
      );
    }

    // ふわふわスプリンクル（小さな丸）
    for (var i = 0; i < 20; i++) {
      final phase = (progress * 1.6 + i * 0.11) % 1.0;
      final x = size.width * ((i * 0.19) % 0.88 + 0.06);
      final y = size.height * (1 - phase) * 0.92;
      final c = candy[i % candy.length];
      canvas.drawCircle(
        Offset(x, y),
        2.5 + (i % 3),
        Paint()..color = c.withValues(alpha: 0.22 + (1 - phase) * 0.28),
      );
    }

    final pins = [
      Offset(size.width * 0.2, size.height * 0.36),
      Offset(size.width * 0.8, size.height * 0.32),
      Offset(size.width * 0.55, size.height * 0.56),
      Offset(size.width * 0.3, size.height * 0.66),
      Offset(size.width * 0.7, size.height * 0.7),
    ];
    for (var i = 0; i < pins.length; i++) {
      final phase = (progress * 1.6 + i * 0.19) % 1.0;
      final bounce = Curves.elasticOut.transform((1 - phase).clamp(0.0, 1.0));
      final pos = pins[i] + Offset(0, -14 * bounce);
      final scale = 0.5 + 0.5 * bounce;
      final c = candy[i % candy.length];
      canvas.drawCircle(
        pos,
        5 + scale * 6,
        Paint()..color = c.withValues(alpha: 0.2 * scale),
      );
      canvas.drawCircle(
        pos,
        3.5 + scale * 2,
        Paint()..color = Colors.white.withValues(alpha: 0.55 * scale),
      );
      canvas.drawCircle(
        pos + Offset(0, 4 * scale),
        1.2,
        Paint()..color = c.withValues(alpha: 0.35 * scale),
      );
    }
  }

  // ── Stealth Tactical: モノトーン・フラットグリッド ─────────────────────
  void _paintTactical(Canvas canvas, Size size) {
    final cx = size.width * 0.5;
    final cy = size.height * 0.42;
    final beat = _beat;

    _ambientWash(
      canvas,
      size,
      [
        Colors.white.withValues(alpha: 0.04),
        Colors.transparent,
      ],
      const [0.0, 1.0],
    );

    _cornerBrackets(canvas, size, branding.accent, 26);
    _monoGrid(canvas, size, branding.scanLineColor);

    final cross = Paint()
      ..color = branding.pulseColor.withValues(alpha: 0.22 + beat * 0.1)
      ..strokeWidth = 0.7;
    canvas.drawLine(Offset(cx - 28, cy), Offset(cx + 28, cy), cross);
    canvas.drawLine(Offset(cx, cy - 28), Offset(cx, cy + 28), cross);
    _strokeCircle(
      canvas,
      Offset(cx, cy),
      18,
      branding.accent.withValues(alpha: 0.18),
      0.6,
    );

    for (var i = 0; i < 3; i++) {
      final blipPhase = (progress * 2.5 + i * 0.35) % 1.0;
      if (blipPhase > 0.8) continue;
      final x = cx + (i - 1) * 42;
      final y = cy - 24 + blipPhase * 48;
      canvas.drawCircle(
        Offset(x, y),
        2,
        Paint()
          ..color = Colors.white.withValues(alpha: 0.5 - blipPhase * 0.35),
      );
    }

    final y = size.height * (0.15 + progress * 0.6);
    final scan = Paint()
      ..color = branding.scanLineColor.withValues(alpha: 0.55)
      ..strokeWidth = 0.8;
    canvas.drawLine(Offset(0, y), Offset(size.width, y), scan);

    if (branding.showReadyLabel) {
      final blink = 0.4 + 0.6 * (0.5 + 0.5 * math.sin(progress * math.pi * 6));
      final tp = TextPainter(
        text: TextSpan(
          text: 'READY',
          style: TextStyle(
            color: branding.subtitleColor.withValues(alpha: 0.25 + blink * 0.5),
            fontSize: 11,
            letterSpacing: 5,
            fontWeight: FontWeight.w600,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset((size.width - tp.width) / 2, size.height * 0.74));
    }
  }

  // ── Magical World: 古文書・魔法陣・ルーン・花火 ─────────────────────────
  void _paintMagical(Canvas canvas, Size size) {
    final cx = size.width * 0.5;
    final cy = size.height * 0.42;
    final warm = _beat;

    _ambientWash(
      canvas,
      size,
      [
        branding.secondaryAccent.withValues(alpha: 0.22),
        branding.glow.withValues(alpha: 0.1),
        Colors.transparent,
      ],
      const [0.0, 0.4, 1.0],
    );

    _vignette(canvas, size, branding.secondaryAccent.withValues(alpha: 0.45));

    for (var w = 0; w < 2; w++) {
      final phase = (progress * 1.2 + w * 0.4) % 1.0;
      canvas.drawCircle(
        Offset(cx, cy),
        24 + phase * size.width * 0.38,
        Paint()
          ..color = branding.accent.withValues(alpha: (1 - phase) * 0.14)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.2,
      );
    }

    final circleRot = progress * math.pi * 0.35;
    canvas.save();
    canvas.translate(cx, cy);
    canvas.rotate(circleRot);
    for (var ring = 0; ring < 3; ring++) {
      final r = 52.0 + ring * 22;
      _strokeCircle(
        canvas,
        Offset.zero,
        r,
        branding.accent.withValues(alpha: 0.32 - ring * 0.06),
        1.2,
      );
      _magicRunes(canvas, r, branding.pulseColor, 24);
    }
    _strokePolygon(
      canvas,
      _star(Offset.zero, 58, 5),
      branding.accent.withValues(alpha: 0.38),
      1.4,
    );
    _strokePolygon(
      canvas,
      _star(Offset.zero, 36, 5),
      branding.coreGlow.withValues(alpha: 0.22),
      0.9,
    );
    canvas.restore();

    _fireworkBursts(canvas, size, cx, cy);

    for (var i = 0; i < 28; i++) {
      final seed = i * 11.3;
      final x = size.width * (0.15 + (i * 0.07) % 0.7);
      final drift = (progress * 1.1 + seed * 0.008) % 1.0;
      final y = size.height * (0.55 + (i % 6) * 0.06) - drift * size.height * 0.35;
      final tw = 0.35 + 0.65 * (0.5 + 0.5 * math.sin(progress * 7 + seed));
      canvas.drawCircle(
        Offset(x, y),
        1.2 + (i % 3) * 0.6,
        Paint()..color = branding.particleColor.withValues(alpha: 0.15 + tw * 0.45),
      );
    }

    canvas.drawCircle(
      Offset(cx, cy),
      28 + warm * 8,
      Paint()..color = branding.glow.withValues(alpha: 0.28 + warm * 0.2),
    );
    canvas.drawCircle(
      Offset(cx, cy),
      7 + warm * 2,
      Paint()..color = branding.coreColor.withValues(alpha: 0.8 + warm * 0.2),
    );
  }

  // ── Astronomy: 静かな宇宙・星・ハイパースペース ─────────────────────────
  void _paintAstronomy(Canvas canvas, Size size) {
    final cx = size.width * 0.5;
    final cy = size.height * 0.42;

    _ambientWash(
      canvas,
      size,
      [
        branding.secondaryAccent.withValues(alpha: 0.08),
        Colors.transparent,
      ],
      const [0.0, 1.0],
    );

    _hyperspaceStreaks(canvas, size, cx, cy);

    final nebulae = [
      (Offset(size.width * 0.2, size.height * 0.3), 90.0, branding.secondaryAccent),
      (Offset(size.width * 0.78, size.height * 0.55), 110.0, branding.accent),
    ];
    for (final (o, r, c) in nebulae) {
      canvas.drawCircle(
        o,
        r,
        Paint()
          ..shader = RadialGradient(
            colors: [c.withValues(alpha: 0.1), Colors.transparent],
          ).createShader(Rect.fromCircle(center: o, radius: r)),
      );
    }

    const constellation = [
      Offset(0.16, 0.22),
      Offset(0.26, 0.34),
      Offset(0.4, 0.3),
      Offset(0.58, 0.2),
      Offset(0.74, 0.28),
      Offset(0.82, 0.38),
    ];
    final line = Paint()
      ..color = branding.accent.withValues(alpha: 0.18)
      ..strokeWidth = 0.6;
    for (var i = 0; i < constellation.length - 1; i++) {
      final a = constellation[i];
      final b = constellation[i + 1];
      canvas.drawLine(
        Offset(a.dx * size.width, a.dy * size.height),
        Offset(b.dx * size.width, b.dy * size.height),
        line,
      );
    }
    for (final p in constellation) {
      canvas.drawCircle(
        Offset(p.dx * size.width, p.dy * size.height),
        1.8,
        Paint()..color = branding.particleColor.withValues(alpha: 0.5),
      );
    }

    const starLayers = [
      (55, 0.02, 0.35),
      (60, 0.035, 0.5),
      (40, 0.05, 0.65),
    ];
    final rng = math.Random(99);
    for (var layer = 0; layer < starLayers.length; layer++) {
      final (count, parallax, baseAlpha) = starLayers[layer];
      for (var i = 0; i < count; i++) {
        final x = rng.nextDouble() * size.width;
        final y = (rng.nextDouble() * size.height +
                parallax * size.height * progress) %
            size.height;
        final tw = 0.25 +
            0.75 *
                (0.5 + 0.5 * math.sin(progress * (4 + layer) + i * 0.5));
        final r = 0.5 + layer * 0.45 + (i % 3) * 0.3;
        final color = i % 11 == 0
            ? branding.pulseColor.withValues(alpha: tw * 0.55)
            : branding.particleColor.withValues(alpha: tw * baseAlpha);
        canvas.drawCircle(Offset(x, y), r, Paint()..color = color);
      }
    }

    _drawMeteor(canvas, size, progress * 1.2, 0.7, 0.1);
    _drawMeteor(canvas, size, progress * 1.2 + 0.48, 0.55, 0.5);

    canvas.drawCircle(
      Offset(cx, cy),
      4,
      Paint()..color = branding.coreColor.withValues(alpha: 0.85),
    );
  }

  void _drawMeteor(
    Canvas canvas,
    Size size,
    double phase,
    double startX,
    double startY,
  ) {
    final meteorPhase = phase % 1.0;
    if (meteorPhase >= 0.38) return;
    final t = meteorPhase / 0.38;
    final start = Offset(size.width * (startX - t * 0.45), size.height * (startY + t * 0.08));
    final end = start + Offset(-90 * t, 55 * t);
    canvas.drawLine(
      start,
      end,
      Paint()
        ..shader = LinearGradient(
          colors: [
            Colors.transparent,
            branding.accent.withValues(alpha: 0.75),
            Colors.white.withValues(alpha: 0.95),
          ],
        ).createShader(Rect.fromPoints(start, end))
        ..strokeWidth = 2.2
        ..strokeCap = StrokeCap.round,
    );
  }

  void _ambientWash(
    Canvas canvas,
    Size size,
    List<Color> colors,
    List<double> stops,
  ) {
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Paint()
        ..shader = RadialGradient(
          center: const Alignment(0, -0.15),
          radius: 1.15,
          colors: colors,
          stops: stops,
        ).createShader(Rect.fromLTWH(0, 0, size.width, size.height)),
    );
  }

  Path _hexagon(Offset c, double r) {
    final p = Path();
    for (var i = 0; i < 6; i++) {
      final a = -math.pi / 2 + i * math.pi / 3;
      final pt = Offset(c.dx + math.cos(a) * r, c.dy + math.sin(a) * r);
      if (i == 0) {
        p.moveTo(pt.dx, pt.dy);
      } else {
        p.lineTo(pt.dx, pt.dy);
      }
    }
    p.close();
    return p;
  }

  Path _star(Offset c, double r, int points) {
    final p = Path();
    for (var i = 0; i < points * 2; i++) {
      final rad = i.isEven ? r : r * 0.42;
      final a = -math.pi / 2 + i * math.pi / points;
      final pt = Offset(c.dx + math.cos(a) * rad, c.dy + math.sin(a) * rad);
      if (i == 0) {
        p.moveTo(pt.dx, pt.dy);
      } else {
        p.lineTo(pt.dx, pt.dy);
      }
    }
    p.close();
    return p;
  }

  void _strokePolygon(Canvas canvas, Path path, Color color, double width) {
    canvas.drawPath(
      path,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = width
        ..strokeJoin = StrokeJoin.round,
    );
  }

  void _cornerBrackets(Canvas canvas, Size size, Color color, double len) {
    final p = Paint()
      ..color = color.withValues(alpha: 0.5)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;
    const m = 20.0;
    canvas.drawLine(Offset(m, m), Offset(m + len, m), p);
    canvas.drawLine(Offset(m, m), Offset(m, m + len), p);
    canvas.drawLine(Offset(size.width - m, m), Offset(size.width - m - len, m), p);
    canvas.drawLine(Offset(size.width - m, m), Offset(size.width - m, m + len), p);
    canvas.drawLine(Offset(m, size.height - m), Offset(m + len, size.height - m), p);
    canvas.drawLine(Offset(m, size.height - m), Offset(m, size.height - m - len), p);
    canvas.drawLine(
      Offset(size.width - m, size.height - m),
      Offset(size.width - m - len, size.height - m),
      p,
    );
    canvas.drawLine(
      Offset(size.width - m, size.height - m),
      Offset(size.width - m, size.height - m - len),
      p,
    );
  }

  void _dualScan(
    Canvas canvas,
    Size size,
    Color accent,
    Color secondary,
    double progress,
  ) {
    final y1 = size.height * progress;
    final y2 = size.height * (1 - progress);
    for (final y in [y1, y2]) {
      canvas.drawRect(
        Rect.fromLTWH(0, y - 44, size.width, 88),
        Paint()
          ..shader = LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.transparent,
              accent.withValues(alpha: 0.38),
              secondary.withValues(alpha: 0.22),
              Colors.transparent,
            ],
          ).createShader(Rect.fromLTWH(0, y - 44, size.width, 88)),
      );
    }
  }

  void _vignette(Canvas canvas, Size size, Color edge) {
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Paint()
        ..shader = RadialGradient(
          colors: [Colors.transparent, edge],
          stops: const [0.45, 1.0],
        ).createShader(Rect.fromLTWH(0, 0, size.width, size.height)),
    );
  }

  void _dotGrid(Canvas canvas, Size size, Color color, double step) {
    final dot = Paint()..color = color.withValues(alpha: 0.35);
    for (var x = step; x < size.width; x += step) {
      for (var y = step; y < size.height; y += step) {
        canvas.drawCircle(Offset(x, y), 0.8, dot);
      }
    }
  }

  void _monoGrid(Canvas canvas, Size size, Color color) {
    final line = Paint()
      ..color = color.withValues(alpha: 0.28)
      ..strokeWidth = 0.55;
    const step = 32.0;
    for (var x = 0.0; x < size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), line);
    }
    for (var y = 0.0; y < size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), line);
    }
    _dotGrid(canvas, size, color, step);
  }

  void _strokeCircle(
    Canvas canvas,
    Offset center,
    double radius,
    Color color,
    double width,
  ) {
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = width,
    );
  }

  void _magicRunes(Canvas canvas, double radius, Color color, int count) {
    final rune = Paint()
      ..color = color.withValues(alpha: 0.35)
      ..strokeWidth = 0.9
      ..strokeCap = StrokeCap.round;
    for (var i = 0; i < count; i++) {
      final a = i * math.pi * 2 / count;
      final outer = Offset(math.cos(a) * radius, math.sin(a) * radius);
      final inner = Offset(math.cos(a) * (radius - 6), math.sin(a) * (radius - 6));
      canvas.drawLine(outer, inner, rune);
      final tick = Offset(
        math.cos(a + 0.12) * (radius - 3),
        math.sin(a + 0.12) * (radius - 3),
      );
      canvas.drawLine(
        inner,
        tick,
        Paint()
          ..color = color.withValues(alpha: 0.28)
          ..strokeWidth = 0.6
          ..strokeCap = StrokeCap.round,
      );
    }
  }

  void _fireworkBursts(Canvas canvas, Size size, double _, double __) {
    final bursts = [
      (0.12, 0.28, 0.22),
      (0.55, 0.18, 0.62),
      (0.82, 0.42, 0.38),
    ];
    for (var b = 0; b < bursts.length; b++) {
      final phase = (progress * 1.8 + b * 0.33) % 1.0;
      if (phase > 0.35) continue;
      final t = phase / 0.35;
      final origin = Offset(size.width * bursts[b].$1, size.height * bursts[b].$2);
      final rays = 10 + b * 2;
      for (var r = 0; r < rays; r++) {
        final ang = r * math.pi * 2 / rays + b;
        final len = 8 + t * 42;
        final end = origin + Offset(math.cos(ang) * len, math.sin(ang) * len);
        canvas.drawLine(
          origin,
          end,
          Paint()
            ..color = (r.isEven ? branding.particleColor : branding.accent)
                .withValues(alpha: (1 - t) * 0.55)
            ..strokeWidth = 1.1
            ..strokeCap = StrokeCap.round,
        );
      }
    }
  }

  void _hyperspaceStreaks(Canvas canvas, Size size, double cx, double cy) {
    final warp = (progress * 2.2) % 1.0;
    for (var i = 0; i < 36; i++) {
      final ang = i * 0.42 + warp * 0.3;
      final len = size.width * (0.15 + (i % 5) * 0.06) * (0.4 + warp * 0.6);
      final start = Offset(
        cx + math.cos(ang) * 12,
        cy + math.sin(ang) * 8,
      );
      final end = Offset(
        cx + math.cos(ang) * len,
        cy + math.sin(ang) * len * 0.55,
      );
      canvas.drawLine(
        start,
        end,
        Paint()
          ..shader = LinearGradient(
            colors: [
              Colors.transparent,
              branding.accent.withValues(alpha: 0.12 + warp * 0.2),
              Colors.white.withValues(alpha: 0.35 + warp * 0.25),
            ],
          ).createShader(Rect.fromPoints(start, end))
          ..strokeWidth = 0.8 + (i % 3) * 0.3
          ..strokeCap = StrokeCap.round,
      );
    }
    canvas.drawCircle(
      Offset(cx, cy),
      18 + warp * 24,
      Paint()
        ..color = branding.coreGlow.withValues(alpha: 0.06 + warp * 0.1),
    );
  }

  @override
  bool shouldRepaint(covariant _LaunchEffectPainter oldDelegate) {
    return oldDelegate.branding.effect != branding.effect ||
        (oldDelegate.progress - progress).abs() > 0.003;
  }
}
