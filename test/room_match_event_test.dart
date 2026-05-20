import 'package:flutter_test/flutter_test.dart';
import 'package:oni_game/sync/firestore_room_blueprint.dart';
import 'package:oni_game/sync/room_match_event.dart';

void main() {
  test('RoomMatchEvent.tryParse reads abort_vote payload', () {
    final ev = RoomMatchEvent.tryParse('e1', {
      RoomEventsFields.type: RoomMatchEventTypes.abortVote,
      RoomEventsFields.emittedAtMs: 1_700_000_000_000,
      RoomEventsFields.actorUid: 'uid-a',
      RoomEventsFields.sessionKey: 42,
      RoomEventsFields.payload: {'agree': true},
    });

    expect(ev, isNotNull);
    expect(ev!.id, 'e1');
    expect(ev.type, RoomMatchEventTypes.abortVote);
    expect(ev.emittedAtMs, 1_700_000_000_000);
    expect(ev.actorUid, 'uid-a');
    expect(ev.sessionKey, 42);
    expect(ev.payload['agree'], isTrue);
  });

  test('RoomMatchEvent.tryParse returns null when required fields missing', () {
    expect(
      RoomMatchEvent.tryParse('x', {
        RoomEventsFields.type: RoomMatchEventTypes.abortVote,
        RoomEventsFields.emittedAtMs: 1,
        // actorUid missing
        RoomEventsFields.sessionKey: 1,
      }),
      isNull,
    );
  });

  test('RoomMatchEvent.tryParse coerces non-map payload to empty map', () {
    final ev = RoomMatchEvent.tryParse('e2', {
      RoomEventsFields.type: RoomMatchEventTypes.reveal,
      RoomEventsFields.emittedAtMs: 0,
      RoomEventsFields.actorUid: 'u',
      RoomEventsFields.sessionKey: 0,
      RoomEventsFields.payload: 'not-a-map',
    });
    expect(ev, isNotNull);
    expect(ev!.payload, isEmpty);
  });
}
