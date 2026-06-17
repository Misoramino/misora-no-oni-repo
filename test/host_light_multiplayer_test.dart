import 'package:oni_game/sync/host_light_rescue.dart';
import 'package:oni_game/sync/host_presence_status.dart';
import 'package:oni_game/sync/room_member_view.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('HostLightRescueKeys', () {
    test('time up key is stable per session', () {
      expect(HostLightRescueKeys.timeUp(42), 'time_up_42');
    });

    test('oni capture key includes target uid', () {
      expect(
        HostLightRescueKeys.oniCapture(7, 'uid_a'),
        'oni_capture_7_uid_a',
      );
    });

    test('disconnect key is per uid', () {
      expect(
        HostLightRescueKeys.disconnectElimination(3, 'p1'),
        'disconnect_3_p1',
      );
    });
  });

  group('HostPresenceStatus unavailableForMatchEnd', () {
    test('background host is unavailable', () {
      final host = RoomMemberView(
        uid: 'h',
        nickname: 'host',
        role: 'runner',
        isSelf: false,
        isHost: true,
        reportedAtUtc: DateTime.utc(2026, 1, 1, 12, 0),
        appLifecycle: 'background',
        backgroundSinceUtc: DateTime.utc(2026, 1, 1, 12, 0),
      );
      expect(
        HostPresenceStatus.unavailableForMatchEnd(
          host,
          DateTime.utc(2026, 1, 1, 12, 1),
        ),
        isTrue,
      );
    });

    test('foreground fresh host is available', () {
      final host = RoomMemberView(
        uid: 'h',
        nickname: 'host',
        role: 'runner',
        isSelf: false,
        isHost: true,
        reportedAtUtc: DateTime.utc(2026, 1, 1, 12, 0),
        appLifecycle: 'foreground',
      );
      expect(
        HostPresenceStatus.unavailableForMatchEnd(
          host,
          DateTime.utc(2026, 1, 1, 12, 0, 5),
        ),
        isFalse,
      );
    });
  });
}
