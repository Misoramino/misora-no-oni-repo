import '../../../game/game_config.dart';
import '../../../game/game_state.dart';
import '../../../game/match_hud_copy.dart';

/// 1 ティックあたりの勝敗・エリア外判定結果。
enum MatchTickAction {
  none,
  endRunnerWin,
  endCaughtByOni,
  consumeSafeChargeAvoidReveal,
  triggerLocationReveal,
  triggerOutsidePeriodicReveal,
  outsideElimination,
  resetOutsideTracking,
}

/// エリア外が続いた秒数など、ティック判定への入力。
class OutsideAreaTickInput {
  const OutsideAreaTickInput({
    required this.overflowMeters,
    required this.outsideSeconds,
    required this.revealedInCurrentOutside,
    required this.safeZoneCharges,
    required this.secondsSinceLastOutsideReveal,
  });

  final double overflowMeters;
  final int outsideSeconds;
  final bool revealedInCurrentOutside;
  final int safeZoneCharges;
  final int secondsSinceLastOutsideReveal;
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
    if (input.outsideSeconds >= GameConfig.outsideAreaEliminationSeconds) {
      return MatchTickAction.outsideElimination;
    }
    if (input.outsideSeconds < GameConfig.outsideAreaGraceSeconds) {
      return null;
    }
    if (!input.revealedInCurrentOutside) {
      if (input.safeZoneCharges > 0) {
        return MatchTickAction.consumeSafeChargeAvoidReveal;
      }
      return MatchTickAction.triggerLocationReveal;
    }
    if (input.secondsSinceLastOutsideReveal >=
        GameConfig.outsideAreaRepeatRevealSeconds) {
      return MatchTickAction.triggerOutsidePeriodicReveal;
    }
    return null;
  }

  /// [_applyMatchTickEffects] がエリア外脱落と判定するための目印。
  static const outsideEliminationMarker = 'プレイエリア外に長時間';

  static String endMessageFor(MatchTickAction action) => switch (action) {
        MatchTickAction.endRunnerWin => MatchHudCopy.matchEndTimeUp(),
        MatchTickAction.endCaughtByOni => MatchHudCopy.captureSucceeded,
        MatchTickAction.outsideElimination =>
          '$outsideEliminationMarker — ${MatchHudCopy.outsideEliminationSuffix}',
        _ => '',
      };

  static GameState endStateFor(MatchTickAction action) => switch (action) {
        MatchTickAction.endRunnerWin => GameState.runnerWin,
        MatchTickAction.endCaughtByOni => GameState.caughtByOni,
        _ => GameState.waiting,
      };
}
