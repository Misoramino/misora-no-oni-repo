import 'package:flutter_test/flutter_test.dart';
import 'package:oni_game/game/player_role.dart';
import 'package:oni_game/game/role_briefing.dart';

void main() {
  test('each role has briefing content', () {
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

  test('werewolf briefing mentions faction', () {
    final b = RoleBriefingCatalog.forRole(PlayerRole.werewolf);
    expect(b.actions.join(), contains('人陣営'));
    expect(b.notes.join(), contains('固定'));
    expect(b.notes.join(), contains('2人'));
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
