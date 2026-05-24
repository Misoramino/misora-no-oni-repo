import 'package:flutter/material.dart';

import '../../../game/player_role.dart';
import '../../../game/role_briefing.dart';
import '../../../game/skill_catalog.dart';
import '../../../game/werewolf_faction_logic.dart';

/// 試合開始時: 自分の役職・目標・スキルを伝えるダイアログ。
Future<void> showRoleBriefingDialog(
  BuildContext context, {
  required PlayerRole role,
  required List<String> skillLabels,
  FactionSide? werewolfCurrentFaction,
}) {
  final briefing = RoleBriefingCatalog.forRole(role);
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
                briefing.headline,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: scheme.primary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                briefing.factionLine,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (role == PlayerRole.werewolf &&
                  werewolfCurrentFaction != null) ...[
                const SizedBox(height: 6),
                Text(
                  'この試合のあなたの陣営: ${werewolfCurrentFaction.label}',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: scheme.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
              const SizedBox(height: 12),
              _section(ctx, '目指すこと', briefing.goals),
              const SizedBox(height: 10),
              _section(ctx, 'やること', briefing.actions),
              if (skillLabels.isNotEmpty) ...[
                const SizedBox(height: 10),
                Text('装備スキル', style: theme.textTheme.labelLarge),
                const SizedBox(height: 4),
                Text(skillLabels.join(' / '), style: theme.textTheme.bodyMedium),
              ],
              if (briefing.notes.isNotEmpty) ...[
                const SizedBox(height: 10),
                _section(ctx, '覚えておくこと', briefing.notes),
              ],
            ],
          ),
        ),
        actions: [
          FilledButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('了解 — 試合開始'),
          ),
        ],
      );
    },
  );
}

Widget _section(BuildContext ctx, String title, List<String> items) {
  final theme = Theme.of(ctx);
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(title, style: theme.textTheme.labelLarge),
      const SizedBox(height: 4),
      for (final item in items)
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 4),
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
    ],
  );
}

IconData _iconForRole(PlayerRole role) => switch (role) {
      PlayerRole.runner => Icons.directions_run_outlined,
      PlayerRole.hunter => Icons.nightlight_round,
      PlayerRole.werewolf => Icons.psychology_alt_outlined,
    };

/// 遊び方シート用: 役職ブロック（目標＋スキル詳細）。
Widget roleBriefingBlock(BuildContext ctx, PlayerRole role) {
  final briefing = RoleBriefingCatalog.forRole(role);
  final theme = Theme.of(ctx);
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Padding(
        padding: const EdgeInsets.only(top: 12, bottom: 4),
        child: Text(
          role.displayName,
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
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
