import '../../../audio/sfx_id.dart';

/// リプレイ再生中の SE 間引き（高速時は重要イベントのみ）。
class ReplaySfxGate {
  ReplaySfxGate({DateTime Function()? clock}) : _clock = clock ?? DateTime.now;

  final DateTime Function() _clock;
  final Map<String, DateTime> _lastByKey = {};

  static const double highSpeedThreshold = 8;

  /// 優先度が低いほど大きい数値（0 が最重要）。
  static int priorityForKind(String kind) {
    if (kind.contains('capture') &&
        !kind.contains('capture_zone_ack') &&
        !kind.contains('capture_zone_placed')) {
      return 0;
    }
    if (kind.contains('accusation_success')) return 1;
    if (kind == 'match_end' || kind.contains('match_end')) return 2;
    if (kind.contains('accusation_failed')) return 3;
    if (kind.contains('reveal') || kind == 'location_reveal') return 4;
    if (kind.contains('safe_zone_pickup')) return 5;
    if (kind.contains('accusation_unlocked')) return 6;
    if (kind.contains('accusation_attempt')) return 7;
    if (kind.contains('accusation_point_scored')) return 8;
    if (kind.contains('capture_zone_bound')) return 9;
    if (kind.contains('capture_zone_placed') ||
        kind.contains('capture_zone_start')) {
      return 10;
    }
    if (kind.contains('capture_zone_ack')) return 11;
    return 50;
  }

  /// 再生してよければ true。通過時にデバウンスを更新する。
  bool tryAcquire({
    required String cueKind,
    required double replaySpeed,
    required SfxId sfx,
  }) {
    final priority = priorityForKind(cueKind);
    if (replaySpeed >= 16 && priority > 1) return false;
    if (replaySpeed >= highSpeedThreshold && priority > 2) return false;
    if (replaySpeed >= 4 && priority > 8) return false;

    final debounceMs = _debounceMs(cueKind, replaySpeed);
    final key = '${sfx.name}|$cueKind';
    final now = _clock();
    final last = _lastByKey[key];
    if (last != null && now.difference(last).inMilliseconds < debounceMs) {
      return false;
    }
    _lastByKey[key] = now;
    return true;
  }

  static int _debounceMs(String kind, double speed) {
    var base = 280;
    if (kind.contains('reveal')) base = 520;
    if (kind.contains('match_end') || kind.contains('accusation_success')) {
      base = 1200;
    }
    if (kind.contains('capture_zone_ack')) base = 120;
    if (speed >= 16) return (base * 2.2).round();
    if (speed >= highSpeedThreshold) return (base * 1.7).round();
    if (speed >= 4) return (base * 1.25).round();
    return base;
  }

  void reset() => _lastByKey.clear();
}
