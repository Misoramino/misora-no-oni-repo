import 'package:flutter/material.dart';

import '../../../game/player_role.dart';
import '../../../game/role_briefing.dart';
import '../../../game/skill_catalog.dart';
import '../../../game/werewolf_faction_logic.dart';

/// 試合開始時: 役職の要点だけを短く伝えるダイアログ。
Future<void> showRoleBriefingDialog(
  BuildContext context, {
  required PlayerRole role,
  required List<String> skillLabels,
  FactionSide? werewolfCurrentFaction,
}) {
  final start = RoleBriefingCatalog.matchStartBriefing(
    role,
    werewolfFaction: werewolfCurrentFaction,
  );
  return showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (ctx) {
      final theme = Theme.of(ctx);
      final scheme = theme.colorScheme;
      return AlertDialog(
        title: Row(
          children: [
            Icon(_iconForRole(role), color: scheme.primary),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'あなたは${role.displayName}',
                style: theme.textTheme.titleLarge,
              ),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                start.tagline,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: scheme.primary,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                start.winLine,
                style: theme.textTheme.bodyLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 14),
              Text('まず意識すること', style: theme.textTheme.labelLarge),
              const SizedBox(height: 6),
              for (final item in start.mustKnow)
                Padding(
                  padding: const EdgeInsets.only(left: 4, bottom: 6),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('・', style: theme.textTheme.bodyMedium),
                      Expanded(
                        child: Text(item, style: theme.textTheme.bodyMedium),
                      ),
                    ],
                  ),
                ),
              if (skillLabels.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text('使えるスキル', style: theme.textTheme.labelLarge),
                const SizedBox(height: 4),
                Text(
                  skillLabels.join(' / '),
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
              const SizedBox(height: 12),
              Text(
                start.learnMoreHint,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: scheme.onSurfaceVariant,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ),
        ),
        actions: [
          FilledButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('了解 — 始める'),
          ),
        ],
      );
    },
  );
}

IconData _iconForRole(PlayerRole role) => switch (role) {
      PlayerRole.runner => Icons.directions_run_outlined,
      PlayerRole.hunter => Icons.nightlight_round,
      PlayerRole.werewolf => Icons.psychology_alt_outlined,
    };

/// 遊び方シート用: 役職ブロック（詳細＋スキル）。
Widget roleBriefingBlock(
  BuildContext ctx,
  PlayerRole role, {
  bool emphasized = false,
}) {
  final briefing = RoleBriefingCatalog.forRole(role);
  final theme = Theme.of(ctx);
  final scheme = theme.colorScheme;
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      if (!emphasized)
        Padding(
          padding: const EdgeInsets.only(top: 12, bottom: 4),
          child: Text(
            role.displayName,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      if (emphasized)
        Material(
          color: scheme.primaryContainer.withValues(alpha: 0.35),
          borderRadius: BorderRadius.circular(10),
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  role.displayName,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: scheme.onPrimaryContainer,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'この試合のあなた向け。くわしい操作・スキルは下にまとめています。',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ),
      if (emphasized) const SizedBox(height: 8),
      Text(
        briefing.headline,
        style: theme.textTheme.bodyMedium?.copyWith(
          color: theme.colorScheme.primary,
          fontWeight: FontWeight.w600,
        ),
      ),
      const SizedBox(height: 4),
      Text(briefing.factionLine, style: theme.textTheme.bodySmall),
      const SizedBox(height: 6),
      Text('目指すこと', style: theme.textTheme.labelMedium),
      for (final g in briefing.goals)
        Padding(
          padding: const EdgeInsets.only(left: 8, top: 2),
          child: Text('・$g', style: theme.textTheme.bodySmall),
        ),
      const SizedBox(height: 6),
      Text('やること', style: theme.textTheme.labelMedium),
      for (final a in briefing.actions)
        Padding(
          padding: const EdgeInsets.only(left: 8, top: 2),
          child: Text('・$a', style: theme.textTheme.bodySmall),
        ),
      if (briefing.notes.isNotEmpty) ...[
        const SizedBox(height: 6),
        Text('Tips', style: theme.textTheme.labelMedium),
        for (final n in briefing.notes)
          Padding(
            padding: const EdgeInsets.only(left: 8, top: 2),
            child: Text(
              '※ $n',
              style: theme.textTheme.bodySmall?.copyWith(
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
      ],
      const SizedBox(height: 6),
      Text('スキル詳細', style: theme.textTheme.labelMedium),
      for (final e in SkillCatalog.entriesForRole(role))
        ListTile(
          dense: true,
          contentPadding: const EdgeInsets.only(left: 0),
          leading: const Icon(Icons.circle, size: 8),
          title: Text(e.title, style: theme.textTheme.bodySmall),
          subtitle: Text(e.body, style: theme.textTheme.bodySmall),
          isThreeLine: e.body.length > 60,
        ),
    ],
  );
}
