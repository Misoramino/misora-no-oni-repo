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

  group('assignByRoleCounts', () {
    int countRole(Map<String, SharedPlayerAssignment> a, PlayerRole r) =>
        a.values.where((e) => e.role == r).length;

    test('honors exact counts and fills the rest with runners', () {
      final assignments = {
        for (var i = 0; i < 6; i++)
          'p$i': SharedPlayerAssignment(role: PlayerRole.runner, skills: []),
      };
      assignByRoleCounts(
        assignments: assignments,
        rnd: math.Random(7),
        hunterCount: 2,
        werewolfCount: 1,
        skillsFor: stubSkills,
      );
      expect(countRole(assignments, PlayerRole.hunter), 2);
      expect(countRole(assignments, PlayerRole.werewolf), 1);
      expect(countRole(assignments, PlayerRole.runner), 3);
    });

    test('clamps counts when they exceed member count', () {
      final assignments = {
        'a': SharedPlayerAssignment(role: PlayerRole.runner, skills: []),
        'b': SharedPlayerAssignment(role: PlayerRole.runner, skills: []),
      };
      assignByRoleCounts(
        assignments: assignments,
        rnd: math.Random(9),
        hunterCount: 5,
        werewolfCount: 5,
        skillsFor: stubSkills,
      );
      expect(assignments.length, 2);
      expect(countRole(assignments, PlayerRole.hunter), 2);
      expect(countRole(assignments, PlayerRole.werewolf), 0);
    });
  });
}
