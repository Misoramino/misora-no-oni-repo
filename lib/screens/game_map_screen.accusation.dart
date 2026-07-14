part of 'game_map_screen.dart';

/// 告発施設の解禁・試行・解決（重みモード含む）。
extension _GameMapAccusation on _GameMapScreenState {
  void _maybeHostPublishAccusationUnlock() {
    if (!_isHost || !_isOnlineFirestore) return;
    if (_gameState != GameState.running || _rt.accusationUnlocked) return;
    if (_hostAccusationUnlockSent) return;
    final assignments = _firestoreSession?.currentMatchStart?.assignments;
    if (assignments == null) return;
    if (!shouldUnlockAccusation(
      playerCount: assignments.length,
      eliminationCount: _rt.syncedEliminationCount,
      elapsedSeconds: _rt.elapsedSeconds,
      matchDurationSeconds: _matchDurationSeconds,
    )) {
      return;
    }
    _hostAccusationUnlockSent = true;
    final reason = _rt.syncedEliminationCount > 0 ? 'elimination' : 'time_ratio';
    final active = _computeActiveAccusationIndices(treatAsUnlocked: true);
    unawaited(
      _publishAccusationUnlocked(
        reason: reason,
        activeSiteIndices: active.toList(growable: false),
      ),
    );
  }

  Set<int> _computeActiveAccusationIndices({bool treatAsUnlocked = false}) {
    final sites = _rt.accusationFacilityPositions;
    final seed = _firestoreSession?.currentMatchStart?.gimmickSeed ?? 0;
    final n = activeAccusationSiteCount(
      accusationUnlocked: treatAsUnlocked || _rt.accusationUnlocked,
      siteCount: sites.length,
      territoryBonus: _rt.accusationTerritoryBonus,
    );
    return pickActiveAccusationSiteIndices(
      gimmickSeed: seed + _rt.elapsedSeconds,
      siteCount: sites.length,
      activeCount: n,
    ).toSet();
  }

  Future<void> _publishAccusationUnlocked({
    required String reason,
    required List<int> activeSiteIndices,
  }) async {
    final fs = _firestoreSession;
    final sk = _matchEventSessionKey;
    if (fs == null || sk == null || !fs.isHost) return;
    final err = await fs.publishHostRoomEvent(
      type: RoomMatchEventTypes.accusationUnlocked,
      payload: {
        'reason': reason,
        'activeSiteIndices': activeSiteIndices,
      },
      sessionKey: sk,
    );
    if (err != null && mounted) _toast(err);
  }

  Future<void> _publishPlayerEliminatedIfOnline({String? cause}) async {
    final fs = _firestoreSession;
    final sk = _matchEventSessionKey;
    final uid = fs?.myUid;
    if (fs == null || sk == null || uid == null || !_isOnlineFirestore) {
      return;
    }
    final faction = _localFactionNow();
    final rule = EliminationAftermathRule.forEliminatedFaction(
      matchDefault: _eliminationAftermathRule,
      factionAtDeath: faction,
    );
    await fs.publishRoomEvent(
      type: RoomMatchEventTypes.playerEliminated,
      payload: {
        'uid': uid,
        'cause': ?cause,
        'factionAtDeath': faction.name,
        'afterCatchRule': rule.name,
        'playerLabel': _localPlayerLabel,
        'lat': _currentPosition.latitude,
        'lng': _currentPosition.longitude,
        'overflowMeters': _playArea.overflowDistanceMeters(_currentPosition),
      },
      sessionKey: sk,
    );
  }

  void _applyAccusationUnlocked(RoomMatchEvent? ev) {
    if (_rt.accusationUnlocked) return;
    if (!mounted) return;
    final copy = _accusationCopy;
    final raw = ev?.payload['activeSiteIndices'];
    if (raw is List) {
      final parsed = raw
          .whereType<num>()
          .map((e) => e.toInt())
          .toSet();
      // 旧クライアントが空 indices を送った場合は解禁前提で再計算する。
      _rt.activeAccusationSiteIndices = parsed.isNotEmpty
          ? parsed
          : _computeActiveAccusationIndices(treatAsUnlocked: true);
    } else {
      _rt.activeAccusationSiteIndices =
          _computeActiveAccusationIndices(treatAsUnlocked: true);
    }
    _syncSetState(() {
      _rt.accusationUnlocked = true;
      _statusMessage = '${copy.facilityName}: ${copy.unlockLines.last}';
    });
    for (final line in copy.unlockLines) {
      _pushHudRevealAlert(
        line,
        momentKind: WorldMomentKind.accusationUnlock,
      );
    }
    HapticFeedback.mediumImpact();
    GameAudio.instance.playWorldSfx(SfxId.unlock, profile: _activeProfile);
    unawaited(WorldAudioDirector.instance.onAccusationUnlock());
    _recordMatchFeed(MatchHudCopy.accusationUnlockFeed(copy.facilityName));
    _maybeBackgroundCrisisAlert(
      kind: BackgroundCrisisKind.accusationUnlocked,
      title: copy.facilityName,
      body: copy.unlockLines.last,
    );
    final sites = _rt.accusationFacilityPositions;
    final active = _rt.activeAccusationSiteIndices;
    final siteIdx = active.isEmpty ? 0 : active.first;
    final pos = sites.isNotEmpty
        ? sites[siteIdx.clamp(0, sites.length - 1)]
        : _currentPosition;
    _emitMatchEvent(
      type: 'accusation_unlocked',
      message: '${copy.facilityName}: ${copy.unlockLines.last}',
      position: pos,
    );
  }

  Future<void> _promptAccusationAtSite(int siteIndex) async {
    if (_accusationPromptOpen) return;
    if (!canLocalPlayerAccuse(
      localRole: _localRole,
      accusationUnlocked: _rt.accusationUnlocked,
      accusationSpent: _rt.accusationSpentByMe,
      accusationPending: _rt.accusationAwaitingResolution,
      isEliminated: _isEliminatedSpectator,
      playerCount: _activeMatchPlayerCount,
    )) {
      return;
    }
    if (_isAccusationSiteBlockedByLiveHunter(siteIndex)) {
      _syncSetState(
        () => _statusMessage =
            '${MatchHudCopy.accusationFacilityBlocked} — '
            '${MatchHudCopy.accusationFacilityBlockedDetail}',
      );
      return;
    }
    if (!await OnboardingPrefs.accusationIntroSeen()) {
      await _maybeShowAccusationIntro();
      if (!mounted || _gameState != GameState.running) return;
    }
    if (_accusationPromptOpen) return;
    _accusationPromptOpen = true;
    await _openAccusationFlow(siteIndex: siteIndex);
  }

  int? _accusationSiteIndexInRange() {
    final sites = _rt.accusationFacilityPositions;
    if (sites.isEmpty) return null;
    var bestIdx = -1;
    var bestDist = double.infinity;
    for (final i in _rt.activeAccusationSiteIndices) {
      if (i < 0 || i >= sites.length) continue;
      final d = Geolocator.distanceBetween(
        _currentPosition.latitude,
        _currentPosition.longitude,
        sites[i].latitude,
        sites[i].longitude,
      );
      if (d <= GameConfig.accusationFacilityRadiusMeters && d < bestDist) {
        bestDist = d;
        bestIdx = i;
      }
    }
    return bestIdx >= 0 ? bestIdx : null;
  }

  void _evaluateAccusationFacility() {
    if (_rt.accusationFacilityPositions.isEmpty) return;
    if (!accusationEnabledForPlayerCount(_activeMatchPlayerCount)) return;

    if (!_rt.accusationUnlocked &&
        shouldUnlockAccusation(
          playerCount: _activeMatchPlayerCount,
          eliminationCount: _rt.syncedEliminationCount,
          elapsedSeconds: _rt.elapsedSeconds,
          matchDurationSeconds: _matchDurationSeconds,
        ) &&
        !_isOnlineFirestore) {
      _rt.activeAccusationSiteIndices =
          _computeActiveAccusationIndices(treatAsUnlocked: true);
      _applyAccusationUnlocked(null);
    }

    final siteIndex = _accusationSiteIndexInRange();
    if (siteIndex == null) {
      _accusationPromptOpen = false;
      return;
    }
    if (_accusationPromptOpen) return;
    if (!canLocalPlayerAccuse(
      localRole: _localRole,
      accusationUnlocked: _rt.accusationUnlocked,
      accusationSpent: _rt.accusationSpentByMe,
      accusationPending: _rt.accusationAwaitingResolution,
      isEliminated: _isEliminatedSpectator,
      playerCount: _activeMatchPlayerCount,
    )) {
      return;
    }
    if (_isAccusationSiteBlockedByLiveHunter(siteIndex)) {
      _syncSetState(
        () => _statusMessage =
            '${MatchHudCopy.accusationFacilityBlocked} — '
            '${MatchHudCopy.accusationFacilityBlockedDetail}',
      );
      return;
    }
    unawaited(_promptAccusationAtSite(siteIndex));
  }

  Future<void> _openAccusationFlow({required int siteIndex}) async {
    final assignments = _firestoreSession?.currentMatchStart?.assignments;
    if (assignments == null || assignments.isEmpty) {
      _accusationPromptOpen = false;
      return;
    }
    final myUid = _firestoreSession?.myUid;
    final copy = _accusationCopy;
    final candidates = <({String uid, String label, bool selectable, String? disabledReason})>[];
    for (final e in assignments.entries) {
      if (e.key == myUid) continue;
      final label = _displayNameForUid(e.key);
      if (e.value.role == PlayerRole.werewolf) {
        candidates.add((
          uid: e.key,
          label: label,
          selectable: false,
          disabledReason: MatchHudCopy.accusationWerewolfDisabled,
        ));
      } else {
        candidates.add((uid: e.key, label: label, selectable: true, disabledReason: null));
      }
    }
    if (!mounted) return;
    final picked = await showAccusationPlayerSheet(
      context: context,
      copy: copy,
      accusationWeight: _accusationWeight,
      candidates: candidates,
    );
    if (!mounted) {
      _accusationPromptOpen = false;
      return;
    }
    if (picked == null) {
      _accusationPromptOpen = false;
      return;
    }
    final label = _displayNameForUid(picked);
    final ok = await showAccusationConfirmDialog(
      context: context,
      targetLabel: label,
      copy: copy,
      accusationWeight: _accusationWeight,
    );
    if (!mounted || ok != true) {
      _accusationPromptOpen = false;
      return;
    }
    await _submitAccusation(accusedUid: picked, siteIndex: siteIndex);
    _accusationPromptOpen = false;
  }

  Future<void> _submitAccusation({
    required String accusedUid,
    required int siteIndex,
  }) async {
    if (_isAccusationSiteBlockedByLiveHunter(siteIndex)) {
      _toast(
        '${MatchHudCopy.accusationFacilityBlocked}。'
        '${MatchHudCopy.accusationFacilityBlockedDetail}',
      );
      return;
    }
    if (_isOnlineFirestore) {
      final fs = _firestoreSession;
      final sk = _matchEventSessionKey;
      if (fs != null && sk != null) {
        final err = await fs.publishRoomEvent(
          type: RoomMatchEventTypes.accusationAttempt,
          payload: {
            'accusedUid': accusedUid,
            'siteIndex': siteIndex,
            'lat': _currentPosition.latitude,
            'lng': _currentPosition.longitude,
          },
          sessionKey: sk,
        );
        if (err != null) {
          if (mounted) _toast(err);
          return;
        }
      }
      // 消費確定は解決イベント到達時。送信直後は待機フラグのみ。
      _syncSetState(() => _rt.accusationAwaitingResolution = true);
      if (_isHost) {
        _hostResolveAccusationAttempt(
          accuserUid: fs?.myUid ?? '',
          accusedUid: accusedUid,
        );
      }
    } else {
      _syncSetState(() {
        _rt.accusationSpentByMe = true;
        _rt.accusationAwaitingResolution = false;
      });
      _resolveAccusationLocally(accuserUid: 'local', accusedUid: accusedUid);
    }
  }

  void _hostResolveAccusationAttempt({
    required String accuserUid,
    required String accusedUid,
  }) {
    if (!_isHost || _gameState != GameState.running) return;
    _markLocalAccusationResolvedIfAccuser(accuserUid);
    final assignments =
        _firestoreSession?.currentMatchStart?.assignments ?? {};
    final copy = _accusationCopy;
    final kind = resolveAccusationOutcome(
      targetIsHunter: isAccusationTargetHunter(
        assignments: assignments,
        accusedUid: accusedUid,
      ),
      weight: _accusationWeight,
    );
    switch (kind) {
      case AccusationResolutionKind.successInstantWin:
        unawaited(WorldAudioDirector.instance.onAccusationSequence());
        _endGame(
          GameState.runnerWin,
          '${MatchHudCopy.accusationSuccess} — ${copy.facilityName}',
          endReason: MatchEndReason.accusationSuccess,
        );
      case AccusationResolutionKind.successEliminateOni:
        unawaited(_publishParticipantEliminatedByHost(
          uid: accusedUid,
          cause: 'accusation_hunter',
        ));
        _notifyAccusationSuccess(
          '${MatchHudCopy.accusationSuccess} — ${GuideTerms.trueOni}を脱落（試合継続）',
        );
      case AccusationResolutionKind.successPoints:
        _applyAccusationPointDelta(delta: 1);
        _notifyAccusationSuccess(
          '${MatchHudCopy.accusationSuccess} — ポイント ${_rt.accusationPointsHuman}',
        );
      case AccusationResolutionKind.failure:
        unawaited(_publishAccusationFailed(accuserUid: accuserUid));
        _applyAccusationFailureToAccuser(accuserUid);
    }
  }

  void _markLocalAccusationResolvedIfAccuser(String accuserUid) {
    final myUid = _firestoreSession?.myUid ?? 'local';
    if (accuserUid != myUid && accuserUid != 'local') return;
    if (!mounted) {
      _rt.accusationSpentByMe = true;
      _rt.accusationAwaitingResolution = false;
      return;
    }
    _syncSetState(() {
      _rt.accusationSpentByMe = true;
      _rt.accusationAwaitingResolution = false;
    });
  }

  void _resolveAccusationLocally({
    required String accuserUid,
    required String accusedUid,
  }) {
    final assignments =
        _firestoreSession?.currentMatchStart?.assignments ?? {};
    final kind = resolveAccusationOutcome(
      targetIsHunter: isAccusationTargetHunter(
        assignments: assignments,
        accusedUid: accusedUid,
      ),
      weight: _accusationWeight,
    );
    switch (kind) {
      case AccusationResolutionKind.successInstantWin:
        unawaited(WorldAudioDirector.instance.onAccusationSequence());
        _endGame(
          GameState.runnerWin,
          '${MatchHudCopy.accusationSuccess}（ローカル）',
          endReason: MatchEndReason.accusationSuccess,
          skipFirestoreSync: true,
        );
      case AccusationResolutionKind.successEliminateOni:
        if (accusedUid == _firestoreSession?.myUid ||
            accusedUid == 'local') {
          _eliminateLocalParticipant(
            '告発により脱落 — 復讐の鬼影として戦線に残る',
            cause: 'accusation_hunter',
          );
        } else {
          _eliminatedUids.add(accusedUid);
          _rt.syncedEliminationCount += 1;
        }
        _notifyAccusationSuccess(
          '${MatchHudCopy.accusationSuccess} — ${GuideTerms.trueOni}を脱落（試合継続）',
        );
      case AccusationResolutionKind.successPoints:
        _applyAccusationPointDelta(delta: 1);
        _notifyAccusationSuccess(
          '${MatchHudCopy.accusationSuccess} — ポイント ${_rt.accusationPointsHuman}',
        );
      case AccusationResolutionKind.failure:
        _applyAccusationFailureToAccuser(accuserUid);
    }
  }

  void _notifyAccusationSuccess(String message) {
    if (!mounted) return;
    final sites = _rt.accusationFacilityPositions;
    final active = _rt.activeAccusationSiteIndices;
    final siteIdx = active.isEmpty ? 0 : active.first;
    final pos = sites.isNotEmpty
        ? sites[siteIdx.clamp(0, sites.length - 1)]
        : _currentPosition;
    _emitMatchEvent(
      type: 'accusation_success',
      message: message,
      position: pos,
      syncFirestore: false,
    );
    _syncSetState(() => _statusMessage = message);
    _pushHudRevealAlert(message);
    _recordMatchFeed(message);
    HapticFeedback.heavyImpact();
    GameAudio.instance.playWorldSfx(SfxId.reveal, profile: _activeProfile);
  }

  void _applyAccusationPointDelta({required int delta}) {
    if (!mounted) return;
    _syncSetState(() => _rt.accusationPointsHuman += delta);
    if (_isOnlineFirestore && _isHost) {
      unawaited(_publishAccusationPointScored());
    }
  }

  Future<void> _publishAccusationPointScored() async {
    final fs = _firestoreSession;
    final sk = _matchEventSessionKey;
    if (fs == null || sk == null || !_isHost) return;
    await fs.publishHostRoomEvent(
      type: RoomMatchEventTypes.accusationPointScored,
      payload: {'total': _rt.accusationPointsHuman},
      sessionKey: sk,
    );
  }

  Map<String, dynamic> _eliminationPayloadForUid(
    String uid, {
    required String cause,
  }) {
    final participants = _matchParticipants();
    MatchParticipantState? pState;
    for (final p in participants) {
      if (p.uid == uid) {
        pState = p;
        break;
      }
    }
    final payload = <String, dynamic>{
      'uid': uid,
      'cause': cause,
      'playerLabel': _displayNameForUid(uid),
    };
    if (pState != null) {
      final faction = WerewolfFactionLogic.factionFor(
        assignmentRole: pState.assignmentRole,
        players: participants,
        uid: uid,
      );
      final rule = EliminationAftermathRule.forEliminatedFaction(
        matchDefault: _eliminationAftermathRule,
        factionAtDeath: faction,
      );
      payload['factionAtDeath'] = faction.name;
      payload['afterCatchRule'] = rule.name;
    }
    final remote = _remoteMembers[uid];
    if (remote?.lat != null && remote?.lng != null) {
      final pos = LatLng(remote!.lat!, remote.lng!);
      payload['lat'] = pos.latitude;
      payload['lng'] = pos.longitude;
      payload['overflowMeters'] = _playArea.overflowDistanceMeters(pos);
    }
    return payload;
  }

  Future<void> _publishParticipantEliminatedByHost({
    required String uid,
    required String cause,
  }) async {
    final fs = _firestoreSession;
    final sk = _matchEventSessionKey;
    if (fs == null || sk == null || !_isHost) return;
    await fs.publishHostRoomEvent(
      type: RoomMatchEventTypes.playerEliminated,
      payload: _eliminationPayloadForUid(uid, cause: cause),
      sessionKey: sk,
    );
  }

  void _applyAccusationFailureToAccuser(String accuserUid) {
    final myUid = _firestoreSession?.myUid ?? 'local';
    if (accuserUid != myUid && accuserUid != 'local') return;
    _markLocalAccusationResolvedIfAccuser(accuserUid);
    if (_accusationWeight.eliminatesAccuserOnFailure) {
      _eliminateLocalParticipant(
        '${MatchHudCopy.accusationFailed} — ${GuideTerms.echoForm}として戦線に残る',
        cause: 'accusation_failed',
      );
      _recordMatchFeed(MatchHudCopy.accusationFailedFeed);
      return;
    }
    if (!mounted) return;
    _syncSetState(() {
      _statusMessage = '${MatchHudCopy.accusationFailed} — ${MatchHudCopy.accusationSpent}';
    });
    _recordMatchFeed('${MatchHudCopy.accusationFailed} — ${MatchHudCopy.accusationSpent}');
  }

  Future<void> _publishAccusationFailed({required String accuserUid}) async {
    final fs = _firestoreSession;
    final sk = _matchEventSessionKey;
    if (fs == null || sk == null) return;
    final payload = {'accuserUid': accuserUid};
    if (_isHost) {
      await fs.publishHostRoomEvent(
        type: RoomMatchEventTypes.accusationFailed,
        payload: payload,
        sessionKey: sk,
      );
    } else {
      await fs.publishRoomEvent(
        type: RoomMatchEventTypes.accusationFailed,
        payload: payload,
        sessionKey: sk,
      );
    }
  }


  bool _isAccusationSiteBlockedByLiveHunter(int siteIndex) {
    if (!_rt.accusationUnlocked) return false;
    if (siteIndex < 0 || siteIndex >= _rt.accusationFacilityPositions.length) {
      return false;
    }
    final hunterUid = _hunterUidFromAssignments;
    if (hunterUid == null) return false;
    final facility = _rt.accusationFacilityPositions[siteIndex];
    LatLng? hunterPos;
    if (_localRole == PlayerRole.hunter) {
      hunterPos = _currentPosition;
    } else if (hunterUid == _firestoreSession?.myUid) {
      hunterPos = _currentPosition;
    } else {
      hunterPos = _resolvedPerceivedOniPosition(hunterUid);
    }
    return AccusationBlockLogic.isHunterBlockingSite(
      facilityPosition: facility,
      hunterPosition: hunterPos,
      hunterPositionKnown: hunterPos != null,
    );
  }

}
