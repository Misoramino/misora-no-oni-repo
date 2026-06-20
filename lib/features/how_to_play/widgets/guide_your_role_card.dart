import 'package:flutter/material.dart';

import '../../../game/player_role.dart';
import '../../../game/role_briefing.dart';
import '../../../presentation/world/world_legibility.dart';
import '../../game_map/widgets/role_briefing_dialog.dart';
import '../guide_terms.dart';

/// 作戦マニュアル冒頭：自分の役職の「目指すこと」だけ（詳細は役職章へ）。
class GuideYourRoleCard extends StatelessWidget {
  const GuideYourRoleCard({
    required this.role,
    super.key,
  });

  final PlayerRole role;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
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
              start.tagline,
              style: theme.textTheme.bodyMedium?.copyWith(height: 1.45),
            ),
            const SizedBox(height: 6),
            Text(
              start.winLine,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
                height: 1.45,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '装備スキルは「スキル」章、役職の要点は「役職」章、数値は「詳細ルール」章で確認できます。',
              style: theme.textTheme.labelSmall?.copyWith(
                color: context.worldMuted,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
