import '../../../game/elimination_aftermath_rule.dart';
import '../../../game/oni_intel_mode.dart';
import '../../../game/player_role.dart';
import '../../../theme/world_profile.dart';

/// カスタム設定シートの初期値。
class GameCustomSettingsInitial {
  const GameCustomSettingsInitial({
    required this.profile,
    required this.oniIntelMode,
    required this.trajectoryConsent,
    required this.eliminationAftermathRule,
    required this.localRole,
    required this.customRuleMode,
    required this.participantRulesOpen,
    required this.matchDurationMinutes,
    required this.skillLoadout,
    required this.useBleScan,
  });

  final WorldProfile profile;
  final OniIntelMode oniIntelMode;
  final bool trajectoryConsent;
  final EliminationAftermathRule eliminationAftermathRule;
  final PlayerRole localRole;
  final bool customRuleMode;
  final bool participantRulesOpen;
  final double matchDurationMinutes;
  final Set<String> skillLoadout;
  final bool useBleScan;
}

/// 「適用」後に画面へ反映する値。
class GameCustomSettingsResult {
  const GameCustomSettingsResult({
    required this.profile,
    required this.oniIntelMode,
    required this.trajectoryConsent,
    required this.eliminationAftermathRule,
    required this.localRole,
    required this.customRuleMode,
    required this.participantRulesOpen,
    required this.matchDurationMinutes,
    required this.skillLoadout,
    required this.useBleScan,
  });

  final WorldProfile profile;
  final OniIntelMode oniIntelMode;
  final bool trajectoryConsent;
  final EliminationAftermathRule eliminationAftermathRule;
  final PlayerRole localRole;
  final bool customRuleMode;
  final bool participantRulesOpen;
  final double matchDurationMinutes;
  final Set<String> skillLoadout;
  final bool useBleScan;
}
