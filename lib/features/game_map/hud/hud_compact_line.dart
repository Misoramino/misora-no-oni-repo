/// 試合中 HUD 一行表示で出す情報の種類。
enum HudCompactLineSlot {
  /// 有効な行を連結して一行スクロール（鬼情報 → 状態 → コンディション）
  all,

  intel,
  status,
  condition,
}

extension HudCompactLineSlotLabel on HudCompactLineSlot {
  String get label => switch (this) {
        HudCompactLineSlot.all => 'すべて',
        HudCompactLineSlot.intel => '鬼情報のみ',
        HudCompactLineSlot.status => '状態メッセージのみ',
        HudCompactLineSlot.condition => 'コンディションのみ',
      };

  static HudCompactLineSlot fromStorage(String? raw) {
    if (raw == null || raw == 'auto') return HudCompactLineSlot.all;
    for (final s in HudCompactLineSlot.values) {
      if (s.name == raw) return s;
    }
    return HudCompactLineSlot.all;
  }
}

/// 一行 HUD に載せる文言（エリア内外はタイマー背景色で示すため含めない）。
String resolveHudCompactLineText({
  required HudCompactLineSlot slot,
  required bool showIntelLine,
  required bool showStatusLine,
  required bool showConditionLine,
  required String intelLine,
  required String statusText,
  required String conditionText,
  String separator = '  ·  ',
}) {
  String? lineFor(HudCompactLineSlot s) {
    return switch (s) {
      HudCompactLineSlot.intel =>
        showIntelLine && intelLine.isNotEmpty ? intelLine : null,
      HudCompactLineSlot.status =>
        showStatusLine && statusText.isNotEmpty ? statusText : null,
      HudCompactLineSlot.condition =>
        showConditionLine && conditionText.isNotEmpty ? conditionText : null,
      HudCompactLineSlot.all => null,
    };
  }

  if (slot != HudCompactLineSlot.all) {
    return lineFor(slot) ?? '';
  }

  final parts = <String>[];
  for (final s in [
    HudCompactLineSlot.intel,
    HudCompactLineSlot.status,
    HudCompactLineSlot.condition,
  ]) {
    final t = lineFor(s);
    if (t != null) parts.add(t);
  }
  return parts.join(separator);
}
