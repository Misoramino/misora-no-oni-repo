import 'package:google_maps_flutter/google_maps_flutter.dart';

import 'match_record.dart';

/// GPS 途切れ区間を再生向けに補間点で埋める（バックグラウンド・通信断の隙間）。
abstract final class TrajectoryGapFill {
  static List<TrajectorySample> densifyForReplay(
    List<TrajectorySample> samples, {
    Duration maxGap = const Duration(seconds: 90),
    Duration step = const Duration(seconds: 8),
  }) {
    if (samples.length < 2) return List<TrajectorySample>.from(samples);
    final sorted = List<TrajectorySample>.from(samples)
      ..sort((a, b) => a.atUtc.compareTo(b.atUtc));
    final out = <TrajectorySample>[sorted.first];
    for (var i = 1; i < sorted.length; i++) {
      final a = sorted[i - 1];
      final b = sorted[i];
      final gap = b.atUtc.difference(a.atUtc);
      if (gap > maxGap) {
        var t = a.atUtc.add(step);
        while (t.isBefore(b.atUtc)) {
          final frac = t.difference(a.atUtc).inMicroseconds /
              gap.inMicroseconds.clamp(1, 1 << 31);
          out.add(
            TrajectorySample(
              atUtc: t,
              position: LatLng(
                a.position.latitude +
                    (b.position.latitude - a.position.latitude) * frac,
                a.position.longitude +
                    (b.position.longitude - a.position.longitude) * frac,
              ),
            ),
          );
          t = t.add(step);
        }
      }
      out.add(b);
    }
    return out;
  }
}
