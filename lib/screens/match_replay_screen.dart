import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../game/game_state.dart';
import '../game/match_event.dart';
import '../game/match_record.dart';
import '../game/play_area.dart';
import '../services/match_recorder.dart';

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

  @override
  void initState() {
    super.initState();
    _trackVisible = {
      for (final k in widget.record.tracks.keys) k: true,
    };
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
    _maybePulseClearEffect();
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
    final markers = _buildMarkersAt(tNow)..addAll(_buildEventMarkers(tNow));
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
            Text(widget.record.outcome.label),
            Text(
              '${widget.record.startedAtUtc.toLocal()} 〜',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
      body: Stack(
        children: [
          GoogleMap(
            initialCameraPosition: CameraPosition(
              target: fallbackTarget,
              zoom: 15,
            ),
            myLocationEnabled: false,
            myLocationButtonEnabled: false,
            onMapCreated: (c) {
              _controller = c;
              if (bounds != null) {
                Future<void>.delayed(const Duration(milliseconds: 320), () {
                  if (!mounted || _controller == null) return;
                  _controller!.animateCamera(
                    CameraUpdate.newLatLngBounds(bounds, 54),
                  );
                });
              }
            },
            polylines: lines,
            markers: markers,
            circles: playArea.type == PlayAreaType.circle
                ? {
                    Circle(
                      circleId: const CircleId('replay-area'),
                      center: playArea.center,
                      radius: playArea.radiusMeters,
                      strokeWidth: 2,
                      fillColor: Colors.blue.withValues(alpha: 0.06),
                      strokeColor: Colors.blue.shade400,
                    ),
                  }
                : {},
            polygons: playArea.type == PlayAreaType.polygon
                ? {
                    Polygon(
                      polygonId: const PolygonId('replay-area'),
                      points: playArea.points,
                      strokeWidth: 2,
                      fillColor: Colors.blue.withValues(alpha: 0.06),
                      strokeColor: Colors.blue.shade400,
                    ),
                  }
                : {},
          ),
          if (widget.record.outcome == GameState.runnerWin && _progress >= 0.9)
            Positioned.fill(
              child: IgnorePointer(
                child: Container(
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    gradient: RadialGradient(
                      colors: [
                        Colors.amber.withValues(alpha: 0.15 * ((_progress - 0.9) / 0.1).clamp(0.0, 1.0)),
                        Colors.transparent,
                      ],
                    ),
                  ),
                  child: Text(
                    'CLEAR',
                    style: TextStyle(
                      fontSize: 42,
                      fontWeight: FontWeight.w900,
                      color: Colors.amberAccent.withValues(alpha: 0.65),
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
              child: Padding(
                padding: EdgeInsets.only(
                  left: 12,
                  right: 12,
                  top: 10,
                  bottom: 12 + MediaQuery.paddingOf(context).bottom,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      '再生 ${_progressFraction()}  /  ${_speed.toStringAsFixed(0)}x',
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                    Slider(
                      value: _progress.clamp(0, 1),
                      onChanged: (v) {
                        setState(() {
                          _progress = v;
                          _celebrationShown = false;
                        });
                      },
                    ),
                    Text(
                      '表示する軌跡',
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      children: [
                        for (final id in widget.record.tracks.keys)
                          FilterChip(
                            label: Text(_trackLabel(id)),
                            selected: _trackVisible[id] ?? true,
                            onSelected: (v) {
                              setState(() => _trackVisible[id] = v);
                            },
                          ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        IconButton.outlined(
                          onPressed: () => _setPlaying(!_playing),
                          icon: Icon(_playing ? Icons.pause : Icons.play_arrow),
                          tooltip: _playing ? '一時停止' : '再生',
                        ),
                        Text('速度'),
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
                    Text(
                      'ログ: consent=${widget.record.consentedToTrajectory} 開始=${range.$1.toLocal()} 経過${_progressLabel(range)}',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'イベント',
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                    if (recentEvents.isEmpty)
                      Text(
                        'この時刻帯のイベントなし',
                        style: Theme.of(context).textTheme.bodySmall,
                      )
                    else
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: [
                          for (final e in recentEvents)
                            Chip(
                              label: Text(
                                e.message,
                                overflow: TextOverflow.ellipsis,
                              ),
                              visualDensity: VisualDensity.compact,
                            ),
                        ],
                      ),
                  ],
                ),
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

  Set<Marker> _buildEventMarkers(DateTime now) {
    final out = <Marker>{};
    for (final e in _eventsNear(now, const Duration(seconds: 90))) {
      out.add(
        Marker(
          markerId: MarkerId('event_${e.type}_${e.atUtc.microsecondsSinceEpoch}'),
          position: e.position,
          infoWindow: InfoWindow(title: 'イベント', snippet: e.message),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueYellow),
        ),
      );
    }
    return out;
  }

  Set<Marker> _buildMarkersAt(DateTime tNow) {
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
        out.add(
          Marker(
            markerId: MarkerId('replay_$id'),
            position: pos,
            icon: BitmapDescriptor.defaultMarkerWithHue(
              _markerHue(id, index),
            ),
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

  static String _trackLabel(String id) {
    if (id == MatchTrackIds.runnerLocal) return '自分（逃走側）';
    if (id == MatchTrackIds.oniLocal) return '鬼（ローカル）';
    return id;
  }

  static String _trackTitle(String id) {
    if (id == MatchTrackIds.runnerLocal) return '逃走者（再生）';
    if (id == MatchTrackIds.oniLocal) return '鬼（再生）';
    return id;
  }

  static Color _trackColor(String id, int fallbackIndex) {
    if (id == MatchTrackIds.runnerLocal) return Colors.lightBlue.shade700;
    if (id == MatchTrackIds.oniLocal) return Colors.red.shade700;
    const palette = <Color>[
      Color(0xFF43A047),
      Color(0xFFFFA726),
      Color(0xFFAB47BC),
      Color(0xFF78909C),
      Color(0xFF0097A7),
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
