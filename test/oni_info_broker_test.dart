
import 'package:flutter_test/flutter_test.dart';
import 'package:oni_game/game/oni_info_broker.dart';
import 'package:oni_game/game/player_role.dart';
import 'package:oni_game/sync/shared_match_snapshot.dart';

void main() {
  test('pickRandomRunnerUid returns only runners', () {
    final assignments = {
      'h1': const SharedPlayerAssignment(role: PlayerRole.hunter, skills: []),
      'r1': const SharedPlayerAssignment(role: PlayerRole.runner, skills: []),
      'r2': const SharedPlayerAssignment(role: PlayerRole.runner, skills: []),
    };
    final picked = pickRandomRunnerUid(assignments: assignments);
    expect(picked, isIn(['r1', 'r2']));
    expect(picked, isNot('h1'));
  });

  test('pickRandomRunnerUid excludes uid when set', () {
    final assignments = {
      'r1': const SharedPlayerAssignment(role: PlayerRole.runner, skills: []),
    };
    expect(
      pickRandomRunnerUid(assignments: assignments, excludeUid: 'r1'),
      isNull,
    );
  });

  test('pickRandomRunnerUid null when no runners', () {
    expect(
      pickRandomRunnerUid(
        assignments: {
          'h1': const SharedPlayerAssignment(role: PlayerRole.hunter, skills: []),
        },
      ),
      isNull,
    );
  });
}
