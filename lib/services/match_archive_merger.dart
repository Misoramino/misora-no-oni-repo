import '../game/game_state.dart';
import '../game/location_reveal_event.dart';
import '../game/match_event.dart';
import '../game/match_record.dart';
import '../game/play_area.dart';
import '../game/trajectory_gap_fill.dart';
import '../services/match_recorder.dart';

/// 端末ローカル記録と Firestore から取得した分散アーカイブを 1 本のリプレイ用記録に統合。
abstract final class MatchArchiveMerger {
  static SavedMatchRecord merge({
    required SavedMatchRecord local,
    required SavedMatchRecord remote,
    bool gapFill = true,
  }) {
    final tracks = Map<String, List<TrajectorySample>>.from(local.tracks);
    for (final entry in remote.tracks.entries) {
      if (entry.value.isEmpty) continue;
      if (entry.key.startsWith('player_') ||
          entry.key == MatchTrackIds.runnerLocal ||
          entry.key == MatchTrackIds.oniLocal ||
          entry.key == MatchTrackIds.spectralLocal ||
          entry.key == MatchTrackIds.revengeOniLocal ||
          entry.key == MatchTrackIds.ghostSpectatorLocal ||
          entry.key == MatchTrackIds.secondGameLocal) {
        tracks[entry.key] = gapFill
            ? TrajectoryGapFill.densifyForReplay(entry.value)
            : List<TrajectorySample>.from(entry.value);
      }
    }
    if (gapFill) {
      for (final id in [MatchTrackIds.runnerLocal, MatchTrackIds.oniLocal]) {
        final existing = tracks[id];
        if (existing != null && existing.length >= 2) {
          tracks[id] = TrajectoryGapFill.densifyForReplay(existing);
        }
      }
    }

    final labels = <String, String>{...local.trackLabels, ...remote.trackLabels};
    final events = _mergeEvents(local.events, remote.events);
    final reveals = _mergeReveals(local.reveals, remote.reveals);

    final started = _earliest(local.startedAtUtc, remote.startedAtUtc);
    final ended = _latest(local.endedAtUtc, remote.endedAtUtc);

    return SavedMatchRecord(
      version: local.version,
      id: local.id,
      startedAtUtc: started,
      endedAtUtc: ended,
      outcome:
          local.outcome != GameState.waiting ? local.outcome : remote.outcome,
      consentedToTrajectory: local.consentedToTrajectory,
      playArea: _preferPlayArea(local.playArea, remote.playArea),
      tracks: tracks,
      trackLabels: labels,
      trackKinds: {...local.trackKinds, ...remote.trackKinds},
      reveals: reveals,
      events: events,
      endReason: local.endReason ?? remote.endReason,
      winningFaction: local.winningFaction ?? remote.winningFaction,
      gimmickLayout: local.gimmickLayout ?? remote.gimmickLayout,
      worldProfile: local.worldProfile ?? remote.worldProfile,
      onlineRoomId: local.onlineRoomId ?? remote.onlineRoomId,
      onlineSessionKey: local.onlineSessionKey ?? remote.onlineSessionKey,
    );
  }

  static List<MatchEvent> _mergeEvents(
    List<MatchEvent> a,
    List<MatchEvent> b,
  ) {
    final seen = <String>{};
    final out = <MatchEvent>[];
    for (final ev in [...a, ...b]) {
      final key =
          '${ev.type}|${ev.atUtc.millisecondsSinceEpoch}|${ev.message}|${ev.position.latitude}|${ev.position.longitude}';
      if (seen.add(key)) out.add(ev);
    }
    out.sort((x, y) => x.atUtc.compareTo(y.atUtc));
    return out;
  }

  static List<LocationRevealEvent> _mergeReveals(
    List<LocationRevealEvent> a,
    List<LocationRevealEvent> b,
  ) {
    final seen = <String>{};
    final out = <LocationRevealEvent>[];
    for (final r in [...a, ...b]) {
      final key =
          '${r.sequence}|${r.timestamp.millisecondsSinceEpoch}|${r.position.latitude}|${r.position.longitude}';
      if (seen.add(key)) out.add(r);
    }
    out.sort((x, y) => x.timestamp.compareTo(y.timestamp));
    return out;
  }

  static DateTime _earliest(DateTime a, DateTime b) =>
      a.isBefore(b) ? a : b;

  static DateTime _latest(DateTime a, DateTime b) => a.isAfter(b) ? a : b;

  static PlayArea _preferPlayArea(PlayArea local, PlayArea remote) {
    if (local.radiusMeters > 10) return local;
    return remote.radiusMeters > 10 ? remote : local;
  }
}
