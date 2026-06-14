import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:oni_game/game/match_role_mix.dart';
import 'package:oni_game/game/player_role.dart';
import 'package:oni_game/sync/shared_match_snapshot.dart';

void main() {
  List<String> stubSkills(PlayerRole role) => ['stub'];

  group('isBalancedAntagonistMix', () {
    test('accepts standard 6-player mix', () {
      expect(
        isBalancedAntagonistMix(hunterCount: 1, runnerCount: 3, werewolfCount: 2),
        isTrue,
      );
    });

    test('rejects when runners are fewer than werewolves', () {
      expect(
        isBalancedAntagonistMix(hunterCount: 1, runnerCount: 1, werewolfCount: 2),
        isFalse,
      );
    });
  });

  group('ensureViableRoleMix', () {
    test('2 players always hunter and runner', () {
      for (var seed = 0; seed < 20; seed++) {
        final assignments = {
          'a': SharedPlayerAssignment(role: PlayerRole.runner, skills: []),
          'b': SharedPlayerAssignment(role: PlayerRole.runner, skills: []),
        };
        ensureViableRoleMix(
          assignments: assignments,
          rnd: math.Random(seed),
          skillsFor: stubSkills,
        );
        expect(
          assignments.values.where((a) => a.role == PlayerRole.hunter).length,
          1,
        );
        expect(
          assignments.values.where((a) => a.role == PlayerRole.runner).length,
          1,
        );
        expect(
          assignments.values.any((a) => a.role == PlayerRole.werewolf),
          isFalse,
        );
      }
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

    test('3 players get hunter werewolf runner', () {
      final assignments = {
        for (var i = 0; i < 3; i++)
          'p$i': SharedPlayerAssignment(role: PlayerRole.runner, skills: []),
      };
      ensureViableRoleMix(
        assignments: assignments,
        rnd: math.Random(4),
        skillsFor: stubSkills,
      );
      expect(
        assignments.values.where((a) => a.role == PlayerRole.hunter).length,
        1,
      );
      expect(
        assignments.values.where((a) => a.role == PlayerRole.werewolf).length,
        1,
      );
      expect(
        assignments.values.where((a) => a.role == PlayerRole.runner).length,
        1,
      );
    });

    test('8 players can assign two hunters when balanced', () {
      final assignments = {
        for (var i = 0; i < 8; i++)
          'p$i': SharedPlayerAssignment(role: PlayerRole.runner, skills: []),
      };
      ensureViableRoleMix(
        assignments: assignments,
        rnd: math.Random(8),
        skillsFor: stubSkills,
      );
      final h =
          assignments.values.where((a) => a.role == PlayerRole.hunter).length;
      final w =
          assignments.values.where((a) => a.role == PlayerRole.werewolf).length;
      final r =
          assignments.values.where((a) => a.role == PlayerRole.runner).length;
      expect(w, 2);
      expect(h, 2);
      expect(
        isBalancedAntagonistMix(
          hunterCount: h,
          runnerCount: r,
          werewolfCount: w,
        ),
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

    test('2 players force hunter and runner regardless of counts', () {
      final assignments = {
        'a': SharedPlayerAssignment(role: PlayerRole.runner, skills: []),
        'b': SharedPlayerAssignment(role: PlayerRole.runner, skills: []),
      };
      assignByRoleCounts(
        assignments: assignments,
        rnd: math.Random(9),
        hunterCount: 0,
        werewolfCount: 1,
        skillsFor: stubSkills,
      );
      expect(countRole(assignments, PlayerRole.hunter), 1);
      expect(countRole(assignments, PlayerRole.werewolf), 0);
      expect(countRole(assignments, PlayerRole.runner), 1);
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
      expect(countRole(assignments, PlayerRole.hunter), 1);
      expect(countRole(assignments, PlayerRole.werewolf), 0);
      expect(countRole(assignments, PlayerRole.runner), 1);
    });
  });
}
