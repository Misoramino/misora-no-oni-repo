import 'package:flutter/material.dart';

import '../../../game/player_role.dart';
import '../../../game/role_briefing.dart';
import '../../../game/runner_modifier.dart';
import '../../../game/skill_catalog.dart';
import '../../../game/werewolf_faction_logic.dart';
import '../../how_to_play/guide_text.dart';
import '../../../presentation/world/world_presentation_catalog.dart';
import '../../../presentation/world/world_presentation_context.dart';
import '../../../theme/world_profile.dart';
import '../../../widgets/app_dialog.dart';
import '../../tutorial/tutorial_entry.dart';
import 'how_to_play_sheet.dart';

/// 試合開始時: 役職の要点だけを短く伝える演出付きダイアログ。
Future<void> showRoleBriefingDialog(
  BuildContext context, {
  required PlayerRole role,
  required List<String> skillLabels,
  WorldProfile? worldProfile,
  FactionSide? werewolfCurrentFaction,
  RunnerModifier runnerModifier = RunnerModifier.none,
}) {
  final start = RoleBriefingCatalog.matchStartBriefing(
    role,
    werewolfFaction: werewolfCurrentFaction,
    runnerModifier: runnerModifier,
  );
  final roleAccent = roleAccentColor(role);
  final profile = worldProfile ?? context.worldProfile;
  final pack = WorldPresentationCatalog.of(profile);
  final accent = Color.lerp(pack.accent, roleAccent, 0.45)!;
  final bodyColor = pack.textOnPanel;
  final mutedBody = bodyColor.withValues(alpha: 0.72);
  return showAppDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (ctx) {
      final theme = Theme.of(ctx);
      final scheme = theme.colorScheme;
      return AppDialog(
        title: 'あなたは${role.displayName}',
        icon: roleIcon(role),
        accent: accent,
        actions: [
          AppDialogAction(
            label: '了解して開始',
            filled: true,
            icon: Icons.play_arrow_rounded,
            onPressed: () => Navigator.pop(ctx),
          ),
        ],
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              start.tagline,
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: accent,
              ),
            ),
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: accent.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: accent.withValues(alpha: 0.30)),
              ),
              child: Row(
                children: [
                  Icon(Icons.flag_rounded, size: 18, color: accent),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      start.winLine,
                      style: theme.textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: bodyColor,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            Text(
              'まず意識すること',
              style: theme.textTheme.labelLarge?.copyWith(color: bodyColor),
            ),
            const SizedBox(height: 6),
            for (final item in start.mustKnow)
              Padding(
                padding: const EdgeInsets.only(left: 4, bottom: 6),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.chevron_right_rounded,
                        size: 18, color: accent),
                    Expanded(
                      child: Text(
                        item,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: bodyColor,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            if (skillLabels.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                '使えるスキル',
                style: theme.textTheme.labelLarge?.copyWith(color: bodyColor),
              ),
              const SizedBox(height: 6),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  for (final s in skillLabels)
                    Chip(
                      label: Text(s),
                      visualDensity: VisualDensity.compact,
                      backgroundColor: scheme.secondaryContainer,
                      side: BorderSide.none,
                    ),
                ],
              ),
            ],
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                style: FilledButton.styleFrom(
                  backgroundColor: accent,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                onPressed: () async {
                  await openTutorialPicker(context);
                },
                icon: const Icon(Icons.school_rounded),
                label: const Text('1分チュートリアルで練習する'),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'スキル操作はチュートリアルで本番と同じ流れを体験できます。',
              style: theme.textTheme.bodySmall?.copyWith(
                color: mutedBody,
              ),
            ),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: () {
                  final host = context;
                  Navigator.pop(ctx);
                  showHowToPlaySheet(
                    host,
                    yourRole: role,
                    initialSectionId: 'roles',
                  );
                },
                icon: const Icon(Icons.menu_book_outlined, size: 18),
                label: const Text('遊び方を見る'),
              ),
            ),
            Text(
              GuideText.forDisplay(start.learnMoreHint),
              style: theme.textTheme.bodySmall?.copyWith(
                color: mutedBody,
              ),
            ),
          ],
        ),
      );
    },
  );
}

/// 役職のシンボルアイコン（ダイアログ・ウェルカム共通）。
IconData roleIcon(PlayerRole role) => switch (role) {
      PlayerRole.runner => Icons.directions_run_rounded,
      PlayerRole.hunter => Icons.nightlight_round,
      PlayerRole.werewolf => Icons.psychology_alt_rounded,
    };

/// 役職のアクセント色（逃走=青緑 / 鬼=赤 / 人狼=紫）。
Color roleAccentColor(PlayerRole role) => switch (role) {
      PlayerRole.runner => const Color(0xFF1FA98A),
      PlayerRole.hunter => const Color(0xFFD64545),
      PlayerRole.werewolf => const Color(0xFF8E5BD8),
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
