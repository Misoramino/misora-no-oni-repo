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
      tracePoints: _tracePoints,
      revealTraces: _recentRevealTraces().toList(growable: false),
      anonymousRevealTraces: _recentAnonymousTraces().toList(growable: false),
      oniIntelTraces: _recentOniIntelTraces().toList(growable: false),
      safeZoneAvailable: _rt.safeZoneAvailable,
      infoBrokerAvailable: _rt.infoBrokerAvailable,
      safeZoneRespawnAt: _rt.safeZoneRespawnAt,
      infoBrokerRespawnAt: _rt.infoBrokerRespawnAt,
      fakePositionActive: _rt.fakePositionActive,
      fakePositionLatLng: _rt.fakePositionLatLng,
      bodyThrowPosition: _rt.bodyThrowPosition,
      bodyThrowAwaitingMapTap: _rt.bodyThrowAwaitingMapTap,
      waitingSkillLockMapTap: _rt.waitingSkillLockMapTap,
      fakeIntelAwaitingMapTap: _rt.fakeIntelAwaitingMapTap,
      skillPlacementPreviewLatLng: _skillPlacementPreviewLatLng,
      skillPlacementPreviewRadiusMeters:
          _skillPlacementPreviewRadiusMeters(),
      skillMapPlacementMaxRangeMeters: _skillMapPlacementMaxRangeMeters(),
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
      oniTrailPoints: _oniTrailPointsForMap(),
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
      showInspectorIntelPins: _isRoomInspector,
      inspectorIntelPins: _isRoomInspector
          ? InspectorIntelPinLogic.build(
              assignments:
                  _firestoreSession?.currentMatchStart?.assignments ?? const {},
              remoteMembers: _remoteMembers,
              revealLog: _rt.revealLog,
              hunterPositions: _lastKnownHunterPositions,
              eliminatedUids: _eliminatedUids,
              now: DateTime.now(),
            )
          : const [],
      inspectorLiveFeed: _isRoomInspector ? _inspectorLiveFeed : const {},
      playAreaPreviewMode:
          _prepMapMode == PrepMapMode.preview &&
          _gameState == GameState.waiting &&
          !_matchPresentationActive,
      playAreaPreviews: _playAreaPreviewEntries(),
    );
  }

  int _secondsUntil(DateTime? target) => MapGeoFormat.secondsUntil(target);

  double _skillPlacementPreviewRadiusMeters() {
    if (_skillPlacementPreviewLatLng == null) return 0;
    if (_rt.waitingSkillLockMapTap) {
      return GameConfig.captureZoneSkillRadiusMeters;
    }
    if (_rt.fakeIntelAwaitingMapTap) return 16;
    return 12;
  }

  double _skillMapPlacementMaxRangeMeters() {
    if (_rt.bodyThrowAwaitingMapTap || _rt.waitingSkillLockMapTap) {
      return GameConfig.bodyThrowDistanceMeters;
    }
    return 0;
  }

  String _skillMapPlacementHint() {
    if (_rt.fakeIntelAwaitingMapTap) {
      return '長押しで暴露位置を決める（プレイエリア内）';
    }
    if (_rt.bodyThrowAwaitingMapTap) {
      return '長押しで人形の位置を決める';
    }
    return '長押しで結界の位置を決める';
  }

  void _logDebug(String line) {
    final stamp = DateTime.now().toIso8601String().substring(11, 19);
    _debugLogs.insert(0, '[$stamp] $line');
    if (_debugLogs.length > 120) {
      _debugLogs.removeLast();
    }
  }

  void _scheduleMapOverlayPublish() {
    if (_mapOverlayPublishScheduled) return;
    _mapOverlayPublishScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _mapOverlayPublishScheduled = false;
      if (mounted) _publishMapOverlay();
    });
  }

  void _publishMapOverlay({bool force = false}) {
    if (!mounted) return;
    final tokens = _mapVisual.pack.tokens;
    final snapshot = _overlaySnapshot(tokens);
    final fp = GameMapOverlayVisual.fingerprint(snapshot);
    if (!force && fp == _lastMapOverlayFingerprint) return;
    _lastMapOverlayFingerprint = fp;
    _mapOverlayNotifier.value = snapshot;
    final pulse = _cameraPulsePhase;
    if (_cameraPulseNotifier.value != pulse) {
      _cameraPulseNotifier.value = pulse;
    }
  }

  void _onSkillPlacementPreview(LatLng? latLng) {
    if (_skillPlacementPreviewLatLng == latLng) return;
    _skillPlacementPreviewLatLng = latLng;
    _publishMapOverlay(force: true);
  }

  Widget _buildInteractiveGoogleMap(WorldProfileTokens tokens) {
    return GameMapInteractiveLayer(
      key: const ValueKey('game_map_interactive_layer'),
      overlayListenable: _mapOverlayNotifier,
      mapStyleJson: _effectiveMapStyleJson,
      initialCameraTarget: _currentPosition,
      onMapCreated: _onMapCreated,
      onTap: _onMapTap,
      onCameraIdle: _onCameraIdle,
      mapController: _mapController,
      skillPlacementActive: _skillMapPlacementActive,
      bodyThrowAwaitingMapTap: _rt.bodyThrowAwaitingMapTap,
      skillPlacementHint: _skillMapPlacementHint(),
      onSkillPlacementPreview: _onSkillPlacementPreview,
      onSkillPlacementConfirm: _confirmSkillMapPlacementAt,
      onSkillPlacementCancel: _cancelSkillMapPlacement,
    );
  }
}
