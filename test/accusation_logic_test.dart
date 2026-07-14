import 'package:flutter_test/flutter_test.dart';
import 'package:oni_game/game/accusation_logic.dart';
import 'package:oni_game/game/match_duration_scaling.dart';
import 'package:oni_game/game/player_role.dart';
import 'package:oni_game/sync/shared_match_snapshot.dart';

void main() {
  final assignments = {
    'h1': const SharedPlayerAssignment(role: PlayerRole.hunter, skills: []),
    'r1': const SharedPlayerAssignment(role: PlayerRole.runner, skills: []),
    'r2': const SharedPlayerAssignment(role: PlayerRole.runner, skills: []),
  };

  test('accusation disabled below min players', () {
    expect(accusationEnabledForPlayerCount(2), false);
    expect(accusationEnabledForPlayerCount(3), true);
  });

  test('unlock at 60 percent elapsed', () {
    final duration = 100;
    expect(
      shouldUnlockAccusation(
        playerCount: 3,
        eliminationCount: 0,
        elapsedSeconds: 59,
        matchDurationSeconds: duration,
      ),
      false,
    );
    expect(
      shouldUnlockAccusation(
        playerCount: 3,
        eliminationCount: 0,
        elapsedSeconds: 60,
        matchDurationSeconds: duration,
      ),
      true,
    );
  });

  test('unlock requires elimination plus scaled min elapsed', () {
    const duration = MatchDurationScaling.recommendedMatchSeconds;
    final minElapsed =
        MatchDurationScaling.accusationUnlockMinElapsedSeconds(duration);
    expect(
      shouldUnlockAccusation(
        playerCount: 3,
        eliminationCount: 1,
        elapsedSeconds: minElapsed - 1,
        matchDurationSeconds: duration,
      ),
      false,
    );
    expect(
      shouldUnlockAccusation(
        playerCount: 3,
        eliminationCount: 1,
        elapsedSeconds: minElapsed,
        matchDurationSeconds: duration,
      ),
      true,
    );
  });

  test('hunter accusation target', () {
    expect(
      isAccusationTargetHunter(assignments: assignments, accusedUid: 'h1'),
      true,
    );
    expect(
      isAccusationTargetHunter(assignments: assignments, accusedUid: 'r1'),
      false,
    );
  });

  test('canLocalPlayerAccuse blocks pending resolution', () {
    expect(
      canLocalPlayerAccuse(
        localRole: PlayerRole.runner,
        accusationUnlocked: true,
        accusationSpent: false,
        accusationPending: true,
        isEliminated: false,
        playerCount: 3,
      ),
      false,
    );
    expect(
      canLocalPlayerAccuse(
        localRole: PlayerRole.runner,
        accusationUnlocked: true,
        accusationSpent: false,
        accusationPending: false,
        isEliminated: false,
        playerCount: 3,
      ),
      true,
    );
  });
}
