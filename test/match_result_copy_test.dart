import 'package:flutter_test/flutter_test.dart';
import 'package:oni_game/features/match/match_result_copy.dart';
import 'package:oni_game/game/elimination_aftermath_rule.dart';
import 'package:oni_game/game/game_state.dart';
import 'package:oni_game/game/werewolf_faction_logic.dart';
import 'package:oni_game/sync/firestore_room_blueprint.dart';

void main() {
  group('MatchResultCopy', () {
    test('runner win headline', () {
      final h = MatchResultCopy.outcomeHeadline(
        outcome: GameState.runnerWin,
        winningFaction: FactionSide.humanTeam,
      );
      expect(h.title, '逃走成功');
      expect(h.subtitle, isNull);
    });

    test('oni defeat on human time-up shows subtitle', () {
      final h = MatchResultCopy.outcomeHeadline(
        outcome: GameState.runnerWin,
        winningFaction: FactionSide.humanTeam,
        playerFactionAtEnd: FactionSide.oniTeam,
      );
      expect(h.title, '逃走成功');
      expect(h.subtitle, contains('敗北'));
    });

    test('host abort headline', () {
      final h = MatchResultCopy.outcomeHeadline(
        outcome: GameState.runnerWin,
        endReason: MatchEndReason.hostAbort,
      );
      expect(h.title, '試合中止');
    });

    test('caught human becomes elimination headline', () {
      final h = MatchResultCopy.outcomeHeadline(
        outcome: GameState.caughtByOni,
        playerFactionAtEnd: FactionSide.humanTeam,
        afterCatchRule: EliminationAftermathRule.spectralOperative,
      );
      expect(h.title, '脱落（捕獲）');
      expect(h.subtitle, contains('残響体'));
    });

    test('caught oni team shows oni victory', () {
      final h = MatchResultCopy.outcomeHeadline(
        outcome: GameState.caughtByOni,
        factionAtDeath: FactionSide.oniTeam,
      );
      expect(h.title, '鬼陣営の勝利');
    });

    test('accusation success headline', () {
      final h = MatchResultCopy.outcomeHeadline(
        outcome: GameState.runnerWin,
        winningFaction: FactionSide.humanTeam,
        endReason: MatchEndReason.accusationSuccess,
      );
      expect(h.title, '逃走者陣営の勝利');
      expect(h.subtitle, '告発成功');
    });

    test('accusation success oni team shows defeat subtitle', () {
      final h = MatchResultCopy.outcomeHeadline(
        outcome: GameState.runnerWin,
        winningFaction: FactionSide.humanTeam,
        endReason: MatchEndReason.accusationSuccess,
        playerFactionAtEnd: FactionSide.oniTeam,
      );
      expect(h.title, '逃走者陣営の勝利');
      expect(h.subtitle, '鬼陣営の敗北');
    });

    test('revenant oni aftermath subtitle', () {
      final h = MatchResultCopy.outcomeHeadline(
        outcome: GameState.caughtByOni,
        afterCatchRule: EliminationAftermathRule.revenantOni,
      );
      expect(h.subtitle, contains('復讐の鬼影'));
    });
  });
}
