import 'package:flutter_test/flutter_test.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:oni_game/game/play_area.dart';
import 'package:oni_game/sync/firestore_room_blueprint.dart';
import 'package:oni_game/sync/firestore_room_session.dart';
import 'package:oni_game/sync/room_match_event.dart';

void main() {
  test('LobbyPlayAreaSnapshot parses room doc and event payloads', () {
    const area = PlayArea.circle(
      center: LatLng(35.0, 139.0),
      radiusMeters: 120,
    );
    final fromDoc = LobbyPlayAreaSnapshot.tryParseRoomDoc({
      RoomDocFields.lobbyPlayArea: area.toJson(),
      RoomDocFields.lobbyPlayAreaSlotName: '公園A',
    });
    expect(fromDoc, isNotNull);
    expect(fromDoc!.slotName, '公園A');
    expect(fromDoc.area.radiusMeters, 120);

    final ev = RoomMatchEvent(
      id: 'e1',
      type: RoomMatchEventTypes.lobbyPlayArea,
      actorUid: 'host',
      sessionKey: lobbySessionKey,
      emittedAtMs: 1,
      payload: {
        'slotName': '駅前',
        'playArea': area.toJson(),
      },
    );
    final fromEvent = LobbyPlayAreaSnapshot.tryParseEvent(ev);
    expect(fromEvent?.slotName, '駅前');
  });
}
