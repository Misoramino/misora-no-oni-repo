import 'package:flutter/material.dart';

import '../../../game/elimination_aftermath_rule.dart';
import '../../../theme/elimination_role_copy.dart';
import '../../../theme/world_profile.dart';

/// 脱落後の操作バー（残響体ジャック / 観戦 / 鬼合流など）。
class EliminationSupportBar extends StatelessWidget {
  const EliminationSupportBar({
    required this.rule,
    required this.worldProfile,
    required this.onOpenResult,
    this.chargeProgress,
    this.chargeActive = false,
    this.matchJackUses = 0,
    this.matchJackLimit = 5,
    this.personalCooldownSeconds,
    this.statusLine,
    super.key,
  });

  final EliminationAftermathRule rule;
  final WorldProfile worldProfile;
  final VoidCallback onOpenResult;
  final double? chargeProgress;
  final bool chargeActive;
  final int matchJackUses;
  final int matchJackLimit;
  final int? personalCooldownSeconds;
  final String? statusLine;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final copy = EliminationRoleCopy.forProfile(worldProfile, rule);
    return Material(
      elevation: 4,
      borderRadius: BorderRadius.circular(12),
      color: theme.colorScheme.primaryContainer.withValues(alpha: 0.94),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(
                  rule.supportsCameraJack
                      ? Icons.sensors
                      : Icons.visibility_outlined,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(copy.roleTitle, style: theme.textTheme.titleSmall),
                      Text(
                        copy.roleSubtitle,
                        style: theme.textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
                TextButton(
                  onPressed: onOpenResult,
                  child: const Text('リザルト'),
                ),
              ],
            ),
            if (rule.supportsCameraJack) ...[
              const SizedBox(height: 8),
              Text(
                '${copy.jackSiteLabel} — 試合 $matchJackUses / $matchJackLimit 回',
                style: theme.textTheme.labelMedium,
              ),
              if (chargeActive && chargeProgress != null) ...[
                const SizedBox(height: 6),
                LinearProgressIndicator(value: chargeProgress),
                Text(
                  '${copy.jackActionLabel}… ${(chargeProgress! * 100).round()}%',
                  style: theme.textTheme.bodySmall,
                ),
              ] else if (personalCooldownSeconds != null &&
                  personalCooldownSeconds! > 0)
                Text(
                  '個人CD: あと ${personalCooldownSeconds}s',
                  style: theme.textTheme.bodySmall,
                ),
            ],
            if (statusLine != null && statusLine!.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(statusLine!, style: theme.textTheme.bodySmall),
            ],
          ],
        ),
      ),
    );
  }
}
