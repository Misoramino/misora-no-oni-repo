part of 'game_map_screen.dart';

/// ホストが background / stale のとき非ホストが担う救済（通話中プレイ向け）。
extension _GameMapHostLight on _GameMapScreenState {
  bool _hostUnavailableForRescue() {
    if (!_isOnlineFirestore) return false;
    final host = _firestoreSession?.hostMember;
    return HostPresenceStatus.unavailableForMatchEnd(
      host,
      DateTime.now().toUtc(),
    );
  }

  void _rememberHostLightRescueKey(String key) {
    _hostLightRescueEmittedKeys.add(key);
  }

  /// 告発解禁: ホスト優先、不通時は非ホストが一度だけ救済イベントを出す。
  void _maybePublishAccusationUnlock() {
    if (_isHost) {
      _maybeHostPublishAccusationUnlock();
      return;
    }
    _maybeParticipantPublishAccusationUnlock();
  }

  void _maybeParticipantPublishAccusationUnlock() {
    if (!_isOnlineFirestore || _isHost) return;
    if (_gameState != GameState.running || _rt.accusationUnlocked) return;
    if (_participantAccusationUnlockSent) return;
    if (!_hostUnavailableForRescue()) return;
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
    final sk = _matchEventSessionKey;
    if (sk == null) return;
    final key = HostLightRescueKeys.accusationUnlock(sk);
    if (_hostLightRescueEmittedKeys.contains(key)) return;
    _participantAccusationUnlockSent = true;
    final reason =
        _rt.syncedEliminationCount > 0 ? 'elimination' : 'time_ratio';
    final active = _computeActiveAccusationIndices();
    unawaited(
      _publishAccusationUnlockRescue(
        idempotencyKey: key,
        reason: reason,
        activeSiteIndices: active.toList(growable: false),
      ),
    );
  }

  Future<void> _publishAccusationUnlockRescue({
    required String idempotencyKey,
    required String reason,
    required List<int> activeSiteIndices,
  }) async {
    final fs = _firestoreSession;
    final sk = _matchEventSessionKey;
    if (fs == null || sk == null || fs.isHost) return;
    final err = await fs.publishHostLightRescueEvent(
      type: HostLightRescueEventTypes.accusationUnlockedRescue,
      idempotencyKey: idempotencyKey,
      payload: {
        'reason': reason,
        'activeSiteIndices': activeSiteIndices,
      },
      sessionKey: sk,
    );
    if (err == null) _rememberHostLightRescueKey(idempotencyKey);
    if (err != null && mounted) _toast(err);
  }

  /// 切断脱落: ホスト不通時のみ非ホストが担う。
  void _maybeParticipantEliminateDisconnectedParticipants() {
    if (_isHost || !_isOnlineFirestore || _gameState != GameState.running) {
      return;
    }
    if (!_hostUnavailableForRescue()) return;
    final fs = _firestoreSession;
    final snap = fs?.currentMatchStart;
    final sk = _matchEventSessionKey;
    if (fs == null || snap == null || sk == null) return;
    final now = DateTime.now().toUtc();
    final lobbyByUid = {
      for (final m in fs.currentLobbyMembers) m.uid: m,
    };
    for (final uid in snap.assignments.keys) {
      if (_eliminatedUids.contains(uid)) {
        _absentSinceByUid.remove(uid);
        continue;
      }
      final member = lobbyByUid[uid];
      final absent = member == null || member.isStale(now);
      if (!absent) {
        _absentSinceByUid.remove(uid);
        continue;
      }
      if (member != null && member.isInBackgroundGrace(now)) {
        _absentSinceByUid.remove(uid);
        continue;
      }
      final since = _absentSinceByUid.putIfAbsent(uid, () => now);
      if (now.difference(since).inSeconds <
          GameConfig.disconnectEliminationGraceSeconds) {
        continue;
      }
      _absentSinceByUid.remove(uid);
      final key = HostLightRescueKeys.disconnectElimination(sk, uid);
      if (_hostLightRescueEmittedKeys.contains(key)) continue;
      _rememberHostLightRescueKey(key);
      unawaited(
        _publishDisconnectEliminationRescue(uid: uid, idempotencyKey: key),
      );
    }
  }

  Future<void> _publishDisconnectEliminationRescue({
    required String uid,
    required String idempotencyKey,
  }) async {
    final fs = _firestoreSession;
    final sk = _matchEventSessionKey;
    if (fs == null || sk == null || fs.isHost) return;
    final err = await fs.publishHostLightRescueEvent(
      type: HostLightRescueEventTypes.playerEliminatedRescue,
      idempotencyKey: idempotencyKey,
      payload: {'uid': uid, 'cause': 'disconnect'},
      sessionKey: sk,
    );
    if (err != null && mounted) _toast(err);
  }

  /// 陣営全滅による終了: ホスト不通時は非ホストが match_end_rescue を担う。
  Future<void> _maybeParticipantFactionEndRescue() async {
    if (_isHost || !_isOnlineFirestore) return;
    if (_gameState != GameState.running &&
        !(_gameState == GameState.caughtByOni && _afterCatchRule != null)) {
      return;
    }
    if (!_hostUnavailableForRescue()) return;
    if (_matchEndRescueInFlight) return;
    final fs = _firestoreSession;
    final sk = _matchEventSessionKey;
    if (fs == null || sk == null || fs.currentPhase == RoomPhase.ended) return;

    final counts = WerewolfFactionLogic.countAliveFactions(
      players: _matchParticipants(),
    );
    if (counts.humanAlive == 0) {
      await _attemptFactionEndRescue(
        outcome: GameState.caughtByOni,
        endReason: MatchEndReason.allHumansEliminated,
        message: MatchHudCopy.matchEndAllHumansEliminated(),
        idempotencyKey: HostLightRescueKeys.factionEnd(
          sk,
          MatchEndReason.allHumansEliminated,
        ),
      );
      return;
    }
    if (counts.oniAlive == 0 && counts.humanAlive > 0) {
      await _attemptFactionEndRescue(
        outcome: GameState.runnerWin,
        endReason: MatchEndReason.oniEliminated,
        message: MatchHudCopy.matchEndOniEliminated(),
        idempotencyKey: HostLightRescueKeys.factionEnd(
          sk,
          MatchEndReason.oniEliminated,
        ),
      );
    }
  }

  Future<void> _attemptFactionEndRescue({
    required GameState outcome,
    required String endReason,
    required String message,
    required String idempotencyKey,
  }) async {
    if (_matchEndRescueInFlight || _gameState == GameState.waiting) return;
    final fs = _firestoreSession;
    final sk = _matchEventSessionKey;
    if (fs == null || sk == null || fs.isHost) return;
    if (_hostLightRescueEmittedKeys.contains(idempotencyKey)) return;
    _matchEndRescueInFlight = true;
    try {
      final err = await fs.publishMatchEndRescue(
        idempotencyKey: idempotencyKey,
        outcome: outcome,
        endReason: endReason,
        message: message,
        sessionKey: sk,
      );
      if (!mounted) return;
      if (err == null) {
        _rememberHostLightRescueKey(idempotencyKey);
        _endGame(
          outcome,
          message,
          endReason: endReason,
          skipFirestoreSync: true,
        );
      }
    } finally {
      _matchEndRescueInFlight = false;
    }
  }

  void _maybeScheduleCaptureBoundRescue({
    required String placeId,
    required LatLng center,
  }) {
    if (_isHost || !_isOnlineFirestore) return;
    if (!_hostUnavailableForRescue()) return;
    _scheduleCaptureBoundOnce(placeId: placeId, center: center);
  }

  /// 鬼が前面のとき、background 逃走者を Firestore イベントで捕獲できるようにする。
  void _maybeOniPublishProximityCaptures() {
    if (!_isOnlineFirestore || _appInBackground) return;
    if (_gameState != GameState.running) return;
    if (!_werewolfCanCaptureNow || !_isPerceivedOniNow) return;

    final fs = _firestoreSession;
    final sk = _matchEventSessionKey;
    final myUid = fs?.myUid;
    if (fs == null || sk == null || myUid == null) return;

    final participants = _matchParticipants();
    for (final member in fs.currentLobbyMembers) {
      if (member.uid == myUid) continue;
      if (_eliminatedUids.contains(member.uid)) continue;

      MatchParticipantState? pState;
      for (final p in participants) {
        if (p.uid == member.uid) {
          pState = p;
          break;
        }
      }
      if (pState == null) continue;
      if (!WerewolfFactionLogic.subjectToOniProximityRules(
        assignmentRole: pState.assignmentRole,
        werewolfInOniForm: pState.werewolfInOniForm,
      )) {
        continue;
      }
      if (WerewolfFactionLogic.perceivedRoleFor(pState) !=
          PerceivedRole.human) {
        continue;
      }

      final bound = _globallyBoundRunnerUids.contains(member.uid);
      final contact = member.proximityBand == ProximityBand.contact.name;

      var gpsCapture = false;
      final remote = _remoteMembers[member.uid];
      if (remote != null && remote.hasCoords) {
        final d = Geolocator.distanceBetween(
          _currentPosition.latitude,
          _currentPosition.longitude,
          remote.lat!,
          remote.lng!,
        );
        gpsCapture = d <= GameConfig.captureDistanceMeters;
      }

      if (!bound && !contact && !gpsCapture) continue;

      if (contact && !gpsCapture && !bound) {
        if (!WerewolfFactionLogic.proximityCapturePermittedForRunner(
          gpsDistanceToHunterMeters: double.infinity,
          captureDistanceMeters: GameConfig.captureDistanceMeters,
          bleContactBand: true,
          participants: participants,
          runnerUid: member.uid,
        )) {
          continue;
        }
      }

      final key = HostLightRescueKeys.oniCapture(sk, member.uid);
      if (_hostLightRescueEmittedKeys.contains(key)) continue;
      _rememberHostLightRescueKey(key);
      unawaited(
        _publishOniCaptureElimination(uid: member.uid, idempotencyKey: key),
      );
    }
  }

  Future<void> _publishOniCaptureElimination({
    required String uid,
    required String idempotencyKey,
  }) async {
    final fs = _firestoreSession;
    final sk = _matchEventSessionKey;
    if (fs == null || sk == null) return;
    final err = await fs.publishHostLightRescueEvent(
      type: HostLightRescueEventTypes.oniCaptureElimination,
      idempotencyKey: idempotencyKey,
      payload: {'uid': uid, 'cause': 'caught'},
      sessionKey: sk,
    );
    if (err != null && mounted) _toast(err);
  }

  void _recordGloballyBoundTargets(List<dynamic> rawTargets) {
    for (final t in rawTargets) {
      final uid = t.toString();
      if (uid.isNotEmpty) _globallyBoundRunnerUids.add(uid);
    }
  }
}
