import 'package:flutter_test/flutter_test.dart';
import 'package:oni_game/game/werewolf_forced_schedule.dart';

void main() {
  test('interval is min of fifteen minutes and match half', () {
    expect(WerewolfForcedSchedule.intervalSeconds(600), 300);
    expect(WerewolfForcedSchedule.intervalSeconds(180), 90);
    expect(WerewolfForcedSchedule.intervalSeconds(900), 450);
  });

  test('voluntary cooldown is one third of interval', () {
    for (final d in [180, 600, 900]) {
      final interval = WerewolfForcedSchedule.intervalSeconds(d);
      expect(
        WerewolfForcedSchedule.voluntaryTransformCooldownSeconds(d),
        interval ~/ 3,
      );
    }
  });

  test('forced toggle fires after interval from last transform', () {
    final t0 = DateTime.utc(2026, 1, 1, 12);
    expect(
      WerewolfForcedSchedule.shouldForceToggle(
        lastTransformAt: t0,
        now: t0.add(const Duration(seconds: 299)),
        matchDurationSeconds: 600,
      ),
      isFalse,
    );
    expect(
      WerewolfForcedSchedule.shouldForceToggle(
        lastTransformAt: t0,
        now: t0.add(const Duration(seconds: 300)),
        matchDurationSeconds: 600,
      ),
      isTrue,
    );
  });

  test('forced toggle uses longer voluntary cooldown than voluntary toggle', () {
    for (final d in [180, 600, 900]) {
      final voluntary =
          WerewolfForcedSchedule.voluntaryTransformCooldownSeconds(d);
      final afterForced =
          WerewolfForcedSchedule.voluntaryTransformCooldownAfterForcedSeconds(d);
      expect(afterForced, greaterThan(voluntary));
      expect(afterForced, voluntary + voluntary ~/ 2);
    }
  });

  test('voluntary cooldown is shorter than forced interval', () {
    for (final d in [180, 600, 900]) {
      final voluntary =
          WerewolfForcedSchedule.voluntaryTransformCooldownSeconds(d);
      final interval = WerewolfForcedSchedule.intervalSeconds(d);
      expect(voluntary, lessThan(interval));
    }
  });
}
