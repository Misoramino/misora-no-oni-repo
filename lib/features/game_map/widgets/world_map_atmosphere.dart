import 'package:flutter/material.dart';

import '../../../theme/world_fx_profile.dart';
import '../../../theme/world_profile.dart';
import '../../../theme/world_visual_pack.dart';
import 'reveal_noise_overlay.dart';
import 'vhs_overlay.dart';
import 'world_map_theme_painters.dart';
import 'world_moment_banner.dart';

/// 世界観ごとの地図上ビネット・reveal フラッシュ（軽量 overlay）。
class WorldMapAtmosphere extends StatelessWidget {
  const WorldMapAtmosphere({
    required this.pack,
    required this.dangerPulse,
    required this.revealFlashActive,
    this.scanPhase = 0,
    this.revealNoiseSeed = 0,
    this.momentKind,
    this.flashOpacityOverride,
    this.subduedOverlay = false,
    this.hideThemeOverlay = false,
    super.key,
  });

  final WorldVisualPack pack;
  final double dangerPulse;
  final bool revealFlashActive;
  final double scanPhase;
  final double revealNoiseSeed;
  final WorldMomentKind? momentKind;
  final double? flashOpacityOverride;
  final bool subduedOverlay;
  final bool hideThemeOverlay;

  WorldFxProfile get _fx => WorldFxCatalog.forProfile(pack.profile);

  @override
  Widget build(BuildContext context) {
    final vignette = pack.vignetteColor;
    final profile = pack.profile;
    final flash = _flashColor(pack, momentKind);
    final flashOpacity = flashOpacityOverride ??
        (momentKind != null
            ? _fx.flashOpacityFor(momentKind!)
            : (profile == WorldProfile.sport ? 0.5 : 0.55));
    final flashScale = pack.usePinBounceFlash && revealFlashActive ? 1.08 : 1.0;

    final vignetteScale = switch (profile) {
      WorldProfile.magical => 0.78,
      WorldProfile.astronomy => 0.82,
      WorldProfile.sport => 0.88,
      WorldProfile.japaneseLuxury => 0.72,
      WorldProfile.westernLuxury => 0.75,
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
    final useNoise = pack.useRevealNoise ||
        momentKind == WorldMomentKind.namedReveal &&
            _fx.revealFlashStyle == WorldRevealFlashStyle.horrorVhs;
    final overlayStrength = hideThemeOverlay
        ? 0.0
        : (subduedOverlay ? 0.28 : 1.0);

    return IgnorePointer(
      child: Stack(
        fit: StackFit.expand,
        children: [
          WorldMapThemeOverlay(
            profile: profile,
            phase: scanPhase,
            accent: pack.tokens.markerAccent,
            strength: overlayStrength,
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
                opacity: revealFlashActive ? flashOpacity : 0,
                duration: const Duration(milliseconds: 180),
                child: ColoredBox(color: flash),
              ),
            ),
          if (revealFlashActive && flash != null && useNoise)
            RevealNoiseOverlay(
              active: revealFlashActive,
              tint: flash,
              seed: revealNoiseSeed,
              grainBoost: revealGrain,
            ),
          if (momentKind != null && revealFlashActive)
            WorldMomentBanner(fx: _fx, kind: momentKind!),
          if (pack.useScanOverlay)
            CustomPaint(
              painter: _ScanLinePainter(
                color: pack.tokens.markerAccent.withValues(alpha: 0.095),
                phase: scanPhase,
              ),
            ),
          if (pack.useScanOverlay && profile == WorldProfile.sciFi && !subduedOverlay) ...[
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

  static Color? _flashColor(WorldVisualPack pack, WorldMomentKind? kind) {
    final base = pack.revealFlashColor;
    if (kind == null) return base;
    final fx = WorldFxCatalog.forProfile(pack.profile);
    return switch (kind) {
      WorldMomentKind.capture => switch (fx.captureFlashStyle) {
          WorldCaptureFlashStyle.cyberGlitch => const Color(0xCC00E5FF),
          WorldCaptureFlashStyle.horrorHeartbeat => const Color(0xCCB71C1C),
          WorldCaptureFlashStyle.magicalImpact => const Color(0xCCE040FB),
          WorldCaptureFlashStyle.astronomyCosmic => const Color(0xCCFFD54F),
          WorldCaptureFlashStyle.tacticalMuted => const Color(0x9955465A),
          WorldCaptureFlashStyle.sportWhistle => const Color(0xCCFF4081),
          WorldCaptureFlashStyle.japaneseInkImpact => const Color(0xCC5D4037),
          WorldCaptureFlashStyle.westernSealImpact => const Color(0xCC722F37),
        },
      WorldMomentKind.namedReveal => switch (fx.revealFlashStyle) {
          WorldRevealFlashStyle.cyberCyanScan => const Color(0xCC00E5FF),
          WorldRevealFlashStyle.horrorVhs => const Color(0xDDB71C1C),
          WorldRevealFlashStyle.magicalSigil => const Color(0xCCE040FB),
          WorldRevealFlashStyle.astronomyOrbit => const Color(0xCCFFD54F),
          WorldRevealFlashStyle.tacticalBracket => const Color(0xAA90A4AE),
          WorldRevealFlashStyle.sportPop => const Color(0xCCFF8FB3),
          WorldRevealFlashStyle.japaneseGoldMist => const Color(0xCCC9A227),
          WorldRevealFlashStyle.westernGildedRecord => const Color(0xCCD4AF37),
        },
      WorldMomentKind.anonReveal => base?.withValues(alpha: 0.65) ??
          const Color(0x88FFFFFF),
      _ => base,
    };
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
