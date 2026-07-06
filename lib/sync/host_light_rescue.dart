/// ホストが background / stale のとき非ホストが担う救済イベントの型と冪等キー。
abstract final class HostLightRescueEventTypes {
  static const accusationUnlockedRescue = 'accusation_unlocked_rescue';
  static const captureZoneBoundRescue = 'capture_zone_bound_rescue';
  static const playerEliminatedRescue = 'player_eliminated_rescue';
  static const oniCaptureElimination = 'oni_capture_elimination';
}

abstract final class HostLightRescueKeys {
  static String timeUp(int sessionKey) => 'time_up_$sessionKey';

  static String factionEnd(int sessionKey, String endReason) =>
      'faction_${endReason}_$sessionKey';

  static String accusationUnlock(int sessionKey) => 'unlock_$sessionKey';

  static String captureBound(int sessionKey, String placeId) =>
      'bound_${placeId}_$sessionKey';

  static String disconnectElimination(int sessionKey, String uid) =>
      'disconnect_${sessionKey}_$uid';

  static String oniCapture(int sessionKey, String targetUid) =>
      'oni_capture_${sessionKey}_$targetUid';

  static String abortMajority(int sessionKey) => 'abort_majority_$sessionKey';
}

/// 救済イベント payload に含める冪等キー名。
const kHostLightIdempotencyPayloadKey = 'idempotencyKey';
