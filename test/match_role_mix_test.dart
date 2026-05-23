import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:oni_game/game/match_role_mix.dart';
import 'package:oni_game/game/player_role.dart';
import 'package:oni_game/sync/shared_match_snapshot.dart';

void main() {
  List<String> stubSkills(PlayerRole role) => ['stub'];

  group('ensureViableRoleMix', () {
    test('2 players with no antagonist gains hunter or werewolf', () {
      final assignments = {
        'a': SharedPlayerAssignment(role: PlayerRole.runner, skills: []),
        'b': SharedPlayerAssignment(role: PlayerRole.runner, skills: []),
      };
      ensureViableRoleMix(
        assignments: assignments,
        rnd: math.Random(1),
        skillsFor: stubSkills,
      );
      expect(
        assignments.values.any(
          (a) =>
              a.role == PlayerRole.hunter || a.role == PlayerRole.werewolf,
        ),
        isTrue,
      );
    });

    test('3+ players without hunter gains hunter', () {
      final assignments = {
        'a': SharedPlayerAssignment(role: PlayerRole.runner, skills: []),
        'b': SharedPlayerAssignment(role: PlayerRole.werewolf, skills: []),
        'c': SharedPlayerAssignment(role: PlayerRole.runner, skills: []),
      };
      ensureViableRoleMix(
        assignments: assignments,
        rnd: math.Random(2),
        skillsFor: stubSkills,
      );
      expect(
        assignments.values.any((a) => a.role == PlayerRole.hunter),
        isTrue,
      );
    });

    test('all hunters demotes one to non-hunter', () {
      final assignments = {
        'a': SharedPlayerAssignment(role: PlayerRole.hunter, skills: []),
        'b': SharedPlayerAssignment(role: PlayerRole.hunter, skills: []),
        'c': SharedPlayerAssignment(role: PlayerRole.hunter, skills: []),
      };
      ensureViableRoleMix(
        assignments: assignments,
        rnd: math.Random(3),
        skillsFor: stubSkills,
      );
      expect(
        assignments.values.any((a) => a.role != PlayerRole.hunter),
        isTrue,
      );
      expect(
        assignments.values.any((a) => a.role == PlayerRole.hunter),
        isTrue,
      );
    });
  });
}
