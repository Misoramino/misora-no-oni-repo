import 'package:google_maps_flutter/google_maps_flutter.dart';

/// 鬼位置の遅延軌跡用サンプル（ライブピンではなく過去の手がかり）。
class OniPathSample {
  const OniPathSample({required this.recordedAt, required this.position});

  final DateTime recordedAt;
  final LatLng position;
}

/// [samples] から「今から見て古いが遅延公開帯」内の点列を返す。
abstract final class OniPathTrailLogic {
  static List<LatLng> visibleTrailPoints({
    required List<OniPathSample> samples,
    required DateTime now,
    required int minAgeSeconds,
    required int maxAgeSeconds,
  }) {
    if (samples.isEmpty) return const [];
    final out = <LatLng>[];
    for (final s in samples) {
      final age = now.difference(s.recordedAt).inSeconds;
      if (age >= minAgeSeconds && age <= maxAgeSeconds) {
        out.add(s.position);
      }
    }
    return out;
  }

  static List<OniPathSample> prune({
    required List<OniPathSample> samples,
    required DateTime now,
    required int retainSeconds,
  }) {
    return samples
        .where((s) => now.difference(s.recordedAt).inSeconds <= retainSeconds)
        .toList(growable: false);
  }
}
