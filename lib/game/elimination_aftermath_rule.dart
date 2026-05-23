/// 脱落後のルール（ホストが試合開始時に同期。カスタムでも選択可）。
enum EliminationAftermathRule {
  /// 残響体: カメラジャックで逃走陣営を支援（既定）。
  spectralOperative,

  /// 観戦のみ（ざっくり位置）。
  ghostSpectator,

  /// 鬼側索敵のざっくり位置。
  joinOni,

  /// 脱落時に鬼として動く（実験・バランス要調整）。
  revenantOni,
}

extension EliminationAftermathRuleX on EliminationAftermathRule {
  String get label => switch (this) {
        EliminationAftermathRule.spectralOperative => '残響体（カメラジャック）',
        EliminationAftermathRule.ghostSpectator => '幽霊（観戦のみ）',
        EliminationAftermathRule.joinOni => '鬼合流（索敵支援）',
        EliminationAftermathRule.revenantOni => '復讐の鬼影（実験）',
      };

  String get infoPanelLine => switch (this) {
        EliminationAftermathRule.spectralOperative =>
          '残響体: 監視端子で鬼の位置を露わにできる',
        EliminationAftermathRule.ghostSpectator => '幽霊: 全体のざっくり位置を表示中',
        EliminationAftermathRule.joinOni => '鬼側合流: 索敵支援（ざっくり位置）',
        EliminationAftermathRule.revenantOni => '復讐の鬼影: 鬼として追跡（実験）',
      };

  bool get supportsCameraJack =>
      this == EliminationAftermathRule.spectralOperative;

  static EliminationAftermathRule? tryParseName(String? raw) {
    if (raw == null || raw.isEmpty) return null;
    for (final v in EliminationAftermathRule.values) {
      if (v.name == raw) return v;
    }
    return null;
  }
}
