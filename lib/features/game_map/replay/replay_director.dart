import 'dart:math' as math;

import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../../game/game_state.dart';
import '../../../game/match_event.dart';
import '../../../game/match_record.dart';
import '../../../services/match_recorder.dart';

/// リプレイの視点モード（ゲームロジック非依存）。
enum ReplayPerspective {
  god,
  runner,
  oni,
  follow,
}

/// カメラ演出用のイベントキュー。
class ReplayCinematicCue {
  const ReplayCinematicCue({
    required this.atUtc,
    required this.position,
    required this.kind,
    required this.flashReveal,
    required this.playSfx,
    this.flashStrong = false,
    this.fadeMuted = false,
  });

  final DateTime atUtc;
  final LatLng position;
  final String kind;
  final bool flashReveal;
  final bool flashStrong;
  final bool playSfx;
  final bool fadeMuted;
}

/// タイムラプス再生の演出判断（純粋ロジック・テスト可能）。
abstract final class ReplayDirector {
  static const cinematicZoom = 16.8;
  static const cinematicHoldMs = 800;
  static const cinematicReturnMs = 800;

  static double progressForTime({
    required DateTime t,
    required DateTime start,
    required int spanMs,
  }) {
    final ms = t.difference(start).inMilliseconds;
    if (spanMs <= 0) return 0;
    return (ms / spanMs).clamp(0.0, 1.0);
  }

  static DateTime timeForProgress({
    required double progress,
    required DateTime start,
    required int spanMs,
  }) =>
      start.add(Duration(milliseconds: (progress.clamp(0, 1) * spanMs).round()));

  static String? primaryTrackForPerspective({
    required ReplayPerspective perspective,
    required SavedMatchRecord record,
    String? followTrackId,
  }) {
    return switch (perspective) {
      ReplayPerspective.god => null,
      ReplayPerspective.runner => _firstTrack(
          record,
          prefer: MatchTrackIds.runnerLocal,
          roleHint: '逃走',
        ),
      ReplayPerspective.oni => _firstTrack(
          record,
          prefer: MatchTrackIds.oniLocal,
          roleHint: '鬼',
        ),
      ReplayPerspective.follow => followTrackId ??
          record.tracks.keys.firstWhere(
            (k) => record.tracks[k]?.isNotEmpty ?? false,
            orElse: () => MatchTrackIds.runnerLocal,
          ),
    };
  }

  static String? _firstTrack(
    SavedMatchRecord record, {
    required String prefer,
    required String roleHint,
  }) {
    if (record.tracks[prefer]?.isNotEmpty ?? false) return prefer;
    for (final e in record.trackLabels.entries) {
      if (e.value.contains(roleHint)) return e.key;
    }
    for (final e in record.tracks.entries) {
      if (e.key.contains('oni') || e.key == MatchTrackIds.oniLocal) {
        if (e.value.isNotEmpty) return e.key;
      }
    }
    for (final e in record.tracks.entries) {
      if (e.value.isNotEmpty) return e.key;
    }
    return null;
  }

  static double estimateSpeedMps(
    List<TrajectorySample> samples,
    DateTime t, {
    Duration window = const Duration(seconds: 12),
  }) {
    if (samples.length < 2) return 0;
    TrajectorySample? before;
    TrajectorySample? after;
    for (final s in samples) {
      if (!s.atUtc.isAfter(t)) before = s;
      if (s.atUtc.isAfter(t)) {
        after = s;
        break;
      }
    }
    before ??= samples.first;
    after ??= samples.last;
    final span = after.atUtc.difference(before.atUtc).inMilliseconds;
    if (span <= 0) return 0;
    final meters = _haversineMeters(before.position, after.position);
    final speed = meters / (span / 1000);
    if (window.inSeconds > 0) {
      return speed.clamp(0, 12);
    }
    return speed;
  }

  static bool isIdle(
    List<TrajectorySample> samples,
    DateTime t, {
    double thresholdMps = 0.35,
  }) =>
      estimateSpeedMps(samples, t) < thresholdMps;

  static bool isNearCapture(
    List<MatchEvent> events,
    DateTime t, {
    Duration window = const Duration(seconds: 10),
  }) {
    for (final e in events) {
      final type = e.type;
      if (!type.contains('capture')) continue;
      final delta = t.difference(e.atUtc).abs();
      if (delta <= window) return true;
    }
    return false;
  }

  static double trailWidth({
    required String trackId,
    required double baseWidth,
    required double speedMps,
    required bool idle,
    required bool captureEmphasis,
    required double pulsePhase,
  }) {
    var w = baseWidth;
    if (speedMps > 2.5) {
      w += (speedMps / 12).clamp(0, 1) * 1.2;
    } else if (speedMps < 0.8) {
      w -= 0.4;
    }
    if (idle) {
      w += 0.45 * math.sin(pulsePhase);
    }
    if (captureEmphasis &&
        (trackId == MatchTrackIds.oniLocal || trackId.contains('oni'))) {
      w += 1.4;
    }
    return w.clamp(2.5, 9);
  }

  static double trailGlowAlpha({
    required bool idle,
    required bool captureEmphasis,
    required double pulsePhase,
  }) {
    var a = 0.22;
    if (idle) a += 0.06 * (0.5 + 0.5 * math.sin(pulsePhase));
    if (captureEmphasis) a += 0.12;
    return a.clamp(0.12, 0.42);
  }

  static double _haversineMeters(LatLng a, LatLng b) {
    const r = 6371000.0;
    final dLat = _rad(b.latitude - a.latitude);
    final dLng = _rad(b.longitude - a.longitude);
    final lat1 = _rad(a.latitude);
    final lat2 = _rad(b.latitude);
    final h = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(lat1) *
            math.cos(lat2) *
            math.sin(dLng / 2) *
            math.sin(dLng / 2);
    return r * 2 * math.atan2(math.sqrt(h), math.sqrt(1 - h));
  }

  static double _rad(double deg) => deg * math.pi / 180;

  /// 終了ホールド時に強調する軌跡（勝者側を優先）。
  static String? endEmphasisTrackId(SavedMatchRecord record) {
    if (record.outcome == GameState.runnerWin) {
      if (record.tracks[MatchTrackIds.runnerLocal]?.isNotEmpty ?? false) {
        return MatchTrackIds.runnerLocal;
      }
    }
    if (record.outcome == GameState.caughtByOni) {
      if (record.tracks[MatchTrackIds.oniLocal]?.isNotEmpty ?? false) {
        return MatchTrackIds.oniLocal;
      }
    }
    for (final e in record.tracks.entries) {
      if (e.value.isNotEmpty) return e.key;
    }
    return null;
  }
}
