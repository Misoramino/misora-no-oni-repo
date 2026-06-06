import '../../../game/accusation_weight.dart';
import '../../../game/elimination_aftermath_rule.dart';
import '../../../game/oni_intel_mode.dart';
import '../../../game/match_quick_preset.dart';
import '../../../game/player_role.dart';

/// ランダム割当時の方式（カスタム公開ルールOFFのとき適用）。
enum RoleAssignMode {
  /// 人数バランスを自動調整したおまかせランダム。
  random,

  /// ホストが指定した役職人数で配分（残りは逃走者）。
  counts;

  static RoleAssignMode fromName(String? raw) {
    for (final v in RoleAssignMode.values) {
      if (v.name == raw) return v;
    }
    return RoleAssignMode.random;
  }
}

/// カスタム設定シートの初期値（ルーム共有ルール・役職・スキル等）。
class GameCustomSettingsInitial {
  const GameCustomSettingsInitial({
    required this.oniIntelMode,
    required this.eliminationAftermathRule,
    required this.localRole,
    required this.customRuleMode,
    required this.participantRulesOpen,
    required this.matchDurationMinutes,
    required this.skillLoadout,
    this.gimmickDensity = 1.0,
    this.roleAssignMode = RoleAssignMode.random,
    this.oniCount = 1,
    this.werewolfCount = 1,
    this.accusationWeight = AccusationWeight.instantWin,
  });

  final OniIntelMode oniIntelMode;
  final EliminationAftermathRule eliminationAftermathRule;
  final PlayerRole localRole;
  final bool customRuleMode;
  final bool participantRulesOpen;
  final double matchDurationMinutes;
  final Set<String> skillLoadout;
  /// ギミック配置の個数倍率（ホスト向け、試合開始で固定）。
  final double gimmickDensity;
  /// ランダム割当の方式（ホスト向け）。
  final RoleAssignMode roleAssignMode;
  /// 役職人数指定モードの鬼／人狼の人数。
  final int oniCount;
  final int werewolfCount;
  /// 告発成功・失敗時の重み（ホスト向け、試合開始で固定）。
  final AccusationWeight accusationWeight;
}

/// 「適用」後に画面へ反映する値。
class GameCustomSettingsResult {
  const GameCustomSettingsResult({
    required this.oniIntelMode,
    required this.eliminationAftermathRule,
    required this.localRole,
    required this.customRuleMode,
    required this.participantRulesOpen,
    required this.matchDurationMinutes,
    required this.skillLoadout,
    this.gimmickDensity = 1.0,
    this.roleAssignMode = RoleAssignMode.random,
    this.oniCount = 1,
    this.werewolfCount = 1,
    this.accusationWeight = AccusationWeight.instantWin,
    this.quickPresetApplied,
  });

  final OniIntelMode oniIntelMode;
  final EliminationAftermathRule eliminationAftermathRule;
  final PlayerRole localRole;
  final bool customRuleMode;
  final bool participantRulesOpen;
  final double matchDurationMinutes;
  final Set<String> skillLoadout;
  final double gimmickDensity;
  final RoleAssignMode roleAssignMode;
  final int oniCount;
  final int werewolfCount;
  final AccusationWeight accusationWeight;
  /// 適用時に選ばれた簡易プリセット（エリア半径の再計算用）。
  final MatchQuickPreset? quickPresetApplied;
}
