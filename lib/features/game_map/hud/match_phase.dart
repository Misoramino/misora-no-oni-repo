/// 試合中 HUD に出すフェーズラベル。
abstract final class MatchPhase {
  static String label({
    required bool accusationUnlocked,
    required int remainingSeconds,
    required int matchDurationSeconds,
  }) {
    if (remainingSeconds <= 600 && remainingSeconds > 0) {
      final min = (remainingSeconds / 60).ceil().clamp(1, 10);
      return '残り$min分';
    }
    if (accusationUnlocked) return '告発可';
    final elapsed = matchDurationSeconds - remainingSeconds;
    if (elapsed < matchDurationSeconds * 0.15) return '序盤・潜伏';
    return '中盤・追跡';
  }
}
