import 'dart:math' as math;

/// 人狼の鬼化⇄人化タイミング（全員通知なし・ローカルのみ）。
///
/// **前回の切替（強制・任意どちらでも）から [intervalSeconds] 経過で強制トグル。**
/// 任意切替は [voluntaryTransformCooldownSeconds] の CD 後に可能で、
/// 発動すると強制タイマーも CD もその時点から再カウントする。
abstract final class WerewolfForcedSchedule {
  /// 強制切替までの目安（秒）: `min(15分, 試合時間÷2)` — 自発切替の猶予を長めに。
  static int intervalSeconds(int matchDurationSeconds) {
    final d = matchDurationSeconds.clamp(60, 90 * 60);
    return math.min(900, d ~/ 2).clamp(60, 900);
  }

  /// 任意の鬼化⇄人化の再切替まで（秒）: `interval ÷ 3`（初回CDも同じ）。
  static int voluntaryTransformCooldownSeconds(int matchDurationSeconds) {
    final interval = intervalSeconds(matchDurationSeconds);
    return interval ~/ 3;
  }

  static int secondsSinceLastTransform(
    DateTime? lastTransformAt,
    DateTime now,
  ) {
    if (lastTransformAt == null) return 0;
    return now.difference(lastTransformAt).inSeconds;
  }

  /// 前回切替から強制間隔を超えたら true。
  static bool shouldForceToggle({
    required DateTime? lastTransformAt,
    required DateTime now,
    required int matchDurationSeconds,
  }) {
    if (lastTransformAt == null) return false;
    return secondsSinceLastTransform(lastTransformAt, now) >=
        intervalSeconds(matchDurationSeconds);
  }

  static int secondsUntilForcedToggle({
    required DateTime? lastTransformAt,
    required DateTime now,
    required int matchDurationSeconds,
  }) {
    final interval = intervalSeconds(matchDurationSeconds);
    if (lastTransformAt == null) return interval;
    final remain =
        interval - secondsSinceLastTransform(lastTransformAt, now);
    return remain.clamp(0, interval);
  }
}
