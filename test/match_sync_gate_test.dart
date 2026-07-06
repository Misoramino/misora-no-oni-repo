import 'package:flutter_test/flutter_test.dart';
import 'package:oni_game/features/game_map/match/match_sync_gate.dart';
import 'package:oni_game/sync/room_match_event.dart';

RoomMatchEvent _ev({required String id, required int sessionKey, int ms = 0}) {
  return RoomMatchEvent(
    id: id,
    type: 'reveal',
    actorUid: 'a',
    sessionKey: sessionKey,
    emittedAtMs: ms,
    payload: const {},
  );
}

void main() {
  group('MatchSyncGate.shouldBufferMatchEvent', () {
    test('buffers when sync not armed and not active', () {
      expect(
        MatchSyncGate.shouldBufferMatchEvent(
          syncArmed: false,
          stillActive: false,
          eventSessionKey: 42,
          boundSessionKey: 42,
        ),
        isTrue,
      );
    });

    test('applies live when sync armed', () {
      expect(
        MatchSyncGate.shouldBufferMatchEvent(
          syncArmed: true,
          stillActive: false,
          eventSessionKey: 42,
          boundSessionKey: 42,
        ),
        isFalse,
      );
    });

    test('applies live when second game still active', () {
      expect(
        MatchSyncGate.shouldBufferMatchEvent(
          syncArmed: false,
          stillActive: true,
          eventSessionKey: 42,
          boundSessionKey: 42,
        ),
        isFalse,
      );
    });

    test('buffers wrong session key', () {
      expect(
        MatchSyncGate.shouldBufferMatchEvent(
          syncArmed: true,
          stillActive: true,
          eventSessionKey: 1,
          boundSessionKey: 2,
        ),
        isTrue,
      );
    });
  });

  group('MatchSyncGate.sortedForReplay', () {
    test('orders by emittedAtMs ascending', () {
      final sorted = MatchSyncGate.sortedForReplay([
        _ev(id: 'c', sessionKey: 1, ms: 300),
        _ev(id: 'a', sessionKey: 1, ms: 100),
        _ev(id: 'b', sessionKey: 1, ms: 200),
      ]);
      expect(sorted.map((e) => e.id).toList(), ['a', 'b', 'c']);
    });
  });
}
