import 'dart:math' as math;

import 'player_role.dart';
import '../sync/shared_match_snapshot.dart';

/// 鬼用情報屋: 試合参加者から逃走者 UID を1人選ぶ。
String? pickRandomRunnerUid({
  required Map<String, SharedPlayerAssignment> assignments,
  String? excludeUid,
  math.Random? rnd,
}) {
  final runners = assignments.entries
      .where((e) => e.value.role == PlayerRole.runner && e.key != excludeUid)
      .map((e) => e.key)
      .toList();
  if (runners.isEmpty) return null;
  final r = rnd ?? math.Random();
  return runners[r.nextInt(runners.length)];
}
