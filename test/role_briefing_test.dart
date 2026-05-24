import 'package:flutter_test/flutter_test.dart';
import 'package:oni_game/game/player_role.dart';
import 'package:oni_game/game/role_briefing.dart';
import 'package:oni_game/game/werewolf_faction_logic.dart';

void main() {
  test('each role has full briefing content for how-to-play', () {
    for (final role in PlayerRole.values) {
      if (role == PlayerRole.runner ||
          role == PlayerRole.hunter ||
          role == PlayerRole.werewolf) {
        final b = RoleBriefingCatalog.forRole(role);
        expect(b.goals, isNotEmpty);
        expect(b.actions, isNotEmpty);
      }
    }
  });

  test('match start briefing is short and plain', () {
    for (final role in [
      PlayerRole.runner,
      PlayerRole.hunter,
      PlayerRole.werewolf,
    ]) {
      final s = RoleBriefingCatalog.matchStartBriefing(role);
      expect(s.tagline, isNotEmpty);
      expect(s.winLine, isNotEmpty);
      expect(s.mustKnow.length, lessThanOrEqualTo(3));
      expect(s.mustKnow.join(), isNot(contains('人ロール')));
    }
  });

  test('werewolf start briefing reflects faction', () {
    final human = RoleBriefingCatalog.matchStartBriefing(
      PlayerRole.werewolf,
      werewolfFaction: FactionSide.humanTeam,
    );
    expect(human.winLine, contains('人側'));
    expect(human.mustKnow.join(), contains('捕'));

    final oni = RoleBriefingCatalog.matchStartBriefing(
      PlayerRole.werewolf,
      werewolfFaction: FactionSide.oniTeam,
    );
    expect(oni.winLine, contains('鬼側'));
    expect(oni.mustKnow.join(), contains('直接'));

    final full = RoleBriefingCatalog.forRole(PlayerRole.werewolf);
    expect(full.notes.join(), contains('2人'));
  });

  test('match start status line is role-specific', () {
    expect(
      RoleBriefingCatalog.matchStartStatusLine(PlayerRole.runner),
      contains('逃げ'),
    );
    expect(
      RoleBriefingCatalog.matchStartStatusLine(PlayerRole.hunter),
      contains('捕'),
    );
    expect(
      RoleBriefingCatalog.matchStartStatusLine(PlayerRole.werewolf),
      contains('陣営'),
    );
  });
}
