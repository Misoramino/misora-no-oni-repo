import 'package:flutter_test/flutter_test.dart';
import 'package:oni_game/game/game_config.dart';
import 'package:oni_game/sync/room_member_view.dart';

void main() {
  test('background grace protects stale heartbeat during app switch', () {
    final now = DateTime.utc(2026, 6, 6, 12, 0, 0);
    final member = RoomMemberView(
      uid: 'u1',
      nickname: 'p',
      role: 'runner',
      isSelf: false,
      reportedAtUtc: now.subtract(const Duration(minutes: 5)),
      appLifecycle: 'background',
      backgroundSinceUtc: now.subtract(const Duration(minutes: 3)),
    );

    expect(member.isStale(now), isTrue);
    expect(member.isInBackgroundGrace(now), isTrue);
  });

  test('background grace expires after max duration', () {
    final now = DateTime.utc(2026, 6, 6, 12, 0, 0);
    final member = RoomMemberView(
      uid: 'u1',
      nickname: 'p',
      role: 'runner',
      isSelf: false,
      reportedAtUtc: now.subtract(const Duration(minutes: 20)),
      appLifecycle: 'background',
      backgroundSinceUtc: now.subtract(
        Duration(seconds: GameConfig.matchBackgroundMaxSeconds + 1),
      ),
    );

    expect(member.isInBackgroundGrace(now), isFalse);
  });
}
