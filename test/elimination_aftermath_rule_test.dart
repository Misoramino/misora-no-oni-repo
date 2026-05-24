import 'package:flutter_test/flutter_test.dart';
import 'package:oni_game/game/elimination_aftermath_rule.dart';
import 'package:oni_game/game/werewolf_faction_logic.dart';

void main() {
  test('spectral match mode branches by faction at death', () {
    expect(
      EliminationAftermathRule.forEliminatedFaction(
        matchDefault: EliminationAftermathRule.spectralOperative,
        factionAtDeath: FactionSide.humanTeam,
      ),
      EliminationAftermathRule.spectralOperative,
    );
    expect(
      EliminationAftermathRule.forEliminatedFaction(
        matchDefault: EliminationAftermathRule.spectralOperative,
        factionAtDeath: FactionSide.oniTeam,
      ),
      EliminationAftermathRule.revenantOni,
    );
  });

  test('joinOni match mode keeps experimental rule', () {
    expect(
      EliminationAftermathRule.forEliminatedFaction(
        matchDefault: EliminationAftermathRule.joinOni,
        factionAtDeath: FactionSide.humanTeam,
      ),
      EliminationAftermathRule.joinOni,
    );
  });
}
