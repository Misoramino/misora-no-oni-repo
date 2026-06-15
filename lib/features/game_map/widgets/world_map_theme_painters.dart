import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../theme/world_profile.dart';

/// 世界観ごとの軽量スクリーンオーバーレイ（地図の視認性を損なわない低アルファ）。
class WorldMapThemeOverlay extends StatelessWidget {
  const WorldMapThemeOverlay({
    required this.profile,
    required this.phase,
    this.accent,
    super.key,
  });

  final WorldProfile profile;
  final double phase;
  final Color? accent;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: CustomPaint(
        painter: switch (profile) {
          WorldProfile.astronomy => _StarfieldPainter(phase: phase),
          WorldProfile.magical => _MagicSigilPainter(
              phase: phase,
              accent: accent ?? const Color(0xFFE040FB),
            ),
          WorldProfile.sciFi => _HexGridPainter(
              phase: phase,
              accent: accent ?? const Color(0xFF00E5FF),
            ),
          WorldProfile.horror => _FogMotesPainter(phase: phase),
          WorldProfile.sport => _SparklePainter(
              phase: phase,
              accent: accent ?? const Color(0xFFFF8FB3),
            ),
          WorldProfile.arg => _CrosshairPainter(phase: phase),
          WorldProfile.japaneseLuxury => _JapaneseLuxuryPainter(
              phase: phase,
              accent: accent ?? const Color(0xFFC9A227),
            ),
          WorldProfile.westernLuxury => _WesternLuxuryPainter(
              phase: phase,
              accent: accent ?? const Color(0xFFD4AF37),
            ),
        },
      ),
    );
  }
}

class _StarfieldPainter extends CustomPainter {
  _StarfieldPainter({required this.phase});

  final double phase;

  @override
  void paint(Canvas canvas, Size size) {
    final rng = math.Random(42);
    final twinkle = (math.sin(phase * math.pi * 2) + 1) * 0.5;
    for (var i = 0; i < 48; i++) {
      final x = rng.nextDouble() * size.width;
      final y = rng.nextDouble() * size.height;
      final r = 0.6 + rng.nextDouble() * 1.4;
      final base = 0.08 + rng.nextDouble() * 0.14;
      final alpha = (base + twinkle * 0.06).clamp(0.05, 0.22);
      final paint = Paint()
        ..color = Color.lerp(
          const Color(0xFFFFF8E1),
          const Color(0xFF80D8FF),
          rng.nextDouble(),
        )!
            .withValues(alpha: alpha);
      canvas.drawCircle(Offset(x, y), r, paint);
    }
    // ごく薄い天の川帯
    final band = Paint()
      ..shader = LinearGradient(
        begin: Alignment(-0.6 + phase * 0.08, -0.9),
        end: const Alignment(0.7, 0.9),
        colors: [
          Colors.transparent,
          const Color(0xFF4FC3F7).withValues(alpha: 0.045),
          const Color(0xFFCE93D8).withValues(alpha: 0.035),
          Colors.transparent,
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), band);
  }

  @override
  bool shouldRepaint(covariant _StarfieldPainter oldDelegate) =>
      oldDelegate.phase != phase;
}

class _MagicSigilPainter extends CustomPainter {
  _MagicSigilPainter({required this.phase, required this.accent});

  final double phase;
  final Color accent;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width * 0.5, size.height * 0.46);
    final radius = math.min(size.width, size.height) * 0.38;
    final rot = phase * math.pi * 2;

    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(rot * 0.15);

    final ring = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2
      ..color = accent.withValues(alpha: 0.11);
    canvas.drawCircle(Offset.zero, radius, ring);
    canvas.drawCircle(Offset.zero, radius * 0.72, ring..color = accent.withValues(alpha: 0.08));

    final rune = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..color = const Color(0xFFFFD54F).withValues(alpha: 0.09);
    for (var i = 0; i < 6; i++) {
      final a = rot + i * math.pi / 3;
      final p1 = Offset(math.cos(a) * radius * 0.55, math.sin(a) * radius * 0.55);
      final p2 = Offset(math.cos(a) * radius, math.sin(a) * radius);
      canvas.drawLine(p1, p2, rune);
    }

    final inner = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.8
      ..color = accent.withValues(alpha: 0.07);
    final path = Path();
    for (var i = 0; i < 8; i++) {
      final a = -rot * 0.4 + i * math.pi / 4;
      final p = Offset(math.cos(a) * radius * 0.32, math.sin(a) * radius * 0.32);
      if (i == 0) {
        path.moveTo(p.dx, p.dy);
      } else {
        path.lineTo(p.dx, p.dy);
      }
    }
    path.close();
    canvas.drawPath(path, inner);
    canvas.restore();

    // きらめき粒子
    final rng = math.Random(7);
    for (var i = 0; i < 14; i++) {
      final x = rng.nextDouble() * size.width;
      final y = rng.nextDouble() * size.height;
      final flicker = (math.sin(phase * 5 + i) + 1) * 0.5;
      canvas.drawCircle(
        Offset(x, y),
        1.2,
        Paint()..color = accent.withValues(alpha: 0.04 + flicker * 0.06),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _MagicSigilPainter oldDelegate) =>
      oldDelegate.phase != phase || oldDelegate.accent != accent;
}

class _HexGridPainter extends CustomPainter {
  _HexGridPainter({required this.phase, required this.accent});

  final double phase;
  final Color accent;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.6
      ..color = accent.withValues(alpha: 0.055);
    const step = 42.0;
    final drift = (phase * 18) % step;
    for (var y = -step; y < size.height + step; y += step * 0.86) {
      for (var x = -step; x < size.width + step; x += step) {
        final ox = x + drift + ((y / step).round() % 2) * (step * 0.5);
        _drawHex(canvas, Offset(ox, y), step * 0.32, paint);
      }
    }
  }

  void _drawHex(Canvas canvas, Offset c, double r, Paint paint) {
    final path = Path();
    for (var i = 0; i < 6; i++) {
      final a = math.pi / 6 + i * math.pi / 3;
      final p = Offset(c.dx + math.cos(a) * r, c.dy + math.sin(a) * r);
      if (i == 0) {
        path.moveTo(p.dx, p.dy);
      } else {
        path.lineTo(p.dx, p.dy);
      }
    }
    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _HexGridPainter oldDelegate) =>
      oldDelegate.phase != phase;
}

class _FogMotesPainter extends CustomPainter {
  _FogMotesPainter({required this.phase});

  final double phase;

  @override
  void paint(Canvas canvas, Size size) {
    final rng = math.Random(19);
    for (var i = 0; i < 22; i++) {
      final x = (rng.nextDouble() * size.width + phase * 40 * (i % 3 + 1)) %
          size.width;
      final y = rng.nextDouble() * size.height;
      final r = 18 + rng.nextDouble() * 36;
      final paint = Paint()
        ..color = const Color(0xFF1A0508).withValues(alpha: 0.04 + rng.nextDouble() * 0.03);
      canvas.drawCircle(Offset(x, y), r, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _FogMotesPainter oldDelegate) =>
      oldDelegate.phase != phase;
}

class _SparklePainter extends CustomPainter {
  _SparklePainter({required this.phase, required this.accent});

  final double phase;
  final Color accent;

  @override
  void paint(Canvas canvas, Size size) {
    final rng = math.Random(3);
    for (var i = 0; i < 10; i++) {
      final x = rng.nextDouble() * size.width;
      final y = rng.nextDouble() * size.height * 0.55;
      final pulse = (math.sin(phase * 4 + i * 1.7) + 1) * 0.5;
      final paint = Paint()
        ..color = accent.withValues(alpha: 0.05 + pulse * 0.07);
      canvas.drawCircle(Offset(x, y), 2 + pulse * 2, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _SparklePainter oldDelegate) =>
      oldDelegate.phase != phase;
}

class _CrosshairPainter extends CustomPainter {
  _CrosshairPainter({required this.phase});

  final double phase;

  @override
  void paint(Canvas canvas, Size size) {
    final c = Offset(size.width * 0.5, size.height * 0.5);
    final len = math.min(size.width, size.height) * 0.22;
    final gap = 10 + phase * 4;
    final paint = Paint()
      ..color = const Color(0xFF9E9E9E).withValues(alpha: 0.07)
      ..strokeWidth = 1;
    canvas.drawLine(Offset(c.dx - len, c.dy), Offset(c.dx - gap, c.dy), paint);
    canvas.drawLine(Offset(c.dx + gap, c.dy), Offset(c.dx + len, c.dy), paint);
    canvas.drawLine(Offset(c.dx, c.dy - len), Offset(c.dx, c.dy - gap), paint);
    canvas.drawLine(Offset(c.dx, c.dy + gap), Offset(c.dx, c.dy + len), paint);
    canvas.drawCircle(c, gap * 0.55, paint..style = PaintingStyle.stroke);
  }

  @override
  bool shouldRepaint(covariant _CrosshairPainter oldDelegate) =>
      oldDelegate.phase != phase;
}

class _JapaneseLuxuryPainter extends CustomPainter {
  _JapaneseLuxuryPainter({required this.phase, required this.accent});

  final double phase;
  final Color accent;

  @override
  void paint(Canvas canvas, Size size) {
    final line = Paint()
      ..color = const Color(0xFFE8D5A3).withValues(alpha: 0.04)
      ..strokeWidth = 0.8;
    for (var x = 0.0; x < size.width; x += 48) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), line);
    }
    final rng = math.Random(17);
    final twinkle = (math.sin(phase * math.pi * 2) + 1) * 0.5;
    for (var i = 0; i < 24; i++) {
      final x = rng.nextDouble() * size.width;
      final y = rng.nextDouble() * size.height;
      final alpha = (0.04 + twinkle * 0.05).clamp(0.03, 0.12);
      canvas.drawCircle(
        Offset(x, y),
        0.8 + rng.nextDouble() * 1.2,
        Paint()..color = accent.withValues(alpha: alpha),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _JapaneseLuxuryPainter old) =>
      old.phase != phase || old.accent != accent;
}

class _WesternLuxuryPainter extends CustomPainter {
  _WesternLuxuryPainter({required this.phase, required this.accent});

  final double phase;
  final Color accent;

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width * 0.5;
    final cy = size.height * 0.38;
    for (var i = 0; i < 5; i++) {
      final sweep = Paint()
        ..color = accent.withValues(alpha: 0.035 + i * 0.008)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2;
      canvas.drawArc(
        Rect.fromCircle(
          center: Offset(cx, cy),
          radius: 40 + i * 28 + phase * 6,
        ),
        -math.pi * 0.75,
        math.pi * 1.5,
        false,
        sweep,
      );
    }
    final corner = Paint()..color = const Color(0xFFECEFF1).withValues(alpha: 0.05);
    const inset = 18.0;
    const len = 22.0;
    for (final origin in [
      Offset(inset, inset),
      Offset(size.width - inset, inset),
      Offset(inset, size.height - inset),
      Offset(size.width - inset, size.height - inset),
    ]) {
      canvas.drawLine(origin, origin + const Offset(len, 0), corner);
      canvas.drawLine(origin, origin + const Offset(0, len), corner);
    }
  }

  @override
  bool shouldRepaint(covariant _WesternLuxuryPainter old) =>
      old.phase != phase || old.accent != accent;
}
