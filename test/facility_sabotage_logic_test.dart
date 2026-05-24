import 'package:flutter_test/flutter_test.dart';
import 'package:oni_game/game/facility_sabotage_logic.dart';
import 'package:oni_game/game/game_config.dart';

void main() {
  final t0 = DateTime.utc(2026, 1, 1, 12);

  test('canStartCharge respects match limit and cooldown', () {
    expect(
      FacilitySabotageLogic.canStartCharge(
        isEliminated: true,
        isRevenantOni: true,
        matchUses: GameConfig.facilitySabotageMatchLimit,
        lastPersonalAt: null,
        now: t0,
        alreadyCharging: false,
      ),
      isFalse,
    );
    expect(
      FacilitySabotageLogic.canStartCharge(
        isEliminated: true,
        isRevenantOni: true,
        matchUses: 0,
        lastPersonalAt: t0.subtract(
          Duration(seconds: GameConfig.facilitySabotagePersonalCooldownSeconds - 1),
        ),
        now: t0,
        alreadyCharging: false,
      ),
      isFalse,
    );
    expect(
      FacilitySabotageLogic.canStartCharge(
        isEliminated: true,
        isRevenantOni: true,
        matchUses: 0,
        lastPersonalAt: null,
        now: t0,
        alreadyCharging: false,
      ),
      isTrue,
    );
  });

  test('charge completes after configured seconds', () {
    final start = t0;
    expect(
      FacilitySabotageLogic.isChargeComplete(
        chargeStartedAt: start,
        now: start.add(
          Duration(seconds: GameConfig.facilitySabotageChargeSeconds - 1),
        ),
      ),
      isFalse,
    );
    expect(
      FacilitySabotageLogic.isChargeComplete(
        chargeStartedAt: start,
        now: start.add(
          Duration(seconds: GameConfig.facilitySabotageChargeSeconds),
        ),
      ),
      isTrue,
    );
  });
}
