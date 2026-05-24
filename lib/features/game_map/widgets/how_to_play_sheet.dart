import 'package:flutter/material.dart';

import '../../../game/player_role.dart';
import '../../../game/role_briefing.dart';
import '../../../game/skill_catalog.dart';
import 'role_briefing_dialog.dart';

/// 遊び方の説明ボトムシート。
void showHowToPlaySheet(BuildContext context) {
  showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (ctx) => DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.85,
      minChildSize: 0.45,
      maxChildSize: 0.95,
      builder: (context, scrollController) {
        return ListView(
          controller: scrollController,
          padding: const EdgeInsets.all(16),
          children: [
            Text('遊び方', style: Theme.of(ctx).textTheme.titleLarge),
            const SizedBox(height: 8),
            Text(
              SkillCatalog.coreRule,
              style: Theme.of(ctx).textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
            _sectionTitle(ctx, '勝利と陣営'),
            _helpTile(
              ctx,
              RoleBriefingCatalog.winConditions.trim(),
              icon: Icons.emoji_events_outlined,
            ),
            const SizedBox(height: 12),
            _sectionTitle(ctx, '流れ'),
            _helpTile(ctx, SkillCatalog.matchFlow, icon: Icons.flag_outlined),
            const SizedBox(height: 12),
            _sectionTitle(ctx, '役職 — 目指すこと・やること'),
            roleBriefingBlock(ctx, PlayerRole.runner),
            roleBriefingBlock(ctx, PlayerRole.hunter),
            roleBriefingBlock(ctx, PlayerRole.werewolf),
            const SizedBox(height: 12),
            _sectionTitle(ctx, 'マップ・ルール'),
            for (final g in SkillCatalog.gimmicks) _entryTile(ctx, g),
            const SizedBox(height: 12),
            _sectionTitle(ctx, 'オンライン'),
            _helpTile(
              ctx,
              'ホストが開始・終了すると役職・エリア・ギミック（イベントエリア含む）も同期します。'
              '試合中止は投票で決まります。',
              icon: Icons.cloud_sync_outlined,
            ),
            const SizedBox(height: 24),
          ],
        );
      },
    ),
  );
}

Widget _sectionTitle(BuildContext ctx, String text) {
  return Padding(
    padding: const EdgeInsets.only(bottom: 6),
    child: Text(text, style: Theme.of(ctx).textTheme.titleSmall),
  );
}

Widget _helpTile(
  BuildContext ctx,
  String body, {
  String? title,
  IconData? icon,
}) {
  return ListTile(
    leading: icon != null ? Icon(icon) : null,
    title: title != null ? Text(title) : null,
    subtitle: Text(body),
    isThreeLine: body.length > 72,
  );
}

Widget _entryTile(BuildContext ctx, SkillHelpEntry e) {
  return _helpTile(ctx, e.body, title: e.title, icon: _iconFor(e.iconName));
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
