import 'anonymous_reveal_trace.dart';

/// アナリスト向けの匿名痕跡読み取り（名前は出さない）。
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

  static String confidenceLabel(AnonymousTraceSource source) => switch (source) {
        AnonymousTraceSource.camera => '信頼: 中',
        AnonymousTraceSource.panic => '信頼: 中',
        AnonymousTraceSource.periodic => '信頼: 低〜中',
        AnonymousTraceSource.other => '信頼: 低',
      };

  static String summaryLine(AnonymousRevealTrace trace, DateTime now) {
    return '${timeBand(trace.timestamp, now)} / '
        '${sourceLabel(trace.source)} / '
        '${confidenceLabel(trace.source)} — ${trace.reasonSummary}';
  }
}
