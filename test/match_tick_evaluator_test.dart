import 'package:flutter_test/flutter_test.dart';
import 'package:oni_game/features/game_map/match/match_tick_evaluator.dart';
import 'package:oni_game/game/game_config.dart';
import 'package:oni_game/game/game_state.dart';

void main() {
  test('terminal: capture ends match', () {
    expect(
      MatchTickEvaluator.evaluateTerminal(
        remainingSeconds: 60,
        captureTriggered: true,
      ),
      MatchTickAction.endCaughtByOni,
    );
  });

  test('terminal: time up is runner win', () {
    expect(
      MatchTickEvaluator.evaluateTerminal(
        remainingSeconds: 0,
        captureTriggered: false,
      ),
      MatchTickAction.endRunnerWin,
    );
    expect(
      MatchTickEvaluator.endStateFor(MatchTickAction.endRunnerWin),
      GameState.runnerWin,
    );
  });

  test('outside: safe charge consumed before reveal', () {
    final action = MatchTickEvaluator.evaluateOutsideArea(
      OutsideAreaTickInput(
        overflowMeters: GameConfig.outsideAreaGraceMeters + 1,
        outsideSeconds: GameConfig.outsideAreaGraceSeconds,
        revealedInCurrentOutside: false,
        safeZoneCharges: 1,
      ),
    );
    expect(action, MatchTickAction.consumeSafeChargeAvoidReveal);
  });

  test('outside: in area resets tracking', () {
    expect(
      MatchTickEvaluator.evaluateOutsideArea(
        const OutsideAreaTickInput(
          overflowMeters: 0,
          outsideSeconds: 99,
          revealedInCurrentOutside: true,
          safeZoneCharges: 0,
        ),
      ),
      MatchTickAction.resetOutsideTracking,
    );
  });
}
