import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../game/game_state.dart';
import '../game/match_event.dart';
import '../game/match_record.dart';
import '../game/play_area.dart';
import '../features/game_map/map/map_marker_kind.dart';
import '../features/game_map/map/map_replay_marker_helper.dart';
import '../sync/firestore_room_blueprint.dart';
import '../features/game_map/visual/map_visual_controller.dart';
import '../features/game_map/visual/reveal_flash_controller.dart';
import '../features/game_map/widgets/world_map_atmosphere.dart';
import '../services/match_recorder.dart';
import '../session/world_profile_prefs.dart';
import '../theme/world_profile.dart';

/// タイムラプス風に軌跡を再生する画面。
class MatchReplayScreen extends StatefulWidget {
  const MatchReplayScreen({super.key, required this.record});

  final SavedMatchRecord record;

  @override
  State<MatchReplayScreen> createState() => _MatchReplayScreenState();
}

class _MatchReplayScreenState extends State<MatchReplayScreen> {
  GoogleMapController? _controller;
  Timer? _clock;

  double _progress = 0;
  double _speed = 8;
  bool _playing = false;

  /// トラックIDごとの線・マーカー表示（参加者が増えても対応）。
  late Map<String, bool> _trackVisible;
  bool _showEventMarkers = true;
  bool _showGimmickMarkers = true;
  bool _showPlayArea = true;
  bool _panelExpanded = false;
  late MapVisualController _mapVisual;
  bool _visualReady = false;
  late RevealFlashController _revealFlash;

  @override
  void initState() {
    super.initState();
    _trackVisible = {
      for (final k in widget.record.tracks.keys) k: true,
    };
    _mapVisual = MapVisualController(WorldProfile.horror);
    _revealFlash = RevealFlashController(() {
      if (mounted) setState(() {});
    });
    Future<void>.microtask(_loadReplayVisual);
  }

  Future<void> _loadReplayVisual() async {
    final profile = await WorldProfilePrefs.load();
    await _mapVisual.reloadForProfile(profile);
    if (!mounted) return;
    setState(() => _visualReady = true);
  }

  Future<void> _fitMapToContent() async {
    final bounds = _computeFitBounds();
    final c = _controller;
    if (bounds == null || c == null) return;
    await c.animateCamera(CameraUpdate.newLatLngBounds(bounds, 54));
  }

  (DateTime, DateTime) get _timeline {
    final flattened =
        widget.record.tracks.entries
            .where((e) => _trackVisible[e.key] ?? true)
            .map((e) => e.value)
            .expand((e) => e);
    DateTime start;
    DateTime end;
    final it = flattened.iterator;
    if (!it.moveNext()) {
      start = widget.record.startedAtUtc;
      end = widget.record.endedAtUtc;
      if (!end.isAfter(start)) {
        end = start.add(const Duration(seconds: 2));
      }
    } else {
      var minT = it.current.atUtc;
      var maxT = it.current.atUtc;
      while (it.moveNext()) {
        final t = it.current.atUtc;
        if (t.isBefore(minT)) minT = t;
        if (t.isAfter(maxT)) maxT = t;
      }
      start = minT;
      end = maxT;
      if (!end.isAfter(start)) {
        end = start.add(const Duration(seconds: 2));
      }
    }
    if (end.difference(start).inMilliseconds < 2000) {
      end = start.add(const Duration(seconds: 2));
    }
    return (start, end);
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
    _controller?.dispose();
    super.dispose();
  }

  void _tick(Timer _) {
    if (!_playing || !mounted) return;
    const dtMs = 50;
    final v = _virtualSpanMs.toDouble();
    setState(() {
      _progress += (dtMs * _speed) / v;
      if (_progress >= 1) {
        _progress = 1;
        _playing = false;
        _clock?.cancel();
      }
    });
    _maybeRevealFlashAt(_timeAtProgress(_progress));
    _maybePulseClearEffect();
  }

  void _maybeRevealFlashAt(DateTime tNow) {
    if (_mapVisual.pack.revealFlashColor == null) return;
    final hit = widget.record.events.any(
      (e) =>
          MapReplayMarkerHelper.isRevealFlashType(e.type) &&
          !e.atUtc.isAfter(tNow) &&
          tNow.difference(e.atUtc) <= const Duration(milliseconds: 500),
    );
    if (!hit || _revealFlash.active) return;
    _revealFlash.trigger(_mapVisual.pack);
  }

  Future<void> _cycleReplayProfile() async {
    final values = WorldProfile.values;
    final i = values.indexOf(_mapVisual.pack.profile);
    final next = values[(i + 1) % values.length];
    await WorldProfilePrefs.save(next);
    await _mapVisual.reloadForProfile(next);
    if (!mounted) return;
    setState(() => _visualReady = true);
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
    if (widget.record.outcome != GameState.runnerWin) return;
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

    for (final e in widget.record.tracks.entries) {
      if (!(_trackVisible[e.key] ?? true)) continue;
      for (final s in e.value) {
        add(s.position);
      }
    }
    final a = widget.record.playArea;
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

    final playArea = widget.record.playArea;
    final lines = _buildTrailPolylines();
    final markers = _buildMarkersAt(tNow)
      ..addAll(_buildEventMarkers(tNow))
      ..addAll(_buildGimmickMarkers());
    final fallbackTarget =
        _firstVisiblePositionAt(tNow) ??
            widget.record.playArea.centerOrFirstPoint;
    final recentEvents = _eventsNear(tNow, const Duration(seconds: 25));
    final bounds = _computeFitBounds();

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.record.galleryTitle),
            if (_visualReady)
              Text(
                _mapVisual.pack.profile.label,
                style: Theme.of(context).textTheme.labelSmall,
              ),
          ],
        ),
        actions: [
          if (_visualReady)
            IconButton(
              tooltip: '世界観を切替（${_mapVisual.pack.profile.label}）',
              onPressed: () => unawaited(_cycleReplayProfile()),
              icon: const Icon(Icons.palette_outlined),
            ),
          IconButton(
            tooltip: _showEventMarkers ? 'イベントを隠す' : 'イベントを表示',
            onPressed: () => setState(() => _showEventMarkers = !_showEventMarkers),
            icon: Icon(
              _showEventMarkers ? Icons.flag : Icons.flag_outlined,
            ),
          ),
          if (widget.record.gimmickLayout != null)
            IconButton(
              tooltip: _showGimmickMarkers ? 'ギミックを隠す' : 'ギミックを表示',
              onPressed: () =>
                  setState(() => _showGimmickMarkers = !_showGimmickMarkers),
              icon: Icon(
                _showGimmickMarkers
                    ? Icons.scatter_plot
                    : Icons.scatter_plot_outlined,
              ),
            ),
          IconButton(
            tooltip: _showPlayArea ? 'エリアを隠す' : 'エリアを表示',
            onPressed: () => setState(() => _showPlayArea = !_showPlayArea),
            icon: Icon(
              _showPlayArea ? Icons.crop_free : Icons.crop_free_outlined,
            ),
          ),
          IconButton(
            tooltip: '全体を表示（ピンチでも拡大縮小できます）',
            onPressed: () => unawaited(_fitMapToContent()),
            icon: const Icon(Icons.fit_screen),
          ),
        ],
      ),
      body: !_visualReady
          ? const Center(child: CircularProgressIndicator())
          : Stack(
        children: [
          Positioned.fill(
            child: IgnorePointer(
              child: WorldMapAtmosphere(
                pack: _mapVisual.pack,
                dangerPulse: 0,
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
            circles: _showPlayArea && playArea.type == PlayAreaType.circle
                ? {
                    Circle(
                      circleId: const CircleId('replay-area'),
                      center: playArea.center,
                      radius: playArea.radiusMeters,
                      strokeWidth: 2,
                      fillColor: _mapVisual.pack.tokens.playAreaColor
                          .withValues(alpha: 0.12),
                      strokeColor: _mapVisual.pack.tokens.playAreaColor,
                    ),
                  }
                : {},
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
          if (widget.record.endReason != MatchEndReason.hostAbort &&
              widget.record.outcome == GameState.runnerWin &&
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
            left: 0,
            right: 0,
            bottom: 0,
            child: Material(
              elevation: 10,
              color: Theme.of(context).colorScheme.surface,
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
                                  style: Theme.of(context).textTheme.labelMedium,
                                ),
                                Slider(
                                  value: _progress.clamp(0, 1),
                                  onChanged: (v) {
                                    setState(() {
                                      _progress = v;
                                      _celebrationShown = false;
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
                          SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Row(
                              children: [
                                for (final id in widget.record.tracks.keys)
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
                              style: Theme.of(context).textTheme.labelMedium,
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
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
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

  Set<Polyline> _buildTrailPolylines() {
    final out = <Polyline>{};
    var index = 0;
    for (final e in widget.record.tracks.entries) {
      final id = e.key;
      final samples = e.value;
      if (!(_trackVisible[id] ?? true) || samples.length < 2) {
        continue;
      }
      out.add(
        Polyline(
          polylineId: PolylineId('trail_$id'),
          color: _trackColor(id, index).withValues(alpha: 0.92),
          width: id == MatchTrackIds.oniLocal ? 5 : 4,
          points: samples.map((s) => s.position).toList(),
        ),
      );
      index += 1;
    }
    return out;
  }

  List<MatchEvent> _eventsNear(DateTime now, Duration window) {
    return widget.record.events
        .where((e) => !e.atUtc.isAfter(now))
        .where((e) => now.difference(e.atUtc) <= window)
        .toList()
      ..sort((a, b) => b.atUtc.compareTo(a.atUtc));
  }

  Set<Marker> _buildGimmickMarkers() {
    final layout = widget.record.gimmickLayout;
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
    for (final e in widget.record.tracks.entries) {
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
    for (final e in widget.record.tracks.entries) {
      final id = e.key;
      if (!(_trackVisible[id] ?? true) || e.value.isEmpty) continue;
      return interpolateAlongTrack(e.value, tUtc);
    }
    return null;
  }

  String _trackLabel(String id) {
    final custom = widget.record.trackLabels[id];
    if (custom != null && custom.isNotEmpty) return custom;
    if (id == MatchTrackIds.runnerLocal) return '自分（逃走側）';
    if (id == MatchTrackIds.oniLocal) return '鬼（ローカル）';
    if (id.startsWith('player_')) return id.substring(7);
    return id;
  }

  String _trackTitle(String id) {
    final custom = widget.record.trackLabels[id];
    if (custom != null && custom.isNotEmpty) return custom;
    if (id == MatchTrackIds.runnerLocal) return '逃走者（再生）';
    if (id == MatchTrackIds.oniLocal) return '鬼（再生）';
    if (id.startsWith('player_')) return id.substring(7);
    return id;
  }

  Color _trackColor(String id, int fallbackIndex) {
    final t = _mapVisual.pack.tokens;
    if (id == MatchTrackIds.runnerLocal) return t.playerRingColor;
    if (id == MatchTrackIds.oniLocal) return t.alertColor;
    final palette = <Color>[
      t.safeColor,
      t.infoColor,
      t.traceColor,
      t.playerRingColor,
      t.revealRingColor,
    ];
    return palette[fallbackIndex % palette.length];
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
