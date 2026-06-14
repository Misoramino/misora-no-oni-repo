import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../../game/anonymous_reveal_trace.dart';
import 'game_map_layer_toggles.dart';
import 'game_map_overlay_snapshot.dart';

/// 地図オーバーレイの描画更新が必要かどうかの軽量判定（ゲームロジックには非依存）。
abstract final class GameMapOverlayVisual {
  /// マーカー／円／線の見た目に効くフィールドだけをハッシュ化する。
  static int fingerprint(GameMapOverlaySnapshot s) {
    return Object.hashAll([
      _coordKey(s.playerMarkerPosition),
      _coordKey(s.oniPosition),
      s.showOniMarker,
      s.remoteOniKnown,
      (s.cameraPulsePhase * 12).round(),
      s.tracePoints.length,
      s.revealTraces.length,
      s.anonymousRevealTraces.length,
      s.oniIntelTraces.length,
      s.remoteMembers.length,
      s.showGimmickMarkers,
      _layerTogglesKey(s.layerToggles),
      (s.mapZoom * 4).round(),
      s.safeZonePositions.length,
      s.infoBrokerPositions.length,
      s.accusationFacilityPositions.length,
      Object.hashAll(s.activeAccusationSiteIndices),
      s.cameraPositions.length,
      Object.hashAll(s.disabledCameraIndices),
      s.fakePositionActive,
      _coordKey(s.fakePositionLatLng),
      _coordKey(s.bodyThrowPosition),
      s.bodyThrowAwaitingMapTap,
      s.waitingSkillLockMapTap,
      s.fakeIntelAwaitingMapTap,
      _coordKey(s.skillPlacementPreviewLatLng),
      (s.skillPlacementPreviewRadiusMeters * 10).round(),
      _coordKey(s.lockZoneCenter),
      (s.lockZoneDisplayRadiusMeters * 10).round(),
      s.editingArea,
      s.polygonDraft.length,
      s.polygonDraftClosed,
      _coordKey(s.circleDraftCenter),
      (s.circleDraftRadiusMeters * 10).round(),
      s.oniTrailPoints.length,
      _coordKey(s.oniMatchStartAnchor),
      s.secondGameIntroHighlight,
      s.showInspectorIntelPins,
      s.inspectorIntelPins.length,
      s.playAreaPreviewMode,
      s.playAreaPreviews.length,
      if (s.revealTraces.isNotEmpty)
        _coordKey(s.revealTraces.last.position)
      else
        0,
      if (s.anonymousRevealTraces.isNotEmpty)
        _coordKey(_anonPos(s.anonymousRevealTraces.last))
      else
        0,
    ]);
  }

  static LatLng _anonPos(AnonymousRevealTrace t) => t.position;

  static int _coordKey(LatLng? p) {
    if (p == null) return 0;
    return Object.hash(
      (p.latitude * 1e5).round(),
      (p.longitude * 1e5).round(),
    );
  }

  static int _layerTogglesKey(GameMapLayerToggles L) => Object.hashAll([
        L.playArea,
        L.remotePlayers,
        L.safeZones,
        L.infoBrokers,
        L.accusationFacilities,
        L.commJamming,
        L.cameras,
        L.traces,
        L.reveals,
        L.oniIntel,
        L.captureZone,
        L.skillMarkers,
        L.ghostRough,
        L.inspectorIntel,
      ]);
}
