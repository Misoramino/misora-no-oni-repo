part of 'game_map_screen.dart';

/// 地図オーバーレイスナップショット組み立て。
extension _GameMapOverlay on _GameMapScreenState {
  Map<String, BitmapDescriptor> _revealAvatarIconsForOverlay() {
    final out = Map<String, BitmapDescriptor>.from(
      _revealAvatarIcons.iconsByUid,
    );
    final icon = _mapVisual.playerAvatarIcon;
    if (icon != null && _shouldUsePhotoPlayerPin()) {
      final uid = _firestoreSession?.myUid ?? 'local';
      out[uid] = icon;
    }
    return out;
  }

  GameMapOverlaySnapshot _overlaySnapshot(WorldProfileTokens tokens) {
    final locallyEliminated =
        _gameState == GameState.caughtByOni && _afterCatchRule != null;
    return GameMapOverlaySnapshot(
      now: DateTime.now(),
      playerMarkerPosition: _playerMarkerPosition,
      oniPosition: _oniPosition,
      showOniMarker: _showOniMarker,
      remoteOniKnown: _remoteOniKnown,
      remoteMembers: _remoteMembers,
      showGimmickMarkers: _showGimmickMapMarkers,
      safeZonePositions: _rt.safeZonePositions,
      infoBrokerPositions: _rt.infoBrokerPositions,
      accusationFacilityPositions: _rt.accusationFacilityPositions,
      activeAccusationSiteIndices: _rt.activeAccusationSiteIndices,
      accusationFacilityTitle: _accusationCopy.facilityName,
      cameraJackPositions: _rt.cameraJackPositions,
      showCameraJackSites:
          _afterCatchRule?.supportsCameraJack == true &&
          _gameState == GameState.caughtByOni,
      commJammingZonePositions: _rt.commJammingZonePositions,
      cameraPositions: _rt.cameraPositions,
      disabledCameraIndices: _rt.disabledCameraIndices,
      tracePoints: locallyEliminated ? const [] : _tracePoints,
      revealTraces: locallyEliminated
          ? const []
          : _recentRevealTraces().toList(growable: false),
      anonymousRevealTraces: locallyEliminated
          ? const []
          : _recentAnonymousTraces().toList(growable: false),
      oniIntelTraces: locallyEliminated
          ? const []
          : _recentOniIntelTraces().toList(growable: false),
      safeZoneAvailable: _rt.safeZoneAvailable,
      infoBrokerAvailable: _rt.infoBrokerAvailable,
      safeZoneRespawnAt: _rt.safeZoneRespawnAt,
      infoBrokerRespawnAt: _rt.infoBrokerRespawnAt,
      fakePositionActive: _rt.fakePositionActive,
      fakePositionLatLng: _rt.fakePositionLatLng,
      bodyThrowPosition: _rt.bodyThrowPosition,
      bodyThrowAwaitingMapTap: _rt.bodyThrowAwaitingMapTap,
      waitingSkillLockMapTap: _rt.waitingSkillLockMapTap,
      skillPlacementPreviewLatLng: _skillPlacementPreviewLatLng,
      skillPlacementPreviewRadiusMeters:
          _skillPlacementPreviewRadiusMeters(),
      afterCatchRule: _afterCatchRule,
      ghostRoughPositions: _afterCatchRule != null
          ? GameMapOverlayBuilder.ghostRoughPositions(
              currentPosition: _currentPosition,
              oniPosition: _oniPosition,
              cameraPositions: _rt.cameraPositions,
            )
          : const [],
      editingArea: _editingArea,
      editCircleMode: _editCircleMode,
      polygonDraft: _polygonDraft,
      polygonDraftClosed: _polygonDraftClosed,
      circleDraftCenter: _circleDraftCenter,
      circleDraftRadiusMeters: _circleDraftRadiusMeters,
      playArea: _playArea,
      lockZoneCenter: _rt.lockZoneCenter,
      lockZoneDisplayRadiusMeters: _rt.lockZoneCenter == null
          ? 0
          : MatchGeoHelpers.lockZoneEscapeRadiusMeters(
              placedBySkill: _rt.lockZoneFromSkill,
              playArea: _playArea,
            ),
      oniTrailPoints:
          locallyEliminated ? const [] : _oniTrailPointsForMap(),
      oniMatchStartAnchor: _showOniMatchStartAnchor ? _oniMatchStartAnchor : null,
      tokens: tokens,
      layerToggles: _mapLayerToggles,
      visualPack: _mapVisual.pack,
      markerRegistry: _mapVisual.markerRegistry,
      mapZoom: _mapVisual.mapZoom,
      playerMarkerIcon: _mapVisual.playerAvatarIcon,
      usePhotoPlayerPin: _shouldUsePhotoPlayerPin(),
      revealAvatarIconsByUid: _revealAvatarIconsForOverlay(),
      cameraPulsePhase: _cameraPulsePhase,
      analystTraceDetail: _localRunnerModifier == RunnerModifier.analyst,
      secondGameIntroHighlight:
          _secondGameIntroHighlight && locallyEliminated,
      secondGameCanUseCameraJack: _secondGameCanUseCameraJack,
      secondGameCanUseAccusationTerritory: _secondGameCanUseAccusationTerritory,
      secondGameCanUseFacilitySabotage: _secondGameCanUseFacilitySabotage,
      secondGameCanUseCameraShutdown: _secondGameCanUseCameraShutdown,
    );
  }

  int _secondsUntil(DateTime? target) => MapGeoFormat.secondsUntil(target);

  double _skillPlacementPreviewRadiusMeters() {
    if (_skillPlacementPreviewLatLng == null) return 0;
    if (_rt.waitingSkillLockMapTap) {
      return GameConfig.captureZoneSkillRadiusMeters;
    }
    return 12;
  }

  void _logDebug(String line) {
    final stamp = DateTime.now().toIso8601String().substring(11, 19);
    _debugLogs.insert(0, '[$stamp] $line');
    if (_debugLogs.length > 120) {
      _debugLogs.removeLast();
    }
  }
}
