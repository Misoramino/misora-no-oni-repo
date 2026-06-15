import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../world_presentation_pack.dart';

/// 各画面用の薄いアンビエント装飾。
class WorldAmbientPainter extends CustomPainter {
  WorldAmbientPainter({required this.pack, required this.phase});

  final WorldPresentationPack pack;
  final double phase;

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
      canvas.drawRect(
        Rect.fromLTWH(x, (t * 40 + i * 80) % size.height, 1.5, 24),
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
      ..color = pack.accent.withValues(alpha: 0.08)
      ..strokeWidth = 1;
    for (var i = 0; i < 5; i++) {
      final y = size.height * 0.2 + i * 28;
      canvas.drawLine(
        Offset(0, y + math.sin(t + i) * 4),
        Offset(size.width * (0.3 + 0.1 * i), y),
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
    for (var i = 0; i < 6; i++) {
      final c = Offset(
        size.width * (0.2 + i * 0.12),
        size.height * (0.25 + math.sin(t + i) * 0.05),
      );
      canvas.drawCircle(
        c,
        2.5,
        Paint()..color = pack.accent.withValues(alpha: 0.18),
      );
    }
  }

  void _stardust(Canvas canvas, Size size, double t) {
    for (var i = 0; i < 20; i++) {
      final a = (i / 20) * math.pi * 2 + t * 0.3;
      final r = size.shortestSide * (0.15 + (i % 5) * 0.04);
      canvas.drawCircle(
        Offset(
          size.width / 2 + math.cos(a) * r,
          size.height * 0.35 + math.sin(a) * r * 0.5,
        ),
        1,
        Paint()..color = pack.accent.withValues(alpha: 0.2),
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
    for (var i = 0; i < 5; i++) {
      final a = -math.pi / 2 + (i - 2) * 0.12 + math.sin(t) * 0.02;
      final end = center + Offset(math.cos(a) * size.height, math.sin(a) * size.height);
      canvas.drawLine(
        center,
        end,
        Paint()
          ..color = pack.accent.withValues(alpha: 0.05)
          ..strokeWidth = 2,
      );
    }
  }

  @override
  bool shouldRepaint(covariant WorldAmbientPainter old) =>
      old.phase != phase || old.pack.profile != pack.profile;
}
