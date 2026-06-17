import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../game/location_reveal_event.dart';
import '../game/match_event.dart';
import '../sync/room_match_event.dart';

/// Firestore `rooms/.../events` を試合リプレイ用のローカルイベントへ変換。
abstract final class RoomEventReplayMapper {
  static MatchEvent? toMatchEvent(RoomMatchEvent ev) {
    final pos = RoomMatchEvent.latLngFromPayload(ev.payload);
    final atUtc =
        DateTime.fromMillisecondsSinceEpoch(ev.emittedAtMs, isUtc: true);
    final message = _messageFor(ev);
    if (message == null) return null;

    return MatchEvent(
      type: _replayType(ev),
      atUtc: atUtc,
      message: message,
      position: pos ?? const LatLng(0, 0),
    );
  }

  static LocationRevealEvent? toReveal(RoomMatchEvent ev) {
    final pos = RoomMatchEvent.latLngFromPayload(ev.payload);
    if (pos == null) return null;
    final atUtc =
        DateTime.fromMillisecondsSinceEpoch(ev.emittedAtMs, isUtc: true);
    return switch (ev.type) {
      RoomMatchEventTypes.reveal ||
      RoomMatchEventTypes.anonymousReveal ||
      RoomMatchEventTypes.fakeIntelReveal =>
        LocationRevealEvent(
          sequence: ev.emittedAtMs,
          timestamp: atUtc,
          position: pos,
          overflowMeters: (ev.payload['overflowMeters'] as num?)?.toDouble() ?? 0,
          playerLabel: (ev.payload['nickname'] as String?)?.trim() ?? 'player',
          reasonSummary: (ev.payload['reason'] as String?) ??
              (ev.payload['reasonSummary'] as String?) ??
              _messageFor(ev),
          subjectUid: ev.payload['subjectUid'] as String? ?? ev.actorUid,
        ),
      _ => null,
    };
  }

  static String _replayType(RoomMatchEvent ev) {
    if (ev.type == RoomMatchEventTypes.matchEvent) {
      return ev.payload['innerType'] as String? ?? 'match_event';
    }
    return ev.type;
  }

  static String? _messageFor(RoomMatchEvent ev) {
    final payloadMsg = ev.payload['message'] as String?;
    if (payloadMsg != null && payloadMsg.trim().isNotEmpty) {
      return payloadMsg.trim();
    }
    return switch (ev.type) {
      RoomMatchEventTypes.reveal => '位置暴露',
      RoomMatchEventTypes.anonymousReveal => '匿名暴露',
      RoomMatchEventTypes.fakeIntelReveal => '偽情報暴露',
      RoomMatchEventTypes.infoBroker => '情報屋',
      RoomMatchEventTypes.oniInfoBroker => '鬼の情報屋',
      RoomMatchEventTypes.safeZonePickup => 'セーフゾーン取得',
      RoomMatchEventTypes.captureZonePlaced =>
        _captureZonePlacedMessage(ev),
      RoomMatchEventTypes.captureZoneAck => _captureZoneAckMessage(ev),
      RoomMatchEventTypes.captureZoneBound => '捕獲結界発動',
      RoomMatchEventTypes.playerEliminated => '脱落',
      RoomMatchEventTypes.accusationUnlocked => '告発解放',
      RoomMatchEventTypes.accusationAttempt => '告発',
      RoomMatchEventTypes.accusationFailed => '告発失敗',
      RoomMatchEventTypes.accusationPointScored => '告発ポイント',
      RoomMatchEventTypes.cameraJack => '監視ジャック',
      RoomMatchEventTypes.facilitySabotage => '施設妨害',
      RoomMatchEventTypes.spectralTerritory => '残響領域',
      RoomMatchEventTypes.cameraShutdown => 'カメラ停止',
      RoomMatchEventTypes.abortMajority => '試合中止（多数決）',
      RoomMatchEventTypes.matchEndRescue => '時間切れ救済',
      RoomMatchEventTypes.matchEvent =>
        ev.payload['innerType'] as String? ?? 'match_event',
      RoomMatchEventTypes.matchStart ||
      RoomMatchEventTypes.matchEnd ||
      RoomMatchEventTypes.abortVote ||
      RoomMatchEventTypes.abortProposal ||
      RoomMatchEventTypes.lobbyPlayArea ||
      RoomMatchEventTypes.lobbyPlayAreaProposal =>
        null,
      _ => null,
    };
  }

  static String _captureZoneAckMessage(RoomMatchEvent ev) {
    final placeId = ev.payload['placeId'] as String? ?? '';
    if (placeId.isEmpty) return '捕獲圏確認';
    return '捕獲圏確認 place:$placeId';
  }

  static String _captureZonePlacedMessage(RoomMatchEvent ev) {
    final placeId = ev.payload['placeId'] as String? ?? '';
    if (placeId.isEmpty) return '捕獲結界設置';
    return '捕獲結界設置 place:$placeId';
  }
}
