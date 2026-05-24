import 'player_role.dart';
import '../sync/shared_match_snapshot.dart';
import 'game_config.dart';
import 'match_duration_scaling.dart';

bool accusationEnabledForPlayerCount(int count) =>
    count >= GameConfig.accusationMinPlayers;

bool shouldUnlockAccusation({
  required int playerCount,
  required int eliminationCount,
  required int elapsedSeconds,
  required int matchDurationSeconds,
}) {
  if (!accusationEnabledForPlayerCount(playerCount)) return false;
  final threshold =
      (matchDurationSeconds * GameConfig.accusationUnlockTimeRatio).floor();
  if (elapsedSeconds >= threshold) return true;
  if (eliminationCount >= 1 &&
      elapsedSeconds >=
          MatchDurationScaling.accusationUnlockMinElapsedSeconds(
            matchDurationSeconds,
          )) {
    return true;
  }
  return false;
}

/// HUD 用: 次に告発が解禁されるまでの秒（null = 既に解禁 or 無効）。
int? secondsUntilAccusationUnlock({
  required int playerCount,
  required int eliminationCount,
  required int elapsedSeconds,
  required int remainingSeconds,
  required int matchDurationSeconds,
}) {
  if (!accusationEnabledForPlayerCount(playerCount)) return null;
  if (shouldUnlockAccusation(
    playerCount: playerCount,
    eliminationCount: eliminationCount,
    elapsedSeconds: elapsedSeconds,
    matchDurationSeconds: matchDurationSeconds,
  )) {
    return null;
  }
  final byRatio = (matchDurationSeconds *
              GameConfig.accusationUnlockTimeRatio)
          .floor() -
      elapsedSeconds;
  final minElimElapsed = MatchDurationScaling.accusationUnlockMinElapsedSeconds(
    matchDurationSeconds,
  );
  final byElim = eliminationCount >= 1
      ? minElimElapsed - elapsedSeconds
      : minElimElapsed;
  final candidates = <int>[];
  if (byRatio > 0) candidates.add(byRatio);
  if (eliminationCount < 1) {
    candidates.add(byElim);
  } else if (elapsedSeconds < minElimElapsed) {
    candidates.add(byElim);
  }
  if (candidates.isEmpty) return remainingSeconds;
  return candidates.reduce((a, b) => a < b ? a : b);
}

bool isAccusationTargetHunter({
  required Map<String, SharedPlayerAssignment> assignments,
  required String accusedUid,
}) {
  final a = assignments[accusedUid];
  return a?.role == PlayerRole.hunter;
}

String? hunterUidFromAssignments(Map<String, SharedPlayerAssignment> assignments) {
  for (final e in assignments.entries) {
    if (e.value.role == PlayerRole.hunter) return e.key;
  }
  return null;
}

bool canLocalPlayerAccuse({
  required PlayerRole localRole,
  required bool accusationUnlocked,
  required bool accusationSpent,
  required bool isEliminated,
  required int playerCount,
}) {
  if (!accusationEnabledForPlayerCount(playerCount)) return false;
  if (localRole != PlayerRole.runner) return false;
  if (!accusationUnlocked || accusationSpent || isEliminated) return false;
  return true;
}
