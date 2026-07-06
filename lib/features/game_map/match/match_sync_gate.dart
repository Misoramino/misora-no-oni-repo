import '../../../sync/room_match_event.dart';

/// オンライン試合イベントの受信ゲート（演出・ロビー待機と同期を分離）。
abstract final class MatchSyncGate {
  /// 試合 session のイベントをバッファすべきか。
  ///
  /// [syncArmed] … `matchStart` 適用済みで同期ライブ
  /// [stillActive] … 脱落後の第二ゲームなど試合継続中
  static bool shouldBufferMatchEvent({
    required bool syncArmed,
    required bool stillActive,
    required int eventSessionKey,
    required int? boundSessionKey,
  }) {
    if (boundSessionKey == null) return true;
    if (eventSessionKey != boundSessionKey) return true;
    if (syncArmed || stillActive) return false;
    return true;
  }

  static List<RoomMatchEvent> sortedForReplay(Iterable<RoomMatchEvent> events) {
    final list = events.toList()
      ..sort((a, b) => a.emittedAtMs.compareTo(b.emittedAtMs));
    return list;
  }
}
