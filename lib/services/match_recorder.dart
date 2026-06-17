import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../game/elimination_aftermath_rule.dart';
import '../game/game_state.dart';
import '../game/location_reveal_event.dart';
import '../game/match_event.dart';
import '../game/match_gimmick_layout.dart';
import '../game/match_record.dart';
import '../game/play_area.dart';
import '../game/werewolf_faction_logic.dart';
import '../game/trajectory_simplify.dart';
import '../features/game_map/replay/replay_track_kind.dart';

/// ローカル1端末での記録用トラックID（同期時はユーザーIDに差し替え）。
abstract final class MatchTrackIds {
  static const runnerLocal = 'runner_local';
  static const oniLocal = 'oni_local';
  static const secondGameLocal = 'second_game_local';
  static const spectralLocal = 'spectral_local';
  static const revengeOniLocal = 'revenge_oni_local';
  static const ghostSpectatorLocal = 'ghost_spectator_local';
}

/// ゲーム中のみ存在。同意があり、かつ破棄しない限り [finalize] で [SavedMatchRecord] を返す。
class MatchRecorder {
  MatchRecorder({
    required PlayArea playAreaSnapshot,
    required this.consentedToTrajectory,
    required LatLng initialRunner,
    required LatLng initialOni,
    this.recordOniTrack = true,
  })  : playAreaSnapshot = _copyArea(playAreaSnapshot),
        startedAtUtc = DateTime.now().toUtc() {
    final t = startedAtUtc;
    _runner.add(TrajectorySample(atUtc: t, position: initialRunner));
    if (recordOniTrack) {
      _oni.add(TrajectorySample(atUtc: t, position: initialOni));
      _lastOniUtc = t;
    }
    _lastRunnerUtc = t;
    _trackKinds[MatchTrackIds.runnerLocal] = ReplayTrackKind.survivor.name;
    if (recordOniTrack) {
      _trackKinds[MatchTrackIds.oniLocal] = ReplayTrackKind.oni.name;
    }
  }

  /// 鬼軌跡を記録するか（単独逃走など、鬼位置が不明なときは false）。
  final bool recordOniTrack;

  final DateTime startedAtUtc;
  final PlayArea playAreaSnapshot;
  final bool consentedToTrajectory;

  final List<TrajectorySample> _runner = [];
  final List<TrajectorySample> _oni = [];
  final Map<String, List<TrajectorySample>> _secondGameTracks = {};
  final Map<String, String> _trackLabels = {};
  final Map<String, String> _trackKinds = {};

  DateTime? _lastRunnerUtc;
  DateTime? _lastOniUtc;
  final Map<String, DateTime?> _lastSecondGameUtc = {};
  bool _discarded = false;
  bool _runnerEliminated = false;
  String? _activeSecondGameTrackId;

  static const Duration _minGap = Duration(seconds: 2);

  static PlayArea _copyArea(PlayArea a) =>
      PlayArea.fromJson(a.toJson());

  void tryAppendRunner(LatLng position) {
    if (_runnerEliminated) return;
    _appendThrottled(
      list: _runner,
      position: position,
      lastTime: _lastRunnerUtc,
      setter: (t) => _lastRunnerUtc = t,
    );
  }

  void tryAppendOni(LatLng position) {
    if (!recordOniTrack) return;
    _appendThrottled(
      list: _oni,
      position: position,
      lastTime: _lastOniUtc,
      setter: (t) => _lastOniUtc = t,
    );
  }

  /// 脱落後の第二ゲーム軌跡（生存軌跡とは別トラック）。
  void tryAppendSecondGame(LatLng position) {
    final trackId = _activeSecondGameTrackId;
    if (trackId == null) return;
    final list = _secondGameTracks.putIfAbsent(trackId, () => []);
    _appendThrottled(
      list: list,
      position: position,
      lastTime: _lastSecondGameUtc[trackId],
      setter: (t) => _lastSecondGameUtc[trackId] = t,
    );
  }

  /// 脱落時に呼ぶ。以降 [tryAppendRunner] は無効、[tryAppendSecondGame] が有効。
  void markRunnerEliminated(EliminationAftermathRule rule) {
    if (_discarded || _runnerEliminated) return;
    _runnerEliminated = true;
    final trackId = ReplayTrackStyle.trackIdForRule(rule);
    final kind = ReplayTrackStyle.kindForRule(rule);
    _activeSecondGameTrackId = trackId;
    _trackKinds[trackId] = kind.name;
    _trackLabels[trackId] = rule.label;
    final list = <TrajectorySample>[];
    if (_runner.isNotEmpty) {
      list.add(_runner.last);
    }
    _secondGameTracks[trackId] = list;
    _lastSecondGameUtc[trackId] = list.isNotEmpty ? list.last.atUtc : null;
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
    String? endReason,
    FactionSide? winningFaction,
    MatchGimmickLayout? gimmickLayout,
    String? worldProfile,
    String? onlineRoomId,
    int? onlineSessionKey,
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

    final tracks = <String, List<TrajectorySample>>{
      MatchTrackIds.runnerLocal: simplifiedRunner,
    };
    if (recordOniTrack && simplifiedOni.isNotEmpty) {
      tracks[MatchTrackIds.oniLocal] = simplifiedOni;
    }
    for (final entry in _secondGameTracks.entries) {
      if (entry.value.isEmpty) continue;
      tracks[entry.key] = entry.value.length >= 2
          ? TrajectorySimplify.minimumSeparation(
              samples: entry.value,
              minSeparationMeters: 8,
              maxPoints: 320,
            )
          : List<TrajectorySample>.from(entry.value);
    }

    return SavedMatchRecord(
      version: SavedMatchRecord.currentVersion,
      id: id,
      startedAtUtc: startedAtUtc,
      endedAtUtc: endedUtc,
      outcome: outcome,
      consentedToTrajectory: consentedToTrajectory,
      playArea: PlayArea.fromJson(playAreaSnapshot.toJson()),
      tracks: tracks,
      trackLabels: Map<String, String>.from(_trackLabels),
      trackKinds: Map<String, String>.from(_trackKinds),
      reveals: revealsCopy,
      events: eventsCopy,
      endReason: endReason,
      winningFaction: winningFaction,
      gimmickLayout: gimmickLayout,
      worldProfile: worldProfile,
      onlineRoomId: onlineRoomId,
      onlineSessionKey: onlineSessionKey,
    );
  }
}
