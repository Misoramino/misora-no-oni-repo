import 'dart:async';
import 'dart:math' as math;

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart' show Curve;

import 'world_music_profile.dart';

typedef LayerAssetResolver = String? Function(String dir, String base);

/// 4 スロット BGM レイヤーエンジン（Base / Ambient / Tension / Moment）。
class BgmLayerEngine {
  BgmLayerEngine({required this.resolveAsset});

  final LayerAssetResolver resolveAsset;

  static const musicExts = ['mp3', 'ogg', 'wav', 'm4a'];

  final Map<WorldMusicLayer, AudioPlayer> _players = {};
  final Map<WorldMusicLayer, String> _activeKeys = {};
  final Map<WorldMusicLayer, double> _targetGains = {};
  final Map<WorldMusicLayer, Timer?> _fadeTimers = {};

  double _masterBgm = 1.0;
  double _duckFactor = 1.0;
  bool _disposed = false;

  bool get isDisposed => _disposed;

  double get duckFactor => _duckFactor;

  void setMasterBgm(double v) {
    _masterBgm = v.clamp(0.0, 1.0);
    _applyAllVolumes();
  }

  void setDuckFactor(double factor) {
    _duckFactor = factor.clamp(0.0, 1.0);
    _applyAllVolumes();
  }

  Future<void> setLayer({
    required WorldMusicLayer slot,
    required LayerTrackRef track,
    required double relativeGain,
    required bool loop,
    required int crossFadeMs,
    required Curve curve,
  }) async {
    if (kIsWeb || _disposed) return;
    final key = _trackKey(track);
    final target = (_masterBgm * _duckFactor * relativeGain * track.gain)
        .clamp(0.0, 1.0);

    if (_activeKeys[slot] == key && _players[slot] != null) {
      _targetGains[slot] = relativeGain * track.gain;
      await _fadeLayer(slot, to: target, ms: crossFadeMs);
      return;
    }

    final path = _resolveTrack(track);
    if (path == null) {
      await stopLayer(slot, fadeMs: crossFadeMs);
      return;
    }

    _targetGains[slot] = relativeGain * track.gain;
    _activeKeys[slot] = key;

    try {
      final p = _players[slot] ??= AudioPlayer(playerId: 'bgm_${slot.name}');
      _fadeTimers[slot]?.cancel();
      _fadeTimers[slot] = null;
      await p.setReleaseMode(loop ? ReleaseMode.loop : ReleaseMode.stop);
      await p.stop();
      await p.play(AssetSource(path), volume: 0);
      await _fadeLayer(slot, to: target, ms: crossFadeMs);
    } catch (e) {
      debugPrint('BgmLayerEngine.setLayer($slot): $e');
    }
  }

  Future<void> fadeLayerGain(
    WorldMusicLayer slot, {
    required double relativeGain,
    required int ms,
  }) async {
    if (_disposed) return;
    _targetGains[slot] = relativeGain;
    final target =
        (_masterBgm * _duckFactor * relativeGain).clamp(0.0, 1.0);
    await _fadeLayer(slot, to: target, ms: ms);
  }

  Future<void> stopLayer(
    WorldMusicLayer slot, {
    int fadeMs = 400,
  }) async {
    if (_disposed) return;
    _activeKeys.remove(slot);
    _targetGains.remove(slot);
    final p = _players[slot];
    if (p == null) return;
    await _fadeLayer(slot, to: 0, ms: fadeMs, stopAtEnd: true);
  }

  Future<void> stopAll({int fadeMs = 500}) async {
    if (_disposed) return;
    for (final slot in WorldMusicLayer.values) {
      await stopLayer(slot, fadeMs: fadeMs);
    }
  }

  Future<void> pauseAll() async {
    if (_disposed) return;
    for (final p in _players.values) {
      try {
        await p.pause();
      } catch (_) {}
    }
  }

  Future<void> resumeAll() async {
    if (_disposed) return;
    for (final entry in _players.entries) {
      if (!_activeKeys.containsKey(entry.key)) continue;
      try {
        await entry.value.resume();
      } catch (_) {}
    }
  }

  Future<void> dispose() async {
    if (_disposed) return;
    _disposed = true;
    for (final t in _fadeTimers.values) {
      t?.cancel();
    }
    _fadeTimers.clear();
    for (final p in _players.values) {
      await p.dispose();
    }
    _players.clear();
    _activeKeys.clear();
    _targetGains.clear();
  }

  String _trackKey(LayerTrackRef track) {
    if (track.bgm != null) return 'bgm:${track.bgm!.name}';
    return 'amb:${track.ambient!.name}';
  }

  String? _resolveTrack(LayerTrackRef track) {
    if (track.bgm != null) {
      return resolveAsset('audio/bgm', track.bgm!.asset);
    }
    return resolveAsset('audio/ambient', track.ambient!.asset);
  }

  Future<void> _fadeLayer(
    WorldMusicLayer slot, {
    required double to,
    required int ms,
    bool stopAtEnd = false,
  }) async {
    if (_disposed) return;
    final p = _players[slot];
    if (p == null) return;
    _fadeTimers[slot]?.cancel();
    if (ms <= 0) {
      await p.setVolume(to);
      if (stopAtEnd && to <= 0) {
        try {
          await p.stop();
        } catch (_) {}
      }
      return;
    }
    final completer = Completer<void>();
    const steps = 12;
    final stepMs = (ms / steps).round().clamp(16, 200);
    var i = 0;
    double from = 0;
    try {
      // audioplayers has no getVolume; start from target approximation
      from = to > 0 ? 0 : (_masterBgm * _duckFactor);
    } catch (_) {}
    _fadeTimers[slot] = Timer.periodic(Duration(milliseconds: stepMs), (t) {
      i++;
      final v = (from + (to - from) * (i / steps)).clamp(0.0, 1.0);
      p.setVolume(v);
      if (i >= steps) {
        t.cancel();
        _fadeTimers[slot] = null;
        if (stopAtEnd) {
          try {
            p.stop();
          } catch (_) {}
        }
        if (!completer.isCompleted) completer.complete();
      }
    });
    return completer.future;
  }

  void _applyAllVolumes() {
    for (final slot in WorldMusicLayer.values) {
      final rel = _targetGains[slot];
      if (rel == null) continue;
      final p = _players[slot];
      if (p == null) continue;
      final v = (_masterBgm * _duckFactor * rel).clamp(0.0, 1.0);
      p.setVolume(v);
    }
  }

  /// dB 減衰を線形ゲイン係数へ（2〜4 dB 想定）。
  static double dbToFactor(double db) =>
      math.pow(10, -db / 20).toDouble().clamp(0.0, 1.0);
}

String? resolveMusicAsset(
  Set<String> assets,
  String dir,
  String base,
) {
  for (final ext in BgmLayerEngine.musicExts) {
    final full = 'assets/$dir/$base.$ext';
    if (assets.contains(full)) return '$dir/$base.$ext';
  }
  return null;
}
