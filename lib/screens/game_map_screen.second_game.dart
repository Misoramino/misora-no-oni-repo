part of 'game_map_screen.dart';

/// 脱落後の第二ゲーム（残響体ジャック・陣取り・鬼影妨害）。
extension _GameMapSecondGame on _GameMapScreenState {
  void _eliminateLocalParticipant(
    String message, {
    required String cause,
    bool publishOnline = true,
  }) {
    if (_gameState != GameState.running) return;
    _dismissOpenModals();
    _tracePoints.add(_currentPosition);
    unawaited(_publishTraceDrop(_currentPosition));
    final factionAtDeath = _localFactionNow();
    final rule = EliminationAftermathRule.forEliminatedFaction(
      matchDefault: _eliminationAftermathRule,
      factionAtDeath: factionAtDeath,
    );
    _cancelCaptureBoundTimers();
    _syncSetState(() {
      _gameState = GameState.caughtByOni;
      _afterCatchRule = rule;
      _factionAtDeath = factionAtDeath;
      _statusMessage = _eliminationStatusMessage(rule, message);
      _accusationPromptOpen = false;
      _prepControlSheetOpen = false;
      _controlSheetMode = ControlSheetMode.hidden;
      _rt.clearActiveChaseState();
    });
    _updateDangerPulse();
    if (publishOnline) {
      unawaited(_publishPlayerEliminatedIfOnline(cause: cause));
    }
    final myUid = _firestoreSession?.myUid ?? 'local';
    _eliminatedUids.add(myUid);
    _emitMatchEvent(
      type: cause,
      message: message,
      position: _currentPosition,
      syncFirestore: false,
    );
    if (cause == 'accusation_failed') {
      _emitMatchEvent(
        type: 'after_catch_rule',
        message: '脱落後: ${rule.label}',
        position: _currentPosition,
        syncFirestore: false,
      );
    }
    HapticFeedback.heavyImpact();
    SystemSound.play(SystemSoundType.alert);
    GameAudio.instance.playSfx(SfxId.eliminated);
    if (cause != 'accusation_failed') {
      _recordMatchFeed('${MatchHudCopy.captureSucceeded} — ${rule.label}');
    }
    if (!_rejoinRestoringEvents) {
      unawaited(_onSecondGameIntroAfterElimination());
    }
    _maybeEndMatchForFactionElimination();
  }

  void _restoreLocalEliminationFromEvent(
    RoomMatchEvent ev, {
    required String message,
  }) {
    final factionName = ev.payload['factionAtDeath'] as String?;
    final ruleName = ev.payload['afterCatchRule'] as String?;
    final faction = factionName != null
        ? FactionSide.values.byName(factionName)
        : _localFactionNow();
    final rule = ruleName != null
        ? EliminationAftermathRule.values.byName(ruleName)
        : EliminationAftermathRule.forEliminatedFaction(
            matchDefault: _eliminationAftermathRule,
            factionAtDeath: faction,
          );
    final myUid = _firestoreSession?.myUid ?? 'local';
    _eliminatedUids.add(myUid);
    _syncSetState(() {
      _gameState = GameState.caughtByOni;
      _afterCatchRule = rule;
      _factionAtDeath = faction;
      _statusMessage = _eliminationStatusMessage(rule, message);
      _controlSheetMode = ControlSheetMode.skillsOnly;
      _accusationPromptOpen = false;
      _prepControlSheetOpen = false;
    });
    _updateDangerPulse();
  }

  String _eliminationStatusMessage(
    EliminationAftermathRule rule,
    String fallback,
  ) {
    final copy = EliminationRoleCopy.forProfile(_mapVisual.pack.profile, rule);
    return switch (rule) {
      EliminationAftermathRule.spectralOperative ||
      EliminationAftermathRule.revenantOni =>
        MatchHudCopy.eliminationCaptured(copy.roleTitle, copy.roleSubtitle),
      EliminationAftermathRule.ghostSpectator =>
        MatchHudCopy.eliminationSpectator(copy.roleTitle),
      EliminationAftermathRule.joinOni =>
        MatchHudCopy.eliminationJoinOni(copy.roleTitle),
    };
  }

  void _evaluateCameraJack() {
    final rule = _afterCatchRule;
    if (rule == null || !rule.supportsCameraJack) return;
    if (_gameState != GameState.caughtByOni) return;
    final sites = _rt.cameraJackPositions;
    if (sites.isEmpty) return;

    final now = DateTime.now();
    final chargeIdx = _rt.cameraJackChargeSiteIndex;
    if (chargeIdx != null &&
        chargeIdx >= 0 &&
        chargeIdx < sites.length &&
        _rt.cameraJackChargeStartedAt != null) {
      final site = sites[chargeIdx];
      final inRange = Geolocator.distanceBetween(
            _currentPosition.latitude,
            _currentPosition.longitude,
            site.latitude,
            site.longitude,
          ) <=
          GameConfig.cameraJackSiteRadiusMeters;
      if (!inRange) {
        _syncSetState(() {
          _rt.cameraJackChargeSiteIndex = null;
          _rt.cameraJackChargeStartedAt = null;
          _statusMessage = 'チャージ中断 — 端子から離れました';
        });
        return;
      }
      if (CameraJackLogic.isChargeComplete(
        chargeStartedAt: _rt.cameraJackChargeStartedAt!,
        now: now,
      )) {
        _completeCameraJack(siteIndex: chargeIdx);
      }
      return;
    }

    if (!CameraJackLogic.canStartCharge(
      isEliminated: true,
      isSpectralOperative: true,
      matchUses: _rt.cameraJackMatchUses,
      lastPersonalJackAt: _rt.lastCameraJackAt,
      now: now,
      alreadyCharging: false,
    )) {
      return;
    }

    for (var i = 0; i < sites.length; i++) {
      final d = Geolocator.distanceBetween(
        _currentPosition.latitude,
        _currentPosition.longitude,
        sites[i].latitude,
        sites[i].longitude,
      );
      if (d <= GameConfig.cameraJackSiteRadiusMeters) {
        _syncSetState(() {
          _rt.cameraJackChargeSiteIndex = i;
          _rt.cameraJackChargeStartedAt = now;
          _statusMessage = 'ジャック端子でチャージ中…';
        });
        return;
      }
    }
  }

  void _completeCameraJack({required int siteIndex}) {
    final now = DateTime.now();
    _syncSetState(() {
      _rt.cameraJackChargeSiteIndex = null;
      _rt.cameraJackChargeStartedAt = null;
      _rt.lastCameraJackAt = now;
      _rt.cameraJackMatchUses += 1;
      _statusMessage = 'カメラジャック — 鬼の位置を送信';
    });
    unawaited(_publishCameraJack(siteIndex: siteIndex));
  }

  Future<void> _publishCameraJack({required int siteIndex}) async {
    final fs = _firestoreSession;
    final sk = _matchEventSessionKey;
    final uid = fs?.myUid;
    if (fs == null || sk == null || uid == null) {
      _applyCameraJackRevealLocally();
      return;
    }
    if (!_isOnlineFirestore) {
      _applyCameraJackRevealLocally();
      return;
    }
    final err = await fs.publishRoomEvent(
      type: RoomMatchEventTypes.cameraJack,
      payload: {
        'ghostUid': uid,
        'siteIndex': siteIndex,
      },
      sessionKey: sk,
    );
    if (err != null && mounted) _toast(err);
  }

  void _applyCameraJackRevealLocally() {
    if (_localRole == PlayerRole.hunter) {
      final raw = _positionForReveal;
      final pick = _reasonPickAt(raw);
      _emitIdentifiedReveal(
        revealKind: 'camera_jack',
        position: raw,
        playerLabel: MatchUiTerms.oniRoleLabel,
        pick: pick,
        syncLocalEventType: 'camera_jack',
        attachAvatarOnReveal: false,
      );
    }
  }

  void _applyRemoteCameraJack(RoomMatchEvent ev) {
    final hunterUid = _hunterUidFromAssignments;
    final myUid = _firestoreSession?.myUid;
    if (hunterUid != null && myUid == hunterUid) {
      _applyCameraJackRevealLocally();
    } else if (_localRole == PlayerRole.hunter) {
      _applyCameraJackRevealLocally();
    }
    if (!mounted) return;
    _syncSetState(() {
      _rt.cameraJackMatchUses += 1;
    });
    _pushHudRevealAlert('残響体が監視網を焼いた — 鬼の位置が露わに');
  }

  int get _werewolfTransformCooldownSeconds =>
      _werewolfCooldownSecondsForUi();

  void _evaluateEliminationAftermathCharges() {
    _evaluateCameraJack();
    _evaluateSpectralTerritoryCharge();
    _evaluateFacilitySabotage();
    _evaluateCameraShutdown();
  }

  void _refreshAccusationSitesAfterTerritoryChange() {
    if (!_rt.accusationUnlocked) return;
    final active = _computeActiveAccusationIndices();
    if (!mounted) return;
    _syncSetState(() => _rt.activeAccusationSiteIndices = active);
  }

  void _evaluateSpectralTerritoryCharge() {
    final rule = _afterCatchRule;
    if (rule == null || !rule.supportsSpectralTerritoryCharge) return;
    if (_gameState != GameState.caughtByOni || !_rt.accusationUnlocked) return;
    final sites = _rt.accusationFacilityPositions;
    if (sites.isEmpty) return;

    final now = DateTime.now();
    final radius = GameConfig.accusationFacilityRadiusMeters;
    final chargeIdx = _rt.spectralTerritoryChargeSiteIndex;
    if (chargeIdx != null &&
        chargeIdx >= 0 &&
        chargeIdx < sites.length &&
        _rt.spectralTerritoryChargeStartedAt != null) {
      final site = sites[chargeIdx];
      final inRange = Geolocator.distanceBetween(
            _currentPosition.latitude,
            _currentPosition.longitude,
            site.latitude,
            site.longitude,
          ) <=
          radius;
      if (!inRange) {
        _syncSetState(() {
          _rt.spectralTerritoryChargeSiteIndex = null;
          _rt.spectralTerritoryChargeStartedAt = null;
          _statusMessage = '陣取り中断 — 施設から離れました';
        });
        return;
      }
      if (SpectralTerritoryLogic.isChargeComplete(
        chargeStartedAt: _rt.spectralTerritoryChargeStartedAt!,
        now: now,
      )) {
        _completeSpectralTerritory(siteIndex: chargeIdx);
      }
      return;
    }

    if (!SpectralTerritoryLogic.canStartCharge(
      isEliminated: true,
      isSpectralOperative: true,
      accusationUnlocked: _rt.accusationUnlocked,
      matchUses: _rt.spectralTerritoryMatchUses,
      lastPersonalAt: _rt.lastSpectralTerritoryAt,
      now: now,
      alreadyCharging: false,
    )) {
      return;
    }

    for (var i = 0; i < sites.length; i++) {
      final d = Geolocator.distanceBetween(
        _currentPosition.latitude,
        _currentPosition.longitude,
        sites[i].latitude,
        sites[i].longitude,
      );
      if (d <= radius) {
        _syncSetState(() {
          _rt.spectralTerritoryChargeSiteIndex = i;
          _rt.spectralTerritoryChargeStartedAt = now;
          _statusMessage = MatchHudCopy.spectralTerritoryCharging;
        });
        return;
      }
    }
  }

  void _completeSpectralTerritory({required int siteIndex}) {
    final now = DateTime.now();
    _syncSetState(() {
      _rt.spectralTerritoryChargeSiteIndex = null;
      _rt.spectralTerritoryChargeStartedAt = null;
      _rt.lastSpectralTerritoryAt = now;
      _rt.spectralTerritoryMatchUses += 1;
      _rt.accusationTerritoryBonus += 1;
      _statusMessage =
          '${MatchHudCopy.spectralTerritorySuccess} — '
          '${MatchHudCopy.spectralTerritorySuccessDetail}';
    });
    _refreshAccusationSitesAfterTerritoryChange();
    unawaited(_publishSpectralTerritory(siteIndex: siteIndex));
  }

  Future<void> _publishSpectralTerritory({required int siteIndex}) async {
    final fs = _firestoreSession;
    final sk = _matchEventSessionKey;
    final uid = fs?.myUid;
    if (fs == null || sk == null || uid == null) return;
    if (!_isOnlineFirestore) return;
    final err = await fs.publishRoomEvent(
      type: RoomMatchEventTypes.spectralTerritory,
      payload: {
        'ghostUid': uid,
        'siteIndex': siteIndex,
      },
      sessionKey: sk,
    );
    if (err != null && mounted) _toast(err);
  }

  void _applyRemoteSpectralTerritory(RoomMatchEvent ev) {
    if (!mounted) return;
    _syncSetState(() {
      _rt.spectralTerritoryMatchUses += 1;
      _rt.accusationTerritoryBonus += 1;
    });
    _refreshAccusationSitesAfterTerritoryChange();
    _pushHudRevealAlert(MatchHudCopy.spectralTerritoryFeed);
  }

  void _evaluateFacilitySabotage() {
    final rule = _afterCatchRule;
    if (rule == null || !rule.supportsFacilitySabotage) return;
    if (_gameState != GameState.caughtByOni || !_rt.accusationUnlocked) return;
    final sites = _rt.accusationFacilityPositions;
    if (sites.isEmpty) return;

    final now = DateTime.now();
    final radius = GameConfig.accusationFacilityRadiusMeters;
    final chargeIdx = _rt.revenantSabotageSiteIndex;
    if (chargeIdx != null &&
        chargeIdx >= 0 &&
        chargeIdx < sites.length &&
        _rt.revenantSabotageStartedAt != null) {
      final site = sites[chargeIdx];
      final inRange = Geolocator.distanceBetween(
            _currentPosition.latitude,
            _currentPosition.longitude,
            site.latitude,
            site.longitude,
          ) <=
          radius;
      if (!inRange) {
        _syncSetState(() {
          _rt.revenantSabotageSiteIndex = null;
          _rt.revenantSabotageStartedAt = null;
          _statusMessage = '妨害中断 — 施設から離れました';
        });
        return;
      }
      if (FacilitySabotageLogic.isChargeComplete(
        chargeStartedAt: _rt.revenantSabotageStartedAt!,
        now: now,
      )) {
        _completeFacilitySabotage(siteIndex: chargeIdx);
      }
      return;
    }

    if (!FacilitySabotageLogic.canStartCharge(
      isEliminated: true,
      isRevenantOni: true,
      matchUses: _rt.revenantSabotageMatchUses,
      lastPersonalAt: _rt.lastRevenantSabotageAt,
      now: now,
      alreadyCharging: false,
    )) {
      return;
    }

    for (var i = 0; i < sites.length; i++) {
      final d = Geolocator.distanceBetween(
        _currentPosition.latitude,
        _currentPosition.longitude,
        sites[i].latitude,
        sites[i].longitude,
      );
      if (d <= radius) {
        _syncSetState(() {
          _rt.revenantSabotageSiteIndex = i;
          _rt.revenantSabotageStartedAt = now;
          _statusMessage = MatchHudCopy.facilitySabotageCharging;
        });
        return;
      }
    }
  }

  void _completeFacilitySabotage({required int siteIndex}) {
    final now = DateTime.now();
    _syncSetState(() {
      _rt.revenantSabotageSiteIndex = null;
      _rt.revenantSabotageStartedAt = null;
      _rt.lastRevenantSabotageAt = now;
      _rt.revenantSabotageMatchUses += 1;
      _rt.accusationTerritoryBonus -= 1;
      _statusMessage =
          '${MatchHudCopy.facilitySabotageSuccess} — '
          '${MatchHudCopy.facilitySabotageSuccessDetail}';
    });
    _refreshAccusationSitesAfterTerritoryChange();
    unawaited(_publishFacilitySabotage(siteIndex: siteIndex));
  }

  Future<void> _publishFacilitySabotage({required int siteIndex}) async {
    final fs = _firestoreSession;
    final sk = _matchEventSessionKey;
    final uid = fs?.myUid;
    if (fs == null || sk == null || uid == null) return;
    if (!_isOnlineFirestore) return;
    final err = await fs.publishRoomEvent(
      type: RoomMatchEventTypes.facilitySabotage,
      payload: {
        'ghostUid': uid,
        'siteIndex': siteIndex,
      },
      sessionKey: sk,
    );
    if (err != null && mounted) _toast(err);
  }

  void _applyRemoteFacilitySabotage(RoomMatchEvent ev) {
    if (!mounted) return;
    _syncSetState(() {
      _rt.revenantSabotageMatchUses += 1;
      _rt.accusationTerritoryBonus -= 1;
    });
    _refreshAccusationSitesAfterTerritoryChange();
    _pushHudRevealAlert(MatchHudCopy.facilitySabotageFeed);
  }

  void _evaluateCameraShutdown() {
    final rule = _afterCatchRule;
    if (rule == null || !rule.supportsFacilitySabotage) return;
    if (_gameState != GameState.caughtByOni) return;
    final cameras = _rt.cameraPositions;
    if (cameras.isEmpty) return;

    final now = DateTime.now();
    final radius = GameConfig.cameraTriggerRadiusMeters;
    final chargeIdx = _rt.revenantCameraShutdownIndex;
    if (chargeIdx != null &&
        chargeIdx >= 0 &&
        chargeIdx < cameras.length &&
        _rt.revenantCameraShutdownStartedAt != null) {
      if (_rt.disabledCameraIndices.contains(chargeIdx)) {
        _syncSetState(() {
          _rt.revenantCameraShutdownIndex = null;
          _rt.revenantCameraShutdownStartedAt = null;
        });
        return;
      }
      final cam = cameras[chargeIdx];
      final inRange = Geolocator.distanceBetween(
            _currentPosition.latitude,
            _currentPosition.longitude,
            cam.latitude,
            cam.longitude,
          ) <=
          radius;
      if (!inRange) {
        _syncSetState(() {
          _rt.revenantCameraShutdownIndex = null;
          _rt.revenantCameraShutdownStartedAt = null;
          _statusMessage = 'カメラ停止中断 — 端末から離れました';
        });
        return;
      }
      if (CameraShutdownLogic.isChargeComplete(
        chargeStartedAt: _rt.revenantCameraShutdownStartedAt!,
        now: now,
      )) {
        _completeCameraShutdown(cameraIndex: chargeIdx);
      }
      return;
    }

    if (!CameraShutdownLogic.canStartShutdown(
      isEliminated: true,
      isRevenantOni: true,
      cameraIndex: 0,
      disabledCameraIndices: _rt.disabledCameraIndices,
      lastPersonalAt: _rt.lastCameraShutdownAt,
      now: now,
      alreadyCharging: false,
    )) {
      return;
    }

    for (var i = 0; i < cameras.length; i++) {
      if (_rt.disabledCameraIndices.contains(i)) continue;
      final d = Geolocator.distanceBetween(
        _currentPosition.latitude,
        _currentPosition.longitude,
        cameras[i].latitude,
        cameras[i].longitude,
      );
      if (d <= radius) {
        _syncSetState(() {
          _rt.revenantCameraShutdownIndex = i;
          _rt.revenantCameraShutdownStartedAt = now;
          _statusMessage = '監視カメラを停止中…';
        });
        return;
      }
    }
  }

  void _completeCameraShutdown({required int cameraIndex}) {
    final now = DateTime.now();
    _syncSetState(() {
      _rt.revenantCameraShutdownIndex = null;
      _rt.revenantCameraShutdownStartedAt = null;
      _rt.lastCameraShutdownAt = now;
      _rt.disabledCameraIndices = {
        ..._rt.disabledCameraIndices,
        cameraIndex,
      };
      _statusMessage = '監視カメラを停止しました';
    });
    unawaited(_publishCameraShutdown(cameraIndex: cameraIndex));
  }

  Future<void> _publishCameraShutdown({required int cameraIndex}) async {
    final fs = _firestoreSession;
    final sk = _matchEventSessionKey;
    final uid = fs?.myUid;
    if (fs == null || sk == null || uid == null) return;
    if (!_isOnlineFirestore) return;
    final err = await fs.publishRoomEvent(
      type: RoomMatchEventTypes.cameraShutdown,
      payload: {
        'ghostUid': uid,
        'cameraIndex': cameraIndex,
      },
      sessionKey: sk,
    );
    if (err != null && mounted) _toast(err);
  }

  void _applyRemoteCameraShutdown(RoomMatchEvent ev) {
    final idx = (ev.payload['cameraIndex'] as num?)?.toInt();
    if (idx == null || idx < 0) return;
    if (!mounted) return;
    _syncSetState(() {
      _rt.disabledCameraIndices = {..._rt.disabledCameraIndices, idx};
    });
    _pushHudRevealAlert('復讐の鬼影が監視カメラを無効化');
  }

  bool get _eliminationChargeActive {
    final rule = _afterCatchRule;
    if (rule == null) return false;
    if (rule.supportsSpectralTerritoryCharge) {
      return _rt.cameraJackChargeStartedAt != null ||
          _rt.spectralTerritoryChargeStartedAt != null;
    }
    if (rule.supportsCameraJack) {
      return _rt.cameraJackChargeStartedAt != null;
    }
    if (rule.supportsFacilitySabotage) {
      return _rt.revenantSabotageStartedAt != null ||
          _rt.revenantCameraShutdownStartedAt != null;
    }
    if (rule.supportsSpectralTerritoryCharge) {
      return _rt.spectralTerritoryChargeStartedAt != null;
    }
    return false;
  }

  double? get _eliminationChargeProgress {
    final now = DateTime.now();
    final rule = _afterCatchRule;
    if (rule == null) return null;
    if (rule.supportsCameraJack && _rt.cameraJackChargeStartedAt != null) {
      return CameraJackLogic.chargeProgress(
        chargeStartedAt: _rt.cameraJackChargeStartedAt!,
        now: now,
      );
    }
    if (rule.supportsFacilitySabotage) {
      if (_rt.revenantSabotageStartedAt != null) {
        return FacilitySabotageLogic.chargeProgress(
          chargeStartedAt: _rt.revenantSabotageStartedAt!,
          now: now,
        );
      }
      if (_rt.revenantCameraShutdownStartedAt != null) {
        return CameraShutdownLogic.chargeProgress(
          chargeStartedAt: _rt.revenantCameraShutdownStartedAt!,
          now: now,
        );
      }
    }
    if (rule.supportsSpectralTerritoryCharge &&
        _rt.spectralTerritoryChargeStartedAt != null) {
      return SpectralTerritoryLogic.chargeProgress(
        chargeStartedAt: _rt.spectralTerritoryChargeStartedAt!,
        now: now,
      );
    }
    return null;
  }

  int get _eliminationPrimaryMatchUses {
    final rule = _afterCatchRule;
    if (rule == null) return 0;
    if (rule.supportsFacilitySabotage) {
      return _rt.revenantSabotageMatchUses;
    }
    return _rt.cameraJackMatchUses;
  }

  int get _eliminationPrimaryMatchLimit {
    final rule = _afterCatchRule;
    if (rule == null) return 0;
    if (rule.supportsFacilitySabotage) {
      return GameConfig.facilitySabotageMatchLimit;
    }
    return GameConfig.cameraJackMatchLimit;
  }

  String? get _eliminationSecondaryLine {
    final rule = _afterCatchRule;
    if (rule == null) return null;
    if (rule.supportsFacilitySabotage) {
      final total = _rt.cameraPositions.length;
      final off = _rt.disabledCameraIndices.length;
      return 'カメラ停止 $off / $total 台';
    }
    if (rule.supportsSpectralTerritoryCharge) {
      return '告発陣取り ${_rt.spectralTerritoryMatchUses} / '
          '${GameConfig.spectralTerritoryMatchLimit} 回';
    }
    return null;
  }

  int? get _eliminationPersonalCooldownSeconds {
    final rule = _afterCatchRule;
    if (rule == null) return null;
    if (rule.supportsFacilitySabotage) {
      if (_rt.revenantCameraShutdownStartedAt != null ||
          _rt.revenantSabotageStartedAt != null) {
        return null;
      }
      final sabotage = _cooldownRemainingSeconds(
        _rt.lastRevenantSabotageAt,
        GameConfig.facilitySabotagePersonalCooldownSeconds,
      );
      final shutdown = _cooldownRemainingSeconds(
        _rt.lastCameraShutdownAt,
        GameConfig.cameraShutdownPersonalCooldownSeconds,
      );
      if (sabotage > 0 && shutdown > 0) {
        return sabotage < shutdown ? sabotage : shutdown;
      }
      return sabotage > 0 ? sabotage : (shutdown > 0 ? shutdown : 0);
    }
    if (rule.supportsSpectralTerritoryCharge) {
      final jack = _cooldownRemainingSeconds(
        _rt.lastCameraJackAt,
        GameConfig.cameraJackPersonalCooldownSeconds,
      );
      final territory = _cooldownRemainingSeconds(
        _rt.lastSpectralTerritoryAt,
        GameConfig.spectralTerritoryPersonalCooldownSeconds,
      );
      if (jack > 0 && territory > 0) {
        return jack < territory ? jack : territory;
      }
      return jack > 0 ? jack : (territory > 0 ? territory : 0);
    }
    return _cooldownRemainingSeconds(
      _rt.lastCameraJackAt,
      GameConfig.cameraJackPersonalCooldownSeconds,
    );
  }

  String? get _eliminationChargeActionLabel {
    final rule = _afterCatchRule;
    if (rule == null || !_eliminationChargeActive) return null;
    if (rule.supportsFacilitySabotage) {
      if (_rt.revenantSabotageStartedAt != null) return '妨害';
      if (_rt.revenantCameraShutdownStartedAt != null) return 'カメラ停止';
    }
    if (rule.supportsSpectralTerritoryCharge &&
        _rt.spectralTerritoryChargeStartedAt != null) {
      return '陣取り';
    }
    if (rule.supportsCameraJack && _rt.cameraJackChargeStartedAt != null) {
      return EliminationRoleCopy.forProfile(
        _mapVisual.pack.profile,
        rule,
      ).jackActionLabel;
    }
    return 'チャージ';
  }
}
