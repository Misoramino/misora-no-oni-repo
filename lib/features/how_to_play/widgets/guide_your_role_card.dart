import 'package:flutter/material.dart';

import '../../../game/player_role.dart';
import '../../../game/role_briefing.dart';
import '../../game_map/widgets/role_briefing_dialog.dart';
import '../guide_terms.dart';

/// 作戦マニュアル冒頭：自分の役職向けクイックリファレンス。
class GuideYourRoleCard extends StatelessWidget {
  const GuideYourRoleCard({
    required this.role,
    super.key,
  });

  final PlayerRole role;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final accent = roleAccentColor(role);
    final start = RoleBriefingCatalog.matchStartBriefing(role);
    final roleLabel = switch (role) {
      PlayerRole.hunter => GuideTerms.trueOni,
      _ => role.displayName,
    };

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: accent.withValues(alpha: 0.10),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(roleIcon(role), color: accent),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'この試合のあなた — $roleLabel',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: accent,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              start.winLine,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text('まずこれだけ', style: theme.textTheme.labelMedium),
            const SizedBox(height: 4),
            for (final item in start.mustKnow)
              Padding(
                padding: const EdgeInsets.only(left: 4, bottom: 4),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.chevron_right_rounded, size: 18, color: accent),
                    Expanded(
                      child: Text(
                        item,
                        style: theme.textTheme.bodySmall?.copyWith(height: 1.4),
                      ),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 4),
            Text(
              'くわしい操作は「役職」章の下にまとめています。',
              style: theme.textTheme.labelSmall?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
