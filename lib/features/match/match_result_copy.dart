import '../../game/elimination_aftermath_rule.dart';
import '../../game/game_state.dart';
import '../../game/werewolf_faction_logic.dart';
import '../../sync/firestore_room_blueprint.dart';

/// リザルト画面の見出し・サブタイトル（ロジック単体テスト用に切り出し）。
abstract final class MatchResultCopy {
  static ({String title, String? subtitle}) outcomeHeadline({
    required GameState outcome,
    FactionSide? winningFaction,
    String? endReason,
    FactionSide? factionAtDeath,
    FactionSide? playerFactionAtEnd,
    EliminationAftermathRule? afterCatchRule,
  }) {
    if (endReason == MatchEndReason.hostAbort) {
      return (title: '試合中止', subtitle: null);
    }
    final personalFaction = factionAtDeath ?? playerFactionAtEnd;
    if (winningFaction == FactionSide.oniTeam) {
      return (
        title: '鬼陣営の勝利',
        subtitle: personalFaction == FactionSide.humanTeam ? '逃走者陣営の敗北' : null,
      );
    }
    if (winningFaction == FactionSide.humanTeam) {
      final subtitle = personalFaction == FactionSide.oniTeam
          ? '鬼陣営の敗北'
          : null;
      return switch (endReason) {
        MatchEndReason.accusationSuccess => (
            title: '逃走者陣営の勝利',
            subtitle: personalFaction == FactionSide.oniTeam
                ? '鬼陣営の敗北'
                : '告発成功',
          ),
        MatchEndReason.oniEliminated => (
            title: '逃走者陣営の勝利',
            subtitle: subtitle,
          ),
        MatchEndReason.allHumansEliminated => (
            title: '鬼陣営の勝利',
            subtitle: subtitle,
          ),
        _ => (title: '逃走成功', subtitle: subtitle),
      };
    }
    return switch (outcome) {
      GameState.runnerWin => (
          title: '逃走成功',
          subtitle: personalFaction == FactionSide.oniTeam
              ? '鬼陣営の敗北'
              : null,
        ),
      GameState.caughtByOni => (
          title: personalFaction == FactionSide.oniTeam ? '鬼陣営の勝利' : '脱落（捕獲）',
          subtitle: _afterCatchSubtitle(afterCatchRule),
        ),
      _ => (title: '試合終了', subtitle: null),
    };
  }

  static String? _afterCatchSubtitle(EliminationAftermathRule? rule) {
    if (rule == null) return '第二ゲームに移行できます';
    return switch (rule) {
      EliminationAftermathRule.spectralOperative => '残響体として戦線に残ります',
      EliminationAftermathRule.revenantOni => '復讐の鬼影として戦線に残ります',
      EliminationAftermathRule.ghostSpectator => '幽霊として観戦を続けます',
      EliminationAftermathRule.joinOni => '鬼側合流として戦線に残ります',
    };
  }
}
