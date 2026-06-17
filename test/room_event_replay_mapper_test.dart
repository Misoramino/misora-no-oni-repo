import 'package:flutter_test/flutter_test.dart';
import 'package:oni_game/services/room_event_replay_mapper.dart';
import 'package:oni_game/sync/room_match_event.dart';

void main() {
  test('maps capture zone placed to replay event', () {
    final ev = RoomMatchEvent(
      id: 'e1',
      type: RoomMatchEventTypes.captureZonePlaced,
      emittedAtMs: DateTime.utc(2026, 1, 1, 12, 5).millisecondsSinceEpoch,
      actorUid: 'u1',
      sessionKey: 42,
      payload: {
        'lat': 35.0,
        'lng': 139.0,
        'message': '捕獲結界を設置',
      },
    );
    final mapped = RoomEventReplayMapper.toMatchEvent(ev);
    expect(mapped, isNotNull);
    expect(mapped!.type, RoomMatchEventTypes.captureZonePlaced);
    expect(mapped.message, '捕獲結界を設置');
  });
}
