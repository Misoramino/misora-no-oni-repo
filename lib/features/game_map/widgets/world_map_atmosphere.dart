import 'package:flutter/material.dart';

import '../../../theme/world_profile.dart';
import '../../../theme/world_visual_pack.dart';
import 'reveal_noise_overlay.dart';
import 'vhs_overlay.dart';
import 'world_map_theme_painters.dart';

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
    final profile = pack.profile;

    final vignetteScale = switch (profile) {
      WorldProfile.magical => 0.78,
      WorldProfile.astronomy => 0.82,
      WorldProfile.sport => 0.88,
      _ => 1.0,
    };
    final pulseBase = profile == WorldProfile.horror ? 0.38 : 0.34;
    final pulseMult = profile == WorldProfile.horror ? 0.52 : 0.35;

    final revealGrain = switch (profile) {
      WorldProfile.horror => 1.22,
      WorldProfile.sciFi => 1.08,
      _ => 1.0,
    };

    final vhsIntensity = profile == WorldProfile.horror ? 1.28 : 1.0;

    return IgnorePointer(
      child: Stack(
        fit: StackFit.expand,
        children: [
          WorldMapThemeOverlay(
            profile: profile,
            phase: scanPhase,
            accent: pack.tokens.markerAccent,
          ),
          if (profile == WorldProfile.arg)
            ColoredBox(
              color: const Color(0xFF1A1D24).withValues(alpha: 0.06),
            ),
          if (profile == WorldProfile.sport)
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: const Alignment(0, -0.28),
                  radius: 1.25,
                  colors: [
                    Colors.amber.shade50.withValues(alpha: 0.085),
                    Colors.white.withValues(alpha: 0.035),
                    Colors.transparent,
                  ],
                  stops: const [0.0, 0.35, 1.0],
                ),
              ),
            ),
          if (vignette != null)
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: const Alignment(0, -0.15),
                  radius: 1.05,
                  colors: [
                    vignette.withValues(
                      alpha: (vignette.a *
                              vignetteScale *
                              (pulseBase + dangerPulse * pulseMult))
                          .clamp(0.0, 1.0),
                    ),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          if (pack.useVhsOverlay)
            VhsOverlay(
              active: true,
              phase: scanPhase,
              intensity: vhsIntensity,
            ),
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
                opacity: revealFlashActive
                    ? (profile == WorldProfile.sport ? 0.5 : 0.55)
                    : 0,
                duration: const Duration(milliseconds: 180),
                child: ColoredBox(color: flash),
              ),
            ),
          if (revealFlashActive && flash != null && pack.useRevealNoise)
            RevealNoiseOverlay(
              active: revealFlashActive,
              tint: flash,
              seed: revealNoiseSeed,
              grainBoost: revealGrain,
            ),
          if (pack.useScanOverlay)
            CustomPaint(
              painter: _ScanLinePainter(
                color: pack.tokens.markerAccent.withValues(alpha: 0.095),
                phase: scanPhase,
              ),
            ),
          if (pack.useScanOverlay && profile == WorldProfile.sciFi) ...[
            CustomPaint(
              painter: _ScanLinePainter(
                color: const Color(0xFF00E5FF).withValues(alpha: 0.062),
                phase: scanPhase * 1.35 + 0.22,
                lineStep: 4,
                lineHeight: 1,
              ),
            ),
            CustomPaint(
              painter: _NeonSweepPainter(
                phase: scanPhase,
                accent: pack.tokens.markerAccent,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _NeonSweepPainter extends CustomPainter {
  _NeonSweepPainter({required this.phase, required this.accent});

  final double phase;
  final Color accent;

  @override
  void paint(Canvas canvas, Size size) {
    final x = (phase * (size.width + 80) * 0.35) % (size.width + 80) - 40;
    final paint = Paint()
      ..shader = LinearGradient(
        colors: [
          Colors.transparent,
          accent.withValues(alpha: 0.12),
          const Color(0xFFE040FB).withValues(alpha: 0.08),
          Colors.transparent,
        ],
        stops: const [0.0, 0.35, 0.65, 1.0],
      ).createShader(Rect.fromLTWH(x, 0, 56, size.height));
    canvas.drawRect(Rect.fromLTWH(x, 0, 56, size.height), paint);
  }

  @override
  bool shouldRepaint(covariant _NeonSweepPainter oldDelegate) =>
      oldDelegate.phase != phase || oldDelegate.accent != accent;
}

class _ScanLinePainter extends CustomPainter {
  _ScanLinePainter({
    required this.color,
    required this.phase,
    this.lineStep = 6,
    this.lineHeight = 2,
  });

  final Color color;
  final double phase;
  final double lineStep;
  final double lineHeight;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color;
    final offset = (phase * 24) % 24;
    for (var y = -offset; y < size.height; y += lineStep) {
      canvas.drawRect(Rect.fromLTWH(0, y, size.width, lineHeight), paint);
    }
  }

  @override
  bool shouldRepaint(covariant _ScanLinePainter oldDelegate) =>
      oldDelegate.color != color ||
      oldDelegate.phase != phase ||
      oldDelegate.lineStep != lineStep ||
      oldDelegate.lineHeight != lineHeight;
}
