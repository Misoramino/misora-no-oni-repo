import '../../../game/game_config.dart';
import '../../../game/game_state.dart';

/// 1 ティックあたりの勝敗・エリア外判定結果。
enum MatchTickAction {
  none,
  endRunnerWin,
  endCaughtByOni,
  consumeSafeChargeAvoidReveal,
  triggerLocationReveal,
  resetOutsideTracking,
}

/// エリア外が続いた秒数など、ティック判定への入力。
class OutsideAreaTickInput {
  const OutsideAreaTickInput({
    required this.overflowMeters,
    required this.outsideSeconds,
    required this.revealedInCurrentOutside,
    required this.safeZoneCharges,
  });

  final double overflowMeters;
  final int outsideSeconds;
  final bool revealedInCurrentOutside;
  final int safeZoneCharges;
}

/// 試合中ティックの純粋判定（副作用なし）。
abstract final class MatchTickEvaluator {
  /// 捕獲・時間切れなど、即終了すべき結果。なければ null。
  static MatchTickAction? evaluateTerminal({
    required int remainingSeconds,
    required bool captureTriggered,
  }) {
    if (captureTriggered) return MatchTickAction.endCaughtByOni;
    if (remainingSeconds <= 0) return MatchTickAction.endRunnerWin;
    return null;
  }

  /// エリア外タイマー・安全地帯チャージ・暴露。
  static MatchTickAction? evaluateOutsideArea(OutsideAreaTickInput input) {
    final isOut = input.overflowMeters > GameConfig.outsideAreaGraceMeters;
    if (!isOut) return MatchTickAction.resetOutsideTracking;
    if (input.revealedInCurrentOutside) return null;
    if (input.outsideSeconds < GameConfig.outsideAreaGraceSeconds) {
      return null;
    }
    if (input.safeZoneCharges > 0) {
      return MatchTickAction.consumeSafeChargeAvoidReveal;
    }
    return MatchTickAction.triggerLocationReveal;
  }

  static String endMessageFor(MatchTickAction action) => switch (action) {
        MatchTickAction.endRunnerWin => '逃走成功。時間切れです。',
        MatchTickAction.endCaughtByOni => 'BLE接近で接触判定。鬼に捕まりました。',
        _ => '',
      };

  static GameState endStateFor(MatchTickAction action) => switch (action) {
        MatchTickAction.endRunnerWin => GameState.runnerWin,
        MatchTickAction.endCaughtByOni => GameState.caughtByOni,
        _ => GameState.waiting,
      };
}
