import '../../features/how_to_play/guide_terms.dart';
import '../../game/elimination_aftermath_rule.dart';
import '../../game/game_state.dart';
import '../../game/match_hud_copy.dart';
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
      return (
        title: MatchHudCopy.matchAborted,
        subtitle: MatchHudCopy.matchAbortedDetail,
      );
    }
    final personalFaction = factionAtDeath ?? playerFactionAtEnd;
    if (winningFaction == FactionSide.oniTeam) {
      return (
        title: MatchHudCopy.oniFactionWin,
        subtitle: personalFaction == FactionSide.humanTeam
            ? '${GuideTerms.humanFaction}の敗北'
            : null,
      );
    }
    if (winningFaction == FactionSide.humanTeam) {
      final subtitle = personalFaction == FactionSide.oniTeam
          ? '${GuideTerms.oniFaction}の敗北'
          : null;
      return switch (endReason) {
        MatchEndReason.accusationSuccess => (
            title: MatchHudCopy.humanFactionWin,
            subtitle: personalFaction == FactionSide.oniTeam
                ? '${GuideTerms.oniFaction}の敗北'
                : MatchHudCopy.humanWinAccusationDetail,
          ),
        MatchEndReason.oniEliminated => (
            title: MatchHudCopy.humanFactionWin,
            subtitle: subtitle ?? MatchHudCopy.humanWinOniEliminatedDetail,
          ),
        MatchEndReason.allHumansEliminated => (
            title: MatchHudCopy.oniFactionWin,
            subtitle: subtitle ?? MatchHudCopy.oniWinDetail,
          ),
        _ => (
            title: MatchHudCopy.humanFactionWin,
            subtitle: subtitle ?? MatchHudCopy.humanWinTimeUpDetail,
          ),
      };
    }
    return switch (outcome) {
      GameState.runnerWin => (
          title: MatchHudCopy.humanFactionWin,
          subtitle: personalFaction == FactionSide.oniTeam
              ? '${GuideTerms.oniFaction}の敗北'
              : MatchHudCopy.humanWinTimeUpDetail,
        ),
      GameState.caughtByOni => (
          title: personalFaction == FactionSide.oniTeam
              ? MatchHudCopy.oniFactionWin
              : MatchHudCopy.resultCapturedTitle,
          subtitle: _afterCatchSubtitle(afterCatchRule),
        ),
      _ => (title: '試合終了', subtitle: null),
    };
  }

  static String? _afterCatchSubtitle(EliminationAftermathRule? rule) {
    if (rule == null) return MatchHudCopy.secondGameTransition;
    return switch (rule) {
      EliminationAftermathRule.spectralOperative =>
        MatchHudCopy.resultAfterCatchSubtitle('${GuideTerms.echoForm}として戦線に残ります'),
      EliminationAftermathRule.revenantOni =>
        MatchHudCopy.resultAfterCatchSubtitle(
          '${GuideTerms.vengefulShadow}として戦線に残ります',
        ),
      EliminationAftermathRule.ghostSpectator =>
        MatchHudCopy.eliminationSpectator('幽霊'),
      EliminationAftermathRule.joinOni =>
        MatchHudCopy.eliminationJoinOni('鬼側合流'),
    };
  }
}
