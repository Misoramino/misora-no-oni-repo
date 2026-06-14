import 'anonymous_reveal_trace.dart';

/// アナリスト向けの不明な痕跡読み取り（名前は出さない）。
abstract final class AnalystTraceFormat {
  static String timeBand(DateTime timestamp, DateTime now) {
    final age = now.difference(timestamp);
    if (age.inMinutes < 2) return '1分以内';
    if (age.inMinutes < 6) return '約5分前';
    if (age.inMinutes < 12) return '約10分前';
    if (age.inMinutes < 25) return '約20分前';
    return 'かなり前';
  }

  static String sourceLabel(AnonymousTraceSource source) => switch (source) {
        AnonymousTraceSource.periodic => '定期観測',
        AnonymousTraceSource.camera => '監視系',
        AnonymousTraceSource.panic => '叫び・パニック',
        AnonymousTraceSource.other => '不明源',
      };

  /// 実位置との差（m）から信頼度を導く。
  static String errorLabel(double errorMeters) {
    if (errorMeters < 1) {
      return '誤差: ほぼなし（信頼: 高）';
    }
    final m = errorMeters.round();
    if (m <= 25) return '誤差: 約${m}m（信頼: 高）';
    if (m <= 70) return '誤差: 約${m}m（信頼: 中）';
    return '誤差: 約${m}m（信頼: 低）';
  }

  static String summaryLine(AnonymousRevealTrace trace, DateTime now) {
    return '${timeBand(trace.timestamp, now)} / '
        '${sourceLabel(trace.source)} / '
        '${errorLabel(trace.errorMeters)} — ${trace.reasonSummary}';
  }
}
