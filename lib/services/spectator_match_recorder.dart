import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../game/game_state.dart';
import '../game/location_reveal_event.dart';
import '../game/match_event.dart';
import '../game/match_record.dart';
import '../game/play_area.dart';
import '../game/trajectory_simplify.dart';
import '../sync/inspector_feed_snapshot.dart';

/// 観戦中にインスペクターフィード・暴露ログから試合記録を組み立てる。
class SpectatorMatchRecorder {
  SpectatorMatchRecorder({DateTime? matchStartedAtUtc})
      : _startedAtUtc = matchStartedAtUtc ?? DateTime.now().toUtc();

  final DateTime _startedAtUtc;
  final Map<String, List<TrajectorySample>> _tracks = {};
  final Map<String, String> _trackLabels = {};
  final Map<String, DateTime> _lastSampleAt = {};
  bool _discarded = false;

  static const Duration _minGap = Duration(seconds: 4);

  void discard() => _discarded = true;

  void ingestInspectorFeed(Map<String, InspectorFeedSnapshot> feed) {
    if (_discarded) return;
    for (final snap in feed.values) {
      final trackId = 'player_${snap.uid}';
      _trackLabels[trackId] = _labelFor(snap);
      _append(
        trackId: trackId,
        atUtc: snap.reportedAtUtc.toUtc(),
        position: LatLng(snap.lat, snap.lng),
      );
    }
  }

  void ingestRevealLog(Iterable<LocationRevealEvent> reveals) {
    if (_discarded) return;
    for (final r in reveals) {
      final uid = r.subjectUid;
      final trackId = uid != null && uid.isNotEmpty
          ? 'player_$uid'
          : 'reveal_${r.playerLabel}';
      _trackLabels.putIfAbsent(
        trackId,
        () => uid != null ? trackId : '${r.playerLabel}（暴露）',
      );
      _append(
        trackId: trackId,
        atUtc: r.timestamp.toUtc(),
        position: r.position,
      );
    }
  }

  SavedMatchRecord? finalize({
    required GameState outcome,
    required PlayArea playArea,
    required List<LocationRevealEvent> reveals,
    required List<MatchEvent> events,
  }) {
    if (_discarded) return null;
    ingestRevealLog(reveals);

    if (_tracks.isEmpty) return null;

    final endedUtc = DateTime.now().toUtc();
    final simplified = <String, List<TrajectorySample>>{};
    for (final e in _tracks.entries) {
      simplified[e.key] = TrajectorySimplify.minimumSeparation(
        samples: e.value,
        minSeparationMeters: 6,
        maxPoints: 320,
      );
    }

    return SavedMatchRecord(
      version: SavedMatchRecord.currentVersion,
      id:
          'spectator_${_startedAtUtc.millisecondsSinceEpoch}_${outcome.name}_${endedUtc.millisecondsSinceEpoch}',
      startedAtUtc: _startedAtUtc,
      endedAtUtc: endedUtc,
      outcome: outcome,
      consentedToTrajectory: true,
      playArea: PlayArea.fromJson(playArea.toJson()),
      tracks: simplified,
      trackLabels: Map<String, String>.from(_trackLabels),
      reveals: List<LocationRevealEvent>.from(reveals)
        ..sort((a, b) => a.timestamp.compareTo(b.timestamp)),
      events: List<MatchEvent>.from(events)
        ..sort((a, b) => a.atUtc.compareTo(b.atUtc)),
    );
  }

  void _append({
    required String trackId,
    required DateTime atUtc,
    required LatLng position,
  }) {
    final last = _lastSampleAt[trackId];
    if (last != null && atUtc.difference(last) < _minGap) return;
    _lastSampleAt[trackId] = atUtc;
    _tracks.putIfAbsent(trackId, () => []).add(
          TrajectorySample(atUtc: atUtc, position: position),
        );
  }

  static String _labelFor(InspectorFeedSnapshot snap) {
    final nick = snap.nickname.trim();
    final role = switch (snap.role) {
      'oni' || 'hunter' => '鬼',
      'spectator' => '観戦',
      _ => '逃走者',
    };
    if (nick.isEmpty) return role;
    return '$nick（$role）';
  }
}
