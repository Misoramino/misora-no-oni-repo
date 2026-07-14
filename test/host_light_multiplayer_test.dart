import 'package:flutter_test/flutter_test.dart';
import 'package:oni_game/sync/host_light_rescue.dart';

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

    test('accusation resolve key includes attempt event id', () {
      expect(
        HostLightRescueKeys.accusationResolve(9, 'evt_1'),
        'accuse_resolve_9_evt_1',
      );
    });

    test('accusation unlock and capture bound keys', () {
      expect(HostLightRescueKeys.accusationUnlock(5), 'unlock_5');
      expect(
        HostLightRescueKeys.captureBound(5, 'p1'),
        'bound_p1_5',
      );
    });
  });
}
