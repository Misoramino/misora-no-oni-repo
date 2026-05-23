import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:oni_game/game/player_role.dart';
import 'package:oni_game/game/runner_modifier.dart';
import 'package:oni_game/game/runner_modifier_assign.dart';
import 'package:oni_game/sync/shared_match_snapshot.dart';

void main() {
  test('assigns analyst and hacker to distinct runners', () {
    final assignments = {
      'h1': const SharedPlayerAssignment(role: PlayerRole.hunter, skills: []),
      'r1': const SharedPlayerAssignment(role: PlayerRole.runner, skills: []),
      'r2': const SharedPlayerAssignment(role: PlayerRole.runner, skills: []),
      'r3': const SharedPlayerAssignment(role: PlayerRole.runner, skills: []),
    };
    assignRunnerModifiers(assignments: assignments, rnd: math.Random(0));
    final mods = assignments.values
        .where((a) => a.role == PlayerRole.runner)
        .map((a) => a.modifier)
        .toList();
    expect(mods, contains(RunnerModifier.analyst));
    expect(mods, contains(RunnerModifier.hacker));
    expect(mods.where((m) => m != RunnerModifier.none).length, 2);
  });
}
