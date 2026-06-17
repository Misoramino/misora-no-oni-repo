/// 試合経過時間をサーバー基準（startedAtUtc）で算出する。
abstract final class MatchElapsedSync {
  static int elapsedSeconds({
    required String? startedAtUtc,
    required int matchDurationSeconds,
    DateTime? nowUtc,
  }) {
    final started = DateTime.tryParse(startedAtUtc ?? '');
    if (started == null) return 0;
    final now = (nowUtc ?? DateTime.now()).toUtc();
    return now
        .difference(started.toUtc())
        .inSeconds
        .clamp(0, matchDurationSeconds);
  }

  static int remainingSeconds({
    required String? startedAtUtc,
    required int matchDurationSeconds,
    DateTime? nowUtc,
  }) {
    final elapsed = elapsedSeconds(
      startedAtUtc: startedAtUtc,
      matchDurationSeconds: matchDurationSeconds,
      nowUtc: nowUtc,
    );
    return (matchDurationSeconds - elapsed).clamp(0, matchDurationSeconds);
  }
}
