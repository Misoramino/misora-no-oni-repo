import 'dart:math' as math;
import 'dart:typed_data';

import 'world_profile.dart';

/// 起動時の短い効果音（WAV PCM、外部ファイル不要）。
abstract final class LaunchSoundSynth {
  static const _sampleRate = 22050;

  static Uint8List wavFor(WorldProfile profile) {
    final samples = switch (profile) {
      WorldProfile.sciFi => _cyberChirp(),
      WorldProfile.horror => _horrorPulse(),
      WorldProfile.sport => _popBlip(),
      WorldProfile.arg => _tacticalClick(),
      WorldProfile.magical => _magicalChime(),
      WorldProfile.astronomy => _astronomySpace(),
    };
    return _encodeWav(samples);
  }

  static List<int> _cyberChirp() {
    return _mix([
      _tone(freq: 880, ms: 55, gain: 0.35),
      _tone(freq: 1320, ms: 45, gain: 0.28, delayMs: 50),
      _sweep(startHz: 400, endHz: 1200, ms: 70, gain: 0.18, delayMs: 90),
    ]);
  }

  static List<int> _horrorPulse() {
    return _mix([
      _tone(freq: 62, ms: 120, gain: 0.5),
      _tone(freq: 48, ms: 90, gain: 0.35, delayMs: 130),
      _noise(ms: 80, gain: 0.12, delayMs: 40),
    ]);
  }

  static List<int> _popBlip() {
    return _mix([
      _tone(freq: 620, ms: 35, gain: 0.3),
      _tone(freq: 980, ms: 40, gain: 0.22, delayMs: 28),
    ]);
  }

  static List<int> _tacticalClick() {
    return _mix([
      _noise(ms: 18, gain: 0.55),
      _tone(freq: 220, ms: 25, gain: 0.2, delayMs: 8),
    ]);
  }

  /// 魔法のチャイム（上昇アルペジオ + きらめき）。
  static List<int> _magicalChime() {
    return _mix([
      _tone(freq: 392, ms: 90, gain: 0.22),
      _tone(freq: 494, ms: 85, gain: 0.2, delayMs: 75),
      _tone(freq: 587, ms: 95, gain: 0.18, delayMs: 150),
      _tone(freq: 784, ms: 130, gain: 0.14, delayMs: 235),
      _tone(freq: 988, ms: 100, gain: 0.1, delayMs: 320),
      _noise(ms: 120, gain: 0.05, delayMs: 180),
    ]);
  }

  /// 宇宙の低音ドローン + 遠い星のティンクル。
  static List<int> _astronomySpace() {
    return _mix([
      _tone(freq: 48, ms: 280, gain: 0.28),
      _tone(freq: 72, ms: 200, gain: 0.15, delayMs: 60),
      _sweep(startHz: 180, endHz: 520, ms: 350, gain: 0.08, delayMs: 100),
      _tone(freq: 1047, ms: 70, gain: 0.1, delayMs: 280),
      _tone(freq: 1318, ms: 90, gain: 0.07, delayMs: 340),
      _noise(ms: 200, gain: 0.03, delayMs: 0),
    ]);
  }

  static List<int> _tone({
    required double freq,
    required int ms,
    double gain = 0.4,
    int delayMs = 0,
  }) {
    final n = (_sampleRate * ms / 1000).round();
    final delay = (_sampleRate * delayMs / 1000).round();
    final out = List<int>.filled(delay + n, 0);
    for (var i = 0; i < n; i++) {
      final t = i / _sampleRate;
      final env = math.sin(math.pi * i / n);
      final v = math.sin(2 * math.pi * freq * t) * env * gain;
      out[delay + i] = (v * 32767).round().clamp(-32768, 32767);
    }
    return out;
  }

  static List<int> _sweep({
    required double startHz,
    required double endHz,
    required int ms,
    double gain = 0.3,
    int delayMs = 0,
  }) {
    final n = (_sampleRate * ms / 1000).round();
    final delay = (_sampleRate * delayMs / 1000).round();
    final out = List<int>.filled(delay + n, 0);
    for (var i = 0; i < n; i++) {
      final t = i / n;
      final freq = startHz + (endHz - startHz) * t;
      final env = math.sin(math.pi * i / n);
      final phase = 2 * math.pi * freq * (i / _sampleRate);
      out[delay + i] = (math.sin(phase) * env * gain * 32767).round();
    }
    return out;
  }

  static List<int> _noise({
    required int ms,
    double gain = 0.2,
    int delayMs = 0,
  }) {
    final n = (_sampleRate * ms / 1000).round();
    final delay = (_sampleRate * delayMs / 1000).round();
    final out = List<int>.filled(delay + n, 0);
    final rng = math.Random(7);
    for (var i = 0; i < n; i++) {
      final env = 1 - (i / n);
      out[delay + i] = ((rng.nextDouble() * 2 - 1) * env * gain * 32767).round();
    }
    return out;
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
