import 'dart:math' as math;

import 'package:flutter/material.dart';

/// reveal フラッシュ時の軽量ノイズ（ホラー / サイバー向け）。
class RevealNoiseOverlay extends StatelessWidget {
  const RevealNoiseOverlay({
    required this.active,
    required this.tint,
    this.seed = 0,
    this.grainBoost = 1.0,
    super.key,
  });

  final bool active;
  final Color tint;
  final double seed;
  /// 1.0 既定。ホラー等でノイズ粒を強める。
  final double grainBoost;

  @override
  Widget build(BuildContext context) {
    if (!active) return const SizedBox.shrink();
    return IgnorePointer(
      child: CustomPaint(
        painter: _RevealNoisePainter(
          tint: tint,
          seed: seed,
          grainBoost: grainBoost,
        ),
        size: Size.infinite,
      ),
    );
  }
}

class _RevealNoisePainter extends CustomPainter {
  _RevealNoisePainter({
    required this.tint,
    required this.seed,
    required this.grainBoost,
  });

  final Color tint;
  final double seed;
  final double grainBoost;

  @override
  void paint(Canvas canvas, Size size) {
    final rng = math.Random((seed * 1000).round());
    final paint = Paint();
    const step = 5.0;
    final b = grainBoost.clamp(0.85, 1.45);
    for (var y = 0.0; y < size.height; y += step) {
      for (var x = 0.0; x < size.width; x += step) {
        final n = rng.nextDouble();
        if (n > 0.72) continue;
        paint.color = tint.withValues(
          alpha: ((0.04 + n * 0.08) * b).clamp(0.0, 0.24),
        );
        canvas.drawRect(Rect.fromLTWH(x, y, step - 1, step - 1), paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _RevealNoisePainter oldDelegate) =>
      oldDelegate.tint != tint ||
      oldDelegate.seed != seed ||
      oldDelegate.grainBoost != grainBoost;
}
