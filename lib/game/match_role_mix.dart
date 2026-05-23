import 'dart:math' as math;

import '../sync/shared_match_snapshot.dart';
import 'player_role.dart';

/// ランダム配分後の役職を、マルチ（2人以上・非カスタム）向けに補正する。
///
/// - 2人: 鬼または人狼が最低1人
/// - 3人以上: 鬼が最低1人
/// - 人数問わず: 全員鬼は禁止（最低1人は逃走者か人狼）
///
/// ソロ・カスタムルール時は呼び出さない。
void ensureViableRoleMix({
  required Map<String, SharedPlayerAssignment> assignments,
  required math.Random rnd,
  required List<String> Function(PlayerRole role) skillsFor,
}) {
  if (assignments.isEmpty) return;

  final keys = assignments.keys.toList();

  void setRole(String uid, PlayerRole role) {
    assignments[uid] = SharedPlayerAssignment(
      role: role,
      skills: skillsFor(role),
    );
  }

  bool hasHunter() =>
      assignments.values.any((a) => a.role == PlayerRole.hunter);

  bool hasAntagonist() => assignments.values.any(
        (a) =>
            a.role == PlayerRole.hunter || a.role == PlayerRole.werewolf,
      );

  bool allHunters() =>
      assignments.values.every((a) => a.role == PlayerRole.hunter);

  if (allHunters()) {
    setRole(keys[rnd.nextInt(keys.length)], PlayerRole.runner);
  }

  if (keys.length <= 2) {
    if (!hasAntagonist()) {
      setRole(
        keys[rnd.nextInt(keys.length)],
        rnd.nextBool() ? PlayerRole.hunter : PlayerRole.werewolf,
      );
    }
    return;
  }

  if (!hasHunter()) {
    final candidates = keys
        .where((k) => assignments[k]!.role != PlayerRole.hunter)
        .toList();
    if (candidates.isNotEmpty) {
      setRole(candidates[rnd.nextInt(candidates.length)], PlayerRole.hunter);
    }
  }

  if (allHunters()) {
    setRole(keys[rnd.nextInt(keys.length)], PlayerRole.runner);
  }
}
