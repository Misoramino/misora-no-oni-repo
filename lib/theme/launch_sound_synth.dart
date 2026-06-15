import 'dart:math' as math;
import 'dart:typed_data';

import 'world_profile.dart';

/// 起動時の世界観別効果音（WAV PCM、外部ファイル不要）。
///
/// 音量より「聴ける長さ」とテーマの物語性を優先（おおよそ 0.7〜1.3 秒）。
abstract final class LaunchSoundSynth {
  static const _sampleRate = 22050;

  static Uint8List wavFor(WorldProfile profile) {
    final samples = switch (profile) {
      WorldProfile.sciFi => _cyberMatrixBoot(),
      WorldProfile.horror => _horrorPulse(),
      WorldProfile.sport => _popCandy(),
      WorldProfile.arg => _tacticalSonar(),
      WorldProfile.magical => _magicalChime(),
      WorldProfile.astronomy => _astronomyWarp(),
      WorldProfile.japaneseLuxury => _japaneseLuxuryBell(),
      WorldProfile.westernLuxury => _westernLuxuryChime(),
    };
    return _encodeWav(_fadeTail(samples, 0.12));
  }

  /// Cyber: ネオン起動 — 低域 → シアンのデジタル階段 → 上昇スイープ。
  static List<int> _cyberMatrixBoot() {
    return _mix([
      _tone(freq: 98, ms: 220, gain: 0.2, envelope: _Env.swell),
      _tone(freq: 196, ms: 160, gain: 0.22, delayMs: 80, envelope: _Env.bell),
      _tone(freq: 392, ms: 140, gain: 0.26, delayMs: 160, envelope: _Env.bell),
      _tone(freq: 587, ms: 130, gain: 0.24, delayMs: 240, envelope: _Env.bell),
      _tone(freq: 784, ms: 120, gain: 0.2, delayMs: 310, envelope: _Env.bell),
      _tone(freq: 988, ms: 200, gain: 0.16, delayMs: 380, envelope: _Env.sustain),
      _sweep(startHz: 280, endHz: 1800, ms: 420, gain: 0.14, delayMs: 280),
      _noise(ms: 180, gain: 0.05, delayMs: 420, envelope: _Env.sustain),
      _echo(_tone(freq: 784, ms: 90, gain: 0.1, envelope: _Env.bell), 90, 0.45),
    ]);
  }

  /// Urban Horror: 心拍の低音 → ノイズ → 下降する不気味なスイープ。
  static List<int> _horrorPulse() {
    return _mix([
      _tone(freq: 52, ms: 280, gain: 0.48, envelope: _Env.swell),
      _tone(freq: 39, ms: 220, gain: 0.36, delayMs: 200, envelope: _Env.sustain),
      _tone(freq: 196, ms: 120, gain: 0.1, delayMs: 120, envelope: _Env.bell),
      _noise(ms: 140, gain: 0.12, delayMs: 80, envelope: _Env.sustain),
      _sweep(startHz: 720, endHz: 90, ms: 380, gain: 0.1, delayMs: 320),
      _tone(freq: 130, ms: 260, gain: 0.08, delayMs: 480, envelope: _Env.sustain),
    ]);
  }

  /// Pop City: お菓子のように弾むパステル・アルペジオ。
  static List<int> _popCandy() {
    const notes = [523.25, 659.25, 784.0, 1046.5, 1318.5];
    final parts = <List<int>>[];
    for (var i = 0; i < notes.length; i++) {
      parts.add(
        _tone(
          freq: notes[i],
          ms: i == notes.length - 1 ? 220 : 110,
          gain: 0.22 - i * 0.02,
          delayMs: i * 95,
          envelope: i == notes.length - 1 ? _Env.sustain : _Env.bell,
        ),
      );
    }
    parts.add(_tone(freq: 1568, ms: 160, gain: 0.1, delayMs: 520, envelope: _Env.bell));
    parts.add(_noise(ms: 120, gain: 0.04, delayMs: 400, envelope: _Env.sustain));
    return _mix(parts);
  }

  /// Stealth Tactical: ソナー ping → 反響（短いクリックだけにしない）。
  static List<int> _tacticalSonar() {
    final ping = _tone(freq: 440, ms: 320, gain: 0.32, envelope: _Env.bell);
    return _mix([
      _noise(ms: 22, gain: 0.35),
      ping,
      _echo(ping, 140, 0.38),
      _echo(ping, 280, 0.22),
      _tone(freq: 220, ms: 200, gain: 0.12, delayMs: 60, envelope: _Env.sustain),
      _tone(freq: 110, ms: 280, gain: 0.08, delayMs: 180, envelope: _Env.swell),
    ]);
  }

  /// Magical: 古文書のチャイム — ゆるやかな上昇と長い余韻。
  static List<int> _magicalChime() {
    const notes = [392.0, 494.0, 587.33, 739.99, 880.0, 1046.5];
    final parts = <List<int>>[];
    for (var i = 0; i < notes.length; i++) {
      parts.add(
        _tone(
          freq: notes[i],
          ms: i < 3 ? 130 : 180,
          gain: 0.2 - i * 0.015,
          delayMs: i * 110,
          envelope: i >= 4 ? _Env.sustain : _Env.bell,
        ),
      );
    }
    parts.add(
      _tone(freq: 1174.7, ms: 320, gain: 0.12, delayMs: 680, envelope: _Env.sustain),
    );
    parts.add(_noise(ms: 200, gain: 0.05, delayMs: 500, envelope: _Env.sustain));
    parts.add(_echo(_tone(freq: 880, ms: 140, gain: 0.08, envelope: _Env.bell), 200, 0.35));
    return _mix(parts);
  }

  /// Astronomy: 静かな宇宙の低音 → ワープのスイープ → 遠い星のティンクル。
  static List<int> _astronomyWarp() {
    return _mix([
      _tone(freq: 41, ms: 520, gain: 0.28, envelope: _Env.swell),
      _tone(freq: 55, ms: 400, gain: 0.16, delayMs: 80, envelope: _Env.sustain),
      _sweep(startHz: 120, endHz: 920, ms: 520, gain: 0.12, delayMs: 200),
      _sweep(startHz: 400, endHz: 1400, ms: 380, gain: 0.08, delayMs: 480),
      _tone(freq: 1046.5, ms: 180, gain: 0.11, delayMs: 620, envelope: _Env.bell),
      _tone(freq: 1318.5, ms: 220, gain: 0.09, delayMs: 760, envelope: _Env.sustain),
      _tone(freq: 1568, ms: 280, gain: 0.07, delayMs: 900, envelope: _Env.sustain),
      _noise(ms: 420, gain: 0.03, delayMs: 0, envelope: _Env.swell),
    ]);
  }

  /// 和風（高級）: 木・和紙の静かな打音。
  static List<int> _japaneseLuxuryBell() {
    return _mix([
      _tone(freq: 196, ms: 90, gain: 0.09, envelope: _Env.pluck),
      _noise(ms: 70, gain: 0.035, envelope: _Env.pluck),
      _tone(freq: 147, ms: 140, gain: 0.07, delayMs: 50, envelope: _Env.swell),
      _tone(freq: 110, ms: 300, gain: 0.05, delayMs: 120, envelope: _Env.sustain),
      _noise(ms: 200, gain: 0.02, delayMs: 80, envelope: _Env.sustain),
      _tone(freq: 98, ms: 320, gain: 0.04, delayMs: 280, envelope: _Env.sustain),
    ]);
  }

  /// 洋風（高級）: 格式ある低音 → 短い金の和音。
  static List<int> _westernLuxuryChime() {
    const notes = [261.63, 329.63, 392.0, 523.25];
    final parts = <List<int>>[];
    for (var i = 0; i < notes.length; i++) {
      parts.add(
        _tone(
          freq: notes[i],
          ms: 160,
          gain: 0.14 - i * 0.01,
          delayMs: i * 90,
          envelope: _Env.bell,
        ),
      );
    }
    parts.add(_tone(freq: 65.41, ms: 520, gain: 0.12, envelope: _Env.swell));
    parts.add(
      _tone(freq: 659.25, ms: 240, gain: 0.08, delayMs: 480, envelope: _Env.sustain),
    );
    return _mix(parts);
  }

  static List<int> _echo(List<int> source, int delayMs, double gainScale) {
    final delay = (_sampleRate * delayMs / 1000).round();
    final out = List<int>.filled(delay + source.length, 0);
    for (var i = 0; i < source.length; i++) {
      out[delay + i] = (source[i] * gainScale).round().clamp(-32768, 32767);
    }
    return out;
  }

  static List<int> _fadeTail(List<int> samples, double tailRatio) {
    final fadeStart = (samples.length * (1 - tailRatio)).round();
    final out = List<int>.from(samples);
    for (var i = fadeStart; i < out.length; i++) {
      final t = (i - fadeStart) / (out.length - fadeStart);
      out[i] = (out[i] * (1 - t)).round();
    }
    return out;
  }

  static List<int> _tone({
    required double freq,
    required int ms,
    double gain = 0.4,
    int delayMs = 0,
    _Env envelope = _Env.bell,
  }) {
    final n = (_sampleRate * ms / 1000).round();
    final delay = (_sampleRate * delayMs / 1000).round();
    final out = List<int>.filled(delay + n, 0);
    for (var i = 0; i < n; i++) {
      final t = i / n;
      final env = _adsr(t, envelope);
      final phase = 2 * math.pi * freq * (i / _sampleRate);
      out[delay + i] = (math.sin(phase) * env * gain * 32767).round().clamp(-32768, 32767);
    }
    return out;
  }

  static List<int> _sweep({
    required double startHz,
    required double endHz,
    required int ms,
    double gain = 0.3,
    int delayMs = 0,
    _Env envelope = _Env.sustain,
  }) {
    final n = (_sampleRate * ms / 1000).round();
    final delay = (_sampleRate * delayMs / 1000).round();
    final out = List<int>.filled(delay + n, 0);
    for (var i = 0; i < n; i++) {
      final t = i / n;
      final freq = startHz + (endHz - startHz) * t;
      final env = _adsr(t, envelope);
      final phase = 2 * math.pi * freq * (i / _sampleRate);
      out[delay + i] = (math.sin(phase) * env * gain * 32767).round();
    }
    return out;
  }

  static List<int> _noise({
    required int ms,
    double gain = 0.2,
    int delayMs = 0,
    _Env envelope = _Env.sustain,
  }) {
    final n = (_sampleRate * ms / 1000).round();
    final delay = (_sampleRate * delayMs / 1000).round();
    final out = List<int>.filled(delay + n, 0);
    final rng = math.Random(7);
    for (var i = 0; i < n; i++) {
      final env = _adsr(i / n, envelope);
      out[delay + i] = ((rng.nextDouble() * 2 - 1) * env * gain * 32767).round();
    }
    return out;
  }

  static double _adsr(double t, _Env kind) {
    return switch (kind) {
      _Env.pluck => math.sin(math.pi * t),
      _Env.bell =>
        math.sin(math.pi * t) * math.pow(1 - t, 0.35).toDouble(),
      _Env.swell => t < 0.2
          ? t / 0.2
          : math.pow(1 - (t - 0.2) / 0.8, 0.55).toDouble(),
      _Env.sustain => t < 0.06
          ? t / 0.06
          : t < 0.55
              ? 1.0
              : (1 - (t - 0.55) / 0.45).clamp(0.0, 1.0),
    };
  }

  static List<int> _mix(List<List<int>> parts) {
    var maxLen = 0;
    for (final p in parts) {
      if (p.length > maxLen) maxLen = p.length;
    }
    final out = List<int>.filled(maxLen, 0);
    for (final p in parts) {
      for (var i = 0; i < p.length; i++) {
        final sum = out[i] + p[i];
        out[i] = sum.clamp(-32768, 32767);
      }
    }
    return out;
  }

  static Uint8List _encodeWav(List<int> samples) {
    final byteRate = _sampleRate * 2;
    final dataSize = samples.length * 2;
    final buffer = ByteData(44 + dataSize);
    void writeStr(int offset, String s) {
      for (var i = 0; i < s.length; i++) {
        buffer.setUint8(offset + i, s.codeUnitAt(i));
      }
    }

    writeStr(0, 'RIFF');
    buffer.setUint32(4, 36 + dataSize, Endian.little);
    writeStr(8, 'WAVE');
    writeStr(12, 'fmt ');
    buffer.setUint32(16, 16, Endian.little);
    buffer.setUint16(20, 1, Endian.little);
    buffer.setUint16(22, 1, Endian.little);
    buffer.setUint32(24, _sampleRate, Endian.little);
    buffer.setUint32(28, byteRate, Endian.little);
    buffer.setUint16(32, 2, Endian.little);
    buffer.setUint16(34, 16, Endian.little);
    writeStr(36, 'data');
    buffer.setUint32(40, dataSize, Endian.little);
    var o = 44;
    for (final s in samples) {
      buffer.setInt16(o, s, Endian.little);
      o += 2;
    }
    return buffer.buffer.asUint8List();
  }
}

enum _Env { pluck, bell, swell, sustain }
