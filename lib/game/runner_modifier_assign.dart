import 'dart:math' as math;

import 'player_role.dart';
import 'runner_modifier.dart';
import '../sync/shared_match_snapshot.dart';
import 'game_config.dart';

/// 3人以上の試合で、逃走者にアナリスト/ハッカーを最大1名ずつ付与。
void assignRunnerModifiers({
  required Map<String, SharedPlayerAssignment> assignments,
  required math.Random rnd,
}) {
  if (assignments.length < GameConfig.accusationMinPlayers) return;

  final runnerKeys = assignments.entries
      .where((e) => e.value.role == PlayerRole.runner)
      .map((e) => e.key)
      .toList();
  if (runnerKeys.isEmpty) return;
  runnerKeys.shuffle(rnd);

  void setModifier(String uid, RunnerModifier mod) {
    final prev = assignments[uid]!;
    assignments[uid] = SharedPlayerAssignment(
      role: prev.role,
      skills: prev.skills,
      modifier: mod,
    );
  }

  setModifier(runnerKeys.first, RunnerModifier.analyst);
  if (runnerKeys.length >= 2) {
    setModifier(runnerKeys[1], RunnerModifier.hacker);
  }
}
