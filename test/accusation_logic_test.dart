import 'package:flutter_test/flutter_test.dart';
import 'package:oni_game/game/accusation_logic.dart';
import 'package:oni_game/game/game_config.dart';
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

  test('unlock requires elimination plus five minutes', () {
    expect(
      shouldUnlockAccusation(
        playerCount: 3,
        eliminationCount: 1,
        elapsedSeconds: 0,
        matchDurationSeconds: GameConfig.matchDurationSeconds,
      ),
      false,
    );
    expect(
      shouldUnlockAccusation(
        playerCount: 3,
        eliminationCount: 1,
        elapsedSeconds: GameConfig.accusationUnlockMinElapsedSeconds - 1,
        matchDurationSeconds: GameConfig.matchDurationSeconds,
      ),
      false,
    );
    expect(
      shouldUnlockAccusation(
        playerCount: 3,
        eliminationCount: 1,
        elapsedSeconds: GameConfig.accusationUnlockMinElapsedSeconds,
        matchDurationSeconds: GameConfig.matchDurationSeconds,
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
}
