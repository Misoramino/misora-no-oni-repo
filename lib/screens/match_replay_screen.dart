import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../audio/game_audio.dart';
import '../audio/world_audio_director.dart';
import '../audio/world_audio_state.dart';
import '../features/game_map/replay/replay_capture_zone.dart';
import '../features/game_map/replay/replay_director.dart';
import '../features/game_map/replay/replay_event_cues.dart';
import '../features/game_map/replay/replay_record_enricher.dart';
import '../features/game_map/replay/replay_sfx_gate.dart';
import '../features/game_map/replay/replay_track_kind.dart';
import '../game/game_state.dart';
import '../game/game_config.dart';
import '../game/match_event.dart';
import '../game/match_record.dart';
import '../game/play_area.dart';
import '../features/game_map/map/map_marker_kind.dart';
import '../features/game_map/map/map_replay_marker_helper.dart';
import '../features/game_map/replay/replay_timeline_utils.dart';
import '../features/game_map/widgets/match_flow_timeline.dart';
import '../sync/firestore_room_blueprint.dart';
import '../features/game_map/visual/map_visual_controller.dart';
import '../features/game_map/visual/reveal_flash_controller.dart';
import '../features/game_map/widgets/world_map_atmosphere.dart';
import '../services/match_recorder.dart';
import '../session/world_profile_prefs.dart';
import '../theme/world_profile.dart';
import '../presentation/world/world_presentation_catalog.dart';
import '../presentation/world/world_presentation_pack.dart';
import '../presentation/world/world_presentation_context.dart';

/// タイムラプス風に軌跡を再生する画面。
class MatchReplayScreen extends StatefulWidget {
  const MatchReplayScreen({super.key, required this.record});

  final SavedMatchRecord record;

  @override
  State<MatchReplayScreen> createState() => _MatchReplayScreenState();
}

class _MatchReplayScreenState extends State<MatchReplayScreen> {
  late final SavedMatchRecord _record;
  GoogleMapController? _controller;
  Timer? _clock;

  double _progress = 0;
  double _speed = 8;
  bool _playing = false;

  /// トラックIDごとの線・マーカー表示（参加者が増えても対応）。
  late Map<String, bool> _trackVisible;
  bool _showEventMarkers = true;
  bool _showRevealMarkers = true;
  bool _showGimmickMarkers = true;
  bool _showPlayArea = true;
  bool _followCamera = true;
  DateTime? _lastCameraFollowAt;
  bool _panelExpanded = false;
  late MapVisualController _mapVisual;
  bool _visualReady = false;
  late RevealFlashController _revealFlash;
  ReplayPerspective _perspective = ReplayPerspective.god;
  String? _followTrackId;
  DateTime? _lastTickUtc;
  DateTime? _cinematicUntil;
  LatLng? _cinematicTarget;
  final Set<String> _firedCueKeys = {};
  final ReplaySfxGate _sfxGate = ReplaySfxGate();
  late final List<ReplayCaptureZone> _captureZones;
  bool _endingHold = false;
  double _pulsePhase = 0;
  WorldAudioState? _audioRestoreState;
  WorldProfile? _audioRestoreProfile;
  static const _speedPresets = <double>[1, 2, 4, 8, 16, 24];

  @override
  void initState() {
    super.initState();
    _record = ReplayRecordEnricher.prepare(widget.record);
    _captureZones = ReplayCaptureZoneCatalog.fromEvents(_record.events);
    _trackVisible = {
      for (final k in _record.tracks.keys) k: true,
    };
    _mapVisual = MapVisualController(_record.effectiveWorldProfile);
    _revealFlash = RevealFlashController(() {
      if (mounted) setState(() {});
    });
    Future<void>.microtask(_loadReplayVisual);
  }

  Future<void> _loadReplayVisual() async {
    final profile = _record.worldProfile != null
        ? WorldProfile.fromStorageName(_record.worldProfile)
        : await WorldProfilePrefs.load();
    await _mapVisual.reloadForProfile(profile);
    if (!mounted) return;
    setState(() => _visualReady = true);
    await _enterReplayAudio(profile);
  }

  Future<void> _fitMapToContent() async {
    final bounds = _computeFitBounds();
    final c = _controller;
    if (bounds == null || c == null) return;
    await c.animateCamera(CameraUpdate.newLatLngBounds(bounds, 54));
  }

  (DateTime, DateTime) get _timeline {
    final visible = {
      for (final e in _record.tracks.entries)
        if (_trackVisible[e.key] ?? true) e.key,
    };
    return ReplayTimelineUtils.computeSpan(
      recordStart: _record.startedAtUtc,
      recordEnd: _record.endedAtUtc,
      tracks: _record.tracks,
      reveals: _record.reveals,
      events: _record.events,
      visibleTrackIds: visible,
    );
  }

  int get _virtualSpanMs {
    final range = _timeline;
    final ms = range.$2.difference(range.$1).inMilliseconds;
    return math.max(2000, ms);
  }

  DateTime _timeAtProgress(double p) {
    final range = _timeline;
    final clamped = p.clamp(0.0, 1.0);
    return range.$1.add(
      Duration(milliseconds: (clamped * _virtualSpanMs).round()),
    );
  }

  @override
  void dispose() {
    _clock?.cancel();
    _revealFlash.dispose();
    if (_audioRestoreProfile != null && _audioRestoreState != null) {
      unawaited(
        WorldAudioDirector.instance.leaveReplay(
          restoreProfile: _audioRestoreProfile!,
          restoreState: _audioRestoreState!,
        ),
      );
    }
    _controller?.dispose();
    super.dispose();
  }

  Future<void> _enterReplayAudio(WorldProfile profile) async {
    final director = WorldAudioDirector.instance;
    _audioRestoreState ??= director.state;
    _audioRestoreProfile ??= director.profile ?? profile;
    await director.enter(WorldAudioState.replay, profile: profile);
  }

  void _tick(Timer _) {
    if (!_playing || !mounted || _endingHold) return;
    final prev = _lastTickUtc ?? _timeAtProgress(_progress);
    const dtMs = 50;
    final v = _virtualSpanMs.toDouble();
    setState(() {
      _pulsePhase += 0.11;
      _progress += (dtMs * _speed) / v;
      if (_progress >= 1) {
        _progress = 1;
        _playing = false;
        _clock?.cancel();
        _beginEndingHold();
      }
    });
    final tNow = _timeAtProgress(_progress);
    _processTimelineCues(prev, tNow);
    _lastTickUtc = tNow;
    _maybeRevealFlashAt(tNow);
    _updateCamera(tNow);
    _maybePulseClearEffect();
  }

  void _beginEndingHold() {
    if (_endingHold) return;
    _endingHold = true;
    final endTrack = ReplayDirector.endEmphasisTrackId(_record);
    if (endTrack != null) {
      setState(() => _followTrackId = endTrack);
      final pos = interpolateAlongTrack(
        _record.tracks[endTrack] ?? const [],
        _record.endedAtUtc,
      );
      if (pos != null) {
        _cinematicTarget = pos;
        _cinematicUntil = DateTime.now().add(
          const Duration(milliseconds: ReplayDirector.cinematicHoldMs),
        );
      }
    }
    unawaited(_fadeOutAndLeaveReplay());
    Future<void>.delayed(const Duration(milliseconds: 2800), () {
      if (!mounted) return;
      Navigator.of(context).maybePop();
    });
  }

  Future<void> _fadeOutAndLeaveReplay() async {
    await GameAudio.instance.stopAllMusicLayers(fadeMs: 520);
    final restoreProfile = _audioRestoreProfile;
    final restoreState = _audioRestoreState;
    if (restoreProfile != null && restoreState != null) {
      await WorldAudioDirector.instance.leaveReplay(
        restoreProfile: restoreProfile,
        restoreState: restoreState,
      );
    }
    _audioRestoreProfile = null;
    _audioRestoreState = null;
  }

  void _processTimelineCues(DateTime prev, DateTime tNow) {
    for (final e in _record.events) {
      if (e.atUtc.isAfter(prev) && !e.atUtc.isAfter(tNow)) {
        _fireCue(ReplayEventCues.fromMatchEvent(e));
      }
    }
    for (final r in _record.reveals) {
      if (r.timestamp.isAfter(prev) && !r.timestamp.isAfter(tNow)) {
        _fireCue(ReplayEventCues.fromReveal(r));
      }
    }
  }

  void _fireCue(ReplayCinematicCue cue) {
    final key = ReplayEventCues.cueKey(cue);
    if (!_firedCueKeys.add(key)) return;
    if (cue.flashReveal && _mapVisual.pack.revealFlashColor != null) {
      _revealFlash.trigger(_mapVisual.pack);
    }
    if (cue.playSfx) {
      final sfx = ReplayEventCues.sfxForCue(
        cue,
        endReason: _record.endReason,
        outcomeName: _record.outcome.name,
      );
      if (sfx != null &&
          _sfxGate.tryAcquire(
            cueKind: cue.kind,
            replaySpeed: _speed,
            sfx: sfx,
          )) {
        unawaited(
          GameAudio.instance.playWorldSfx(
            sfx,
            profile: _mapVisual.pack.profile,
          ),
        );
      }
    }
    _cinematicTarget = cue.position;
    _cinematicUntil = DateTime.now().add(
      Duration(
        milliseconds: cue.flashStrong
            ? ReplayDirector.cinematicHoldMs + 200
            : ReplayDirector.cinematicHoldMs,
      ),
    );
    if (_perspective == ReplayPerspective.follow && _followTrackId != null) {
      // イベント時は対象付近へ視線誘導（追跡モード時）
      _lastCameraFollowAt = null;
    }
  }

  void _updateCamera(DateTime tNow) {
    final c = _controller;
    if (c == null) return;
    final now = DateTime.now();
    if (_cinematicUntil != null &&
        _cinematicTarget != null &&
        now.isBefore(_cinematicUntil!)) {
      unawaited(
        c.animateCamera(
          CameraUpdate.newCameraPosition(
            CameraPosition(
              target: _cinematicTarget!,
              zoom: ReplayDirector.cinematicZoom,
            ),
          ),
          duration: const Duration(milliseconds: 800),
        ),
      );
      return;
    }
    if (_cinematicUntil != null &&
        _cinematicTarget != null &&
        now.difference(_cinematicUntil!) <
            const Duration(milliseconds: ReplayDirector.cinematicReturnMs)) {
      return;
    }
    _cinematicUntil = null;
    _cinematicTarget = null;
    if (!_playing || !_followCamera) return;
    if (_lastCameraFollowAt != null &&
        now.difference(_lastCameraFollowAt!) <
            const Duration(milliseconds: 500)) {
      return;
    }
    final pos = _cameraTargetAt(tNow);
    if (pos == null) return;
    _lastCameraFollowAt = now;
    unawaited(
      c.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(target: pos, zoom: 15.2),
        ),
        duration: const Duration(milliseconds: 650),
      ),
    );
  }

  LatLng? _cameraTargetAt(DateTime tUtc) {
    final trackId = ReplayDirector.primaryTrackForPerspective(
      perspective: _perspective,
      record: _record,
      followTrackId: _followTrackId,
    );
    if (trackId != null) {
      final samples = _record.tracks[trackId];
      if (samples != null && samples.isNotEmpty) {
        return interpolateAlongTrack(samples, tUtc);
      }
    }
    return _firstVisiblePositionAt(tUtc);
  }

  void _seekToTime(DateTime at) {
    final range = _timeline;
    final p = ReplayDirector.progressForTime(
      t: at,
      start: range.$1,
      spanMs: _virtualSpanMs,
    );
    setState(() {
      _progress = p;
      _celebrationShown = false;
      _endingHold = false;
      _lastTickUtc = at;
    });
    _maybeRevealFlashAt(at);
    _seekCameraToCurrent(at);
  }

  Future<void> _seekCameraToCurrent(DateTime tNow) async {
    final c = _controller;
    final pos = _cameraTargetAt(tNow);
    if (c == null || pos == null) return;
    await c.animateCamera(CameraUpdate.newLatLng(pos));
  }

  void _maybeRevealFlashAt(DateTime tNow) {
    if (_mapVisual.pack.revealFlashColor == null) return;
    final hit = ReplayTimelineUtils.isRevealFlashAt(
      reveals: _record.reveals,
      events: _record.events,
      tNow: tNow,
    );
    if (!hit || _revealFlash.active) return;
    _revealFlash.trigger(_mapVisual.pack);
  }

  void _setPlaying(bool v) {
    setState(() {
      _playing = v;
      if (_playing) {
        if (_progress >= 1) _progress = 0;
        _clock?.cancel();
        _clock = Timer.periodic(const Duration(milliseconds: 50), _tick);
      } else {
        _clock?.cancel();
      }
    });
  }

  bool _celebrationShown = false;
  void _maybePulseClearEffect() {
    if (_celebrationShown) return;
    if (_record.outcome != GameState.runnerWin) return;
    if (_progress >= 0.92) {
      _celebrationShown = true;
      HapticFeedback.mediumImpact();
    }
  }

  LatLngBounds? _computeFitBounds() {
    var minLat = 90.0;
    var maxLat = -90.0;
    var minLng = 180.0;
    var maxLng = -180.0;
    void add(LatLng p) {
      minLat = math.min(minLat, p.latitude);
      maxLat = math.max(maxLat, p.latitude);
      minLng = math.min(minLng, p.longitude);
      maxLng = math.max(maxLng, p.longitude);
    }

    for (final e in _record.tracks.entries) {
      if (!(_trackVisible[e.key] ?? true)) continue;
      for (final s in e.value) {
        add(s.position);
      }
    }
    final a = _record.playArea;
    switch (a.type) {
      case PlayAreaType.circle:
        final d = (a.radiusMeters / 111111).clamp(0.0003, 0.06);
        add(LatLng(a.center.latitude + d, a.center.longitude));
        add(LatLng(a.center.latitude - d, a.center.longitude));
      case PlayAreaType.polygon:
        for (final p in a.points) {
          add(p);
        }
    }
    if (!maxLat.isFinite || minLat > maxLat || minLng > maxLng) return null;

    final pad = math.max(maxLat - minLat, maxLng - minLng) * 0.08 + 1e-4;
    return LatLngBounds(
      southwest: LatLng(minLat - pad, minLng - pad),
      northeast: LatLng(maxLat + pad, maxLng + pad),
    );
  }

  @override
  Widget build(BuildContext context) {
    final range = _timeline;
    final tNow = _timeAtProgress(_progress);

    final playArea = _record.playArea;
    final lines = _buildTrailPolylines(tNow);
    final markers = _buildMarkersAt(tNow)
      ..addAll(_buildEventMarkers(tNow))
      ..addAll(_buildRevealMarkers(tNow))
      ..addAll(_buildGimmickMarkers());
    final captureCircles = _buildCaptureZoneCircles(tNow);
    final fallbackTarget =
        _firstVisiblePositionAt(tNow) ??
            _record.playArea.centerOrFirstPoint;
    final recentEvents = _eventsNear(tNow, const Duration(seconds: 25));
    final bounds = _computeFitBounds();

    final captureNear =
        ReplayDirector.isNearCapture(_record.events, tNow);
    final dangerPulse = captureNear ? 0.35 + 0.15 * math.sin(_pulsePhase) : 0.0;
    final replayProfile = _visualReady
        ? _mapVisual.pack.profile
        : _record.effectiveWorldProfile;
    final uiPack = WorldPresentationCatalog.of(replayProfile);

    return Theme(
      data: Theme.of(context).copyWith(
        extensions: [WorldProfileTheme(replayProfile)],
        chipTheme: ChipThemeData(
          backgroundColor: uiPack.panelSurface,
          selectedColor: uiPack.accent.withValues(alpha: 0.28),
          labelStyle: TextStyle(color: uiPack.textOnPanel, fontSize: 12),
          secondaryLabelStyle: TextStyle(color: uiPack.textOnPanel, fontSize: 12),
          side: BorderSide(color: uiPack.panelBorder),
          checkmarkColor: uiPack.accent,
        ),
      ),
      child: Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
                _record.galleryTitle,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              if (_record.endReason != null)
                Text(
                  _endReasonLabel(_record.endReason!),
                  style: Theme.of(context).textTheme.labelSmall,
                ),
            if (_visualReady)
              Text(
                _mapVisual.pack.profile.label,
                style: Theme.of(context).textTheme.labelSmall,
              ),
          ],
        ),
        actions: const [],
      ),
      body: !_visualReady
          ? const Center(child: CircularProgressIndicator())
          : Stack(
        children: [
          Positioned.fill(
            child: IgnorePointer(
              child: WorldMapAtmosphere(
                pack: _mapVisual.pack,
                dangerPulse: dangerPulse,
                revealFlashActive: _revealFlash.active,
                scanPhase: _playing ? _progress : 0,
                revealNoiseSeed: _revealFlash.noiseSeed,
              ),
            ),
          ),
          GoogleMap(
            style: _mapVisual.mapStyleJson,
            initialCameraPosition: CameraPosition(
              target: fallbackTarget,
              zoom: 15,
            ),
            myLocationEnabled: false,
            myLocationButtonEnabled: false,
            zoomGesturesEnabled: true,
            scrollGesturesEnabled: true,
            rotateGesturesEnabled: true,
            tiltGesturesEnabled: false,
            onMapCreated: (c) {
              _controller = c;
              if (bounds != null) {
                Future<void>.delayed(const Duration(milliseconds: 320), () {
                  if (!mounted || _controller == null) return;
                  unawaited(_fitMapToContent());
                });
              }
            },
            polylines: lines,
            markers: markers,
            circles: {
              ...captureCircles,
              if (_showPlayArea && playArea.type == PlayAreaType.circle)
                Circle(
                  circleId: const CircleId('replay-area'),
                  center: playArea.center,
                  radius: playArea.radiusMeters,
                  strokeWidth: 2,
                  fillColor: _mapVisual.pack.tokens.playAreaColor
                      .withValues(alpha: 0.12),
                  strokeColor: _mapVisual.pack.tokens.playAreaColor,
                ),
            },
            polygons: _showPlayArea && playArea.type == PlayAreaType.polygon
                ? {
                    Polygon(
                      polygonId: const PolygonId('replay-area'),
                      points: playArea.points,
                      strokeWidth: 2,
                      fillColor: _mapVisual.pack.tokens.playAreaColor
                          .withValues(alpha: 0.12),
                      strokeColor: _mapVisual.pack.tokens.playAreaColor,
                    ),
                  }
                : {},
          ),
          if (_record.endReason != MatchEndReason.hostAbort &&
              _record.outcome == GameState.runnerWin &&
              _progress >= 0.9)
            Positioned.fill(
              child: IgnorePointer(
                child: Container(
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    gradient: RadialGradient(
                      colors: [
                        _mapVisual.pack.tokens.markerAccent.withValues(
                          alpha: 0.15 * ((_progress - 0.9) / 0.1).clamp(0.0, 1.0),
                        ),
                        Colors.transparent,
                      ],
                    ),
                  ),
                  child: Text(
                    'CLEAR',
                    style: TextStyle(
                      fontSize: 42,
                      fontWeight: FontWeight.w900,
                      color: _mapVisual.pack.tokens.markerAccent
                          .withValues(alpha: 0.65),
                      letterSpacing: 4,
                    ),
                  ),
                ),
              ),
            ),
          Positioned(
            top: 8,
            left: 8,
            right: 8,
            child: _ReplayLayerToolbar(
              pack: uiPack,
              showGimmicks: _record.gimmickLayout != null,
              showEventMarkers: _showEventMarkers,
              showRevealMarkers: _showRevealMarkers,
              followCamera: _followCamera,
              showGimmickMarkers: _showGimmickMarkers,
              showPlayArea: _showPlayArea,
              onToggleEvents: () =>
                  setState(() => _showEventMarkers = !_showEventMarkers),
              onToggleReveals: () =>
                  setState(() => _showRevealMarkers = !_showRevealMarkers),
              onToggleFollow: () =>
                  setState(() => _followCamera = !_followCamera),
              onToggleGimmicks: () =>
                  setState(() => _showGimmickMarkers = !_showGimmickMarkers),
              onTogglePlayArea: () =>
                  setState(() => _showPlayArea = !_showPlayArea),
              onFitAll: () => unawaited(_fitMapToContent()),
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Material(
              elevation: 10,
              color: uiPack.panelSurface,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  InkWell(
                    onTap: () => setState(() => _panelExpanded = !_panelExpanded),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      child: Row(
                        children: [
                          IconButton.outlined(
                            onPressed: () => _setPlaying(!_playing),
                            icon: Icon(_playing ? Icons.pause : Icons.play_arrow),
                            tooltip: _playing ? '一時停止' : '再生',
                          ),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Text(
                                  '${_progressFraction()} · ${_speed.round()}x · ${_progressLabel(range)}',
                                  style: Theme.of(context)
                                      .textTheme
                                      .labelMedium
                                      ?.copyWith(color: uiPack.textOnPanel),
                                ),
                                Slider(
                                  value: _progress.clamp(0, 1),
                                  onChanged: (v) {
                                    setState(() {
                                      _progress = v;
                                      _celebrationShown = false;
                                      _endingHold = false;
                                      _lastTickUtc = _timeAtProgress(v);
                                    });
                                    _maybeRevealFlashAt(_timeAtProgress(v));
                                  },
                                ),
                              ],
                            ),
                          ),
                          Icon(
                            _panelExpanded
                                ? Icons.expand_more
                                : Icons.expand_less,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '詳細',
                            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                  color: uiPack.textOnPanel.withValues(alpha: 0.75),
                                ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (_panelExpanded)
                    Padding(
                      padding: EdgeInsets.only(
                        left: 12,
                        right: 12,
                        bottom: 12 + MediaQuery.paddingOf(context).bottom,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '軌跡の表示',
                            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                                  color: uiPack.textOnPanel,
                                ),
                          ),
                          const SizedBox(height: 4),
                          SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Row(
                              children: [
                                for (final id in _record.tracks.keys)
                                  Padding(
                                    padding: const EdgeInsets.only(right: 6),
                                    child: FilterChip(
                                      label: Text(_trackLabel(id)),
                                      selected: _trackVisible[id] ?? true,
                                      onSelected: (v) {
                                        setState(() => _trackVisible[id] = v);
                                      },
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '再生速度',
                            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                                  color: uiPack.textOnPanel,
                                ),
                          ),
                          const SizedBox(height: 4),
                          Wrap(
                            spacing: 6,
                            runSpacing: 4,
                            children: [
                              for (final s in _speedPresets)
                                ChoiceChip(
                                  label: Text('${s.round()}x'),
                                  selected: (_speed - s).abs() < 0.5,
                                  onSelected: (_) =>
                                      setState(() => _speed = s),
                                ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Text(
                            'カメラ視点',
                            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                                  color: uiPack.textOnPanel,
                                ),
                          ),
                          const SizedBox(height: 4),
                          SegmentedButton<ReplayPerspective>(
                            segments: const [
                              ButtonSegment(
                                value: ReplayPerspective.god,
                                label: Text('俯瞰'),
                                icon: Icon(Icons.public, size: 16),
                              ),
                              ButtonSegment(
                                value: ReplayPerspective.runner,
                                label: Text('逃走'),
                                icon: Icon(Icons.directions_run, size: 16),
                              ),
                              ButtonSegment(
                                value: ReplayPerspective.oni,
                                label: Text('鬼'),
                                icon: Icon(Icons.whatshot_outlined, size: 16),
                              ),
                              ButtonSegment(
                                value: ReplayPerspective.follow,
                                label: Text('追尾'),
                                icon: Icon(Icons.person_pin_circle, size: 16),
                              ),
                            ],
                            selected: {_perspective},
                            onSelectionChanged: (v) {
                              setState(() => _perspective = v.first);
                            },
                          ),
                          if (_perspective == ReplayPerspective.follow) ...[
                            const SizedBox(height: 6),
                            Text(
                              '追尾する参加者',
                              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                    color: uiPack.textOnPanel.withValues(alpha: 0.8),
                                  ),
                            ),
                            const SizedBox(height: 4),
                            SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: Row(
                                children: [
                                  for (final id in _record.tracks.keys)
                                    Padding(
                                      padding: const EdgeInsets.only(right: 6),
                                      child: ChoiceChip(
                                        label: Text(_trackLabel(id)),
                                        selected: _followTrackId == id,
                                        onSelected: (_) {
                                          setState(() {
                                            _followTrackId = id;
                                            _perspective =
                                                ReplayPerspective.follow;
                                          });
                                        },
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ],
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              const Text('速度'),
                              Expanded(
                                child: Slider(
                                  min: 1,
                                  max: 24,
                                  divisions: 23,
                                  value: _speed.clamp(1, 24),
                                  label: '${_speed.round()}x',
                                  onChanged: (v) => setState(() => _speed = v),
                                ),
                              ),
                            ],
                          ),
                          if (recentEvents.isNotEmpty) ...[
                            Text(
                              'この時刻のイベント',
                              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                                    color: uiPack.textOnPanel,
                                  ),
                            ),
                            const SizedBox(height: 4),
                            SizedBox(
                              height: 36,
                              child: ListView.separated(
                                scrollDirection: Axis.horizontal,
                                itemCount: recentEvents.length,
                                separatorBuilder: (_, _) =>
                                    const SizedBox(width: 6),
                                itemBuilder: (_, i) {
                                  final e = recentEvents[i];
                                  return Chip(
                                    label: Text(
                                      e.message,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    visualDensity: VisualDensity.compact,
                                  );
                                },
                              ),
                            ),
                          ],
                          if (_record.reveals.isNotEmpty ||
                              _record.events.isNotEmpty) ...[
                            const SizedBox(height: 10),
                            Text(
                              '試合の流れ',
                              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                                    color: uiPack.textOnPanel,
                                  ),
                            ),
                            const SizedBox(height: 6),
                            ConstrainedBox(
                              constraints: const BoxConstraints(maxHeight: 160),
                              child: SingleChildScrollView(
                                child: MatchFlowTimeline(
                                  reveals: _record.reveals,
                                  events: _record.events,
                                  maxItems: 12,
                                  onSeekTo: _seekToTime,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
      ),
    );
  }

  String _progressFraction() =>
      '${(_progress * 100).clamp(0, 100).toStringAsFixed(0)} %';

  String _progressLabel((DateTime, DateTime) range) {
    final tNow = _timeAtProgress(_progress);
    final off = tNow.difference(range.$1).inSeconds;
    final m = (off ~/ 60).toString().padLeft(2, '0');
    final s = (off % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  Set<Polyline> _buildTrailPolylines(DateTime tNow) {
    final out = <Polyline>{};
    var index = 0;
    final captureNear =
        ReplayDirector.isNearCapture(_record.events, tNow);
    final emphasisId =
        _perspective == ReplayPerspective.follow ? _followTrackId : null;
    for (final e in _record.tracks.entries) {
      final id = e.key;
      final clipped = ReplayTimelineUtils.samplesUpTo(e.value, tNow);
      if (!(_trackVisible[id] ?? true) || clipped.length < 2) {
        index += 1;
        continue;
      }
      final kind = ReplayTrackStyle.kindForTrackId(
        id,
        trackKinds: _record.trackKinds,
      );
      final emphasized =
          emphasisId == id || (_followTrackId != null && _followTrackId == id);
      final color = _trackColorForKind(id, kind, index);
      final opacity = emphasized
          ? ReplayTrackStyle.lineOpacity(kind, emphasized: true)
          : (_followTrackId != null && !emphasized
              ? ReplayTrackStyle.dimmedOpacity(kind, emphasized: false)
              : ReplayTrackStyle.lineOpacity(kind, emphasized: false));
      final speed = ReplayDirector.estimateSpeedMps(clipped, tNow);
      final idle = ReplayDirector.isIdle(clipped, tNow);
      final baseW = kind == ReplayTrackKind.oni ? 5.0 : 4.0;
      final width = ReplayDirector.trailWidth(
        trackId: id,
        baseWidth: baseW,
        speedMps: speed,
        idle: idle,
        captureEmphasis: captureNear,
        pulsePhase: _pulsePhase,
      );
      final glowAlpha = ReplayDirector.trailGlowAlpha(
        idle: idle,
        captureEmphasis:
            captureNear && (kind == ReplayTrackKind.oni || id.contains('oni')),
        pulsePhase: _pulsePhase,
      );
      final points = clipped.map((s) => s.position).toList();
      final dashed = ReplayTrackStyle.useDashedLine(kind);
      out.add(
        Polyline(
          polylineId: PolylineId('trail_glow_$id'),
          color: color.withValues(alpha: glowAlpha * opacity),
          width: (width + (emphasized ? 4 : 3)).round(),
          points: points,
          patterns: dashed
              ? [PatternItem.dash(28), PatternItem.gap(14)]
              : const [],
        ),
      );
      out.add(
        Polyline(
          polylineId: PolylineId('trail_$id'),
          color: color.withValues(alpha: opacity),
          width: (width + (emphasized ? 1.2 : 0)).round(),
          points: points,
          patterns: dashed
              ? [PatternItem.dash(28), PatternItem.gap(14)]
              : const [],
        ),
      );
      index += 1;
    }
    return out;
  }

  Set<Circle> _buildCaptureZoneCircles(DateTime tNow) {
    final out = <Circle>{};
    final alert = _mapVisual.pack.tokens.alertColor;
    for (final zone in _captureZones) {
      final visual = ReplayCaptureZoneCatalog.visualAt(zone, tNow);
      if (!visual.visible) continue;
      final color = visual.boundFlash
          ? alert.withValues(alpha: visual.strokeAlpha)
          : alert.withValues(alpha: visual.strokeAlpha * 0.85);
      out.add(
        Circle(
          circleId: CircleId(zone.id),
          center: zone.center,
          radius: GameConfig.captureZoneRadiusMeters,
          strokeWidth: visual.strokeWidth.round(),
          strokeColor: color,
          fillColor: alert.withValues(alpha: visual.fillAlpha),
        ),
      );
    }
    return out;
  }

  Color _trackColorForKind(String id, ReplayTrackKind kind, int fallbackIndex) {
    return switch (kind) {
      ReplayTrackKind.spectral => const Color(0xFF8FE8E8),
      ReplayTrackKind.revengeOni => const Color(0xFF9B6B8E),
      ReplayTrackKind.ghostSpectator => const Color(0xFF9E9E9E),
      ReplayTrackKind.secondGame => const Color(0xFF7EB8D8),
      ReplayTrackKind.oni => _mapVisual.pack.tokens.alertColor,
      ReplayTrackKind.survivor => _mapVisual.pack.tokens.playerRingColor,
      ReplayTrackKind.spectator => const Color(0xFFB0B0B0),
    };
  }

  Set<Marker> _buildRevealMarkers(DateTime now) {
    if (!_showRevealMarkers || !(_mapVisual.markerRegistry?.isReady ?? false)) {
      return {};
    }
    final reg = _mapVisual.markerRegistry!;
    final out = <Marker>{};
    for (final r in _record.reveals) {
      if (r.timestamp.isAfter(now)) continue;
      if (now.difference(r.timestamp) > const Duration(seconds: 90)) continue;
      final label = r.playerLabel.isNotEmpty ? r.playerLabel : '暴露';
      final reason = r.reasonSummary ?? '';
      out.add(
        Marker(
          markerId: MarkerId('reveal_${r.sequence}_${r.timestamp.microsecondsSinceEpoch}'),
          position: r.position,
          icon: reg.iconOrHue(MapMarkerKind.reveal, BitmapDescriptor.hueRose),
          infoWindow: InfoWindow(
            title: label,
            snippet: reason.isNotEmpty ? reason : '位置暴露',
          ),
        ),
      );
    }
    return out;
  }

  String _endReasonLabel(String reason) => switch (reason) {
        MatchEndReason.timeUp => '時間切れ',
        MatchEndReason.accusationSuccess => '告発成功',
        MatchEndReason.allHumansEliminated => '全員脱落',
        MatchEndReason.oniEliminated => '鬼撃破',
        MatchEndReason.hostAbort => '中止',
        MatchEndReason.hostEnded => 'ホスト終了',
        MatchEndReason.caught => '捕獲',
        _ => '試合終了',
      };

  List<MatchEvent> _eventsNear(DateTime now, Duration window) {
    return _record.events
        .where((e) => !e.atUtc.isAfter(now))
        .where((e) => now.difference(e.atUtc) <= window)
        .toList()
      ..sort((a, b) => b.atUtc.compareTo(a.atUtc));
  }

  Set<Marker> _buildGimmickMarkers() {
    final layout = _record.gimmickLayout;
    if (!_showGimmickMarkers || layout == null) return {};
    if (!(_mapVisual.markerRegistry?.isReady ?? false)) return {};
    final reg = _mapVisual.markerRegistry!;
    final out = <Marker>{};
    void addAll(
      List<LatLng> points,
      MapMarkerKind kind,
      String label,
    ) {
      for (var i = 0; i < points.length; i++) {
        out.add(
          Marker(
            markerId: MarkerId('gimmick_${kind.name}_$i'),
            position: points[i],
            icon: reg.iconOrHue(kind, BitmapDescriptor.hueAzure),
            infoWindow: InfoWindow(title: label),
          ),
        );
      }
    }

    addAll(layout.safeZones, MapMarkerKind.safeZone, '安全地帯');
    addAll(layout.infoBrokers, MapMarkerKind.infoBroker, '情報屋');
    addAll(layout.cameras, MapMarkerKind.trace, '監視カメラ');
    addAll(layout.cameraJacks, MapMarkerKind.trace, '監視端子');
    addAll(
      layout.accusationFacilities,
      MapMarkerKind.infoBroker,
      '告発施設',
    );
    addAll(layout.commJammingZones, MapMarkerKind.fakePosition, '通信妨害');
    return out;
  }

  Set<Marker> _buildEventMarkers(DateTime now) {
    if (!_showEventMarkers || !(_mapVisual.markerRegistry?.isReady ?? false)) {
      return {};
    }
    final reg = _mapVisual.markerRegistry!;
    final out = <Marker>{};
    for (final e in _eventsNear(now, const Duration(seconds: 90))) {
      final kind = MapReplayMarkerHelper.forEventType(e.type);
      out.add(
        Marker(
          markerId: MarkerId('event_${e.type}_${e.atUtc.microsecondsSinceEpoch}'),
          position: e.position,
          infoWindow: InfoWindow(title: 'イベント', snippet: e.message),
          icon: reg.iconOrHue(kind, BitmapDescriptor.hueYellow),
        ),
      );
    }
    return out;
  }

  Set<Marker> _buildMarkersAt(DateTime tNow) {
    if (!(_mapVisual.markerRegistry?.isReady ?? false)) return {};
    final reg = _mapVisual.markerRegistry!;
    final out = <Marker>{};
    var index = 0;
    for (final e in _record.tracks.entries) {
      final id = e.key;
      final samples = e.value;
      if (!(_trackVisible[id] ?? true) || samples.isEmpty) {
        index += 1;
        continue;
      }
      final pos = interpolateAlongTrack(samples, tNow);
      if (pos != null) {
        final kind = MapReplayMarkerHelper.forTrackId(id);
        out.add(
          Marker(
            markerId: MarkerId('replay_$id'),
            position: pos,
            icon: reg.iconOrHue(kind, _markerHue(id, index)),
            infoWindow: InfoWindow(title: _trackTitle(id)),
          ),
        );
      }
      index += 1;
    }
    return out;
  }

  LatLng? _firstVisiblePositionAt(DateTime tUtc) {
    for (final e in _record.tracks.entries) {
      final id = e.key;
      if (!(_trackVisible[id] ?? true) || e.value.isEmpty) continue;
      return interpolateAlongTrack(e.value, tUtc);
    }
    return null;
  }

  String _trackLabel(String id) {
    return ReplayTrackStyle.defaultTrackLabel(
      id,
      trackLabels: _record.trackLabels,
      trackKinds: _record.trackKinds,
    );
  }

  String _trackTitle(String id) {
    return ReplayTrackStyle.defaultTrackTitle(
      id,
      trackLabels: _record.trackLabels,
      trackKinds: _record.trackKinds,
    );
  }

  /// 既知キー以外は色相をずらして区別。
  double _markerHue(String id, int fallbackIndex) {
    if (id == MatchTrackIds.runnerLocal) return BitmapDescriptor.hueAzure;
    if (id == MatchTrackIds.oniLocal) return BitmapDescriptor.hueRed;
    const hues = <double>[
      BitmapDescriptor.hueGreen,
      BitmapDescriptor.hueOrange,
      BitmapDescriptor.hueViolet,
      BitmapDescriptor.hueYellow,
      BitmapDescriptor.hueCyan,
    ];
    return hues[fallbackIndex % hues.length];
  }
}

class _ReplayLayerToolbar extends StatelessWidget {
  const _ReplayLayerToolbar({
    required this.pack,
    required this.showGimmicks,
    required this.showEventMarkers,
    required this.showRevealMarkers,
    required this.followCamera,
    required this.showGimmickMarkers,
    required this.showPlayArea,
    required this.onToggleEvents,
    required this.onToggleReveals,
    required this.onToggleFollow,
    required this.onToggleGimmicks,
    required this.onTogglePlayArea,
    required this.onFitAll,
  });

  final WorldPresentationPack pack;
  final bool showGimmicks;
  final bool showEventMarkers;
  final bool showRevealMarkers;
  final bool followCamera;
  final bool showGimmickMarkers;
  final bool showPlayArea;
  final VoidCallback onToggleEvents;
  final VoidCallback onToggleReveals;
  final VoidCallback onToggleFollow;
  final VoidCallback onToggleGimmicks;
  final VoidCallback onTogglePlayArea;
  final VoidCallback onFitAll;

  @override
  Widget build(BuildContext context) {
    return Material(
      elevation: 3,
      color: pack.panelSurface.withValues(alpha: 0.94),
      borderRadius: BorderRadius.circular(14),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              _ReplayLayerToggle(
                pack: pack,
                label: 'イベント',
                icon: Icons.flag_outlined,
                active: showEventMarkers,
                onPressed: onToggleEvents,
              ),
              _ReplayLayerToggle(
                pack: pack,
                label: '暴露',
                icon: Icons.campaign_outlined,
                active: showRevealMarkers,
                onPressed: onToggleReveals,
              ),
              _ReplayLayerToggle(
                pack: pack,
                label: '追従',
                icon: Icons.gps_fixed,
                active: followCamera,
                onPressed: onToggleFollow,
              ),
              if (showGimmicks)
                _ReplayLayerToggle(
                  pack: pack,
                  label: 'ギミック',
                  icon: Icons.scatter_plot_outlined,
                  active: showGimmickMarkers,
                  onPressed: onToggleGimmicks,
                ),
              _ReplayLayerToggle(
                pack: pack,
                label: 'エリア',
                icon: Icons.crop_free,
                active: showPlayArea,
                onPressed: onTogglePlayArea,
              ),
              _ReplayLayerToggle(
                pack: pack,
                label: '全体',
                icon: Icons.fit_screen,
                active: true,
                onPressed: onFitAll,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ReplayLayerToggle extends StatelessWidget {
  const _ReplayLayerToggle({
    required this.pack,
    required this.label,
    required this.icon,
    required this.active,
    required this.onPressed,
  });

  final WorldPresentationPack pack;
  final String label;
  final IconData icon;
  final bool active;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final fg = active ? pack.accent : pack.textOnPanel.withValues(alpha: 0.72);
    final bg = active
        ? pack.accent.withValues(alpha: 0.16)
        : Colors.transparent;
    return Padding(
      padding: const EdgeInsets.only(right: 4),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: active ? pack.accent.withValues(alpha: 0.55) : pack.panelBorder,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 16, color: fg),
              const SizedBox(width: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: active ? FontWeight.w700 : FontWeight.w500,
                  color: fg,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

extension PlayAreaReplayExt on PlayArea {
  LatLng get centerOrFirstPoint {
    switch (type) {
      case PlayAreaType.circle:
        return center;
      case PlayAreaType.polygon:
        return points.isEmpty ? const LatLng(0, 0) : points.first;
    }
  }
}
