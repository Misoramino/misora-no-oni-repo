import 'package:flutter/material.dart';

import '../../../presentation/world/world_presentation_catalog.dart';
import '../../../theme/world_profile.dart';

/// 体投げなど、スキルフェーズの案内バナー（カウントダウン任意）。
class SkillTimerHud extends StatelessWidget {
  const SkillTimerHud({
    required this.phaseLabel,
    this.secondsLeft,
    this.totalSeconds,
    this.hint,
    this.accent,
    this.surfaceColor,
    this.worldProfile,
    super.key,
  });

  final String phaseLabel;
  final int? secondsLeft;
  final int? totalSeconds;
  final String? hint;
  final Color? accent;
  final Color? surfaceColor;
  final WorldProfile? worldProfile;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final pack =
        worldProfile != null ? WorldPresentationCatalog.of(worldProfile!) : null;
    final color = accent ?? pack?.accent ?? scheme.primary;
    final surface = surfaceColor ??
        (pack != null
            ? Color.alphaBlend(
                pack.accent.withValues(alpha: 0.10),
                pack.panelSurface.withValues(alpha: 0.94),
              )
            : scheme.surface.withValues(alpha: 0.94));
    final titleColor = pack?.textOnPanel ?? scheme.onSurface;
    final hintColor = pack?.mutedOnPanel ?? const Color(0xFF424242);
    final radius = pack?.hudCornerRadius ?? 16.0;
    final showCountdown =
        secondsLeft != null && totalSeconds != null && totalSeconds! > 0;
    final left = secondsLeft ?? 0;
    final progress = showCountdown
        ? (left / totalSeconds!).clamp(0.0, 1.0)
        : 0.0;
    final urgent = showCountdown && left <= 5;

    return Material(
      color: surface,
      elevation: urgent ? 8 : 4,
      shadowColor: color.withValues(alpha: 0.25),
      borderRadius: BorderRadius.circular(radius),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(radius),
          border: Border.all(
            color: urgent
                ? color
                : (pack?.panelBorder.withValues(alpha: 0.55) ??
                    scheme.outlineVariant),
            width: urgent ? 2 : 1,
          ),
        ),
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
        child: Row(
          children: [
            if (showCountdown) ...[
              SizedBox(
                width: 52,
                height: 52,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    CircularProgressIndicator(
                      value: progress,
                      strokeWidth: 4,
                      backgroundColor: color.withValues(alpha: 0.15),
                      color: urgent ? scheme.error : color,
                    ),
                    Text(
                      '$left',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: urgent ? scheme.error : titleColor,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
            ] else
              Padding(
                padding: const EdgeInsets.only(right: 10),
                child: Icon(Icons.sports_martial_arts, color: color, size: 28),
              ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    phaseLabel,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: titleColor,
                    ),
                  ),
                  if (hint != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      hint!,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: hintColor,
                        height: 1.35,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
