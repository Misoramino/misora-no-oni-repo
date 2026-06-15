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
    final active = _computeActiveAccusationIndices();
    unawaited(
      _publishAccusationUnlocked(
        reason: reason,
        activeSiteIndices: active.toList(growable: false),
      ),
    );
  }

  Set<int> _computeActiveAccusationIndices() {
    final sites = _rt.accusationFacilityPositions;
    final seed = _firestoreSession?.currentMatchStart?.gimmickSeed ?? 0;
    final n = activeAccusationSiteCount(
      accusationUnlocked: _rt.accusationUnlocked,
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
      _rt.activeAccusationSiteIndices = raw
          .whereType<num>()
          .map((e) => e.toInt())
          .toSet();
    } else {
      _rt.activeAccusationSiteIndices = _computeActiveAccusationIndices();
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
    GameAudio.instance.playSfx(SfxId.unlock, profile: _activeProfile);
    _recordMatchFeed(MatchHudCopy.accusationUnlockFeed(copy.facilityName));
  }

  Future<void> _promptAccusationAtSite(int siteIndex) async {
    if (_accusationPromptOpen) return;
    if (!canLocalPlayerAccuse(
      localRole: _localRole,
      accusationUnlocked: _rt.accusationUnlocked,
      accusationSpent: _rt.accusationSpentByMe,
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
      _rt.activeAccusationSiteIndices = _computeActiveAccusationIndices();
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
    _syncSetState(() => _rt.accusationSpentByMe = true);
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
        if (err != null && mounted) _toast(err);
      }
      if (_isHost) {
        _hostResolveAccusationAttempt(
          accuserUid: fs?.myUid ?? '',
          accusedUid: accusedUid,
        );
      }
    } else {
      _resolveAccusationLocally(accuserUid: 'local', accusedUid: accusedUid);
    }
  }

  void _hostResolveAccusationAttempt({
    required String accuserUid,
    required String accusedUid,
  }) {
    if (!_isHost || _gameState != GameState.running) return;
    final assignments =
        _firestoreSession?.currentMatchStart?.assignments ?? {};
    final copy = _accusationCopy;
    final success = isAccusationTargetHunter(
      assignments: assignments,
      accusedUid: accusedUid,
    );
    if (success) {
      switch (_accusationWeight) {
        case AccusationWeight.instantWin:
          _endGame(
            GameState.runnerWin,
            '${MatchHudCopy.accusationSuccess} — ${copy.facilityName}',
            endReason: MatchEndReason.accusationSuccess,
          );
        case AccusationWeight.eliminateOni:
          unawaited(_publishParticipantEliminatedByHost(
            uid: accusedUid,
            cause: 'accusation_hunter',
          ));
          _notifyAccusationSuccess(
            '${MatchHudCopy.accusationSuccess} — ${GuideTerms.trueOni}を脱落（試合継続）',
          );
        case AccusationWeight.points:
          _applyAccusationPointDelta(delta: 1);
          _notifyAccusationSuccess(
            '${MatchHudCopy.accusationSuccess} — ポイント ${_rt.accusationPointsHuman}',
          );
      }
      return;
    }
    unawaited(_publishAccusationFailed(accuserUid: accuserUid));
    _applyAccusationFailureToAccuser(accuserUid);
  }

  void _resolveAccusationLocally({
    required String accuserUid,
    required String accusedUid,
  }) {
    final assignments =
        _firestoreSession?.currentMatchStart?.assignments ?? {};
    if (isAccusationTargetHunter(
      assignments: assignments,
      accusedUid: accusedUid,
    )) {
      switch (_accusationWeight) {
        case AccusationWeight.instantWin:
          _endGame(
            GameState.runnerWin,
            '${MatchHudCopy.accusationSuccess}（ローカル）',
            endReason: MatchEndReason.accusationSuccess,
            skipFirestoreSync: true,
          );
        case AccusationWeight.eliminateOni:
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
        case AccusationWeight.points:
          _applyAccusationPointDelta(delta: 1);
          _notifyAccusationSuccess(
            '${MatchHudCopy.accusationSuccess} — ポイント ${_rt.accusationPointsHuman}',
          );
      }
      return;
    }
    _applyAccusationFailureToAccuser(accuserUid);
  }

  void _notifyAccusationSuccess(String message) {
    if (!mounted) return;
    _syncSetState(() => _statusMessage = message);
    _pushHudRevealAlert(message);
    _recordMatchFeed(message);
    HapticFeedback.heavyImpact();
    GameAudio.instance.playSfx(SfxId.reveal, profile: _activeProfile);
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

  Future<void> _publishParticipantEliminatedByHost({
    required String uid,
    required String cause,
  }) async {
    final fs = _firestoreSession;
    final sk = _matchEventSessionKey;
    if (fs == null || sk == null || !_isHost) return;
    await fs.publishHostRoomEvent(
      type: RoomMatchEventTypes.playerEliminated,
      payload: {'uid': uid, 'cause': cause},
      sessionKey: sk,
    );
  }

  void _applyAccusationFailureToAccuser(String accuserUid) {
    final myUid = _firestoreSession?.myUid ?? 'local';
    if (accuserUid != myUid && accuserUid != 'local') return;
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
    if (_isHost) {
      await fs.publishHostRoomEvent(
        type: RoomMatchEventTypes.accusationFailed,
        payload: {'accuserUid': accuserUid},
        sessionKey: sk,
      );
    }
  }
}
