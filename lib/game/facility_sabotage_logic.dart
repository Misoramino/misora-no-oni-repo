import 'game_config.dart';

/// 復讐の鬼影 — 告発施設への妨害チャージ。
abstract final class FacilitySabotageLogic {
  static bool canStartCharge({
    required bool isEliminated,
    required bool isRevenantOni,
    required int matchUses,
    required DateTime? lastPersonalAt,
    required DateTime now,
    required bool alreadyCharging,
  }) {
    if (!isEliminated || !isRevenantOni) return false;
    if (alreadyCharging) return false;
    if (matchUses >= GameConfig.facilitySabotageMatchLimit) return false;
    if (lastPersonalAt != null) {
      final since = now.difference(lastPersonalAt).inSeconds;
      if (since < GameConfig.facilitySabotagePersonalCooldownSeconds) {
        return false;
      }
    }
    return true;
  }

  static double chargeProgress({
    required DateTime chargeStartedAt,
    required DateTime now,
  }) {
    final sec = now.difference(chargeStartedAt).inSeconds;
    return (sec / GameConfig.facilitySabotageChargeSeconds).clamp(0.0, 1.0);
  }

  static bool isChargeComplete({
    required DateTime chargeStartedAt,
    required DateTime now,
  }) =>
      now.difference(chargeStartedAt).inSeconds >=
      GameConfig.facilitySabotageChargeSeconds;
}
