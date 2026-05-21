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

  // ── Cyber Night: 道路パース・グリッド・スキャン ─────────────────────────
  void _paintCyber(Canvas canvas, Size size) {
    final cx = size.width * 0.5;
    final horizon = size.height * 0.38;
    final road = Paint()
      ..color = branding.scanLineColor
      ..strokeWidth = 0.8;
    for (var i = -4; i <= 4; i++) {
      final spread = i * 0.12;
      canvas.drawLine(
        Offset(cx + spread * size.width * 0.15, size.height),
        Offset(cx + spread * size.width * 0.02, horizon),
        road,
      );
    }

    final grid = Paint()
      ..color = branding.scanLineColor.withValues(alpha: 0.5)
      ..strokeWidth = 0.5;
    const step = 24.0;
    for (var x = 0.0; x < size.width; x += step) {
      canvas.drawLine(Offset(x, horizon), Offset(x, size.height), grid);
    }
    for (var y = horizon; y < size.height; y += step * 0.7) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), grid);
    }

    _cornerBrackets(canvas, size, branding.accent, 18);
    _dualScan(canvas, size, branding.accent, progress);

    final nodePhase = progress * math.pi * 2;
    for (var i = 0; i < 5; i++) {
      final t = (nodePhase + i * 1.2) % (math.pi * 2);
      final alpha = (0.3 + 0.5 * (0.5 + 0.5 * math.sin(t))).clamp(0.0, 1.0);
      canvas.drawCircle(
        Offset(size.width * (0.2 + i * 0.15), horizon + 40 + math.sin(t) * 12),
        2.5,
        Paint()..color = branding.particleColor.withValues(alpha: alpha),
      );
    }
  }

  // ── Urban Horror: VHS・ビネット・心拍リング ─────────────────────────────
  void _paintHorror(Canvas canvas, Size size) {
    _vignette(canvas, size, branding.secondaryAccent.withValues(alpha: 0.55));

    final vhs = Paint()..color = Colors.black.withValues(alpha: 0.12);
    for (var y = 0.0; y < size.height; y += 4) {
      if ((y.toInt() + (progress * 40).toInt()) % 8 == 0) {
        canvas.drawLine(Offset(0, y), Offset(size.width, y), vhs);
      }
    }

    final rng = math.Random(13);
    for (var i = 0; i < 160; i++) {
      final flicker = math.sin(progress * 20 + i) > 0.6 ? 0.14 : 0.05;
      canvas.drawCircle(
        Offset(rng.nextDouble() * size.width, rng.nextDouble() * size.height),
        0.5 + rng.nextDouble() * 1.2,
        Paint()..color = Colors.white.withValues(alpha: flicker),
      );
    }

    final center = Offset(size.width * 0.5, size.height * 0.42);
    final beat = 0.5 + 0.5 * math.sin(progress * math.pi * 3.5);
    for (var ring = 1; ring <= 3; ring++) {
      final r = 12.0 * ring + beat * 10;
      canvas.drawCircle(
        center,
        r,
        Paint()
          ..color = branding.pulseColor.withValues(
            alpha: (0.35 - ring * 0.08) * beat,
          )
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.2,
      );
    }
    canvas.drawCircle(
      center,
      3 + beat * 2,
      Paint()..color = branding.particleColor.withValues(alpha: 0.75 + beat * 0.25),
    );
  }

  // ── Pop City: パステルオーブ・バウンスピン ───────────────────────────────
  void _paintPop(Canvas canvas, Size size) {
    final orbs = [
      (Offset(size.width * 0.15, size.height * 0.2), 48.0, branding.accent),
      (Offset(size.width * 0.85, size.height * 0.25), 40.0, branding.secondaryAccent),
      (Offset(size.width * 0.7, size.height * 0.75), 36.0, branding.particleColor),
    ];
    for (final (o, r, c) in orbs) {
      canvas.drawCircle(
        o,
        r,
        Paint()..color = c.withValues(alpha: 0.12),
      );
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
    }
  }

  // ── Stealth Tactical: レティクル・レーダー・READY ───────────────────────
  void _paintTactical(Canvas canvas, Size size) {
    _cornerBrackets(canvas, size, branding.accent, 24);
    _dotGrid(canvas, size, branding.scanLineColor, 32);

    final cx = size.width * 0.5;
    final cy = size.height * 0.42;
    final sweep = progress * math.pi * 2;
    final radarRect = Rect.fromCircle(center: Offset(cx, cy), radius: 72);
    canvas.drawArc(
      radarRect,
      sweep - 0.5,
      0.55,
      false,
      Paint()
        ..color = branding.accent.withValues(alpha: 0.45)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );
    canvas.drawCircle(
      Offset(cx, cy),
      72,
      Paint()
        ..color = branding.scanLineColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.8,
    );
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

  // ── Magical World: 魔術環・浮遊する金の火花・紫の霧 ─────────────────────
  void _paintMagical(Canvas canvas, Size size) {
    final cx = size.width * 0.5;
    final cy = size.height * 0.42;

    // 紫の霧（キャンドルライトの奥）
    final mist = Paint()
      ..shader = RadialGradient(
        colors: [
          branding.secondaryAccent.withValues(alpha: 0.22),
          Colors.transparent,
        ],
      ).createShader(Rect.fromCircle(center: Offset(cx, cy), radius: size.width * 0.55));
    canvas.drawCircle(Offset(cx, cy), size.width * 0.55, mist);

    // 回転する魔術環（3重）
    for (var ring = 0; ring < 3; ring++) {
      final rot = progress * math.pi * (1.2 + ring * 0.3) + ring * 0.9;
      final r = 52.0 + ring * 22;
      final ringPaint = Paint()
        ..color = (ring.isEven ? branding.accent : branding.secondaryAccent)
            .withValues(alpha: 0.22 + ring * 0.06)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2;
      canvas.save();
      canvas.translate(cx, cy);
      canvas.rotate(rot);
      canvas.drawArc(
        Rect.fromCircle(center: Offset.zero, radius: r),
        0,
        math.pi * 1.35,
        false,
        ringPaint,
      );
      canvas.drawArc(
        Rect.fromCircle(center: Offset.zero, radius: r),
        math.pi,
        math.pi * 0.85,
        false,
        ringPaint,
      );
      canvas.restore();
    }

    // 浮遊する金の火花（上昇）
    final rng = math.Random(42);
    for (var i = 0; i < 36; i++) {
      final seed = i * 17.3;
      final x = (rng.nextDouble() * 0.6 + 0.2) * size.width;
      final baseY = size.height * (0.55 + (i % 7) * 0.06);
      final drift = (progress * 1.2 + seed) % 1.0;
      final y = baseY - drift * size.height * 0.35;
      final twinkle = 0.35 + 0.65 * (0.5 + 0.5 * math.sin(progress * 8 + seed));
      final sz = 1.2 + (i % 3) * 0.8;
      canvas.drawCircle(
        Offset(x, y),
        sz * twinkle,
        Paint()..color = branding.particleColor.withValues(alpha: 0.15 + twinkle * 0.45),
      );
    }

    // 中心の暖かいグロー
    final warm = 0.5 + 0.5 * math.sin(progress * math.pi * 2);
    canvas.drawCircle(
      Offset(cx, cy),
      28 + warm * 6,
      Paint()..color = branding.glow.withValues(alpha: 0.25 + warm * 0.2),
    );
    canvas.drawCircle(
      Offset(cx, cy),
      6,
      Paint()..color = branding.pulseColor.withValues(alpha: 0.5 + warm * 0.35),
    );
  }

  // ── Astronomy: 星野・星雲・軌道・流れ星 ─────────────────────────────────
  void _paintAstronomy(Canvas canvas, Size size) {
    // 星雲
    final nebulae = [
      (Offset(size.width * 0.25, size.height * 0.3), 90.0, branding.secondaryAccent),
      (Offset(size.width * 0.78, size.height * 0.55), 110.0, const Color(0xFF7E57C2)),
      (Offset(size.width * 0.5, size.height * 0.75), 70.0, branding.accent),
    ];
    for (final (o, r, c) in nebulae) {
      canvas.drawCircle(
        o,
        r,
        Paint()
          ..shader = RadialGradient(
            colors: [c.withValues(alpha: 0.14), Colors.transparent],
          ).createShader(Rect.fromCircle(center: o, radius: r)),
      );
    }

    // 星（3層パララックス）
    final rng = math.Random(99);
    for (var layer = 0; layer < 3; layer++) {
      final count = 40 + layer * 25;
      final parallax = 0.02 * (layer + 1) * progress;
      for (var i = 0; i < count; i++) {
        final x = rng.nextDouble() * size.width;
        final y = (rng.nextDouble() * size.height + parallax * size.height) % size.height;
        final tw = 0.3 +
            0.7 *
                (0.5 +
                    0.5 *
                        math.sin(
                          progress * (4 + layer * 2) + i * 0.7,
                        ));
        final r = 0.6 + layer * 0.5 + (i % 3) * 0.3;
        final color = i % 11 == 0
            ? branding.pulseColor.withValues(alpha: tw * 0.7)
            : branding.particleColor.withValues(alpha: tw * (0.35 + layer * 0.15));
        canvas.drawCircle(Offset(x, y), r, Paint()..color = color);
      }
    }

    // 軌道リング（ロゴ周りの宇宙感）
    final cx = size.width * 0.5;
    final cy = size.height * 0.42;
    final orbitRot = progress * math.pi * 0.4;
    canvas.save();
    canvas.translate(cx, cy);
    canvas.rotate(orbitRot);
    canvas.drawOval(
      Rect.fromCenter(center: Offset.zero, width: 200, height: 56),
      Paint()
        ..color = branding.accent.withValues(alpha: 0.2)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.9,
    );
    canvas.restore();

    // 流れ星（progress で1周期）
    final meteorPhase = (progress * 1.4) % 1.0;
    if (meteorPhase < 0.35) {
      final t = meteorPhase / 0.35;
      final start = Offset(size.width * (0.75 - t * 0.5), size.height * (0.15 + t * 0.1));
      final end = start + Offset(-80 * t, 50 * t);
      final meteor = Paint()
        ..shader = LinearGradient(
          colors: [
            Colors.transparent,
            branding.accent.withValues(alpha: 0.7),
            Colors.white.withValues(alpha: 0.9),
          ],
        ).createShader(Rect.fromPoints(start, end))
        ..strokeWidth = 1.8
        ..strokeCap = StrokeCap.round;
      canvas.drawLine(start, end, meteor);
    }

    // 遠方の地球っぽい弧（地平）
    canvas.drawArc(
      Rect.fromCenter(
        center: Offset(cx, size.height * 0.92),
        width: size.width * 1.4,
        height: 80,
      ),
      math.pi,
      math.pi,
      false,
      Paint()
        ..color = branding.accent.withValues(alpha: 0.12)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1,
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

  void _dualScan(Canvas canvas, Size size, Color accent, double progress) {
    final y1 = size.height * progress;
    final y2 = size.height * (1 - progress);
    for (final y in [y1, y2]) {
      canvas.drawRect(
        Rect.fromLTWH(0, y - 36, size.width, 72),
        Paint()
          ..shader = LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.transparent,
              accent.withValues(alpha: 0.28),
              Colors.transparent,
            ],
          ).createShader(Rect.fromLTWH(0, y - 36, size.width, 72)),
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
        (oldDelegate.progress - progress).abs() > 0.006;
  }
}
