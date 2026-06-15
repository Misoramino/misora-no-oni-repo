part of 'game_map_screen.dart';

/// 位置暴露（名前付き／匿名）の発行と、安全地帯・情報屋ギミックの取得判定。
///
/// `game_map_screen.dart` 本体（`_GameMapScreenState`）から物理的に切り出したもの。
/// 挙動は本体にあった頃と完全に同一（同一ライブラリの extension）。
extension _GameMapRevealsGimmicks on _GameMapScreenState {
  void _scheduleGimmickRelocate({
    required String kind,
    required int index,
    required LatLng position,
    required DateTime from,
    bool localHint = false,
  }) {
    final applyAt = from.add(
      const Duration(seconds: GameConfig.gimmickRelocateDelaySeconds),
    );
    final pending = PendingGimmickRelocate(
      kind: kind,
      index: index,
      position: position,
      applyAt: applyAt,
    );
    final existing = _rt.pendingGimmickRelocates.indexWhere(
      (p) => p.kind == kind && p.index == index,
    );
    if (existing >= 0) {
      _rt.pendingGimmickRelocates[existing] = pending;
    } else {
      _rt.pendingGimmickRelocates.add(pending);
    }
    if (localHint) {
      _localGimmickRelocateHintUntil = applyAt;
    }
  }

  void _applyDueGimmickRelocates(DateTime now) {
    final due = _rt.pendingGimmickRelocates
        .where((p) => !now.isBefore(p.applyAt))
        .toList(growable: false);
    if (due.isEmpty) return;
    for (final p in due) {
      switch (p.kind) {
        case 'safe_zone':
          if (p.index >= 0 && p.index < _rt.safeZonePositions.length) {
            _rt.safeZonePositions[p.index] = p.position;
          }
        case 'info_broker':
          if (p.index >= 0 && p.index < _rt.infoBrokerPositions.length) {
            _rt.infoBrokerPositions[p.index] = p.position;
          }
      }
      _rt.pendingGimmickRelocates.remove(p);
    }
  }

  void _applyRemoteGimmickRelocate({
    required String kind,
    required int hitIndex,
    required LatLng nextPosition,
  }) {
    final now = DateTime.now();
    _syncSetState(() {
      if (kind == 'info_broker') {
        _rt.infoBrokerAvailable = false;
        _rt.infoBrokerRespawnAt = now.add(
          const Duration(seconds: GameConfig.infoBrokerRespawnSeconds),
        );
      } else if (kind == 'safe_zone') {
        _rt.safeZoneAvailable = false;
        _rt.safeZoneRespawnAt = now.add(
          const Duration(seconds: GameConfig.safeZoneRespawnSeconds),
        );
      }
      _scheduleGimmickRelocate(
        kind: kind,
        index: hitIndex,
        position: nextPosition,
        from: now,
      );
    });
  }

  void _appendInfectionPulseReveal() {
    final pos = _positionForReveal;
    final pick = _reasonPickAt(pos);
    _emitAnonymousReveal(
      position: pos,
      pick: pick,
      source: 'panic',
    );
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(MatchHudCopy.panicTraceSnack),
      ),
    );
  }

  void _updateDangerPulse() {
    final shouldPulse = _rt.dangerPulseActive;
    if (shouldPulse) {
      if (!_dangerPulseController.isAnimating) {
        _dangerPulseController.repeat(reverse: true);
      }
    } else {
      if (_dangerPulseController.isAnimating) {
        _dangerPulseController.stop();
        _dangerPulseController.value = 0;
      }
    }
  }

  RevealReasonPick _reasonPickAt(
    LatLng pos, {
    bool forceCamera = false,
    bool periodic = false,
  }) {
    if (forceCamera) return RevealReasonPool.cameraPick();
    if (periodic) {
      return RevealReasonPool.periodicPick(
        revealPosition: pos,
        cameraPositions: _rt.cameraPositions,
        safeZonePositions: _rt.safeZonePositions,
        actorOutsidePlayArea: !_playArea.contains(_currentPosition),
      );
    }
    return RevealReasonPool.pick(
      revealPosition: pos,
      cameraPositions: _rt.cameraPositions,
      safeZonePositions: _rt.safeZonePositions,
      actorOutsidePlayArea: !_playArea.contains(_currentPosition),
    );
  }

  void _emitIdentifiedReveal({
    required String revealKind,
    required LatLng position,
    required String playerLabel,
    required RevealReasonPick pick,
    double overflowMeters = 0,
    String? syncLocalEventType,
    bool pushHud = true,
    String? subjectUid,
    bool attachAvatarOnReveal = true,
  }) {
    final shown = _displayRevealPosition(position);
    final resolvedSubjectUid = attachAvatarOnReveal
        ? (subjectUid ?? _firestoreSession?.myUid ?? 'local')
        : null;
    _rt.revealCount += 1;
    final ev = LocationRevealEvent(
      sequence: _rt.revealCount,
      timestamp: DateTime.now(),
      position: shown,
      overflowMeters: overflowMeters,
      playerLabel: playerLabel,
      reasonSummary: pick.summary,
      subjectUid: resolvedSubjectUid,
    );
    _syncSetState(() {
      _rt.revealLog.insert(0, ev);
      if (_rt.revealLog.length > 50) _rt.revealLog.removeLast();
      _statusMessage = MatchHudCopy.namedRevealStatus(playerLabel, pick.summary);
    });
    if (pushHud) {
      _pushHudRevealAlert(
        MatchHudCopy.namedRevealAlert(playerLabel, pick.summary),
      );
    }
    _emitMatchEvent(
      type: syncLocalEventType ?? revealKind,
      message: pick.narrative,
      position: shown,
      syncFirestore: false,
    );
    unawaited(
      _publishFirestoreReveal(
        revealKind: revealKind,
        message: pick.narrative,
        position: shown,
        playerLabel: playerLabel,
        overflowMeters: overflowMeters,
        reasonSummary: pick.summary,
      ),
    );
  }

  void _triggerLocationReveal(double overflowMeters) {
    _rt.revealedInCurrentOutside = true;
    final playerLabel = _localPlayerLabel;
    final raw = _positionForReveal;
    final pick = _reasonPickAt(raw);
    _emitIdentifiedReveal(
      revealKind: 'area_reveal',
      position: raw,
      playerLabel: playerLabel,
      pick: pick,
      overflowMeters: overflowMeters,
      syncLocalEventType: 'area_reveal',
    );
    HapticFeedback.heavyImpact();
    GameAudio.instance.playWorldSfx(SfxId.reveal, profile: _activeProfile);
    _retuneGpsIfNeeded();
  }

  void _emitLocationReveal({
    required String type,
    required String message,
    LatLng? overridePosition,
    String? reasonSummary,
  }) {
    final raw = overridePosition ?? _positionForReveal;
    final pick = reasonSummary != null
        ? RevealReasonPick(summary: reasonSummary, narrative: message)
        : _reasonPickAt(raw);
    _emitIdentifiedReveal(
      revealKind: type,
      position: raw,
      playerLabel: _localPlayerLabel,
      pick: pick,
      syncLocalEventType: type,
    );
  }

  void _evaluateSafeZone() {
    if (_rt.safeZoneCharges >= GameConfig.safeZoneMaxCharges) return;
    final now = DateTime.now();
    final hitIndex = GimmickPickupEvaluator.pickupIndexIfAllowed(
      available: _rt.safeZoneAvailable,
      positions: _rt.safeZonePositions,
      radiusMeters: GameConfig.safeZoneRadiusMeters,
      playerPosition: _currentPosition,
      lastPickupAt: _rt.lastSafeChargeAt,
      cooldownSeconds: GameConfig.safeZoneChargeCooldownSeconds,
      now: now,
    );
    if (hitIndex == null) return;
    final hit = _rt.safeZonePositions[hitIndex];
    final nextSafeZone = GimmickRelocator.relocate(
      area: _playArea,
      avoid: [
        ..._rt.safeZonePositions,
        ..._rt.infoBrokerPositions,
        ..._rt.cameraPositions,
        ..._rt.commJammingZonePositions,
      ],
      angleSeed: 35 + _rt.elapsedSeconds * 7 + hitIndex * 53,
      radiusFactor: 0.44,
    );
    _syncSetState(() {
      _rt.lastSafeChargeAt = now;
      _rt.safeZoneCharges += 1;
      _refreshSkillCooldownsFromSafeZone();
      _rt.safeZoneAvailable = false;
      _rt.safeZoneRespawnAt = now.add(
        const Duration(seconds: GameConfig.safeZoneRespawnSeconds),
      );
      _scheduleGimmickRelocate(
        kind: 'safe_zone',
        index: hitIndex,
        position: nextSafeZone,
        from: now,
        localHint: true,
      );
      _statusMessage = '安全地帯: ステルス獲得 + スキル再使用可能（移動中）';
    });
    _emitMatchEvent(
      type: 'safe_charge',
      message: '安全地帯でチャージ獲得・スキル再使用可能・安全地帯移動',
      position: hit,
    );
  }

  void _evaluateInfoBroker(double distanceToOni) {
    final now = DateTime.now();
    final isHunter = _localRole == PlayerRole.hunter;
    final hitIndex = GimmickPickupEvaluator.pickupIndexIfAllowed(
      available: _rt.infoBrokerAvailable,
      positions: _rt.infoBrokerPositions,
      radiusMeters: GameConfig.infoBrokerRadiusMeters,
      playerPosition: _currentPosition,
      lastPickupAt: isHunter ? _rt.lastHunterInfoBrokerAt : _rt.lastInfoBrokerAt,
      cooldownSeconds: isHunter
          ? GameConfig.oniInfoBrokerCooldownSeconds
          : GameConfig.infoBrokerCooldownSeconds,
      now: now,
    );
    if (hitIndex == null) return;
    final hit = _rt.infoBrokerPositions[hitIndex];
    if (isHunter) {
      _applyHunterInfoBroker(hitIndex: hitIndex, hit: hit, now: now);
    } else {
      _applyRunnerInfoBroker(
        hitIndex: hitIndex,
        hit: hit,
        now: now,
        distanceToOni: distanceToOni,
      );
    }
  }

  LatLng _relocateInfoBroker(int hitIndex) {
    return GimmickRelocator.relocate(
      area: _playArea,
      avoid: [
        ..._rt.safeZonePositions,
        ..._rt.infoBrokerPositions,
        ..._rt.cameraPositions,
        ..._rt.commJammingZonePositions,
      ],
      angleSeed: 150 + _rt.elapsedSeconds * 11 + hitIndex * 71,
      radiusFactor: 0.58,
    );
  }

  void _markInfoBrokerUsed({
    required int hitIndex,
    required LatLng hit,
    required LatLng nextInfoBroker,
    required DateTime now,
    required String statusMessage,
    DateTime? runnerLastAt,
    DateTime? hunterLastAt,
  }) {
    _syncSetState(() {
      if (runnerLastAt != null) _rt.lastInfoBrokerAt = runnerLastAt;
      if (hunterLastAt != null) _rt.lastHunterInfoBrokerAt = hunterLastAt;
      _rt.infoBrokerAvailable = false;
      _rt.infoBrokerRespawnAt = now.add(
        const Duration(seconds: GameConfig.infoBrokerRespawnSeconds),
      );
      _scheduleGimmickRelocate(
        kind: 'info_broker',
        index: hitIndex,
        position: nextInfoBroker,
        from: now,
        localHint: true,
      );
      _statusMessage = statusMessage;
    });
  }

  void _applyRunnerInfoBroker({
    required int hitIndex,
    required LatLng hit,
    required DateTime now,
    required double distanceToOni,
  }) {
    final bearing = Geolocator.bearingBetween(
      _currentPosition.latitude,
      _currentPosition.longitude,
      _oniPosition.latitude,
      _oniPosition.longitude,
    );
    final direction = MapGeoUtils.bearingToDirection(bearing);
    final distBand = distanceToOni <= GameConfig.dangerDistanceMeters
        ? '至近'
        : distanceToOni <= GameConfig.warningDistanceMeters
        ? '中距離'
        : '遠距離';
    var intel = OniIntelTextBuilder.build(
      mode: _oniIntelMode,
      elapsedSeconds: _rt.elapsedSeconds,
      oniInCommJammingZone: _oniInCommJammingZone,
      playerPosition: _currentPosition,
      commJammingZoneCenters: _rt.commJammingZonePositions,
      direction: direction,
      distanceBand: distBand,
      bearingDegrees: bearing,
    );
    if (_localRunnerModifier == RunnerModifier.hacker) {
      final facing = _oniFacingDirectionLabel();
      intel = OniIntelTextBuilder.buildHackerAugment(
        baseIntel: intel,
        distanceBand: distBand,
        distanceMeters: distanceToOni,
        oniFacingDirection: facing,
      );
    }
    final nextInfoBroker = _relocateInfoBroker(hitIndex);
    _syncSetState(() {
      _rt.lastInfoBrokerAt = now;
      _rt.infoBrokerAvailable = false;
      _rt.infoBrokerRespawnAt = now.add(
        const Duration(seconds: GameConfig.infoBrokerRespawnSeconds),
      );
      _rt.lastOniIntelText = intel;
      _rt.lastOniIntelAt = now;
      _rt.showOniIntelCard = true;
      _rt.oniIntelTraces.insert(
        0,
        OniIntelTrace(timestamp: now, position: hit, text: intel),
      );
      if (_rt.oniIntelTraces.length > 20) {
        _rt.oniIntelTraces.removeLast();
      }
      _scheduleGimmickRelocate(
        kind: 'info_broker',
        index: hitIndex,
        position: nextInfoBroker,
        from: now,
        localHint: true,
      );
      final trailHint = _oniTrailPointsForMap().length >= 2
          ? ' · 地図に鬼の遅延軌跡を表示'
          : '';
      _statusMessage = '情報屋: $intel$trailHint';
    });
    _emitMatchEvent(
      type: 'info_broker',
      message: '情報屋を利用: $intel',
      position: hit,
      syncFirestore: false,
    );
    unawaited(
      _publishFirestoreInfoBroker(
        intel: intel,
        hitIndex: hitIndex,
        pickupLat: hit.latitude,
        pickupLng: hit.longitude,
        nextLat: nextInfoBroker.latitude,
        nextLng: nextInfoBroker.longitude,
      ),
    );
  }

  String? _oniFacingDirectionLabel() {
    final deg = _lastKnownOniHeadingDegrees;
    if (deg == null) return null;
    return MapGeoUtils.bearingToDirection(deg);
  }
}
