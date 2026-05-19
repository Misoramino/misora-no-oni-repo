import 'package:flutter/material.dart';

import '../../../theme/world_visual_pack.dart';
import 'reveal_noise_overlay.dart';
import 'vhs_overlay.dart';

/// 世界観ごとの地図上ビネット・reveal フラッシュ（軽量 overlay）。
class WorldMapAtmosphere extends StatelessWidget {
  const WorldMapAtmosphere({
    required this.pack,
    required this.dangerPulse,
    required this.revealFlashActive,
    this.scanPhase = 0,
    this.revealNoiseSeed = 0,
    super.key,
  });

  final WorldVisualPack pack;
  final double dangerPulse;
  final bool revealFlashActive;
  final double scanPhase;
  final double revealNoiseSeed;

  @override
  Widget build(BuildContext context) {
    final vignette = pack.vignetteColor;
    final flash = pack.revealFlashColor;
    final flashScale = pack.usePinBounceFlash && revealFlashActive ? 1.08 : 1.0;

    return IgnorePointer(
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (vignette != null)
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: const Alignment(0, -0.15),
                  radius: 1.05,
                  colors: [
                    vignette.withValues(
                      alpha: (vignette.a * (0.35 + dangerPulse * 0.35))
                          .clamp(0.0, 1.0),
                    ),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          if (pack.useVhsOverlay)
            VhsOverlay(active: true, phase: scanPhase),
          if (revealFlashActive && flash != null)
            AnimatedScale(
              scale: flashScale,
              duration: Duration(
                milliseconds: pack.usePinBounceFlash ? 280 : 180,
              ),
              curve: pack.usePinBounceFlash
                  ? Curves.elasticOut
                  : Curves.easeOut,
              child: AnimatedOpacity(
                opacity: revealFlashActive ? 0.55 : 0,
                duration: const Duration(milliseconds: 180),
                child: ColoredBox(color: flash),
              ),
            ),
          if (revealFlashActive && flash != null && pack.useRevealNoise)
            RevealNoiseOverlay(
              active: revealFlashActive,
              tint: flash,
              seed: revealNoiseSeed,
            ),
          if (pack.useScanOverlay)
            CustomPaint(
              painter: _ScanLinePainter(
                color: pack.tokens.markerAccent.withValues(alpha: 0.06),
                phase: scanPhase,
              ),
            ),
        ],
      ),
    );
  }
}

class _ScanLinePainter extends CustomPainter {
  _ScanLinePainter({required this.color, required this.phase});

  final Color color;
  final double phase;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color;
    final offset = (phase * 24) % 24;
    for (var y = -offset; y < size.height; y += 6) {
      canvas.drawRect(Rect.fromLTWH(0, y, size.width, 2), paint);
    }
  }

  @override
  bool shouldRepaint(covariant _ScanLinePainter oldDelegate) =>
      oldDelegate.color != color || oldDelegate.phase != phase;
}
