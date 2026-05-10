import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../game/game_state.dart';
import '../game/location_reveal_event.dart';
import '../game/match_event.dart';
import '../game/match_record.dart';
import '../game/play_area.dart';
import '../game/trajectory_simplify.dart';

/// ローカル1端末での記録用トラックID（同期時はユーザーIDに差し替え）。
abstract final class MatchTrackIds {
  static const runnerLocal = 'runner_local';
  static const oniLocal = 'oni_local';
}

/// ゲーム中のみ存在。同意があり、かつ破棄しない限り [finalize] で [SavedMatchRecord] を返す。
class MatchRecorder {
  MatchRecorder({
    required PlayArea playAreaSnapshot,
    required this.consentedToTrajectory,
    required LatLng initialRunner,
    required LatLng initialOni,
  })  : playAreaSnapshot = _copyArea(playAreaSnapshot),
        startedAtUtc = DateTime.now().toUtc() {
    final t = startedAtUtc;
    _runner.add(TrajectorySample(atUtc: t, position: initialRunner));
    _oni.add(TrajectorySample(atUtc: t, position: initialOni));
    _lastRunnerUtc = t;
    _lastOniUtc = t;
  }

  final DateTime startedAtUtc;
  final PlayArea playAreaSnapshot;
  final bool consentedToTrajectory;

  final List<TrajectorySample> _runner = [];
  final List<TrajectorySample> _oni = [];

  DateTime? _lastRunnerUtc;
  DateTime? _lastOniUtc;
  bool _discarded = false;

  static const Duration _minGap = Duration(seconds: 2);

  static PlayArea _copyArea(PlayArea a) =>
      PlayArea.fromJson(a.toJson());

  void tryAppendRunner(LatLng position) {
    _appendThrottled(
      list: _runner,
      position: position,
      lastTime: _lastRunnerUtc,
      setter: (t) => _lastRunnerUtc = t,
    );
  }

  void tryAppendOni(LatLng position) {
    _appendThrottled(
      list: _oni,
      position: position,
      lastTime: _lastOniUtc,
      setter: (t) => _lastOniUtc = t,
    );
  }

  void _appendThrottled({
    required List<TrajectorySample> list,
    required LatLng position,
    required DateTime? lastTime,
    required void Function(DateTime) setter,
  }) {
    if (_discarded || !consentedToTrajectory) return;
    final now = DateTime.now().toUtc();
    if (lastTime != null && now.difference(lastTime) < _minGap) return;
    setter(now);
    list.add(TrajectorySample(atUtc: now, position: position));
  }

  void discard() {
    _discarded = true;
  }

  SavedMatchRecord? finalize({
    required GameState outcome,
    required List<LocationRevealEvent> reveals,
    required List<MatchEvent> events,
  }) {
    if (_discarded || !consentedToTrajectory) return null;

    final endedUtc = DateTime.now().toUtc();
    final revealsCopy = List<LocationRevealEvent>.from(reveals)
      ..sort((a, b) => a.timestamp.compareTo(b.timestamp));
    final eventsCopy = List<MatchEvent>.from(events)
      ..sort((a, b) => a.atUtc.compareTo(b.atUtc));

    final id =
        'match_${startedAtUtc.millisecondsSinceEpoch}_${outcome.name}_${endedUtc.millisecondsSinceEpoch}';

    final simplifiedRunner = TrajectorySimplify.minimumSeparation(
      samples: _runner,
      minSeparationMeters: 8,
      maxPoints: 420,
    );
    final simplifiedOni = TrajectorySimplify.minimumSeparation(
      samples: _oni,
      minSeparationMeters: 8,
      maxPoints: 220,
    );

    return SavedMatchRecord(
      version: SavedMatchRecord.currentVersion,
      id: id,
      startedAtUtc: startedAtUtc,
      endedAtUtc: endedUtc,
      outcome: outcome,
      consentedToTrajectory: consentedToTrajectory,
      playArea: PlayArea.fromJson(playAreaSnapshot.toJson()),
      tracks: {
        MatchTrackIds.runnerLocal: simplifiedRunner,
        MatchTrackIds.oniLocal: simplifiedOni,
      },
      reveals: revealsCopy,
      events: eventsCopy,
    );
  }
}
