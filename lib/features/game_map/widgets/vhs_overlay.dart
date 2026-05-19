import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Urban Horror 向け VHS 風（走査線・RGB ずれ・上下の黒帯）。
class VhsOverlay extends StatelessWidget {
  const VhsOverlay({
    required this.active,
    required this.phase,
    super.key,
  });

  final bool active;
  final double phase;

  @override
  Widget build(BuildContext context) {
    if (!active) return const SizedBox.shrink();
    return IgnorePointer(
      child: CustomPaint(
        painter: _VhsPainter(phase: phase),
        size: Size.infinite,
      ),
    );
  }
}

class _VhsPainter extends CustomPainter {
  _VhsPainter({required this.phase});

  final double phase;

  @override
  void paint(Canvas canvas, Size size) {
    final bandH = size.height * 0.06;
    final bandPaint = Paint()..color = Colors.black.withValues(alpha: 0.35);
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, bandH), bandPaint);
    canvas.drawRect(
      Rect.fromLTWH(0, size.height - bandH, size.width, bandH),
      bandPaint,
    );

    final tearY = (phase * size.height * 1.3) % (size.height + 40) - 20;
    final tear = Paint()..color = Colors.white.withValues(alpha: 0.04);
    canvas.drawRect(Rect.fromLTWH(0, tearY, size.width, 3), tear);

    final linePaint = Paint();
    for (var y = 0.0; y < size.height; y += 4) {
      final wobble = math.sin((y + phase * 120) * 0.08) * 1.5;
      linePaint.color = Colors.white.withValues(alpha: 0.025);
      canvas.drawRect(Rect.fromLTWH(wobble, y, size.width, 1), linePaint);
    }

    final chroma = Paint()..blendMode = BlendMode.screen;
    chroma.color = const Color(0xFFFF1744).withValues(alpha: 0.03);
    canvas.drawRect(
      Rect.fromLTWH(-2, phase * 6 % 4, size.width, size.height),
      chroma,
    );
    chroma.color = const Color(0xFF00E5FF).withValues(alpha: 0.03);
    canvas.drawRect(
      Rect.fromLTWH(2, -phase * 5 % 4, size.width, size.height),
      chroma,
    );
  }

  @override
  bool shouldRepaint(covariant _VhsPainter oldDelegate) =>
      oldDelegate.phase != phase;
}
