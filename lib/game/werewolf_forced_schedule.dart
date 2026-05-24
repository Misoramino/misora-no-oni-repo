import 'dart:math' as math;

/// 人狼の強制鬼化⇄人化タイミング（全員通知なし・ローカルのみ）。
abstract final class WerewolfForcedSchedule {
  /// 10分（600秒）と試合時間の1/3の**短い方**を間隔に、繰り返し強制切替。
  static int intervalSeconds(int matchDurationSeconds) {
    final d = matchDurationSeconds.clamp(60, 90 * 60);
    return math.min(600, d ~/ 3).clamp(30, 600);
  }

  /// 経過秒がこの値以上になったら、その閾値の強制切替を1回発火。
  static List<int> thresholdSeconds(int matchDurationSeconds) {
    final d = matchDurationSeconds.clamp(60, 90 * 60);
    final step = intervalSeconds(d);
    final out = <int>[];
    for (var t = step; t < d; t += step) {
      out.add(t);
    }
    return out;
  }

  /// 強制切替発動後の再切替まで（秒）: `0.9 × interval`。
  static int forcedTransformCooldownSeconds(int matchDurationSeconds) {
    final interval = intervalSeconds(matchDurationSeconds);
    return (interval * 9) ~/ 10;
  }

  /// 任意の鬼化⇄人化の再切替まで（秒）: `0.75 × interval`。
  static int voluntaryTransformCooldownSeconds(int matchDurationSeconds) {
    final interval = intervalSeconds(matchDurationSeconds);
    return (interval * 3) ~/ 4;
  }
}
