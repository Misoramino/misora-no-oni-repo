import 'package:flutter_test/flutter_test.dart';
import 'package:oni_game/game/werewolf_forced_schedule.dart';

void main() {
  test('interval is min of ten minutes and match third', () {
    expect(WerewolfForcedSchedule.intervalSeconds(600), 200);
    expect(WerewolfForcedSchedule.intervalSeconds(180), 60);
    expect(WerewolfForcedSchedule.intervalSeconds(900), 300);
  });

  test('voluntary cooldown is 0.75 times interval', () {
    for (final d in [180, 600, 900]) {
      final interval = WerewolfForcedSchedule.intervalSeconds(d);
      expect(
        WerewolfForcedSchedule.voluntaryTransformCooldownSeconds(d),
        (interval * 3) ~/ 4,
      );
    }
  });

  test('forced toggle fires after interval from last transform', () {
    final t0 = DateTime.utc(2026, 1, 1, 12);
    expect(
      WerewolfForcedSchedule.shouldForceToggle(
        lastTransformAt: t0,
        now: t0.add(const Duration(seconds: 199)),
        matchDurationSeconds: 600,
      ),
      isFalse,
    );
    expect(
      WerewolfForcedSchedule.shouldForceToggle(
        lastTransformAt: t0,
        now: t0.add(const Duration(seconds: 200)),
        matchDurationSeconds: 600,
      ),
      isTrue,
    );
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
