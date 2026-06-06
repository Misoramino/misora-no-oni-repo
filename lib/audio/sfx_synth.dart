import 'dart:math' as math;
import 'dart:typed_data';

import 'sfx_id.dart';

/// 効果音のコード合成（外部ファイル不要のフォールバック）。
///
/// 短く・粒立ちの良い UI/ゲーム SE を WAV(PCM16/22.05kHz) で生成する。
abstract final class SfxSynth {
  static const _sampleRate = 22050;

  static final Map<SfxId, Uint8List> _cache = {};

  /// [id] の合成 WAV を返す（生成結果はキャッシュ）。
  static Uint8List wavFor(SfxId id) {
    return _cache.putIfAbsent(id, () => _encodeWav(_fadeTail(_build(id), 0.1)));
  }

  static List<int> _build(SfxId id) => switch (id) {
        SfxId.uiTap => _mix([
            _tone(freq: 880, ms: 38, gain: 0.18, env: _Env.pluck),
            _tone(freq: 1320, ms: 30, gain: 0.10, env: _Env.pluck),
          ]),
        SfxId.uiToggle => _mix([
            _tone(freq: 660, ms: 40, gain: 0.16, env: _Env.pluck),
            _tone(freq: 990, ms: 60, gain: 0.12, delayMs: 35, env: _Env.bell),
          ]),
        SfxId.uiBack => _mix([
            _tone(freq: 520, ms: 50, gain: 0.16, env: _Env.pluck),
            _tone(freq: 350, ms: 70, gain: 0.12, delayMs: 40, env: _Env.bell),
          ]),
        SfxId.uiConfirm => _mix([
            _tone(freq: 784, ms: 70, gain: 0.18, env: _Env.bell),
            _tone(freq: 1175, ms: 120, gain: 0.14, delayMs: 60, env: _Env.bell),
          ]),
        SfxId.uiError || SfxId.denied => _mix([
            _tone(freq: 196, ms: 110, gain: 0.22, env: _Env.bell),
            _tone(freq: 185, ms: 150, gain: 0.18, delayMs: 90, env: _Env.bell),
          ]),
        SfxId.matchStart => _mix([
            _tone(freq: 392, ms: 120, gain: 0.2, env: _Env.bell),
            _tone(freq: 523, ms: 120, gain: 0.2, delayMs: 110, env: _Env.bell),
            _tone(freq: 784, ms: 220, gain: 0.22, delayMs: 220, env: _Env.sustain),
            _sweep(startHz: 300, endHz: 1200, ms: 320, gain: 0.1, delayMs: 120),
          ]),
        SfxId.matchWin => _fanfare(),
        SfxId.matchLose => _mix([
            _tone(freq: 392, ms: 200, gain: 0.2, env: _Env.bell),
            _tone(freq: 330, ms: 220, gain: 0.2, delayMs: 180, env: _Env.bell),
            _tone(freq: 262, ms: 380, gain: 0.22, delayMs: 360, env: _Env.sustain),
            _sweep(startHz: 600, endHz: 120, ms: 480, gain: 0.08, delayMs: 200),
          ]),
        SfxId.capture => _mix([
            _noise(ms: 60, gain: 0.3),
            _tone(freq: 130, ms: 200, gain: 0.34, env: _Env.swell),
            _sweep(startHz: 900, endHz: 110, ms: 280, gain: 0.16, delayMs: 30),
          ]),
        SfxId.eliminated => _mix([
            _tone(freq: 110, ms: 320, gain: 0.34, env: _Env.swell),
            _sweep(startHz: 740, endHz: 90, ms: 420, gain: 0.12, delayMs: 40),
            _noise(ms: 120, gain: 0.1, delayMs: 20),
          ]),
        SfxId.reveal => _mix([
            _tone(freq: 1320, ms: 70, gain: 0.16, env: _Env.bell),
            _tone(freq: 1760, ms: 120, gain: 0.12, delayMs: 50, env: _Env.bell),
            _noise(ms: 80, gain: 0.06),
          ]),
        SfxId.anonReveal => _mix([
            _tone(freq: 660, ms: 80, gain: 0.12, env: _Env.bell),
            _noise(ms: 90, gain: 0.07, delayMs: 20),
          ]),
        SfxId.skillCast => _mix([
            _sweep(startHz: 420, endHz: 1500, ms: 220, gain: 0.16),
            _tone(freq: 1500, ms: 120, gain: 0.12, delayMs: 180, env: _Env.bell),
          ]),
        SfxId.skillReady => _mix([
            _tone(freq: 988, ms: 70, gain: 0.16, env: _Env.bell),
            _tone(freq: 1319, ms: 110, gain: 0.14, delayMs: 70, env: _Env.bell),
          ]),
        SfxId.proximityWarning => _mix([
            _tone(freq: 440, ms: 120, gain: 0.18, env: _Env.bell),
          ]),
        SfxId.proximityDanger => _mix([
            _tone(freq: 660, ms: 90, gain: 0.2, env: _Env.bell),
            _tone(freq: 660, ms: 90, gain: 0.2, delayMs: 130, env: _Env.bell),
          ]),
        SfxId.reward => _mix([
            _tone(freq: 784, ms: 90, gain: 0.18, env: _Env.bell),
            _tone(freq: 1046, ms: 90, gain: 0.18, delayMs: 90, env: _Env.bell),
            _tone(freq: 1568, ms: 200, gain: 0.2, delayMs: 180, env: _Env.sustain),
          ]),
        SfxId.unlock => _mix([
            _sweep(startHz: 500, endHz: 1600, ms: 260, gain: 0.14),
            _tone(freq: 1760, ms: 220, gain: 0.16, delayMs: 240, env: _Env.sustain),
            _tone(freq: 2093, ms: 180, gain: 0.1, delayMs: 320, env: _Env.bell),
          ]),
        SfxId.confetti => _mix([
            _noise(ms: 60, gain: 0.12),
            _tone(freq: 1568, ms: 80, gain: 0.12, delayMs: 20, env: _Env.pluck),
            _tone(freq: 2093, ms: 90, gain: 0.1, delayMs: 70, env: _Env.pluck),
          ]),
      };

  static List<int> _fanfare() {
    const notes = [523.25, 659.25, 784.0, 1046.5];
    final parts = <List<int>>[];
    for (var i = 0; i < notes.length; i++) {
      parts.add(
        _tone(
          freq: notes[i],
          ms: i == notes.length - 1 ? 320 : 120,
          gain: 0.22,
          delayMs: i * 110,
          env: i == notes.length - 1 ? _Env.sustain : _Env.bell,
        ),
      );
    }
    parts.add(_tone(freq: 1568, ms: 260, gain: 0.12, delayMs: 440, env: _Env.bell));
    return _mix(parts);
  }

  static List<int> _tone({
    required double freq,
    required int ms,
    double gain = 0.3,
    int delayMs = 0,
    _Env env = _Env.bell,
  }) {
    final n = (_sampleRate * ms / 1000).round();
    final delay = (_sampleRate * delayMs / 1000).round();
    final out = List<int>.filled(delay + n, 0);
    for (var i = 0; i < n; i++) {
      final t = i / n;
      final e = _adsr(t, env);
      final phase = 2 * math.pi * freq * (i / _sampleRate);
      out[delay + i] =
          (math.sin(phase) * e * gain * 32767).round().clamp(-32768, 32767);
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
      final e = _adsr(t, _Env.sustain);
      final phase = 2 * math.pi * freq * (i / _sampleRate);
      out[delay + i] =
          (math.sin(phase) * e * gain * 32767).round().clamp(-32768, 32767);
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
    final rng = math.Random(11);
    for (var i = 0; i < n; i++) {
      final e = _adsr(i / n, _Env.bell);
      out[delay + i] =
          ((rng.nextDouble() * 2 - 1) * e * gain * 32767).round().clamp(-32768, 32767);
    }
    return out;
  }

  static double _adsr(double t, _Env kind) => switch (kind) {
        _Env.pluck => math.pow(1 - t, 2.2).toDouble(),
        _Env.bell => math.sin(math.pi * t) * math.pow(1 - t, 0.4).toDouble(),
        _Env.swell =>
          t < 0.25 ? t / 0.25 : math.pow(1 - (t - 0.25) / 0.75, 0.6).toDouble(),
        _Env.sustain => t < 0.06
            ? t / 0.06
            : t < 0.6
                ? 1.0
                : (1 - (t - 0.6) / 0.4).clamp(0.0, 1.0),
      };

  static List<int> _mix(List<List<int>> parts) {
    var maxLen = 0;
    for (final p in parts) {
      if (p.length > maxLen) maxLen = p.length;
    }
    final out = List<int>.filled(maxLen, 0);
    for (final p in parts) {
      for (var i = 0; i < p.length; i++) {
        out[i] = (out[i] + p[i]).clamp(-32768, 32767);
      }
    }
    return out;
  }

  static List<int> _fadeTail(List<int> samples, double tailRatio) {
    if (samples.isEmpty) return samples;
    final fadeStart = (samples.length * (1 - tailRatio)).round();
    final out = List<int>.from(samples);
    for (var i = fadeStart; i < out.length; i++) {
      final t = (i - fadeStart) / (out.length - fadeStart);
      out[i] = (out[i] * (1 - t)).round();
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
