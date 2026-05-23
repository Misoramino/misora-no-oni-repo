import 'game_config.dart';

/// カメラジャック（残響体）のチャージ・CD判定。
abstract final class CameraJackLogic {
  static bool canStartCharge({
    required bool isEliminated,
    required bool isSpectralOperative,
    required int matchUses,
    required DateTime? lastPersonalJackAt,
    required DateTime now,
    required bool alreadyCharging,
  }) {
    if (!isEliminated || !isSpectralOperative) return false;
    if (alreadyCharging) return false;
    if (matchUses >= GameConfig.cameraJackMatchLimit) return false;
    if (lastPersonalJackAt != null) {
      final since = now.difference(lastPersonalJackAt).inSeconds;
      if (since < GameConfig.cameraJackPersonalCooldownSeconds) return false;
    }
    return true;
  }

  static double chargeProgress({
    required DateTime chargeStartedAt,
    required DateTime now,
  }) {
    final sec = now.difference(chargeStartedAt).inSeconds;
    return (sec / GameConfig.cameraJackChargeSeconds).clamp(0.0, 1.0);
  }

  static bool isChargeComplete({
    required DateTime chargeStartedAt,
    required DateTime now,
  }) =>
      now.difference(chargeStartedAt).inSeconds >=
      GameConfig.cameraJackChargeSeconds;
}
