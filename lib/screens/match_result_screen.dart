import 'package:flutter/material.dart';

import '../game/elimination_aftermath_rule.dart';
import '../game/game_state.dart';
import '../game/werewolf_faction_logic.dart';
import '../widgets/responsive_page.dart';

/// 試合終了後の専用リザルト画面（ギャラリー・ロビー・次の準備への導線）。
class MatchResultScreen extends StatelessWidget {
  const MatchResultScreen({
    required this.outcome,
    required this.detail,
    required this.roleSummary,
    required this.matchDurationLabel,
    required this.onPrepareNext,
    required this.onOpenGallery,
    required this.onOpenLobby,
    this.afterCatchRule,
    this.factionAtDeath,
    this.playerFactionAtEnd,
    this.winningFaction,
    super.key,
  });

  final GameState outcome;
  final String detail;
  final String roleSummary;
  final String matchDurationLabel;
  final EliminationAftermathRule? afterCatchRule;
  final FactionSide? factionAtDeath;
  final FactionSide? playerFactionAtEnd;
  final FactionSide? winningFaction;
  final VoidCallback onPrepareNext;
  final VoidCallback onOpenGallery;
  final VoidCallback onOpenLobby;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final (IconData icon, String title, Color accent) = switch (outcome) {
      GameState.runnerWin => (
        Icons.emoji_events_outlined,
        '逃走成功',
        Colors.green.shade700,
      ),
      GameState.caughtByOni => (
        Icons.front_hand_outlined,
        '捕獲',
        Colors.red.shade700,
      ),
      _ => (Icons.flag_outlined, '試合終了', theme.colorScheme.primary),
    };

    final factionWinLabel = winningFaction?.label;
    final effectivePersonalFaction = factionAtDeath ?? playerFactionAtEnd;
    final personalFactionLabel = effectivePersonalFaction?.label;
    final personalWon = winningFaction != null &&
        effectivePersonalFaction != null &&
        winningFaction == effectivePersonalFaction;

    return Scaffold(
      appBar: AppBar(title: const Text('リザルト')),
      body: ResponsivePage(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Icon(icon, size: 64, color: accent),
              const SizedBox(height: 12),
              Text(
                title,
                textAlign: TextAlign.center,
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: accent,
                ),
              ),
              if (factionWinLabel != null) ...[
                const SizedBox(height: 6),
                Text(
                  '$factionWinLabel の勝利',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
              if (personalFactionLabel != null) ...[
                const SizedBox(height: 6),
                Text(
                  personalWon
                      ? 'あなたの陣営（$personalFactionLabel）は勝利'
                      : 'あなたの陣営（$personalFactionLabel）は敗北',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: personalWon ? Colors.green.shade700 : Colors.grey.shade700,
                  ),
                ),
              ],
              const SizedBox(height: 8),
              Text(detail, textAlign: TextAlign.center),
              const SizedBox(height: 16),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('あなたの役職・スキル', style: theme.textTheme.titleSmall),
                      const SizedBox(height: 6),
                      Text(roleSummary),
                      if (factionAtDeath != null) ...[
                        const SizedBox(height: 8),
                        Text(
                          '脱落時の陣営: ${factionAtDeath!.label}',
                          style: theme.textTheme.bodySmall,
                        ),
                      ] else if (playerFactionAtEnd != null) ...[
                        const SizedBox(height: 8),
                        Text(
                          'あなたの陣営: ${playerFactionAtEnd!.label}',
                          style: theme.textTheme.bodySmall,
                        ),
                      ],
                      const SizedBox(height: 10),
                      Text(
                        '制限時間: $matchDurationLabel',
                        style: theme.textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
              ),
              if (outcome == GameState.caughtByOni && afterCatchRule != null) ...[
                const SizedBox(height: 12),
                Card(
                  color: theme.colorScheme.surfaceContainerHighest,
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.visibility_outlined,
                              color: theme.colorScheme.primary,
                            ),
                            const SizedBox(width: 8),
                            Text('第二ゲーム', style: theme.textTheme.titleSmall),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(afterCatchRule!.label),
                        const SizedBox(height: 6),
                        Text(
                          _afterCatchBlurb(afterCatchRule!),
                          style: theme.textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: onOpenGallery,
                icon: const Icon(Icons.play_circle_outline),
                label: const Padding(
                  padding: EdgeInsets.symmetric(vertical: 10),
                  child: Text('軌跡再生・ギャラリー'),
                ),
              ),
              const SizedBox(height: 10),
              OutlinedButton.icon(
                onPressed: onOpenLobby,
                icon: const Icon(Icons.groups_outlined),
                label: const Text('ルームロビーへ'),
              ),
              const SizedBox(height: 10),
              OutlinedButton.icon(
                onPressed: onPrepareNext,
                icon: const Icon(Icons.restart_alt),
                label: const Text('次の準備へ（地図オフ）'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static String _afterCatchBlurb(EliminationAftermathRule rule) =>
      switch (rule) {
        EliminationAftermathRule.spectralOperative =>
          '地図に戻ると、残響体として監視ジャックや告発施設の陣取りができます。',
        EliminationAftermathRule.revenantOni =>
          '地図に戻ると、復讐の鬼影として告発妨害やカメラ停止ができます。',
        EliminationAftermathRule.ghostSpectator =>
          '地図に戻ると、中立の幽霊として全体のざっくり位置マーカーが表示されます。',
        EliminationAftermathRule.joinOni =>
          '地図に戻ると、鬼側合流として索敵支援用のざっくり位置が表示されます。',
      };
}
