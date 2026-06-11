import 'package:flutter/material.dart';

import '../../../game/player_role.dart';
import '../../../game/skill_catalog.dart';
import 'how_to_play_content.dart';
import 'how_to_play_diagrams.dart';
import 'role_briefing_dialog.dart';

/// 遊び方の説明ボトムシート（ゲームプレイに集中。準備・エリア編集は含めない）。
void showHowToPlaySheet(
  BuildContext context, {
  PlayerRole? yourRole,
}) {
  showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (sheetCtx) => DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.85,
      minChildSize: 0.45,
      maxChildSize: 0.95,
      builder: (_, scrollController) {
        final otherRoles = PlayerRole.values
            .where((r) => r != yourRole)
            .toList(growable: false);
        final gimmicks = SkillCatalog.gimmicks
            .where(
              (g) =>
                  g.id != 'runner_analyst' && g.id != 'runner_hacker',
            )
            .toList(growable: false);

        return ListView(
          controller: scrollController,
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
          children: [
            Text('遊び方', style: Theme.of(sheetCtx).textTheme.titleLarge),
            const SizedBox(height: 8),
            Text(
              'ゲーム中のルールと役職の説明です。'
              '準備画面やエリア編集は、準備画面のコーチマークをご覧ください。',
              style: Theme.of(sheetCtx).textTheme.bodySmall?.copyWith(
                    color: Theme.of(sheetCtx).colorScheme.onSurfaceVariant,
                    height: 1.4,
                  ),
            ),
            const SizedBox(height: 12),
            _HelpExpansion(
              icon: Icons.info_outline,
              title: 'このゲームについて',
              initiallyExpanded: true,
              child: _bodyText(sheetCtx, HowToPlayContent.intro),
            ),
            _HelpExpansion(
              icon: Icons.emoji_events_outlined,
              title: '勝ち方・負け方',
              initiallyExpanded: true,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const HelpFactionDiagram(),
                  _bodyText(sheetCtx, HowToPlayContent.winConditions),
                ],
              ),
            ),
            _HelpExpansion(
              icon: Icons.route_outlined,
              title: '1試合の流れ',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const HelpFlowDiagram(
                    steps: [
                      (icon: Icons.play_circle, label: '開始', color: null),
                      (icon: Icons.map_outlined, label: '逃走', color: null),
                      (icon: Icons.front_hand, label: '捕獲', color: null),
                      (icon: Icons.emoji_events, label: '勝敗', color: null),
                    ],
                  ),
                  _bodyText(sheetCtx, HowToPlayContent.matchFlow),
                ],
              ),
            ),
            _HelpExpansion(
              icon: Icons.radar_outlined,
              title: '位置情報のルール',
              child: _bodyText(sheetCtx, HowToPlayContent.positionRules),
            ),
            _HelpExpansion(
              icon: Icons.warning_amber_outlined,
              title: 'プレイエリア外',
              child: _bodyText(sheetCtx, HowToPlayContent.outsideAreaRules),
            ),
            _HelpExpansion(
              icon: Icons.touch_app_outlined,
              title: 'スキルの置き方',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const HelpFlowDiagram(
                    steps: [
                      (icon: Icons.bolt, label: 'スキル', color: null),
                      (
                        icon: Icons.pan_tool_alt_outlined,
                        label: '長押し',
                        color: null,
                      ),
                      (
                        icon: Icons.check_circle_outline,
                        label: '離して設置',
                        color: null,
                      ),
                    ],
                  ),
                  _bodyText(sheetCtx, HowToPlayContent.mapSkillPlacement),
                ],
              ),
            ),
            _HelpExpansion(
              icon: Icons.bolt_outlined,
              title: '第二ゲーム（残響体・復讐の鬼影）',
              initiallyExpanded: yourRole != null,
              child: _bodyText(sheetCtx, HowToPlayContent.secondGame),
            ),
            _HelpExpansion(
              icon: Icons.account_balance_outlined,
              title: '告発施設',
              child: _bodyText(sheetCtx, HowToPlayContent.accusationRules),
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
              title: 'マップのギミック',
              child: Column(
                children: [
                  for (final g in gimmicks)
                    _compactEntry(
                      sheetCtx,
                      g.title,
                      g.body,
                      _iconFor(g.iconName),
                    ),
                ],
              ),
            ),
            _HelpExpansion(
              icon: Icons.cloud_sync_outlined,
              title: 'オンライン',
              child: _bodyText(sheetCtx, HowToPlayContent.onlineBrief),
            ),
          ],
        );
      },
    ),
  );
}

Widget _bodyText(BuildContext ctx, String text) {
  return Text(
    text.trim(),
    style: Theme.of(ctx).textTheme.bodyMedium?.copyWith(height: 1.55),
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
    padding: const EdgeInsets.only(bottom: 12),
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
              const SizedBox(height: 4),
              Text(
                body,
                style: Theme.of(ctx).textTheme.bodySmall?.copyWith(height: 1.45),
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
      'account_balance' => Icons.account_balance_outlined,
      'timeline' => Icons.timeline_outlined,
      'place' => Icons.place_outlined,
      _ => Icons.help_outline,
    };
