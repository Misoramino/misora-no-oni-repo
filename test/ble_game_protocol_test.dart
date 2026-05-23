import 'package:flutter_test/flutter_test.dart';
import 'package:oni_game/proximity/ble_game_protocol.dart';

void main() {
  test('encode and match room session payload', () {
    const roomId = 'room-abc';
    const sessionKey = 12345678;
    final oniBytes = BleGameProtocol.encodePayload(
      roomId: roomId,
      sessionKey: sessionKey,
      advertiseAsOni: true,
    );
    final runnerBytes = BleGameProtocol.encodePayload(
      roomId: roomId,
      sessionKey: sessionKey,
      advertiseAsOni: false,
    );
    expect(oniBytes.length, 12);
    expect(
      BleGameProtocol.matchesPayload(
        oniBytes,
        roomId: roomId,
        sessionKey: sessionKey,
        requireOniBeacon: true,
      ),
      isTrue,
    );
    expect(
      BleGameProtocol.matchesPayload(
        runnerBytes,
        roomId: roomId,
        sessionKey: sessionKey,
        requireOniBeacon: true,
      ),
      isFalse,
    );
    expect(
      BleGameProtocol.matchesPayload(
        runnerBytes,
        roomId: roomId,
        sessionKey: sessionKey,
        requireOniBeacon: false,
      ),
      isTrue,
    );
  });
}
