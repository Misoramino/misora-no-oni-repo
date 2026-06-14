import 'dart:math' as math;

import '../sync/shared_match_snapshot.dart';
import 'player_role.dart';

/// 鬼・人狼・逃走者の人数がバランス制約を満たすか。
///
/// `H <= (R + W×0.5) <= 4×H` かつ `R >= W`（逃走者 ≧ 人狼）。
bool isBalancedAntagonistMix({
  required int hunterCount,
  required int runnerCount,
  required int werewolfCount,
}) {
  if (hunterCount < 1 || runnerCount < 0 || werewolfCount < 0) return false;
  if (runnerCount < werewolfCount) return false;
  final humanSide = runnerCount + werewolfCount * 0.5;
  return hunterCount <= humanSide && humanSide <= 4 * hunterCount;
}

int werewolfCountForPlayerCount(int playerCount) =>
    playerCount >= 6 ? 2 : 1;

/// 6人以上で条件付きに鬼を増やす。3〜5人は鬼1固定。
int hunterCountForPlayerCount(int playerCount, int werewolfCount) {
  if (playerCount < 6) return 1;
  final maxH = playerCount - werewolfCount - werewolfCount;
  if (maxH < 1) return 1;
  final target = (playerCount ~/ 4).clamp(1, maxH);
  for (var h = target; h >= 1; h--) {
    final r = playerCount - h - werewolfCount;
    if (isBalancedAntagonistMix(
      hunterCount: h,
      runnerCount: r,
      werewolfCount: werewolfCount,
    )) {
      return h;
    }
  }
  return 1;
}

/// ランダム配分後の役職を、マルチ（2人以上・非カスタム）向けに補正する。
///
/// ## 人数別（[RoleAssignMode.random] / カスタムオフ時）
///
/// | 人数 | 鬼 | 人狼 | 逃走者 |
/// |-----:|---:|-----:|-------:|
/// | 1 | 0〜1 | 0〜1 | 残り |
/// | 2 | 1 | 0 | 1 |
/// | 3 | 1 | 1 | 1 |
/// | 4 | 1 | 1 | 2 |
/// | 5 | 1 | 1 | 3 |
/// | 6+ | 1〜（条件付き） | 2（6人以上） | 残り |
///
/// 6人以上の鬼人数は `H <= (R + W×0.5) <= 4×H` を満たす範囲で増やす。
///
/// [RoleAssignMode.counts] のときはホスト設定の鬼・人狼人数で [assignByRoleCounts]。
/// カスタムルール ON のときは本補正を呼ばない。
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

  if (n == 1) {
    if (assignments.values.every((a) => a.role == PlayerRole.runner)) {
      setRole(
        keys.first,
        rnd.nextBool() ? PlayerRole.hunter : PlayerRole.werewolf,
      );
    }
    return;
  }

  if (n == 2) {
    // 2人: 必ず鬼1 + 逃走者1（鬼なしは即人陣営勝利のため人狼のみ不可）。
    keys.shuffle(rnd);
    setRole(keys[0], PlayerRole.hunter);
    setRole(keys[1], PlayerRole.runner);
    return;
  }

  final werewolfCount = werewolfCountForPlayerCount(n);
  var hunterCount = hunterCountForPlayerCount(n, werewolfCount);
  var runnerCount = n - hunterCount - werewolfCount;
  if (runnerCount < werewolfCount) {
    runnerCount = werewolfCount;
    hunterCount = n - werewolfCount - runnerCount;
    if (hunterCount < 1) hunterCount = 1;
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

/// ホストが指定した役職人数で配分する。
///
/// 鬼=[hunterCount]・人狼=[werewolfCount]・残り=逃走者。
/// 指定がメンバー数を超える場合はクランプ（鬼を優先、次に人狼）。
/// 2人のときは鬼1・逃走者1を強制（鬼なし試合を防ぐ）。
void assignByRoleCounts({
  required Map<String, SharedPlayerAssignment> assignments,
  required math.Random rnd,
  required int hunterCount,
  required int werewolfCount,
  required List<String> Function(PlayerRole role) skillsFor,
}) {
  if (assignments.isEmpty) return;
  final keys = assignments.keys.toList();
  final n = keys.length;

  var h = hunterCount.clamp(0, n);
  var w = werewolfCount.clamp(0, n - h);
  if (n == 2) {
    h = 1;
    w = 0;
  }

  final pool = <PlayerRole>[
    ...List.filled(h, PlayerRole.hunter),
    ...List.filled(w, PlayerRole.werewolf),
  ];
  while (pool.length < n) {
    pool.add(PlayerRole.runner);
  }
  pool.shuffle(rnd);

  for (var i = 0; i < keys.length; i++) {
    assignments[keys[i]] = SharedPlayerAssignment(
      role: pool[i],
      skills: skillsFor(pool[i]),
    );
  }
}
