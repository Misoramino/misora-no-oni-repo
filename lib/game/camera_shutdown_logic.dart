import 'game_config.dart';

/// 復讐の鬼影 — 監視カメラのシャットダウン（台数を減らす・回数制限なし・各カメラ1回）。
abstract final class CameraShutdownLogic {
  static bool canStartShutdown({
    required bool isEliminated,
    required bool isRevenantOni,
    required int cameraIndex,
    required Set<int> disabledCameraIndices,
    required DateTime? lastPersonalAt,
    required DateTime now,
    required bool alreadyCharging,
  }) {
    if (!isEliminated || !isRevenantOni) return false;
    if (alreadyCharging) return false;
    if (disabledCameraIndices.contains(cameraIndex)) return false;
    if (lastPersonalAt != null) {
      final since = now.difference(lastPersonalAt).inSeconds;
      if (since < GameConfig.cameraShutdownPersonalCooldownSeconds) {
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
    return (sec / GameConfig.cameraShutdownChargeSeconds).clamp(0.0, 1.0);
  }

  static bool isChargeComplete({
    required DateTime chargeStartedAt,
    required DateTime now,
  }) =>
      now.difference(chargeStartedAt).inSeconds >=
      GameConfig.cameraShutdownChargeSeconds;
}
