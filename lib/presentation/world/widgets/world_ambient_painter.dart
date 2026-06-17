import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../world_presentation_pack.dart';

/// 各画面用の薄いアンビエント装飾。
class WorldAmbientPainter extends CustomPainter {
  WorldAmbientPainter({
    required this.pack,
    required this.phase,
    this.strength = 1.0,
  });

  final WorldPresentationPack pack;
  final double phase;
  final double strength;

  double _a(double alpha) => (alpha * strength).clamp(0.0, 1.0);

  @override
  void paint(Canvas canvas, Size size) {
    final t = phase * math.pi * 2;
    switch (pack.momentParticle) {
      case WorldParticleKind.smokeRain:
        _smokeRain(canvas, size, t);
      case WorldParticleKind.neonPop:
        _neonPop(canvas, size, t);
      case WorldParticleKind.dataBits:
        _dataBits(canvas, size, t);
      case WorldParticleKind.dust:
        _dust(canvas, size, t);
      case WorldParticleKind.sparks:
        _sparks(canvas, size, t);
      case WorldParticleKind.stardust:
        _stardust(canvas, size, t);
      case WorldParticleKind.goldInk:
        _goldInk(canvas, size, t);
      case WorldParticleKind.lightRays:
        _lightRays(canvas, size, t);
    }
  }

  void _smokeRain(Canvas canvas, Size size, double t) {
    final paint = Paint()..color = pack.accent.withValues(alpha: 0.04);
    for (var i = 0; i < 6; i++) {
      final x = size.width * (0.1 + i * 0.15);
      final y = (t * 40 + i * 80) % size.height;
      canvas.drawRect(
        Rect.fromLTWH(x, y, 1.5, 24),
        paint,
      );
    }
  }

  void _neonPop(Canvas canvas, Size size, double t) {
    for (var i = 0; i < 8; i++) {
      final x = size.width * (0.08 + i * 0.11);
      final y = size.height * (0.15 + (i % 3) * 0.25);
      canvas.drawCircle(
        Offset(x, y + math.sin(t + i) * 6),
        3 + (i % 2),
        Paint()
          ..color = (i.isEven ? pack.accent : pack.accentMuted)
              .withValues(alpha: 0.12),
      );
    }
  }

  void _dataBits(Canvas canvas, Size size, double t) {
    final paint = Paint()
      ..color = pack.accent.withValues(alpha: _a(0.04))
      ..strokeWidth = 1;
    for (var i = 0; i < 4; i++) {
      final y = size.height * 0.2 + i * 28;
      canvas.drawLine(
        Offset(0, y + math.sin(t + i) * 3),
        Offset(size.width * (0.22 + 0.08 * i), y),
        paint,
      );
    }
  }

  void _dust(Canvas canvas, Size size, double t) {
    for (var i = 0; i < 10; i++) {
      canvas.drawCircle(
        Offset(
          size.width * ((i * 0.09 + t * 0.02) % 1),
          size.height * (0.3 + (i % 4) * 0.12),
        ),
        1.2,
        Paint()..color = pack.accentMuted.withValues(alpha: 0.15),
      );
    }
  }

  void _sparks(Canvas canvas, Size size, double t) {
    final center = Offset(size.width * 0.5, size.height * 0.42);
    final radius = size.shortestSide * 0.28;
    final ring = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..color = pack.accentMuted.withValues(alpha: 0.12);
    canvas.drawCircle(center, radius, ring);
    canvas.drawCircle(center, radius * 0.62, ring..color = const Color(0xFFFFD54F).withValues(alpha: 0.1));
    for (var i = 0; i < 6; i++) {
      final a = t + i * math.pi / 3;
      final c = center + Offset(math.cos(a) * radius * 0.85, math.sin(a) * radius * 0.85);
      canvas.drawCircle(
        c,
        2.5,
        Paint()..color = pack.accent.withValues(alpha: 0.2),
      );
      // 古代文字風の短い刻み
      final rune = Paint()
        ..color = pack.accentMuted.withValues(alpha: 0.14)
        ..strokeWidth = 1.2;
      canvas.drawLine(c, c + Offset(0, -8 - math.sin(t + i) * 3), rune);
    }
    for (var i = 0; i < 4; i++) {
      final spark = Offset(
        size.width * (0.15 + i * 0.22),
        size.height * (0.2 + math.sin(t * 1.2 + i) * 0.04),
      );
      canvas.drawCircle(
        spark,
        1.8,
        Paint()..color = const Color(0xFFFFE082).withValues(alpha: 0.22),
      );
    }
  }

  void _stardust(Canvas canvas, Size size, double t) {
    // 星雲（淡い光の塊）
    final nebula = [
      (Offset(size.width * 0.28, size.height * 0.32), const Color(0xFF7E57C2)),
      (Offset(size.width * 0.72, size.height * 0.48), const Color(0xFF4FC3F7)),
      (Offset(size.width * 0.5, size.height * 0.62), const Color(0xFFFFD54F)),
    ];
    for (final (c, color) in nebula) {
      final pulse = 0.85 + math.sin(t + c.dx) * 0.08;
      final paint = Paint()
        ..shader = RadialGradient(
          colors: [
            color.withValues(alpha: 0.09 * pulse),
            color.withValues(alpha: 0.03),
            Colors.transparent,
          ],
        ).createShader(Rect.fromCircle(center: c, radius: size.shortestSide * 0.22));
      canvas.drawCircle(c, size.shortestSide * 0.22, paint);
    }
    final rng = math.Random(31);
    for (var i = 0; i < 18; i++) {
      final x = rng.nextDouble() * size.width;
      final y = (rng.nextDouble() * size.height + t * 8) % size.height;
      final tw = 0.5 + 0.5 * math.sin(t * 1.4 + i);
      canvas.drawCircle(
        Offset(x, y),
        0.6 + (i % 3) * 0.25,
        Paint()..color = pack.accent.withValues(alpha: 0.08 + tw * 0.06),
      );
    }
  }

  void _goldInk(Canvas canvas, Size size, double t) {
    final paint = Paint()
      ..color = pack.accent.withValues(alpha: 0.06)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;
    final path = Path()
      ..moveTo(size.width * 0.1, size.height * 0.7)
      ..quadraticBezierTo(
        size.width * (0.3 + math.sin(t) * 0.05),
        size.height * 0.5,
        size.width * 0.9,
        size.height * 0.75,
      );
    canvas.drawPath(path, paint);
  }

  void _lightRays(Canvas canvas, Size size, double t) {
    final center = Offset(size.width * 0.5, -size.height * 0.1);
    for (var i = 0; i < 3; i++) {
      final a = -math.pi / 2 + (i - 1) * 0.1 + math.sin(t) * 0.015;
      final end = center + Offset(math.cos(a) * size.height, math.sin(a) * size.height);
      canvas.drawLine(
        center,
        end,
        Paint()
          ..color = pack.accent.withValues(alpha: _a(0.03))
          ..strokeWidth = 1.5,
      );
    }
  }

  @override
  bool shouldRepaint(covariant WorldAmbientPainter old) =>
      old.phase != phase ||
      old.pack.profile != pack.profile ||
      old.strength != strength;
}
