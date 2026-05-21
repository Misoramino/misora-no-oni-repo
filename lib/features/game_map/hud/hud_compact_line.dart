/// 試合中 HUD 一行表示で出す情報の種類。
enum HudCompactLineSlot {
  /// 有効な行のうち優先度順で最初の1つ（鬼情報 → 状態 → コンディション）
  auto,

  intel,
  status,
  condition,
}

extension HudCompactLineSlotLabel on HudCompactLineSlot {
  String get label => switch (this) {
        HudCompactLineSlot.auto => '自動（有効な行から1つ）',
        HudCompactLineSlot.intel => '鬼情報',
        HudCompactLineSlot.status => '状態メッセージ',
        HudCompactLineSlot.condition => 'コンディション',
      };

  static HudCompactLineSlot fromStorage(String? raw) {
    if (raw == null) return HudCompactLineSlot.auto;
    for (final s in HudCompactLineSlot.values) {
      if (s.name == raw) return s;
    }
    return HudCompactLineSlot.auto;
  }
}

/// 一行 HUD に載せる文言を決める（エリア内外はタイマー背景色で示すため含めない）。
String resolveHudCompactLineText({
  required HudCompactLineSlot slot,
  required bool showIntelLine,
  required bool showStatusLine,
  required bool showConditionLine,
  required String intelLine,
  required String statusText,
  required String conditionText,
}) {
  String? lineFor(HudCompactLineSlot s) {
    return switch (s) {
      HudCompactLineSlot.intel =>
        showIntelLine && intelLine.isNotEmpty ? intelLine : null,
      HudCompactLineSlot.status =>
        showStatusLine && statusText.isNotEmpty ? statusText : null,
      HudCompactLineSlot.condition =>
        showConditionLine && conditionText.isNotEmpty ? conditionText : null,
      HudCompactLineSlot.auto => null,
    };
  }

  if (slot != HudCompactLineSlot.auto) {
    return lineFor(slot) ?? '';
  }

  for (final s in [
    HudCompactLineSlot.intel,
    HudCompactLineSlot.status,
    HudCompactLineSlot.condition,
  ]) {
    final t = lineFor(s);
    if (t != null) return t;
  }
  return '';
}
