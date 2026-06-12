import 'package:flutter_test/flutter_test.dart';
import 'package:oni_game/features/how_to_play/guide_terms.dart';
import 'package:oni_game/features/match/match_result_copy.dart';
import 'package:oni_game/game/elimination_aftermath_rule.dart';
import 'package:oni_game/game/game_state.dart';
import 'package:oni_game/game/match_hud_copy.dart';
import 'package:oni_game/game/werewolf_faction_logic.dart';
import 'package:oni_game/sync/firestore_room_blueprint.dart';

void main() {
  group('MatchResultCopy', () {
    test('runner win headline', () {
      final h = MatchResultCopy.outcomeHeadline(
        outcome: GameState.runnerWin,
        winningFaction: FactionSide.humanTeam,
      );
      expect(h.title, MatchHudCopy.humanFactionWin);
      expect(h.subtitle, MatchHudCopy.humanWinTimeUpDetail);
    });

    test('oni defeat on human time-up shows subtitle', () {
      final h = MatchResultCopy.outcomeHeadline(
        outcome: GameState.runnerWin,
        winningFaction: FactionSide.humanTeam,
        playerFactionAtEnd: FactionSide.oniTeam,
      );
      expect(h.title, MatchHudCopy.humanFactionWin);
      expect(h.subtitle, contains('敗北'));
    });

    test('host abort headline', () {
      final h = MatchResultCopy.outcomeHeadline(
        outcome: GameState.runnerWin,
        endReason: MatchEndReason.hostAbort,
      );
      expect(h.title, MatchHudCopy.matchAborted);
      expect(h.subtitle, MatchHudCopy.matchAbortedDetail);
    });

    test('caught human becomes elimination headline', () {
      final h = MatchResultCopy.outcomeHeadline(
        outcome: GameState.caughtByOni,
        playerFactionAtEnd: FactionSide.humanTeam,
        afterCatchRule: EliminationAftermathRule.spectralOperative,
      );
      expect(h.title, MatchHudCopy.resultCapturedTitle);
      expect(h.subtitle, contains(GuideTerms.echoForm));
    });

    test('caught oni team shows oni victory', () {
      final h = MatchResultCopy.outcomeHeadline(
        outcome: GameState.caughtByOni,
        factionAtDeath: FactionSide.oniTeam,
      );
      expect(h.title, MatchHudCopy.oniFactionWin);
    });

    test('accusation success headline', () {
      final h = MatchResultCopy.outcomeHeadline(
        outcome: GameState.runnerWin,
        winningFaction: FactionSide.humanTeam,
        endReason: MatchEndReason.accusationSuccess,
      );
      expect(h.title, MatchHudCopy.humanFactionWin);
      expect(h.subtitle, MatchHudCopy.humanWinAccusationDetail);
    });

    test('accusation success oni team shows defeat subtitle', () {
      final h = MatchResultCopy.outcomeHeadline(
        outcome: GameState.runnerWin,
        winningFaction: FactionSide.humanTeam,
        endReason: MatchEndReason.accusationSuccess,
        playerFactionAtEnd: FactionSide.oniTeam,
      );
      expect(h.title, MatchHudCopy.humanFactionWin);
      expect(h.subtitle, '${GuideTerms.oniFaction}の敗北');
    });

    test('revenant oni aftermath subtitle', () {
      final h = MatchResultCopy.outcomeHeadline(
        outcome: GameState.caughtByOni,
        afterCatchRule: EliminationAftermathRule.revenantOni,
      );
      expect(h.subtitle, contains(GuideTerms.vengefulShadow));
    });
  });
}
