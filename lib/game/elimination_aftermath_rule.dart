/// 脱落後の観戦ルール（ローカル1端末のルーム設定。将来はホストが同期）。
enum EliminationAftermathRule {
  /// 中立の幽霊として、全員のざっくり位置だけを見る。
  ghostSpectator,

  /// 鬼側に合流した索敵支援として、同じざっくり位置を鬼視点で見る。
  joinOni,
}

extension EliminationAftermathRuleX on EliminationAftermathRule {
  String get label => switch (this) {
        EliminationAftermathRule.ghostSpectator => '幽霊（中立・全体ざっくり）',
        EliminationAftermathRule.joinOni => '鬼合流（鬼側索敵のざっくり）',
      };

  String get infoPanelLine => switch (this) {
        EliminationAftermathRule.ghostSpectator => '幽霊: 全体のざっくり位置を表示中',
        EliminationAftermathRule.joinOni => '鬼側合流: 索敵支援（ざっくり位置）を表示中',
      };

  static EliminationAftermathRule? tryParseName(String? raw) {
    if (raw == null || raw.isEmpty) return null;
    for (final v in EliminationAftermathRule.values) {
      if (v.name == raw) return v;
    }
    return null;
  }
}
