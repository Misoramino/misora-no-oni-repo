import '../../../services/match_recorder.dart';
import 'map_marker_kind.dart';

/// 軌跡再生用: トラック ID / イベント type → マーカー種別。
abstract final class MapReplayMarkerHelper {
  static MapMarkerKind forTrackId(String id) {
    if (id == MatchTrackIds.runnerLocal) return MapMarkerKind.player;
    if (id == MatchTrackIds.oniLocal) return MapMarkerKind.oni;
    if (id.contains('oni')) return MapMarkerKind.remoteOni;
    return MapMarkerKind.remoteRunner;
  }

  static MapMarkerKind forEventType(String type) {
    if (type.contains('reveal') ||
        type == 'area_reveal' ||
        type == 'infection_reveal' ||
        type == 'accidental_reveal') {
      return MapMarkerKind.reveal;
    }
    return switch (type) {
      'info_broker' => MapMarkerKind.infoBroker,
      'safe_charge' => MapMarkerKind.safeZone,
      'trace_drop' => MapMarkerKind.trace,
      'fake_start' || 'fake_intel_reveal' => MapMarkerKind.fakePosition,
      'body_throw_start' => MapMarkerKind.bodyThrow,
      'capture_zone_start' ||
      'capture_zone_placed' ||
      'capture_zone_bound' =>
        MapMarkerKind.safeZone,
      'accusation_unlocked' => MapMarkerKind.infoBroker,
      'accusation_attempt' => MapMarkerKind.reveal,
      'accusation_success' => MapMarkerKind.reveal,
      'accusation_failed' => MapMarkerKind.trace,
      'accusation_point_scored' => MapMarkerKind.safeZone,
      'player_eliminated' => MapMarkerKind.oni,
      'werewolf_transform_start' => MapMarkerKind.oni,
      _ => MapMarkerKind.trace,
    };
  }

  static bool isRevealFlashType(String type) =>
      type.contains('reveal') ||
      type == 'area_reveal' ||
      type == 'infection_reveal' ||
      type == 'accidental_reveal' ||
      type == 'fake_intel_reveal';
}
