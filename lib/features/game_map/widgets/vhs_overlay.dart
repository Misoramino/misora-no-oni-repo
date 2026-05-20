import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Urban Horror 向け VHS 風（走査線・RGB ずれ・上下の黒帯）。
class VhsOverlay extends StatelessWidget {
  const VhsOverlay({
    required this.active,
    required this.phase,
    this.intensity = 1.0,
    super.key,
  });

  final bool active;
  final double phase;
  /// 1.0 既定。大きいほどチラつき・色収差が強い（ホラー向け）。
  final double intensity;

  @override
  Widget build(BuildContext context) {
    if (!active) return const SizedBox.shrink();
    return IgnorePointer(
      child: CustomPaint(
        painter: _VhsPainter(phase: phase, intensity: intensity),
        size: Size.infinite,
      ),
    );
  }
}

class _VhsPainter extends CustomPainter {
  _VhsPainter({required this.phase, this.intensity = 1.0});

  final double phase;
  final double intensity;

  @override
  void paint(Canvas canvas, Size size) {
    final i = intensity.clamp(0.7, 1.6);
    final bandH = size.height * 0.06;
    final bandPaint = Paint()
      ..color = Colors.black.withValues(alpha: (0.32 * i).clamp(0.0, 0.55));
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, bandH), bandPaint);
    canvas.drawRect(
      Rect.fromLTWH(0, size.height - bandH, size.width, bandH),
      bandPaint,
    );

    final tearY = (phase * size.height * 1.3) % (size.height + 40) - 20;
    final tear = Paint()
      ..color = Colors.white.withValues(alpha: (0.035 * i).clamp(0.0, 0.1));
    canvas.drawRect(Rect.fromLTWH(0, tearY, size.width, 3), tear);

    final linePaint = Paint();
    for (var y = 0.0; y < size.height; y += 4) {
      final wobble = math.sin((y + phase * 120) * 0.08) * 1.5 * i;
      linePaint.color =
          Colors.white.withValues(alpha: (0.028 * i).clamp(0.0, 0.08));
      canvas.drawRect(Rect.fromLTWH(wobble, y, size.width, 1), linePaint);
    }

    final chroma = Paint()..blendMode = BlendMode.screen;
    chroma.color =
        const Color(0xFFFF1744).withValues(alpha: (0.034 * i).clamp(0.0, 0.08));
    canvas.drawRect(
      Rect.fromLTWH(-2, phase * 6 % 4, size.width, size.height),
      chroma,
    );
    chroma.color =
        const Color(0xFF00E5FF).withValues(alpha: (0.028 * i).clamp(0.0, 0.07));
    canvas.drawRect(
      Rect.fromLTWH(2, -phase * 5 % 4, size.width, size.height),
      chroma,
    );

    // 心拍に近い薄い脈動（画面端の赤み）
    final pulse = (math.sin(phase * math.pi * 2 * 1.15) * 0.5 + 0.5) * 0.04 * i;
    final edge = Paint()
      ..color = const Color(0xFF4A0000).withValues(alpha: pulse);
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, 3), edge);
    canvas.drawRect(
      Rect.fromLTWH(0, size.height - 3, size.width, 3),
      edge,
    );
  }

  @override
  bool shouldRepaint(covariant _VhsPainter oldDelegate) =>
      oldDelegate.phase != phase || oldDelegate.intensity != intensity;
}
