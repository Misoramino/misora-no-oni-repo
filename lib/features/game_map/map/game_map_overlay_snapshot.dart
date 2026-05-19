import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../../game/elimination_aftermath_rule.dart';
import '../../../game/location_reveal_event.dart';
import '../../../game/oni_intel_trace.dart';
import '../../../game/play_area.dart';
import '../../../sync/remote_member_snapshot.dart';
import '../../../theme/world_profile_tokens.dart';
import '../../../theme/world_visual_pack.dart';
import 'game_map_layer_toggles.dart';
import 'map_marker_icon_registry.dart';

/// [GameMapOverlayBuilder] 用の地図描画スナップショット（1 フレーム分）。
class GameMapOverlaySnapshot {
  const GameMapOverlaySnapshot({
    required this.now,
    required this.playerMarkerPosition,
    required this.oniPosition,
    required this.showOniMarker,
    required this.remoteOniKnown,
    required this.remoteMembers,
    required this.showGimmickMarkers,
    required this.safeZonePositions,
    required this.infoBrokerPositions,
    required this.commJammingZonePositions,
    required this.cameraPositions,
    required this.tracePoints,
    required this.revealTraces,
    required this.oniIntelTraces,
    required this.safeZoneAvailable,
    required this.infoBrokerAvailable,
    required this.safeZoneRespawnAt,
    required this.infoBrokerRespawnAt,
    required this.triggeredCameras,
    required this.fakePositionActive,
    required this.fakePositionLatLng,
    required this.bodyThrowPosition,
    required this.afterCatchRule,
    required this.ghostRoughPositions,
    required this.editingArea,
    required this.editCircleMode,
    required this.polygonDraft,
    required this.polygonDraftClosed,
    required this.circleDraftCenter,
    required this.circleDraftRadiusMeters,
    required this.playArea,
    required this.captureZoneCenter,
    required this.tokens,
    this.layerToggles = GameMapLayerToggles.allOn,
    this.visualPack,
    this.markerRegistry,
    this.mapZoom = 16,
    this.playerMarkerIcon,
    this.usePhotoPlayerPin = false,
    this.cameraPulsePhase = 0,
  });

  final DateTime now;
  final LatLng playerMarkerPosition;
  final LatLng oniPosition;
  final bool showOniMarker;
  final bool remoteOniKnown;
  final Map<String, RemoteMemberSnapshot> remoteMembers;
  final bool showGimmickMarkers;
  final List<LatLng> safeZonePositions;
  final List<LatLng> infoBrokerPositions;
  final List<LatLng> commJammingZonePositions;
  final List<LatLng> cameraPositions;
  final List<LatLng> tracePoints;
  final List<LocationRevealEvent> revealTraces;
  final List<OniIntelTrace> oniIntelTraces;
  final bool safeZoneAvailable;
  final bool infoBrokerAvailable;
  final DateTime? safeZoneRespawnAt;
  final DateTime? infoBrokerRespawnAt;
  final Set<int> triggeredCameras;
  final bool fakePositionActive;
  final LatLng? fakePositionLatLng;
  final LatLng? bodyThrowPosition;
  final EliminationAftermathRule? afterCatchRule;
  final List<LatLng> ghostRoughPositions;
  final bool editingArea;
  final bool editCircleMode;
  final List<LatLng> polygonDraft;
  final bool polygonDraftClosed;
  final LatLng circleDraftCenter;
  final double circleDraftRadiusMeters;
  final PlayArea playArea;
  final LatLng? captureZoneCenter;
  final WorldProfileTokens tokens;
  final GameMapLayerToggles layerToggles;
  final WorldVisualPack? visualPack;
  final MapMarkerIconRegistry? markerRegistry;
  final double mapZoom;
  final BitmapDescriptor? playerMarkerIcon;
  final bool usePhotoPlayerPin;

  /// 0〜1。監視カメラのスキャン円アニメ用。
  final double cameraPulsePhase;
}
