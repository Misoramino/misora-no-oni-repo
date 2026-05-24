import 'dart:math' as math;

import 'game_config.dart';

/// 試合時間（30〜60分モデル）に連動する各種タイミング。
abstract final class MatchDurationScaling {
  static const int minMatchSeconds = 600;
  static const int maxMatchSeconds = 90 * 60;

  /// 推奨モデルケース（標準プレイ）。
  static const int recommendedMatchSeconds = 45 * 60;

  static int clampDuration(int matchDurationSeconds) =>
      matchDurationSeconds.clamp(minMatchSeconds, maxMatchSeconds);

  /// 告発解禁の「脱落＋経過」条件。固定5分と試合25%の**長い方**（上限15分）。
  static int accusationUnlockMinElapsedSeconds(int matchDurationSeconds) {
    final d = clampDuration(matchDurationSeconds);
    final scaled = (d * 0.25).round();
    return math
        .max(GameConfig.accusationUnlockMinElapsedSeconds, scaled)
        .clamp(300, 15 * 60);
  }

  /// 鬼の遅延軌跡: 試合の約22〜38%前の帯（幅は試合に比例）。
  static ({int minAgeSeconds, int maxAgeSeconds, int retainSeconds}) oniTrail(
    int matchDurationSeconds,
  ) {
    final d = clampDuration(matchDurationSeconds);
    final minAge = (d * 0.22).round().clamp(300, 20 * 60);
    final maxAge = (d * 0.38).round().clamp(minAge + 120, d ~/ 2);
    final retain = (d * 0.42).round().clamp(maxAge + 60, d);
    return (
      minAgeSeconds: minAge,
      maxAgeSeconds: maxAge,
      retainSeconds: retain,
    );
  }

  /// 試合開始付近の鬼位置ピン（短い試合・序盤の手がかり）。長い試合では10分まで。
  static int oniStartAnchorMaxElapsedSeconds(int matchDurationSeconds) {
    final d = clampDuration(matchDurationSeconds);
    return math.min(600, (d * 0.15).round()).clamp(180, 600);
  }
}
