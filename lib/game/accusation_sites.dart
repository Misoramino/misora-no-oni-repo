import 'dart:math' as math;

import 'package:google_maps_flutter/google_maps_flutter.dart';

import 'game_config.dart';

/// 告発施設の**有効数**（マップ上で告発できる施設の数）。
///
/// 配置された [siteCount] のうち、次の条件で 1 ずつ増える（最大 [siteCount]）。
/// 残響体の人数は**まだ**加算していません（今後の奪い合い設計用）。
///
/// | 条件 | 有効 +1 |
/// |------|---------|
/// | 常時 | 1（最低） |
/// | 脱落 1 人以上 | +1 |
/// | 経過 ≥ 試合時間の 60% | +1 |
/// | 脱落 2 人以上 | +1 |
///
/// 例: 施設 5 箇所・10 分試合 → 開始直後は 1、脱落1+5分後は最大 3、
/// 6 分経過（60%）で +1、脱落2 で +1 → 最大 4〜5。
int activeAccusationSiteCount({
  required int siteCount,
  required int eliminationCount,
  required int elapsedSeconds,
  required int matchDurationSeconds,
}) {
  if (siteCount <= 0) return 0;
  var active = 1;
  if (eliminationCount >= 1) active++;
  if (elapsedSeconds >=
      (matchDurationSeconds * GameConfig.accusationUnlockTimeRatio).floor()) {
    active++;
  }
  if (eliminationCount >= 2) active++;
  return active.clamp(1, siteCount);
}

/// [gimmickSeed] で決定的に有効インデックスを選ぶ。
List<int> pickActiveAccusationSiteIndices({
  required int gimmickSeed,
  required int siteCount,
  required int activeCount,
}) {
  if (siteCount <= 0 || activeCount <= 0) return const [];
  final indices = List<int>.generate(siteCount, (i) => i);
  final rnd = math.Random(gimmickSeed ^ (activeCount * 7919));
  indices.shuffle(rnd);
  final n = activeCount.clamp(1, siteCount);
  final picked = indices.take(n).toList()..sort();
  return picked;
}

bool isAccusationSiteActive(int index, Set<int> activeIndices) =>
    activeIndices.contains(index);

LatLng? nearestActiveAccusationSite({
  required LatLng player,
  required List<LatLng> sites,
  required Set<int> activeIndices,
}) {
  LatLng? best;
  var bestDist = double.infinity;
  for (final i in activeIndices) {
    if (i < 0 || i >= sites.length) continue;
    final p = sites[i];
    final d = _planarDistanceMeters(player, p);
    if (d < bestDist) {
      bestDist = d;
      best = p;
    }
  }
  return best;
}

double _planarDistanceMeters(LatLng a, LatLng b) {
  const mPerDegLat = 111320.0;
  final mPerDegLng =
      111320.0 * math.cos(a.latitude * math.pi / 180).clamp(0.2, 1.0);
  final dLat = (a.latitude - b.latitude) * mPerDegLat;
  final dLng = (a.longitude - b.longitude) * mPerDegLng;
  return math.sqrt(dLat * dLat + dLng * dLng);
}
