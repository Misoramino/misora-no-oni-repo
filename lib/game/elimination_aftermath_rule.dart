import 'werewolf_faction_logic.dart';

/// 脱落後のルール（ホストが試合開始時に同期。カスタムでも選択可）。
enum EliminationAftermathRule {
  /// 残響体: カメラジャックで逃走陣営を支援（既定）。
  spectralOperative,

  /// 観戦のみ（ざっくり位置）。
  ghostSpectator,

  /// 鬼側索敵のざっくり位置。
  joinOni,

  /// 脱落時に鬼として動く（実験・バランス要調整）。
  revenantOni;

  /// 試合の脱落後モードが [spectralOperative] / [revenantOni] のとき、
  /// 脱落時点の陣営で残響体 or 復讐の鬼影に分岐する。
  /// [ghostSpectator] / [joinOni] は試合全体の実験モードとしてそのまま適用。
  static EliminationAftermathRule forEliminatedFaction({
    required EliminationAftermathRule matchDefault,
    required FactionSide factionAtDeath,
  }) {
    return switch (matchDefault) {
      EliminationAftermathRule.spectralOperative ||
      EliminationAftermathRule.revenantOni =>
        factionAtDeath == FactionSide.oniTeam
            ? EliminationAftermathRule.revenantOni
            : EliminationAftermathRule.spectralOperative,
      _ => matchDefault,
    };
  }

  /// 後方互換。新規は [forEliminatedFaction] を使う。
  static EliminationAftermathRule forEliminatedRole({
    required EliminationAftermathRule matchDefault,
    required bool isOniSide,
  }) =>
      forEliminatedFaction(
        matchDefault: matchDefault,
        factionAtDeath:
            isOniSide ? FactionSide.oniTeam : FactionSide.humanTeam,
      );

  static EliminationAftermathRule? tryParseName(String? raw) {
    if (raw == null || raw.isEmpty) return null;
    for (final v in EliminationAftermathRule.values) {
      if (v.name == raw) return v;
    }
    return null;
  }
}

extension EliminationAftermathRuleX on EliminationAftermathRule {
  String get label => switch (this) {
        EliminationAftermathRule.spectralOperative => '残響体（カメラジャック）',
        EliminationAftermathRule.ghostSpectator => '幽霊（観戦のみ）',
        EliminationAftermathRule.joinOni => '鬼合流（索敵支援）',
        EliminationAftermathRule.revenantOni => '復讐の鬼影（鬼側・実験）',
      };

  String get infoPanelLine => switch (this) {
        EliminationAftermathRule.spectralOperative =>
          '残響体: 監視ジャック / 告発施設の陣取り',
        EliminationAftermathRule.ghostSpectator => '幽霊: 全体のざっくり位置を表示中',
        EliminationAftermathRule.joinOni => '鬼側合流: 索敵支援（ざっくり位置）',
        EliminationAftermathRule.revenantOni =>
          '復讐の鬼影: 告発妨害（3回）/ カメラ停止（無制限・各1回）',
      };

  bool get supportsCameraJack =>
      this == EliminationAftermathRule.spectralOperative;

  bool get supportsFacilitySabotage =>
      this == EliminationAftermathRule.revenantOni;

  bool get supportsSpectralTerritoryCharge =>
      this == EliminationAftermathRule.spectralOperative;
}
