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

  // ── Cyber Night: ネオン都市・データの雨・走査 ───────────────────────────
  void _paintCyber(Canvas canvas, Size size) {
    final cx = size.width * 0.5;
    final cy = size.height * 0.42;
    final horizon = size.height * 0.36;
    final beat = _beat;

    _ambientWash(
      canvas,
      size,
      [
        branding.secondaryAccent.withValues(alpha: 0.18),
        Colors.transparent,
      ],
      const [0.0, 1.0],
    );

    // 地平ネオン
    canvas.drawRect(
      Rect.fromLTWH(0, horizon - 2, size.width, 4),
      Paint()
        ..shader = LinearGradient(
          colors: [
            Colors.transparent,
            branding.accent.withValues(alpha: 0.55 + beat * 0.25),
            branding.secondaryAccent.withValues(alpha: 0.45),
            Colors.transparent,
          ],
        ).createShader(Rect.fromLTWH(0, horizon - 8, size.width, 16)),
    );

    final road = Paint()
      ..color = branding.accent.withValues(alpha: 0.35 + beat * 0.2)
      ..strokeWidth = 1.1;
    for (var i = -5; i <= 5; i++) {
      final spread = i * 0.11;
      canvas.drawLine(
        Offset(cx + spread * size.width * 0.16, size.height),
        Offset(cx + spread * size.width * 0.02, horizon),
        road,
      );
    }

    final grid = Paint()
      ..color = branding.scanLineColor.withValues(alpha: 0.82)
      ..strokeWidth = 0.7;
    const step = 22.0;
    for (var x = 0.0; x < size.width; x += step) {
      canvas.drawLine(Offset(x, horizon), Offset(x, size.height), grid);
    }
    for (var y = horizon; y < size.height; y += step * 0.65) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), grid);
    }

    // データの雨（上昇する光条）
    for (var i = 0; i < 14; i++) {
      final phase = (progress * 1.6 + i * 0.11) % 1.0;
      final x = size.width * (0.08 + (i * 0.067) % 0.84);
      final h = size.height * (0.12 + (i % 5) * 0.04);
      final y = size.height * (1 - phase) - h;
      canvas.drawLine(
        Offset(x, y + h),
        Offset(x, y),
        Paint()
          ..color = (i.isEven ? branding.accent : branding.particleColor)
              .withValues(alpha: 0.25 + phase * 0.45)
          ..strokeWidth = 1.2
          ..strokeCap = StrokeCap.round,
      );
    }

    _cornerBrackets(canvas, size, branding.accent, 22);
    _dualScan(canvas, size, branding.accent, branding.secondaryAccent, progress);

    // 中心ヘックス（回転）
    final hexR = 38 + beat * 8;
    canvas.save();
    canvas.translate(cx, cy);
    canvas.rotate(progress * math.pi * 0.5);
    _strokePolygon(
      canvas,
      _hexagon(Offset.zero, hexR),
      branding.secondaryAccent.withValues(alpha: 0.22 + beat * 0.18),
      1.2,
    );
    canvas.restore();

    for (var i = 0; i < 7; i++) {
      final t = progress * math.pi * 2 + i * 0.9;
      final alpha = (0.4 + 0.6 * (0.5 + 0.5 * math.sin(t))).clamp(0.0, 1.0);
      canvas.drawCircle(
        Offset(
          cx + math.cos(t) * size.width * 0.32,
          cy + math.sin(t) * size.height * 0.18,
        ),
        2.8,
        Paint()..color = branding.particleColor.withValues(alpha: alpha),
      );
    }
  }

  // ── Urban Horror: VHS・赤い閃光・心拍 ───────────────────────────────────
  void _paintHorror(Canvas canvas, Size size) {
    final center = Offset(size.width * 0.5, size.height * 0.42);
    final beat = 0.5 + 0.5 * math.sin(progress * math.pi * 3.5);

    _ambientWash(
      canvas,
      size,
      [
        branding.secondaryAccent.withValues(alpha: 0.2),
        Colors.transparent,
      ],
      const [0.0, 1.0],
    );

    if (math.sin(progress * math.pi * 7) > 0.92) {
      canvas.drawRect(
        Rect.fromLTWH(0, 0, size.width, size.height),
        Paint()..color = branding.accent.withValues(alpha: 0.06),
      );
    }

    _vignette(canvas, size, branding.secondaryAccent.withValues(alpha: 0.62));

    final glitchY = (progress * 47) % size.height;
    canvas.drawRect(
      Rect.fromLTWH(0, glitchY, size.width, 6),
      Paint()..color = branding.accent.withValues(alpha: 0.12 + beat * 0.1),
    );

    final vhs = Paint()..color = Colors.black.withValues(alpha: 0.14);
    for (var y = 0.0; y < size.height; y += 3) {
      if ((y.toInt() + (progress * 50).toInt()) % 7 == 0) {
        canvas.drawLine(Offset(0, y), Offset(size.width, y), vhs);
      }
    }

    const horrorDust = <Offset>[
      Offset(0.12, 0.18),
      Offset(0.88, 0.22),
      Offset(0.35, 0.55),
      Offset(0.72, 0.48),
      Offset(0.5, 0.12),
      Offset(0.2, 0.78),
      Offset(0.8, 0.7),
    ];
    for (var i = 0; i < horrorDust.length; i++) {
      final flicker = math.sin(progress * 18 + i * 2.1) > 0.55 ? 0.2 : 0.06;
      final p = horrorDust[i];
      canvas.drawCircle(
        Offset(p.dx * size.width, p.dy * size.height),
        0.8 + (i % 3) * 0.5,
        Paint()..color = Colors.white.withValues(alpha: flicker),
      );
    }

    for (var ring = 1; ring <= 4; ring++) {
      final r = 14.0 * ring + beat * 14;
      canvas.drawCircle(
        center,
        r,
        Paint()
          ..color = branding.pulseColor.withValues(
            alpha: (0.42 - ring * 0.07) * beat,
          )
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.4,
      );
    }
    canvas.drawCircle(
      center,
      4 + beat * 3,
      Paint()..color = branding.particleColor.withValues(alpha: 0.85 + beat * 0.15),
    );
  }

  // ── Pop City: パステル・バウンス・紙吹雪 ─────────────────────────────────
  void _paintPop(Canvas canvas, Size size) {
    final beat = _beat;

    _ambientWash(
      canvas,
      size,
      [
        branding.accent.withValues(alpha: 0.1),
        branding.secondaryAccent.withValues(alpha: 0.06),
        Colors.transparent,
      ],
      const [0.0, 0.45, 1.0],
    );

    final orbs = [
      (Offset(size.width * 0.15, size.height * 0.2), 52.0, branding.accent),
      (Offset(size.width * 0.85, size.height * 0.25), 44.0, branding.secondaryAccent),
      (Offset(size.width * 0.7, size.height * 0.75), 40.0, branding.particleColor),
    ];
    for (final (o, r, c) in orbs) {
      canvas.drawCircle(
        o,
        r + beat * 6,
        Paint()..color = c.withValues(alpha: 0.16 + beat * 0.08),
      );
    }

    const confettiColors = [
      Color(0xFFFF8FB3),
      Color(0xFF80DEEA),
      Color(0xFFFFD54F),
      Color(0xFFCE93D8),
    ];
    for (var i = 0; i < 16; i++) {
      final phase = (progress * 2.2 + i * 0.13) % 1.0;
      final x = size.width * ((i * 0.17) % 0.9 + 0.05);
      final y = size.height * (1 - phase) * 0.95;
      final rot = phase * math.pi * 4 + i;
      canvas.save();
      canvas.translate(x, y);
      canvas.rotate(rot);
      canvas.drawRect(
        Rect.fromCenter(center: Offset.zero, width: 6, height: 3),
        Paint()
          ..color = confettiColors[i % confettiColors.length]
              .withValues(alpha: 0.35 + (1 - phase) * 0.4),
      );
      canvas.restore();
    }

    final pins = [
      Offset(size.width * 0.18, size.height * 0.35),
      Offset(size.width * 0.82, size.height * 0.3),
      Offset(size.width * 0.58, size.height * 0.58),
      Offset(size.width * 0.28, size.height * 0.68),
      Offset(size.width * 0.72, size.height * 0.72),
      Offset(size.width * 0.45, size.height * 0.22),
    ];
    final colors = [
      const Color(0xFFFF8FB3),
      const Color(0xFF80DEEA),
      const Color(0xFFFFD54F),
      const Color(0xFFCE93D8),
      const Color(0xFFFFAB91),
      const Color(0xFF81D4FA),
    ];
    for (var i = 0; i < pins.length; i++) {
      final phase = (progress * 1.8 + i * 0.17) % 1.0;
      final bounce = Curves.elasticOut.transform((1 - phase).clamp(0.0, 1.0));
      final yOff = -18 * bounce;
      final pos = pins[i] + Offset(0, yOff);
      final scale = 0.4 + 0.6 * bounce;
      final c = colors[i % colors.length];
      canvas.drawCircle(
        pos,
        (4 + scale * 8),
        Paint()..color = c.withValues(alpha: 0.28 * scale),
      );
      canvas.drawCircle(
        pos,
        3,
        Paint()..color = c.withValues(alpha: 0.65 * scale),
      );
      canvas.drawCircle(
        pos + const Offset(0, 5),
        1.5,
        Paint()..color = c.withValues(alpha: 0.4 * scale),
      );
      if (scale > 0.7) {
        canvas.drawCircle(
          pos + Offset(0, -8 * scale),
          2,
          Paint()..color = Colors.white.withValues(alpha: 0.5 * scale),
        );
      }
    }
  }

  // ── Stealth Tactical: レーダー・ブリップ・走査 ─────────────────────────
  void _paintTactical(Canvas canvas, Size size) {
    final cx = size.width * 0.5;
    final cy = size.height * 0.42;
    final beat = _beat;
    final sweep = progress * math.pi * 2;

    _ambientWash(
      canvas,
      size,
      [
        branding.scanLineColor.withValues(alpha: 0.12),
        Colors.transparent,
      ],
      const [0.0, 1.0],
    );

    _cornerBrackets(canvas, size, branding.accent, 28);
    _dotGrid(canvas, size, branding.scanLineColor, 28);

    for (var ring = 1; ring <= 3; ring++) {
      final r = 48.0 + ring * 28;
      canvas.drawCircle(
        Offset(cx, cy),
        r,
        Paint()
          ..color = branding.scanLineColor.withValues(alpha: 0.2 + ring * 0.05)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 0.9,
      );
    }

    canvas.drawArc(
      Rect.fromCircle(center: Offset(cx, cy), radius: 88),
      sweep - 0.65,
      0.75,
      false,
      Paint()
        ..color = branding.accent.withValues(alpha: 0.55 + beat * 0.2)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
    canvas.drawArc(
      Rect.fromCircle(center: Offset(cx, cy), radius: 88),
      sweep + math.pi,
      0.4,
      false,
      Paint()
        ..color = branding.pulseColor.withValues(alpha: 0.25)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1,
    );

    // レーダーブリップ
    for (var i = 0; i < 5; i++) {
      final blipPhase = (progress * 3 + i * 0.31) % 1.0;
      if (blipPhase > 0.85) continue;
      final ang = i * 1.25 + progress * 0.8;
      final dist = 30 + blipPhase * 55;
      canvas.drawCircle(
        Offset(cx + math.cos(ang) * dist, cy + math.sin(ang) * dist * 0.65),
        3,
        Paint()..color = branding.pulseColor.withValues(alpha: 0.7 - blipPhase * 0.5),
      );
    }
    canvas.drawLine(
      Offset(cx - 20, cy),
      Offset(cx + 20, cy),
      Paint()..color = branding.pulseColor.withValues(alpha: 0.35)..strokeWidth = 0.8,
    );
    canvas.drawLine(
      Offset(cx, cy - 20),
      Offset(cx, cy + 20),
      Paint()..color = branding.pulseColor.withValues(alpha: 0.35)..strokeWidth = 0.8,
    );

    final y = size.height * (0.2 + progress * 0.55);
    final scan = Paint()
      ..color = branding.scanLineColor
      ..strokeWidth = 1;
    canvas.drawLine(Offset(0, y), Offset(size.width, y), scan);
    canvas.drawLine(Offset(0, y + 14), Offset(size.width, y + 14), scan);

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

  // ── Magical World: 魔術環・昇る火花・波紋 ───────────────────────────────
  void _paintMagical(Canvas canvas, Size size) {
    final cx = size.width * 0.5;
    final cy = size.height * 0.42;
    final warm = _beat;

    _ambientWash(
      canvas,
      size,
      [
        branding.secondaryAccent.withValues(alpha: 0.18),
        branding.glow.withValues(alpha: 0.08),
        Colors.transparent,
      ],
      const [0.0, 0.35, 1.0],
    );

    final mist = Paint()
      ..shader = RadialGradient(
        colors: [
          branding.secondaryAccent.withValues(alpha: 0.28),
          Colors.transparent,
        ],
      ).createShader(Rect.fromCircle(center: Offset(cx, cy), radius: size.width * 0.6));
    canvas.drawCircle(Offset(cx, cy), size.width * 0.6, mist);

    // 拡がる波紋
    for (var w = 0; w < 3; w++) {
      final phase = (progress * 1.5 + w * 0.33) % 1.0;
      canvas.drawCircle(
        Offset(cx, cy),
        20 + phase * size.width * 0.45,
        Paint()
          ..color = branding.accent.withValues(alpha: (1 - phase) * 0.2)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5,
      );
    }

    for (var ring = 0; ring < 3; ring++) {
      final rot = progress * math.pi * (1.4 + ring * 0.35) + ring * 0.9;
      final r = 48.0 + ring * 24;
      final ringPaint = Paint()
        ..color = (ring.isEven ? branding.accent : branding.secondaryAccent)
            .withValues(alpha: 0.28 + ring * 0.08)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.4;
      canvas.save();
      canvas.translate(cx, cy);
      canvas.rotate(rot);
      canvas.drawArc(
        Rect.fromCircle(center: Offset.zero, radius: r),
        0,
        math.pi * 1.4,
        false,
        ringPaint,
      );
      canvas.drawArc(
        Rect.fromCircle(center: Offset.zero, radius: r),
        math.pi,
        math.pi * 0.9,
        false,
        ringPaint,
      );
      // 六芒星のひずみ
      _strokePolygon(
        canvas,
        _star(Offset.zero, r * 0.72, 6),
        branding.particleColor.withValues(alpha: 0.12),
        0.8,
      );
      canvas.restore();
    }

    const sparkX = [0.22, 0.45, 0.68, 0.35, 0.55, 0.28, 0.72, 0.4];
    for (var i = 0; i < 48; i++) {
      final seed = i * 13.7;
      final x = size.width * (sparkX[i % sparkX.length] + math.sin(seed) * 0.04);
      final baseY = size.height * (0.5 + (i % 8) * 0.05);
      final drift = (progress * 1.4 + seed * 0.01) % 1.0;
      final y = baseY - drift * size.height * 0.42;
      final twinkle = 0.4 + 0.6 * (0.5 + 0.5 * math.sin(progress * 9 + seed));
      final sz = 1.4 + (i % 4) * 0.9;
      canvas.drawCircle(
        Offset(x, y),
        sz * twinkle,
        Paint()..color = branding.particleColor.withValues(alpha: 0.2 + twinkle * 0.55),
      );
    }

    canvas.drawCircle(
      Offset(cx, cy),
      32 + warm * 10,
      Paint()..color = branding.glow.withValues(alpha: 0.32 + warm * 0.25),
    );
    canvas.drawCircle(
      Offset(cx, cy),
      8 + warm * 2,
      Paint()..color = branding.pulseColor.withValues(alpha: 0.65 + warm * 0.35),
    );
  }

  // ── Astronomy: 星雲・星座・軌道・流星群 ───────────────────────────────────
  void _paintAstronomy(Canvas canvas, Size size) {
    final cx = size.width * 0.5;
    final cy = size.height * 0.42;

    _ambientWash(
      canvas,
      size,
      [
        branding.secondaryAccent.withValues(alpha: 0.12),
        const Color(0xFF1A237E).withValues(alpha: 0.15),
        Colors.transparent,
      ],
      const [0.0, 0.4, 1.0],
    );

    final nebulae = [
      (Offset(size.width * 0.22, size.height * 0.28), 100.0, branding.secondaryAccent),
      (Offset(size.width * 0.8, size.height * 0.52), 120.0, const Color(0xFF7E57C2)),
      (Offset(size.width * 0.48, size.height * 0.72), 85.0, branding.accent),
    ];
    for (final (o, r, c) in nebulae) {
      canvas.drawCircle(
        o,
        r,
        Paint()
          ..shader = RadialGradient(
            colors: [c.withValues(alpha: 0.22), Colors.transparent],
          ).createShader(Rect.fromCircle(center: o, radius: r)),
      );
    }

    const constellation = [
      Offset(0.18, 0.2),
      Offset(0.28, 0.32),
      Offset(0.42, 0.28),
      Offset(0.55, 0.18),
      Offset(0.72, 0.25),
    ];
    final line = Paint()
      ..color = branding.accent.withValues(alpha: 0.25)
      ..strokeWidth = 0.8;
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
        2.2,
        Paint()..color = branding.pulseColor.withValues(alpha: 0.55),
      );
    }

    const starLayers = [
      (48, 0.025, 0.45),
      (55, 0.04, 0.55),
      (35, 0.06, 0.7),
    ];
    final rng = math.Random(99);
    for (var layer = 0; layer < starLayers.length; layer++) {
      final (count, parallax, baseAlpha) = starLayers[layer];
      for (var i = 0; i < count; i++) {
        final x = rng.nextDouble() * size.width;
        final y = (rng.nextDouble() * size.height +
                parallax * size.height * progress) %
            size.height;
        final tw = 0.35 +
            0.65 *
                (0.5 + 0.5 * math.sin(progress * (5 + layer * 2) + i * 0.6));
        final r = 0.7 + layer * 0.55 + (i % 3) * 0.35;
        final color = i % 9 == 0
            ? branding.pulseColor.withValues(alpha: tw * 0.85)
            : branding.particleColor.withValues(alpha: tw * baseAlpha);
        canvas.drawCircle(Offset(x, y), r, Paint()..color = color);
      }
    }

    final orbitRot = progress * math.pi * 0.55;
    canvas.save();
    canvas.translate(cx, cy);
    canvas.rotate(orbitRot);
    for (final (w, h, a) in [(200.0, 58.0, 0.28), (240.0, 70.0, 0.14)]) {
      canvas.drawOval(
        Rect.fromCenter(center: Offset.zero, width: w, height: h),
        Paint()
          ..color = branding.accent.withValues(alpha: a)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1,
      );
    }
    canvas.restore();

    _drawMeteor(canvas, size, progress * 1.3, 0.75, 0.12);
    _drawMeteor(canvas, size, progress * 1.3 + 0.55, 0.6, 0.55);

    canvas.drawArc(
      Rect.fromCenter(
        center: Offset(cx, size.height * 0.9),
        width: size.width * 1.5,
        height: 90,
      ),
      math.pi,
      math.pi,
      false,
      Paint()
        ..color = branding.accent.withValues(alpha: 0.18)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2,
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

  @override
  bool shouldRepaint(covariant _LaunchEffectPainter oldDelegate) {
    return oldDelegate.branding.effect != branding.effect ||
        (oldDelegate.progress - progress).abs() > 0.003;
  }
}
