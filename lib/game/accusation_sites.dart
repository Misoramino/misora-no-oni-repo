import 'dart:math' as math;

import 'package:google_maps_flutter/google_maps_flutter.dart';

/// 告発施設の**有効数**（マップ上で告発できる施設の数）。
///
/// - **解禁前**: 0（施設は地図にあっても告発不可）
/// - **解禁時**: 基本 1 箇所
/// - **脱落数・経過時間では増えない**（陣取りボーナス [territoryBonus] のみ）
///
/// 逃走側残響体（`spectral_territory`）と鬼側影（`facility_sabotage`）で [territoryBonus] を増減。
int activeAccusationSiteCount({
  required bool accusationUnlocked,
  required int siteCount,
  int territoryBonus = 0,
}) {
  if (!accusationUnlocked || siteCount <= 0) return 0;
  return (1 + territoryBonus).clamp(0, siteCount);
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
