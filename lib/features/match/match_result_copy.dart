import '../../game/elimination_aftermath_rule.dart';
import '../../game/game_state.dart';
import '../../game/werewolf_faction_logic.dart';

/// リザルト画面の見出し・サブタイトル（ロジック単体テスト用に切り出し）。
abstract final class MatchResultCopy {
  static ({String title, String? subtitle}) outcomeHeadline({
    required GameState outcome,
    FactionSide? factionAtDeath,
    FactionSide? playerFactionAtEnd,
    EliminationAftermathRule? afterCatchRule,
  }) {
    final personalFaction = factionAtDeath ?? playerFactionAtEnd;
    return switch (outcome) {
      GameState.runnerWin => (
          title: '逃走成功',
          subtitle: personalFaction == FactionSide.oniTeam
              ? '時間切れ — 鬼陣営の敗北'
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
