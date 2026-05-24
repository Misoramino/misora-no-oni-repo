import 'game_config.dart';

/// 残響体 — 告発施設での陣取り（有効施設 +1）。
abstract final class SpectralTerritoryLogic {
  static bool canStartCharge({
    required bool isEliminated,
    required bool isSpectralOperative,
    required bool accusationUnlocked,
    required int matchUses,
    required DateTime? lastPersonalAt,
    required DateTime now,
    required bool alreadyCharging,
  }) {
    if (!isEliminated || !isSpectralOperative || !accusationUnlocked) {
      return false;
    }
    if (alreadyCharging) return false;
    if (matchUses >= GameConfig.spectralTerritoryMatchLimit) return false;
    if (lastPersonalAt != null) {
      final since = now.difference(lastPersonalAt).inSeconds;
      if (since < GameConfig.spectralTerritoryPersonalCooldownSeconds) {
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
    return (sec / GameConfig.spectralTerritoryChargeSeconds).clamp(0.0, 1.0);
  }

  static bool isChargeComplete({
    required DateTime chargeStartedAt,
    required DateTime now,
  }) =>
      now.difference(chargeStartedAt).inSeconds >=
      GameConfig.spectralTerritoryChargeSeconds;
}
