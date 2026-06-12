import 'package:flutter/material.dart';

/// 体投げの設置猶予・発動中など、スキル系の残り時間表示。
class SkillTimerHud extends StatelessWidget {
  const SkillTimerHud({
    required this.phaseLabel,
    required this.secondsLeft,
    required this.totalSeconds,
    this.hint,
    this.accent,
    super.key,
  });

  final String phaseLabel;
  final int secondsLeft;
  final int totalSeconds;
  final String? hint;
  final Color? accent;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final color = accent ?? Colors.deepOrange.shade700;
    final progress = totalSeconds <= 0
        ? 0.0
        : (secondsLeft / totalSeconds).clamp(0.0, 1.0);
    final urgent = secondsLeft <= 5;

    return Material(
      color: scheme.surface.withValues(alpha: 0.94),
      elevation: urgent ? 8 : 4,
      shadowColor: color.withValues(alpha: 0.35),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: urgent ? color : scheme.outlineVariant,
            width: urgent ? 2 : 1,
          ),
        ),
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
        child: Row(
          children: [
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
                    '$secondsLeft',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: urgent ? scheme.error : scheme.onSurface,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    phaseLabel,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: color,
                    ),
                  ),
                  if (hint != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      hint!,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: scheme.onSurfaceVariant,
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
