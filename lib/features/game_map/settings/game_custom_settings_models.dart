import '../../../game/elimination_aftermath_rule.dart';
import '../../../game/oni_intel_mode.dart';
import '../../../game/player_role.dart';

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
  });

  final OniIntelMode oniIntelMode;
  final EliminationAftermathRule eliminationAftermathRule;
  final PlayerRole localRole;
  final bool customRuleMode;
  final bool participantRulesOpen;
  final double matchDurationMinutes;
  final Set<String> skillLoadout;
  final double gimmickDensity;
}
