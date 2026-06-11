import 'package:flutter_test/flutter_test.dart';
import 'package:oni_game/game/player_role.dart';
import 'package:oni_game/game/werewolf_faction_logic.dart';

void main() {
  group('WerewolfFactionLogic.countAliveFactions', () {
    test('counts non-eliminated by faction', () {
      final players = [
        const MatchParticipantState(
          uid: 'r1',
          assignmentRole: PlayerRole.runner,
          werewolfInOniForm: false,
          eliminated: false,
        ),
        const MatchParticipantState(
          uid: 'h1',
          assignmentRole: PlayerRole.hunter,
          werewolfInOniForm: false,
          eliminated: false,
        ),
        const MatchParticipantState(
          uid: 'r2',
          assignmentRole: PlayerRole.runner,
          werewolfInOniForm: false,
          eliminated: true,
        ),
      ];
      final counts = WerewolfFactionLogic.countAliveFactions(players: players);
      expect(counts.humanAlive, 1);
      expect(counts.oniAlive, 1);
    });

    test('solo runner eliminated leaves zero humans', () {
      final players = [
        const MatchParticipantState(
          uid: 'solo',
          assignmentRole: PlayerRole.runner,
          werewolfInOniForm: false,
          eliminated: true,
        ),
      ];
      final counts = WerewolfFactionLogic.countAliveFactions(players: players);
      expect(counts.humanAlive, 0);
      expect(counts.oniAlive, 0);
    });
  });
}
