import 'dart:math' as math;

import '../sync/shared_match_snapshot.dart';
import 'player_role.dart';

/// ランダム配分後の役職を、マルチ（2人以上・非カスタム）向けに補正する。
///
/// 目安: 逃走者 ≧ 人狼 ≧ 鬼（鬼は基本1人）。
/// ソロ・カスタムルール時は呼び出さない。
void ensureViableRoleMix({
  required Map<String, SharedPlayerAssignment> assignments,
  required math.Random rnd,
  required List<String> Function(PlayerRole role) skillsFor,
}) {
  if (assignments.isEmpty) return;

  final keys = assignments.keys.toList();
  final n = keys.length;

  void setRole(String uid, PlayerRole role) {
    assignments[uid] = SharedPlayerAssignment(
      role: role,
      skills: skillsFor(role),
    );
  }

  if (n <= 2) {
    var hasAntagonist = assignments.values.any(
      (a) => a.role == PlayerRole.hunter || a.role == PlayerRole.werewolf,
    );
    if (assignments.values.every((a) => a.role == PlayerRole.hunter)) {
      setRole(keys[rnd.nextInt(keys.length)], PlayerRole.runner);
    }
    if (!hasAntagonist) {
      setRole(
        keys[rnd.nextInt(keys.length)],
        rnd.nextBool() ? PlayerRole.hunter : PlayerRole.werewolf,
      );
    }
    return;
  }

  final hunterCount = 1;
  final werewolfCount = n >= 6 ? 2 : 1;
  var runnerCount = n - hunterCount - werewolfCount;
  if (runnerCount < werewolfCount) {
    runnerCount = werewolfCount;
  }

  final pool = <PlayerRole>[
    ...List.filled(hunterCount, PlayerRole.hunter),
    ...List.filled(werewolfCount, PlayerRole.werewolf),
    ...List.filled(runnerCount, PlayerRole.runner),
  ];
  while (pool.length < n) {
    pool.add(PlayerRole.runner);
  }
  while (pool.length > n) {
    pool.removeLast();
  }
  pool.shuffle(rnd);

  for (var i = 0; i < keys.length; i++) {
    setRole(keys[i], pool[i]);
  }
}
