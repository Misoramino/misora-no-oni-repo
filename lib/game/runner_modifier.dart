/// 逃走者の試合内特化（独立ロールではない）。
enum RunnerModifier {
  none,
  analyst,
  hacker,
}

extension RunnerModifierLabel on RunnerModifier {
  String get label => switch (this) {
        RunnerModifier.none => '標準',
        RunnerModifier.analyst => 'アナリスト',
        RunnerModifier.hacker => 'ハッカー',
      };

}

RunnerModifier parseRunnerModifier(String? raw) {
  if (raw == null) return RunnerModifier.none;
  for (final v in RunnerModifier.values) {
    if (v.name == raw) return v;
  }
  return RunnerModifier.none;
}
