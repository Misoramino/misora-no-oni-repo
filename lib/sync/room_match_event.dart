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

/// Firestore `capture_zone_*` イベント payload の解釈。
abstract final class CaptureZoneEventPayload {
  /// スキル「捕獲結界」由来か（接触拘束のタッチロックでは false）。
  ///
  /// 旧クライアントは `fromSkill` 未送信。`capture_zone_placed` はスキル専用のため true 扱い。
  static bool fromSkill(Map<String, dynamic> payload) {
    final raw = payload['fromSkill'] ?? payload['placedBySkill'];
    if (raw is bool) return raw;
    return true;
  }

  /// 設置者が捕獲（殺害）可能な結界か。鬼陣営人狼の結界は false。
  static bool capturePermitted(Map<String, dynamic> payload) {
    final raw = payload['capturePermitted'];
    if (raw is bool) return raw;
    return true;
  }
}

abstract final class RoomMatchEventTypes {
  static const matchStart = 'match_start';
  static const matchEnd = 'match_end';

  /// 時間切れ救済（非ホストが host 不通時に一度だけ発行）。
  static const matchEndRescue = 'match_end_rescue';
  static const reveal = 'reveal';
  static const anonymousReveal = 'anonymous_reveal';
  static const fakeIntelReveal = 'fake_intel_reveal';
  static const infoBroker = 'info_broker';
  static const oniInfoBroker = 'oni_info_broker';
  static const safeZonePickup = 'safe_zone_pickup';
  static const matchEvent = 'match_event';
  static const captureZonePlaced = 'capture_zone_placed';
  static const captureZoneAck = 'capture_zone_ack';
  static const captureZoneBound = 'capture_zone_bound';

  /// 試合中止の賛否（payload: `{ agree: bool }`）。
  static const abortVote = 'abort_vote';

  /// 試合中止投票の開始（payload: `{ expiresAtMs: int }`）。
  static const abortProposal = 'abort_proposal';

  /// 過半数で試合中止が確定（payload: `{ message: string }`）。
  static const abortMajority = 'abort_majority';
  static const playerEliminated = 'player_eliminated';
  static const accusationUnlocked = 'accusation_unlocked';
  static const accusationAttempt = 'accusation_attempt';
  static const accusationFailed = 'accusation_failed';
  static const accusationPointScored = 'accusation_point_scored';
  static const cameraJack = 'camera_jack';
  static const facilitySabotage = 'facility_sabotage';
  static const spectralTerritory = 'spectral_territory';
  static const cameraShutdown = 'camera_shutdown';

  /// ロビー中のプレイエリア共有（sessionKey = [FirestoreRoomSession.lobbySessionKey]）。
  static const lobbyPlayArea = 'lobby_play_area';

  /// 非ホスト→ホストへのエリア提案（sessionKey = lobbySessionKey）。
  static const lobbyPlayAreaProposal = 'lobby_play_area_proposal';
}
