import 'dart:math' as math;

import 'package:flutter/material.dart';

/// reveal フラッシュ時の軽量ノイズ（ホラー / サイバー向け）。
class RevealNoiseOverlay extends StatelessWidget {
  const RevealNoiseOverlay({
    required this.active,
    required this.tint,
    this.seed = 0,
    super.key,
  });

  final bool active;
  final Color tint;
  final double seed;

  @override
  Widget build(BuildContext context) {
    if (!active) return const SizedBox.shrink();
    return IgnorePointer(
      child: CustomPaint(
        painter: _RevealNoisePainter(tint: tint, seed: seed),
        size: Size.infinite,
      ),
    );
  }
}

class _RevealNoisePainter extends CustomPainter {
  _RevealNoisePainter({required this.tint, required this.seed});

  final Color tint;
  final double seed;

  @override
  void paint(Canvas canvas, Size size) {
    final rng = math.Random((seed * 1000).round());
    final paint = Paint();
    const step = 5.0;
    for (var y = 0.0; y < size.height; y += step) {
      for (var x = 0.0; x < size.width; x += step) {
        final n = rng.nextDouble();
        if (n > 0.72) continue;
        paint.color = tint.withValues(alpha: (0.04 + n * 0.08).clamp(0.0, 0.2));
        canvas.drawRect(Rect.fromLTWH(x, y, step - 1, step - 1), paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _RevealNoisePainter oldDelegate) =>
      oldDelegate.tint != tint || oldDelegate.seed != seed;
}
