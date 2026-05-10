import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import 'match_record.dart';

/// 記録済み離散軌跡を「あと見返し／同期向け」に軽く間引く。
abstract final class TrajectorySimplify {
  /// 先頭維持。中間で `minSeparationMeters` 未満の移動は落とす。末尾は時間が最新になるよう必ず載せる。
  static List<TrajectorySample> minimumSeparation({
    required List<TrajectorySample> samples,
    required double minSeparationMeters,
    int maxPoints = 420,
  }) {
    if (samples.isEmpty) return const [];
    if (samples.length == 1) return List<TrajectorySample>.from(samples);

    final out = <TrajectorySample>[samples.first];
    for (var i = 1; i <= samples.length - 2; i++) {
      if (out.length >= maxPoints - 1) break;
      final cand = samples[i];
      final d = Geolocator.distanceBetween(
        out.last.position.latitude,
        out.last.position.longitude,
        cand.position.latitude,
        cand.position.longitude,
      );
      if (d >= minSeparationMeters) {
        out.add(cand);
      }
    }

    final last = samples.last;
    if (out.last.atUtc != last.atUtc ||
        !_almostSameLatLng(out.last.position, last.position)) {
      if (Geolocator.distanceBetween(
                out.last.position.latitude,
                out.last.position.longitude,
                last.position.latitude,
                last.position.longitude,
              ) >=
              minSeparationMeters ||
          out.last.atUtc != last.atUtc) {
        out.add(last);
      } else {
        out[out.length - 1] = last;
      }
    }

    if (out.length > maxPoints) {
      return _evenResample(out, maxPoints);
    }
    return out;
  }

  static bool _almostSameLatLng(LatLng a, LatLng b) {
    final d = Geolocator.distanceBetween(
      a.latitude,
      a.longitude,
      b.latitude,
      b.longitude,
    );
    return d < 2;
  }

  /// 均等間引き（極端に長いときの保険）。
  static List<TrajectorySample> _evenResample(
    List<TrajectorySample> list,
    int maxPoints,
  ) {
    if (list.length <= maxPoints) return list;
    final step = list.length / maxPoints;
    return List<TrajectorySample>.generate(
      maxPoints,
      (idx) => idx >= maxPoints - 1
          ? list.last
          : idx == 0
              ? list.first
              : list[(idx * step).floor().clamp(1, list.length - 2)],
    );
  }
}
