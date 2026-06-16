import 'package:flutter_test/flutter_test.dart';
import 'package:oni_game/game/game_config.dart';

void main() {
  test('disconnect elimination is ~2 minutes not ~4', () {
    final totalSeconds = GameConfig.memberPresenceStaleSeconds +
        GameConfig.disconnectEliminationGraceSeconds;
    expect(totalSeconds, lessThan(150));
    expect(totalSeconds, greaterThanOrEqualTo(120));
  });
}
