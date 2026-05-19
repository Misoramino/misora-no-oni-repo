import 'package:google_maps_flutter/google_maps_flutter.dart';

import 'firestore_room_blueprint.dart';

/// `rooms/{roomId}/events` の 1 件（append-only）。
class RoomMatchEvent {
  const RoomMatchEvent({
    required this.id,
    required this.type,
    required this.emittedAtMs,
    required this.actorUid,
    required this.sessionKey,
    required this.payload,
  });

  final String id;
  final String type;
  final int emittedAtMs;
  final String actorUid;
  final int sessionKey;
  final Map<String, dynamic> payload;

  static RoomMatchEvent? tryParse(String id, Map<String, dynamic> data) {
    final type = data[RoomEventsFields.type] as String?;
    final ms = data[RoomEventsFields.emittedAtMs];
    final actor = data[RoomEventsFields.actorUid] as String?;
    final session = data[RoomEventsFields.sessionKey];
    final rawPayload = data[RoomEventsFields.payload];
    if (type == null || ms is! num || actor == null || session is! num) {
      return null;
    }
    final payload = rawPayload is Map<String, dynamic>
        ? rawPayload
        : rawPayload is Map
        ? Map<String, dynamic>.from(rawPayload)
        : <String, dynamic>{};
    return RoomMatchEvent(
      id: id,
      type: type,
      emittedAtMs: ms.toInt(),
      actorUid: actor,
      sessionKey: session.toInt(),
      payload: payload,
    );
  }

  static LatLng? latLngFromPayload(Map<String, dynamic> p) {
    final lat = p['lat'];
    final lng = p['lng'];
    if (lat is! num || lng is! num) return null;
    return LatLng(lat.toDouble(), lng.toDouble());
  }
}

abstract final class RoomMatchEventTypes {
  static const matchStart = 'match_start';
  static const matchEnd = 'match_end';
  static const reveal = 'reveal';
  static const fakeIntelReveal = 'fake_intel_reveal';
  static const infoBroker = 'info_broker';
  static const matchEvent = 'match_event';
  static const captureZonePlaced = 'capture_zone_placed';
  static const captureZoneAck = 'capture_zone_ack';
  static const captureZoneBound = 'capture_zone_bound';
}
