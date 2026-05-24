import 'package:flutter_test/flutter_test.dart';
import 'package:oni_game/game/werewolf_forced_schedule.dart';

void main() {
  test('interval is min of ten minutes and match third', () {
    expect(WerewolfForcedSchedule.intervalSeconds(600), 200);
    expect(WerewolfForcedSchedule.intervalSeconds(180), 60);
    expect(WerewolfForcedSchedule.intervalSeconds(900), 300);
  });

  test('ten minute match fires every 200s', () {
    final t = WerewolfForcedSchedule.thresholdSeconds(600);
    expect(t, [200, 400]);
  });

  test('three minute match fires every 60s', () {
    final t = WerewolfForcedSchedule.thresholdSeconds(180);
    expect(t, [60, 120]);
  });

  test('cooldowns are 0.75 and 0.9 times interval', () {
    for (final d in [180, 600, 900]) {
      final interval = WerewolfForcedSchedule.intervalSeconds(d);
      expect(
        WerewolfForcedSchedule.voluntaryTransformCooldownSeconds(d),
        (interval * 3) ~/ 4,
      );
      expect(
        WerewolfForcedSchedule.forcedTransformCooldownSeconds(d),
        (interval * 9) ~/ 10,
      );
    }
  });

  test('ten minute match cooldowns', () {
    expect(
      WerewolfForcedSchedule.voluntaryTransformCooldownSeconds(600),
      150,
    );
    expect(
      WerewolfForcedSchedule.forcedTransformCooldownSeconds(600),
      180,
    );
  });

  test('voluntary cooldown is shorter than forced cooldown', () {
    for (final d in [180, 600, 900]) {
      final voluntary =
          WerewolfForcedSchedule.voluntaryTransformCooldownSeconds(d);
      final forced = WerewolfForcedSchedule.forcedTransformCooldownSeconds(d);
      expect(voluntary, lessThan(forced));
    }
  });
}
