import 'package:flutter/material.dart';

import '../../../theme/world_fx_profile.dart';

/// 決定的瞬間の短いバナー（FOUND / SIGNAL DETECTED など）。
class WorldMomentBanner extends StatelessWidget {
  const WorldMomentBanner({
    required this.fx,
    required this.kind,
    super.key,
  });

  final WorldFxProfile fx;
  final WorldMomentKind kind;

  @override
  Widget build(BuildContext context) {
    final text = fx.bannerFor(kind);
    if (text.isEmpty) return const SizedBox.shrink();

    final theme = Theme.of(context);
    final accent = _accentFor(fx.revealFlashStyle);
    final subtle = kind == WorldMomentKind.anonReveal;

    return IgnorePointer(
      child: Center(
        child: AnimatedOpacity(
          opacity: 1,
          duration: const Duration(milliseconds: 120),
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 28),
            padding: EdgeInsets.symmetric(
              horizontal: subtle ? 14 : 18,
              vertical: subtle ? 8 : 10,
            ),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: subtle ? 0.42 : 0.55),
              borderRadius: BorderRadius.circular(subtle ? 10 : 12),
              border: Border.all(
                color: accent.withValues(alpha: subtle ? 0.35 : 0.65),
                width: subtle ? 1 : 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: accent.withValues(alpha: subtle ? 0.12 : 0.28),
                  blurRadius: subtle ? 12 : 22,
                ),
              ],
            ),
            child: Text(
              text,
              textAlign: TextAlign.center,
              style: (subtle
                      ? theme.textTheme.labelLarge
                      : theme.textTheme.titleMedium)
                  ?.copyWith(
                color: accent.withValues(alpha: subtle ? 0.85 : 1),
                fontWeight: subtle ? FontWeight.w600 : FontWeight.w800,
                letterSpacing: subtle ? 1.0 : 2.2,
              ),
            ),
          ),
        ),
      ),
    );
  }

  static Color _accentFor(WorldRevealFlashStyle style) => switch (style) {
        WorldRevealFlashStyle.cyberCyanScan => const Color(0xFF00E5FF),
        WorldRevealFlashStyle.horrorVhs => const Color(0xFFB71C1C),
        WorldRevealFlashStyle.magicalSigil => const Color(0xFFE040FB),
        WorldRevealFlashStyle.astronomyOrbit => const Color(0xFFFFD54F),
        WorldRevealFlashStyle.tacticalBracket => const Color(0xFF90A4AE),
        WorldRevealFlashStyle.sportPop => const Color(0xFFFF4081),
        WorldRevealFlashStyle.japaneseGoldMist => const Color(0xFFC9A227),
        WorldRevealFlashStyle.westernGildedRecord => const Color(0xFFD4AF37),
      };
}
