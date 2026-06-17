import '../../../game/location_reveal_event.dart';
import '../../../game/match_event.dart';
import '../../../game/match_record.dart';

/// タイムラプス再生の時間軸・軌跡クリップ（テスト可能）。
abstract final class ReplayTimelineUtils {
  static List<TrajectorySample> samplesUpTo(
    List<TrajectorySample> samples,
    DateTime tUtc,
  ) {
    return [
      for (final s in samples)
        if (!s.atUtc.isAfter(tUtc)) s,
    ];
  }

  /// 記録メタ・軌跡・暴露・イベントから再生区間を決める。
  static (DateTime start, DateTime end) computeSpan({
    required DateTime recordStart,
    required DateTime recordEnd,
    required Map<String, List<TrajectorySample>> tracks,
    required List<LocationRevealEvent> reveals,
    required List<MatchEvent> events,
    Set<String>? visibleTrackIds,
  }) {
    var start = recordStart.toUtc();
    var end = recordEnd.toUtc();

    void consider(DateTime t) {
      final u = t.toUtc();
      if (u.isBefore(start)) start = u;
      if (u.isAfter(end)) end = u;
    }

    for (final e in tracks.entries) {
      if (visibleTrackIds != null && !(visibleTrackIds.contains(e.key))) {
        continue;
      }
      for (final s in e.value) {
        consider(s.atUtc);
      }
    }
    for (final r in reveals) {
      consider(r.timestamp);
    }
    for (final e in events) {
      consider(e.atUtc);
    }

    if (!end.isAfter(start)) {
      end = start.add(const Duration(seconds: 2));
    }
    if (end.difference(start).inMilliseconds < 2000) {
      end = start.add(const Duration(seconds: 2));
    }
    return (start, end);
  }

  static bool isRevealFlashAt({
    required List<LocationRevealEvent> reveals,
    required List<MatchEvent> events,
    required DateTime tNow,
    Duration window = const Duration(milliseconds: 500),
  }) {
    for (final r in reveals) {
      if (!r.timestamp.isAfter(tNow) &&
          tNow.difference(r.timestamp) <= window) {
        return true;
      }
    }
    for (final e in events) {
      if (!e.type.contains('reveal')) continue;
      if (!e.atUtc.isAfter(tNow) && tNow.difference(e.atUtc) <= window) {
        return true;
      }
    }
    return false;
  }
}
