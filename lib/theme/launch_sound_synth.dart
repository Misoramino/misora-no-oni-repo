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
      _tone(freq: 110, ms: 40, gain: 0.22),
      _tone(freq: 880, ms: 50, gain: 0.38),
      _tone(freq: 1320, ms: 45, gain: 0.3, delayMs: 48),
      _tone(freq: 1760, ms: 35, gain: 0.18, delayMs: 88),
      _sweep(startHz: 520, endHz: 1400, ms: 65, gain: 0.2, delayMs: 95),
    ]);
  }

  static List<int> _horrorPulse() {
    return _mix([
      _tone(freq: 55, ms: 110, gain: 0.55),
      _tone(freq: 41, ms: 85, gain: 0.4, delayMs: 115),
      _tone(freq: 220, ms: 45, gain: 0.12, delayMs: 60),
      _noise(ms: 70, gain: 0.14, delayMs: 35),
      _sweep(startHz: 900, endHz: 180, ms: 90, gain: 0.08, delayMs: 150),
    ]);
  }

  static List<int> _popBlip() {
    return _mix([
      _tone(freq: 523, ms: 32, gain: 0.32),
      _tone(freq: 784, ms: 36, gain: 0.26, delayMs: 26),
      _tone(freq: 1047, ms: 42, gain: 0.2, delayMs: 58),
      _tone(freq: 1319, ms: 30, gain: 0.14, delayMs: 88),
    ]);
  }

  static List<int> _tacticalClick() {
    return _mix([
      _noise(ms: 14, gain: 0.6),
      _tone(freq: 180, ms: 22, gain: 0.28, delayMs: 6),
      _tone(freq: 320, ms: 18, gain: 0.16, delayMs: 22),
      _noise(ms: 10, gain: 0.35, delayMs: 38),
    ]);
  }

  static List<int> _magicalChime() {
    return _mix([
      _tone(freq: 392, ms: 75, gain: 0.24),
      _tone(freq: 494, ms: 70, gain: 0.22, delayMs: 65),
      _tone(freq: 587, ms: 80, gain: 0.2, delayMs: 130),
      _tone(freq: 784, ms: 110, gain: 0.16, delayMs: 200),
      _tone(freq: 988, ms: 85, gain: 0.12, delayMs: 275),
      _tone(freq: 1175, ms: 70, gain: 0.1, delayMs: 330),
      _noise(ms: 90, gain: 0.06, delayMs: 160),
    ]);
  }

  static List<int> _astronomySpace() {
    return _mix([
      _tone(freq: 44, ms: 200, gain: 0.32),
      _tone(freq: 66, ms: 150, gain: 0.18, delayMs: 50),
      _sweep(startHz: 200, endHz: 480, ms: 280, gain: 0.1, delayMs: 80),
      _tone(freq: 1047, ms: 65, gain: 0.12, delayMs: 240),
      _tone(freq: 1318, ms: 80, gain: 0.09, delayMs: 295),
      _tone(freq: 1568, ms: 55, gain: 0.07, delayMs: 340),
      _noise(ms: 160, gain: 0.035, delayMs: 0),
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
