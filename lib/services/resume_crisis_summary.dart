import 'background_crisis_alert.dart';

/// 復帰 replay 中にキューした危機イベント（テスト可能）。
class ResumeCrisisEntry {
  const ResumeCrisisEntry({
    required this.kind,
    required this.title,
    required this.body,
  });

  final BackgroundCrisisKind kind;
  final String title;
  final String body;

  String get summaryLine => switch (kind) {
        BackgroundCrisisKind.eliminated => '捕獲されました',
        BackgroundCrisisKind.selfNamedReveal => '名前付き暴露されました',
        BackgroundCrisisKind.outsideAreaReveal => 'プレイエリア外に近づいていました',
        BackgroundCrisisKind.accusationUnlocked => '告発が解禁されました',
        BackgroundCrisisKind.matchEnded => '試合が終了しました',
        BackgroundCrisisKind.captureZoneBound ||
        BackgroundCrisisKind.touchLock =>
          '捕獲圏・拘束の危険がありました',
        BackgroundCrisisKind.proximityDanger ||
        BackgroundCrisisKind.panicImminent =>
          '鬼が非常に近い状態でした',
        BackgroundCrisisKind.proximityWarning ||
        BackgroundCrisisKind.panicWarning ||
        BackgroundCrisisKind.panicStarted ||
        BackgroundCrisisKind.panicTrace =>
          '近接・パニックの危険がありました',
      };
}

/// 復帰 replay 中の危機通知を集約し、サマリー表示用に整列する。
class ResumeCrisisSummaryCollector {
  final List<ResumeCrisisEntry> _entries = [];

  void record({
    required BackgroundCrisisKind kind,
    required String title,
    required String body,
  }) {
    _entries.add(ResumeCrisisEntry(kind: kind, title: title, body: body));
  }

  bool get isEmpty => _entries.isEmpty;

  /// 優先度順に並べ、同カテゴリは先頭のみ残す。
  List<ResumeCrisisEntry> drainPrioritized() {
    if (_entries.isEmpty) return const [];
    final sorted = [..._entries]..sort(
        (a, b) => _priority(a.kind).compareTo(_priority(b.kind)),
      );
    _entries.clear();
    final seen = <String>{};
    final out = <ResumeCrisisEntry>[];
    for (final e in sorted) {
      final cat = BackgroundCrisisAlert.categoryFor(e.kind);
      if (seen.add(cat)) out.add(e);
    }
    return out;
  }

  static int _priority(BackgroundCrisisKind kind) => switch (kind) {
        BackgroundCrisisKind.matchEnded => 0,
        BackgroundCrisisKind.eliminated => 1,
        BackgroundCrisisKind.selfNamedReveal => 2,
        BackgroundCrisisKind.accusationUnlocked => 3,
        BackgroundCrisisKind.captureZoneBound ||
        BackgroundCrisisKind.touchLock =>
          4,
        BackgroundCrisisKind.proximityDanger ||
        BackgroundCrisisKind.panicImminent =>
          5,
        BackgroundCrisisKind.outsideAreaReveal => 6,
        _ => 7,
      };
}
