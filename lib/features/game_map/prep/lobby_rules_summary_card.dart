import 'package:flutter/material.dart';

import '../../../game/match_setup_summary.dart';

/// ルームロビー向けのルール概要カード（非ホスト向け）。
class LobbyRulesSummaryCard extends StatelessWidget {
  const LobbyRulesSummaryCard({
    required this.participantCount,
    super.key,
  });

  final int participantCount;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final playerHint = participantCount >= 5
        ? '人数OK（告発可）'
        : participantCount >= 3
            ? 'やや少なめ（告発可）'
            : '3人未満（告発不可）';

    return Card(
      margin: const EdgeInsets.only(top: 12, bottom: 4),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.rule_folder_outlined, color: theme.colorScheme.primary),
                const SizedBox(width: 8),
                Text(
                  'ルール概要',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              '参加 $participantCount 人 · 推奨 ${MatchSetupSummary.recommendedPlayers} · '
              '${MatchSetupSummary.recommendedDuration}',
              style: theme.textTheme.bodySmall,
            ),
            const SizedBox(height: 4),
            Text(
              playerHint,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              '告発の重み・制限時間などの詳細は、ゲーム画面の「準備」でホスト設定を確認できます。',
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.outline,
                height: 1.35,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
