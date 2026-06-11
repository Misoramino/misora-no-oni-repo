import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../features/onboarding/welcome_flow.dart';
import '../../../features/onboarding/onboarding_replay_sheet.dart';
import '../../../features/tutorial/tutorial_entry.dart';
import '../../../game/player_role.dart';
import '../../../game/role_briefing.dart';
import '../../../game/skill_catalog.dart';
import 'how_to_play_diagrams.dart';
import 'role_briefing_dialog.dart';

/// 遊び方の説明ボトムシート。
void showHowToPlaySheet(
  BuildContext context, {
  PlayerRole? yourRole,
  bool prepPhase = false,
}) {
  showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
      builder: (sheetCtx) => DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.82,
      minChildSize: 0.45,
      maxChildSize: 0.95,
      builder: (_, scrollController) {
        final otherRoles = PlayerRole.values
            .where((r) => r != yourRole)
            .toList(growable: false);
        return ListView(
          controller: scrollController,
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          children: [
            Text('遊び方', style: Theme.of(sheetCtx).textTheme.titleLarge),
            if (prepPhase) ...[
              const SizedBox(height: 10),
              Material(
                color: Theme.of(sheetCtx).colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(10),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        color: Theme.of(sheetCtx).colorScheme.primary,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'いまは準備中 — 「プレイエリア」「基本ルール」の章がおすすめです。',
                          style: Theme.of(sheetCtx).textTheme.bodySmall,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
            const SizedBox(height: 8),
            Text(
              '章を開いて読めます。初めての方は「かんたんガイド」から。',
              style: Theme.of(sheetCtx).textTheme.bodySmall?.copyWith(
                    color: Theme.of(sheetCtx).colorScheme.onSurfaceVariant,
                  ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                FilledButton.tonalIcon(
                  onPressed: () {
                    Navigator.pop(sheetCtx);
                    showWelcomeFlow(context);
                  },
                  icon: const Icon(Icons.auto_awesome_rounded),
                  label: const Text('かんたんガイド'),
                ),
                FilledButton.icon(
                  onPressed: () {
                    Navigator.pop(sheetCtx);
                    openTutorialPicker(context);
                  },
                  icon: const Icon(Icons.school_rounded),
                  label: const Text('チュートリアル'),
                ),
                OutlinedButton.icon(
                  onPressed: () {
                    Navigator.pop(sheetCtx);
                    showOnboardingReplaySheet(context);
                  },
                  icon: const Icon(Icons.replay_rounded),
                  label: const Text('ガイド再視聴'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _HelpExpansion(
              icon: Icons.flag_outlined,
              title: '基本ルール',
              initiallyExpanded: true,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const HelpFlowDiagram(
                    steps: [
                      (icon: Icons.groups_outlined, label: '準備', color: null),
                      (icon: Icons.play_circle, label: '開始', color: null),
                      (icon: Icons.map_outlined, label: '逃走', color: null),
                      (icon: Icons.emoji_events, label: '勝敗', color: null),
                    ],
                  ),
                  Text(
                    SkillCatalog.coreRule,
                    style: Theme.of(sheetCtx).textTheme.bodyMedium?.copyWith(
                          height: 1.45,
                        ),
                  ),
                ],
              ),
            ),
            _HelpExpansion(
              icon: Icons.emoji_events_outlined,
              title: '勝利と陣営',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const HelpFactionDiagram(),
                  Text(
                    RoleBriefingCatalog.winConditions.trim(),
                    style: Theme.of(sheetCtx).textTheme.bodyMedium?.copyWith(
                          height: 1.45,
                        ),
                  ),
                ],
              ),
            ),
            _HelpExpansion(
              icon: Icons.route_outlined,
              title: '1 試合の流れ',
              child: Text(
                SkillCatalog.matchFlow,
                style: Theme.of(sheetCtx).textTheme.bodyMedium?.copyWith(height: 1.45),
              ),
            ),
            _HelpExpansion(
              icon: Icons.map_outlined,
              title: 'プレイエリアとマップ',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const HelpMapConceptDiagram(),
                  Text(
                    SkillCatalog.playAreaGuide,
                    style: Theme.of(sheetCtx).textTheme.bodyMedium?.copyWith(
                          height: 1.45,
                        ),
                  ),
                ],
              ),
            ),
            _HelpExpansion(
              icon: Icons.touch_app_outlined,
              title: 'スキルの置き方',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const HelpFlowDiagram(
                    steps: [
                      (icon: Icons.bolt, label: 'スキル\nを押す', color: null),
                      (
                        icon: Icons.pan_tool_alt_outlined,
                        label: '地図を\n押し続け',
                        color: null,
                      ),
                      (
                        icon: Icons.check_circle_outline,
                        label: '指を離して\n設置',
                        color: null,
                      ),
                    ],
                  ),
                  Text(
                    SkillCatalog.mapSkillPlacementGuide,
                    style: Theme.of(sheetCtx).textTheme.bodyMedium?.copyWith(
                          height: 1.45,
                        ),
                  ),
                ],
              ),
            ),
            if (yourRole != null)
              _HelpExpansion(
                icon: Icons.person_pin_circle_outlined,
                title: 'あなたの役職 — ${yourRole.displayName}',
                initiallyExpanded: true,
                child: roleBriefingBlock(sheetCtx, yourRole, emphasized: true),
              ),
            _HelpExpansion(
              icon: Icons.groups_outlined,
              title: yourRole != null ? 'ほかの役職' : '役職一覧',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (final role
                      in yourRole != null ? otherRoles : PlayerRole.values)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: roleBriefingBlock(sheetCtx, role),
                    ),
                ],
              ),
            ),
            _HelpExpansion(
              icon: Icons.scatter_plot_outlined,
              title: 'マップ・ギミック',
              child: Column(
                children: [
                  for (final g in SkillCatalog.gimmicks)
                    _compactEntry(sheetCtx, g.title, g.body, _iconFor(g.iconName)),
                ],
              ),
            ),
            _HelpExpansion(
              icon: Icons.cloud_sync_outlined,
              title: 'オンライン',
              child: Text(
                'ホストが開始・終了すると役職・エリア・ギミックも同期します。'
                '試合中止は投票で決まります。',
                style: Theme.of(sheetCtx).textTheme.bodyMedium?.copyWith(height: 1.45),
              ),
            ),
          ],
        );
      },
    ),
  );
}

class _HelpExpansion extends StatelessWidget {
  const _HelpExpansion({
    required this.icon,
    required this.title,
    required this.child,
    this.initiallyExpanded = false,
  });

  final IconData icon;
  final String title;
  final Widget child;
  final bool initiallyExpanded;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      clipBehavior: Clip.antiAlias,
      child: ExpansionTile(
        initiallyExpanded: initiallyExpanded,
        leading: Icon(icon, color: Theme.of(context).colorScheme.primary),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        expandedCrossAxisAlignment: CrossAxisAlignment.stretch,
        children: [child],
      ),
    );
  }
}

Widget _compactEntry(
  BuildContext ctx,
  String title,
  String body,
  IconData icon,
) {
  return Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: Theme.of(ctx).colorScheme.primary),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: Theme.of(ctx).textTheme.titleSmall),
              const SizedBox(height: 2),
              Text(
                body,
                style: Theme.of(ctx).textTheme.bodySmall?.copyWith(height: 1.4),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

IconData _iconFor(String name) => switch (name) {
      'scatter_plot' => Icons.scatter_plot_outlined,
      'psychology_alt' => Icons.psychology_alt_outlined,
      'near_me' => Icons.near_me_outlined,
      'trip_origin' => Icons.trip_origin_outlined,
      'nightlight' => Icons.nightlight_outlined,
      'shield' => Icons.shield_outlined,
      'storefront' => Icons.storefront_outlined,
      'videocam' => Icons.videocam_outlined,
      'bubble_chart' => Icons.bubble_chart_outlined,
      'front_hand' => Icons.front_hand_outlined,
      'schedule' => Icons.schedule_outlined,
      _ => Icons.help_outline,
    };
