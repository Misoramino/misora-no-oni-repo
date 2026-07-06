part of 'game_map_screen.dart';

/// 試合開始・終了・リセット・ティック評価・中止投票。
extension _GameMapMatchLifecycle on _GameMapScreenState {
  /// 準備画面の「試合を開始」— 無効条件でも押下時に理由を表示する。
  Future<void> _onPrepStartPressed() async {
    if (!_isHost) {
      _toast('試合の開始はホストのみできます');
      return;
    }
    if (_isOnlineFirestore && !_isLobbyPlayAreaAppliedForStart()) {
      await _showMatchStartPlayAreaBlockDialog(
        'プレイエリアが適用されていません。マップから編集・保存し「選択エリアを適用」してください。',
      );
      return;
    }
    await _startGame();
  }

  Future<void> _startGame() async {
    if (_matchPresentationActive || _matchStartInFlight) return;
    if (_gameState != GameState.waiting) {
      if (_gameState == GameState.running) return;
      _toast('新しい試合を始めるには「リセット」で結果を閉じてからにしてください');
      return;
    }
    _matchStartInFlight = true;
    try {
      if (_editingArea) {
        _toast('エリア編集中は開始できません');
        return;
      }
      if (_isOnlineFirestore && !_isHost) {
        _toast('試合の開始はホストのみできます');
        return;
      }

      final playAreaOk = await _validatePlayAreaForMatchStart();
      if (!playAreaOk || !mounted) return;

      if (_isOnlineFirestore && _isHost) {
        final count = _lobbyParticipantCount();
        if (count < GameConfig.accusationMinPlayers) {
          final proceed = await showDialog<bool>(
            context: context,
            builder: (ctx) => AlertDialog(
              title: const Text('少人数で開始'),
              content: Text(
                '現在 $count 人です。'
                '${GameConfig.accusationMinPlayers}人未満の試合では告発は使えません。\n'
                'このまま開始しますか？',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx, false),
                  child: const Text('待つ'),
                ),
                FilledButton(
                  onPressed: () => Navigator.pop(ctx, true),
                  child: const Text('開始する'),
                ),
              ],
            ),
          );
          if (proceed != true || !mounted) return;
        }
        if (count > 1) {
          final notReady = _notReadyNonHostNicknames();
          if (notReady.isNotEmpty) {
            final proceed = await _confirmHostStartWithNotReadyPlayers(
              notReady,
            );
            if (!proceed || !mounted) return;
          }
        }
      }

      game_feedback.Feedback.confirm();
      unawaited(WorldAudioDirector.instance.beginMatchPresentation());
      _progressRecordedForMatch = false;
      _lastNewlyUnlockedTitles = const [];
      _matchRoleBriefingShown = false;
      _ensureMatchRecorder(discardExisting: true);

      if (_isOnlineFirestore && _isHost) {
        final snapshot = await _buildSharedMatchSnapshot();
        final err = await _firestoreSession!.publishMatchStart(snapshot);
        if (err != null) {
          _toast(err);
          return;
        }
        await _applySharedMatchStart(snapshot);
      } else {
        _assignDefaultSetupIfNeeded();
        final seed = DateTime.now().millisecondsSinceEpoch;
        final gimmicks = await GeneratedGimmicks.createForMatchStart(
          area: _playArea,
          seed: seed,
          density: _gimmickDensity,
          googleMapsApiKey: GoogleMapsConfig.apiKey,
        );
        _rt.applyStartGimmicks(
          gimmicks: gimmicks,
          matchDurationSeconds: _matchDurationSeconds,
        );
      }

      _retuneGpsIfNeeded();
      await _runMatchStartPresentation(rejoin: false, inspector: false);
      if (!mounted) return;
      _startGameCore();
      if (!mounted) return;
      await _runPostMatchStartOnboarding();
    } finally {
      _matchStartInFlight = false;
      _matchPresentationActive = false;
    }
  }

  void _startGameCore({bool rejoin = false, bool inspector = false}) {
    if (!rejoin) {
      _roomEventDeduper.clear();
      _eliminatedUids.clear();
    _absentSinceByUid.clear();
      _factionAtDeath = null;
    }
    _syncSetState(() {
      _gameState = GameState.running;
      _afterCatchRule = null;
      if (inspector) {
        _controlSheetMode = ControlSheetMode.hidden;
        _prepMapMode = PrepMapMode.browse;
        _statusMessage = '観戦モード — マップ・暴露イベントを閲覧中（操作不可）';
      } else {
        _statusMessage = rejoin
            ? '試合再参加 — ${_localRole.displayName}'
            : RoleBriefingCatalog.matchStartStatusLine(_localRole);
        _controlSheetMode = ControlSheetMode.skillsOnly;
      }
      _hudExpanded = false;
      _rt.showOniIntelCard = !inspector;
      _abortVoteYesUids.clear();
      _abortProposalInitiatorUid = null;
      _abortProposalExpiresAt = null;
    });
    _abortProposalTimer?.cancel();
    _abortProposalTimer = null;
    if (!inspector) {
      _wasActiveInCurrentOnlineMatch = true;
    }
    if (!rejoin) {
      _captureAcksByPlace.clear();
      _capturePlacedTargetsByPlace.clear();
      _lastKnownHunterPositions.clear();
      _oniPathSamples.clear();
      _hunterPathSamples.clear();
      _lastKnownAssignedHunterHeadingDegrees = null;
      _bodyThrowBroadcastActive = false;
      _oniMatchStartAnchor = null;
      if (_localRole == PlayerRole.hunter) {
        _oniMatchStartAnchor = _currentPosition;
      }
      if (!inspector && _localRole == PlayerRole.werewolf) {
        _rt.lastWerewolfTransformAt = DateTime.now();
      }
    }
    if (_isOnlineFirestore) {
      final sk = _matchEventSessionKey;
      if (sk != null) {
        _firestoreSession?.startRoomEventsListener(sk);
      }
    }
    if (_localRole == PlayerRole.hunter && !_isRoomInspector) {
      _maybePublishHunterPosition(_currentPosition, force: true);
    } else if (_localRole == PlayerRole.werewolf &&
        _rt.werewolfInOniForm &&
        !_isRoomInspector) {
      _maybePublishHunterPosition(_currentPosition, force: true);
    }
    if (_isOnlineFirestore) {
      unawaited(_bootstrapOnlineMatchEvents());
      _startOnlineEventSyncPump();
    }
    unawaited(_syncBleMatchContext());
    _retuneRenderPump();
    if (!rejoin) {
      _emitMatchEvent(
        type: 'gimmicks_generated',
        message:
            'ギミック生成: 安全地帯${_rt.safeZonePositions.length} / 情報屋${_rt.infoBrokerPositions.length} / 監視カメラ${_rt.cameraPositions.length} / 通信障害${_rt.commJammingZonePositions.length}',
        position: _playAreaAnchor,
      );
      _logDebug('match_start scale=${_timeScale}x online=$_isOnlineFirestore');
    } else {
      _logDebug(
        'match_rejoin scale=${_timeScale}x inspector=$inspector online=$_isOnlineFirestore',
      );
    }
    unawaited(
      WorldAudioDirector.instance.enter(
        WorldAudioState.match,
        profile: _activeProfile,
      ),
    );

    _matchTimer?.cancel();
    _matchTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted || !_isMatchStillActiveForLocalPlayer) return;
      if (_gameState == GameState.running && _activeMatchPlayerCount > 1) {
        _matchRecorder?.tryAppendOni(_oniPosition);
      }
      _syncSetState(() {
        if (_isOnlineFirestore) {
          final snap = _firestoreSession?.currentMatchStart;
          if (snap != null) {
            _syncMatchTimerFromSnapshot(snap);
          }
        } else {
          _rt.remainingSeconds -= _timeScale;
          _rt.elapsedSeconds += _timeScale;
        }
        if (_gameState == GameState.running) {
          _estimatedBatteryScore += _batteryCostPerSecond() * _timeScale;
        }
      });
      if (_gameState == GameState.running) {
        WorldAudioDirector.instance.onMatchTick(_rt.remainingSeconds);
      }
      if (_rt.remainingSeconds <= 0) {
        unawaited(_handleMatchTimeUp());
        return;
      }
      if (_gameState == GameState.running) {
        _evaluateGame();
        if (_isOnlineFirestore &&
            _isPerceivedOniNow &&
            !_isRoomInspector &&
            _rt.elapsedSeconds % 5 == 0) {
          _maybePublishHunterPosition(_currentPosition, force: true);
        }
      } else {
        _evaluateEliminationAftermathCharges();
        _maybePublishAccusationUnlock();
      }
      _retuneGpsIfNeeded();
      unawaited(_maybeAutoClaimHostIfAbsent());
      if (_isHost && !_appInBackground) {
        _maybeEliminateDisconnectedParticipants();
      } else if (!_isHost) {
        _maybeParticipantEliminateDisconnectedParticipants();
      }
    });
  }

  /// 2分間応答なしの参加者をホストが脱落扱いにする（復帰前なら猶予）。
  void _maybeEliminateDisconnectedParticipants() {
    if (!_isHost || !_isOnlineFirestore || _gameState != GameState.running) {
      return;
    }
    final fs = _firestoreSession;
    final snap = fs?.currentMatchStart;
    if (fs == null || snap == null) return;
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
      _eliminatedUids.add(uid);
      unawaited(
        _publishParticipantEliminatedByHost(
          uid: uid,
          cause: 'disconnect',
        ),
      );
    }
  }

  /// ホスト不在時に非ホストが時間切れ終了を担う。
  Future<void> _handleMatchTimeUp() async {
    if (!mounted || _gameState != GameState.running) return;
    if (_isHost) {
      _endGameForTimeUp();
      return;
    }
    if (!_isOnlineFirestore) return;
    final fs = _firestoreSession;
    if (fs == null) return;
    final now = DateTime.now().toUtc();
    final host = fs.hostMember;

    if (fs.isHostAbsent(now)) {
      if (_hostAbsentClaimInFlight) return;
      await _maybeAutoClaimHostIfAbsent();
      if (mounted && _isHost) {
        _endGameForTimeUp();
        return;
      }
    }

    if (HostPresenceStatus.unavailableForMatchEnd(host, now)) {
      await _attemptMatchEndRescue();
    }
  }

  /// ホストが通話中などで終了できないとき、非ホストが一度だけ時間切れ終了を発行。
  Future<void> _attemptMatchEndRescue() async {
    if (_matchEndRescueInFlight || _gameState != GameState.running) return;
    final fs = _firestoreSession;
    final sk = _matchEventSessionKey;
    if (fs == null || sk == null || fs.isHost) return;
    if (fs.currentPhase == RoomPhase.ended) return;
    if (_rt.remainingSeconds > 0) return;

    _matchEndRescueInFlight = true;
    try {
      final counts = WerewolfFactionLogic.countAliveFactions(
        players: _matchParticipants(),
      );
      final GameState outcome;
      final String message;
      final String endReason;
      if (counts.humanAlive == 0 && counts.oniAlive > 0) {
        outcome = GameState.caughtByOni;
        message = MatchHudCopy.matchEndAllHumansEliminated();
        endReason = MatchEndReason.allHumansEliminated;
      } else {
        outcome = GameState.runnerWin;
        message = MatchTickEvaluator.endMessageFor(MatchTickAction.endRunnerWin);
        endReason = MatchEndReason.timeUp;
      }
      final err = await fs.publishMatchEndRescue(
        idempotencyKey: HostLightRescueKeys.timeUp(sk),
        outcome: outcome,
        endReason: endReason,
        message: message,
        sessionKey: sk,
      );
      if (!mounted) return;
      if (err == null) {
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

  /// ホスト引継ぎ後に権限付き処理を再同期する。
  Future<void> _reconcileHostAuthorityAfterHandoff() async {
    if (!_isHost || !_isOnlineFirestore) return;
    final fs = _firestoreSession;
    final snap = fs?.currentMatchStart;
    if (fs == null || snap == null) return;
    if (_gameState != GameState.running &&
        _gameState != GameState.caughtByOni) {
      return;
    }
    _syncMatchTimerFromSnapshot(snap);
    _maybeEliminateDisconnectedParticipants();
    await _replayMissedMatchEventsOnResume();
    await _rebuildHostCaptureBindTimersFromEvents();
  }

  Future<void> _rebuildHostCaptureBindTimersFromEvents() async {
    if (!_isHost || !_isOnlineFirestore) return;
    final sk = _matchEventSessionKey;
    final fs = _firestoreSession;
    if (sk == null || fs == null) return;
    final events = await fs.fetchMatchEvents(sk);
    events.sort((a, b) => a.emittedAtMs.compareTo(b.emittedAtMs));
    for (final ev in events) {
      if (ev.type != RoomMatchEventTypes.captureZonePlaced) continue;
      final placeId = ev.payload['placeId'] as String?;
      if (placeId == null || _captureBoundTimers.containsKey(placeId)) {
        continue;
      }
      final cLat = ev.payload['centerLat'];
      final cLng = ev.payload['centerLng'];
      if (cLat is! num || cLng is! num) continue;
      _captureAcksByPlace.putIfAbsent(placeId, () => <String>{});
      _scheduleHostCaptureBoundOnce(
        placeId: placeId,
        center: LatLng(cLat.toDouble(), cLng.toDouble()),
      );
    }
  }

  /// ホストが一定時間オフラインのとき、参加メンバーが即座にホストを引き継ぐ。
  Future<void> _maybeAutoClaimHostIfAbsent() async {
    if (!_isOnlineFirestore || _isHost) return;
    final fs = _firestoreSession;
    if (fs == null) return;
    if (!fs.isHostAbsent(DateTime.now().toUtc())) return;
    if (_hostAbsentClaimInFlight) return;
    _hostAbsentClaimInFlight = true;
    try {
      final err = await fs.claimHostIfAbsent();
      if (!mounted) return;
      if (err == null) {
        _toast('ホストが不在のため、あなたがホストを引き継ぎました');
        await _reconcileHostAuthorityAfterHandoff();
        _syncSetState(() {});
      }
    } finally {
      _hostAbsentClaimInFlight = false;
    }
  }

  Future<GeneratedGimmicks> _gimmicksFromSnapshot(
    SharedMatchSnapshot snapshot,
  ) async {
    var gimmicks = GeneratedGimmicks.create(
      snapshot.playArea,
      seed: snapshot.gimmickSeed,
      density: snapshot.gimmickDensity,
    );
    if (snapshot.eventAreas != null) {
      gimmicks = gimmicks.copyWith(eventAreas: snapshot.eventAreas);
    }
    if (snapshot.accusationSites != null) {
      gimmicks = gimmicks.copyWith(
        accusationFacilities: snapshot.accusationSites,
      );
    }
    if (snapshot.cameraJackSites != null) {
      gimmicks = gimmicks.copyWith(cameraJackSites: snapshot.cameraJackSites);
    }
    return gimmicks;
  }

  Future<SharedMatchSnapshot> _buildSharedMatchSnapshot() async {
    final fs = _firestoreSession!;
    final seed = DateTime.now().millisecondsSinceEpoch;
    final rnd = math.Random(seed);
    final oniIntel = _customRuleMode
        ? _oniIntelMode
        : OniIntelMode.values[rnd.nextInt(OniIntelMode.values.length)];
    final aftermath = _customRuleMode
        ? _eliminationAftermathRule
        : EliminationAftermathRule.spectralOperative;
    final assignments = <String, SharedPlayerAssignment>{};
    final members = fs.currentLobbyMembers;
    if (members.isEmpty && fs.myUid != null) {
      assignments[fs.myUid!] = _assignmentForUid(
        fs.myUid!,
        null,
        rnd,
        isSelf: true,
      );
    } else {
      for (final m in members) {
        assignments[m.uid] = _assignmentForUid(
          m.uid,
          m,
          rnd,
          isSelf: m.uid == fs.myUid,
        );
      }
    }
    if (!_customRuleMode && assignments.length > 1) {
      if (_roleAssignMode == RoleAssignMode.counts) {
        assignByRoleCounts(
          assignments: assignments,
          rnd: rnd,
          hunterCount: _roleOniCount,
          werewolfCount: _roleWerewolfCount,
          skillsFor: (role) => _randomSkillsFor(role, rnd).toList(),
        );
      } else {
        ensureViableRoleMix(
          assignments: assignments,
          rnd: rnd,
          skillsFor: (role) => _randomSkillsFor(role, rnd).toList(),
        );
      }
      assignRunnerModifiers(assignments: assignments, rnd: rnd);
    }
    final gimmicks = await GeneratedGimmicks.createForMatchStart(
      area: _playArea,
      seed: seed,
      density: _gimmickDensity,
      googleMapsApiKey: GoogleMapsConfig.apiKey,
    );
    return SharedMatchSnapshot(
      gimmickSeed: seed,
      playArea: _playArea,
      matchDurationSeconds: _matchDurationSeconds,
      oniIntelMode: oniIntel,
      eliminationAftermathRule: aftermath,
      assignments: assignments,
      startedAtUtc: DateTime.now().toUtc().toIso8601String(),
      gimmickDensity: _gimmickDensity,
      eventAreas: gimmicks.eventAreas,
      accusationSites: gimmicks.accusationFacilities,
      cameraJackSites: gimmicks.cameraJackSites,
      accusationWeight: _accusationWeight,
    );
  }

  SharedPlayerAssignment _assignmentForUid(
    String uid,
    RoomMemberView? member,
    math.Random rnd, {
    required bool isSelf,
  }) {
    if (_customRuleMode) {
      if (isSelf) {
        return SharedPlayerAssignment(
          role: _localRole,
          skills: _skillLoadout.toList(),
        );
      }
      final fromPref = member?.preferredAssignment;
      if (fromPref != null) return fromPref;
    }
    final role =
        assignablePlayerRoles[rnd.nextInt(assignablePlayerRoles.length)];
    return SharedPlayerAssignment(
      role: role,
      skills: _randomSkillsFor(role, rnd).toList(),
    );
  }

  Future<void> _applySharedMatchStart(SharedMatchSnapshot snapshot) async {
    _boundMatchSessionKey = snapshot.gimmickSeed;
    _playArea = snapshot.playArea;
    _matchDurationSeconds = snapshot.matchDurationSeconds;
    _oniIntelMode = snapshot.oniIntelMode;
    _eliminationAftermathRule = snapshot.eliminationAftermathRule;
    _accusationWeight = snapshot.accusationWeight;
    final mine = snapshot.assignmentFor(_firestoreSession?.myUid);
    if (mine != null) {
      _localRole = mine.role;
      _skillLoadout = mine.skills.toSet();
      _localRunnerModifier = mine.modifier;
    }
    _hostAccusationUnlockSent = false;
    _participantAccusationUnlockSent = false;
    _hostLightRescueEmittedKeys.clear();
    _globallyBoundRunnerUids.clear();
    final gimmicks = await _gimmicksFromSnapshot(snapshot);
    _rt.applyStartGimmicks(
      gimmicks: gimmicks,
      matchDurationSeconds: snapshot.matchDurationSeconds,
    );
    if (_isOnlineFirestore) {
      _firestoreSession?.startRoomEventsListener(snapshot.gimmickSeed);
    }
    unawaited(_syncBleMatchContext());
    if (_localRole == PlayerRole.hunter) {
      _oniPosition = _currentPosition;
      _remoteOniKnown = true;
    }
    if (_isOnlineFirestore) {
      await _armMatchSync();
    }
  }

  void _resetGame({bool skipFirestoreSync = false}) {
    _disarmMatchSync();
    _stopOnlineEventSyncPump();
    _boundMatchSessionKey = null;
    _matchRoleBriefingShown = false;
    _matchTimer?.cancel();
    _cancelCaptureBoundTimers();
    _roomEventDeduper.clear();
    _hostAccusationUnlockSent = false;
    _participantAccusationUnlockSent = false;
    _hostLightRescueEmittedKeys.clear();
    _globallyBoundRunnerUids.clear();
    _accusationPromptOpen = false;
    _matchRecorder?.discard();
    _matchRecorder = null;
    _spectatorMatchRecorder?.discard();
    _spectatorMatchRecorder = null;
    _lastSpectatorRecord = null;
    _finalizeRecordingFuture = null;
    _retuneGpsIfNeeded();
    _rt.resetToLobby(matchDurationSeconds: _matchDurationSeconds);
    _matchPresentationActive = false;
    _matchStartInFlight = false;
    _wasActiveInCurrentOnlineMatch = false;
    _syncSetState(() {
      _gameState = GameState.waiting;
      _prepMapMode = PrepMapMode.hidden;
      _afterCatchRule = null;
      _isRoomInspector = false;
      _statusMessage = 'リセットしました。開始ボタンでゲーム開始。';
      _prepControlSheetOpen = false;
      _abortVoteYesUids.clear();
      _abortProposalInitiatorUid = null;
      _abortProposalExpiresAt = null;
    });
    _abortProposalTimer?.cancel();
    _abortProposalTimer = null;
    _captureAcksByPlace.clear();
    _capturePlacedTargetsByPlace.clear();
    _eliminatedUids.clear();
    _absentSinceByUid.clear();
    _factionAtDeath = null;
    _unbindInspectorFeed();
    _lobbyAreaProposals.clear();
    _inlineStatusTimer?.cancel();
    _inlineStatusMessage = null;
    _pendingRunningMatch = null;
    _matchStartWhileEditingPromptOpen = false;
    _clearLocalPrepReady();
    unawaited(_firestoreSession?.clearInspectorFeedPosition());
    unawaited(_syncBleMatchContext());
    _retuneRenderPump();
    if (!skipFirestoreSync && _isOnlineFirestore && _isHost) {
      unawaited(_firestoreSession!.updateRoomPhase(RoomPhase.lobby));
    }
    _logDebug('match_reset');
  }

  void _assignDefaultSetupIfNeeded() {
    if (_isOnlineFirestore) return;
    if (_customRuleMode) return;
    final seed = DateTime.now().millisecondsSinceEpoch;
    final rnd = math.Random(seed);
    const roles = assignablePlayerRoles;
    _localRole = roles[rnd.nextInt(roles.length)];
    _skillLoadout = _randomSkillsFor(_localRole, rnd);
    _oniIntelMode =
        OniIntelMode.values[rnd.nextInt(OniIntelMode.values.length)];
    _eliminationAftermathRule = EliminationAftermathRule.spectralOperative;
  }

  Set<String> _randomSkillsFor(PlayerRole role, math.Random rnd) {
    final list = skillCandidatesForRole(role).toList()..shuffle(rnd);
    return list.take(role == PlayerRole.hunter ? 2 : 1).toSet();
  }

  LatLng get _playAreaAnchor {
    switch (_playArea.type) {
      case PlayAreaType.circle:
        return _playArea.center;
      case PlayAreaType.polygon:
        return _playArea.points.isEmpty
            ? _currentPosition
            : _playArea.points.first;
    }
  }

  Future<void> _requestAbortByVote() async {
    if (_gameState != GameState.running && !_matchPresentationActive) {
      _toast('ゲーム中のみ中止提案できます');
      return;
    }
    final participantCount = _activeMatchPlayerCount;
    if (participantCount <= 1) {
      final ok = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('試合を中止'),
          content: const Text('参加者が1人のため、投票なしで試合を終了します。'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('キャンセル'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('中止する'),
            ),
          ],
        ),
      );
      if (!mounted || ok != true) return;
      _toast('試合を中止しました');
      if (_isOnlineFirestore && _isHost) {
        _abortMatch('ホストにより試合中止');
      } else {
        _resetGame();
      }
      return;
    }
      final sk = _activeMatchSessionKey;
      if (_isOnlineFirestore && sk != null) {
      final fs = _firestoreSession;
      if (fs == null) {
        _toast('ルームに接続していません');
        return;
      }
      final myUid = fs.myUid;
      if (myUid == null) return;

      if (_abortProposalInitiatorUid == null) {
        final expiresAt = DateTime.now().add(
          const Duration(seconds: GameConfig.abortProposalTimeoutSeconds),
        );
        final err = await fs.publishRoomEvent(
          type: RoomMatchEventTypes.abortProposal,
          payload: {'expiresAtMs': expiresAt.millisecondsSinceEpoch},
          sessionKey: sk,
        );
        if (err != null && mounted) {
          _toast(err);
          return;
        }
        _beginAbortProposal(initiatorUid: myUid, expiresAt: expiresAt);
      }

      await _showAbortVotePromptDialog(
        initiatorLabel: myUid == _abortProposalInitiatorUid
            ? 'あなた'
            : '他の参加者',
      );
      return;
    }

    final approved = await _showAbortVoteDialog();
    if (!mounted || approved == null) return;
    if (approved) {
      _toast('過半数同意で中止しました');
      _logDebug('abort_vote:approved');
      _resetGame();
    } else {
      _toast('中止提案は否決されました');
      _logDebug('abort_vote:rejected');
    }
  }

  void _beginAbortProposal({
    required String initiatorUid,
    required DateTime expiresAt,
  }) {
    _abortProposalInitiatorUid = initiatorUid;
    _abortProposalExpiresAt = expiresAt;
    _abortVoteYesUids.clear();
    _abortProposalTimer?.cancel();
    final wait = expiresAt.difference(DateTime.now());
    if (wait.isNegative) return;
    _abortProposalTimer = Timer(wait, _onAbortProposalTimedOut);
  }

  void _onAbortProposalTimedOut() {
    final roomRunning =
        _isOnlineFirestore &&
        _firestoreSession?.currentPhase == RoomPhase.running;
    if (!mounted ||
        (_gameState != GameState.running &&
            !_matchPresentationActive &&
            !roomRunning)) {
      return;
    }
    if (_abortProposalInitiatorUid == null) return;
    final initiator = _abortProposalInitiatorUid!;
    final n = _activeMatchPlayerCount;
    final need = (n ~/ 2) + 1;
    if (_abortVoteYesUids.length >= need) return;
    final fs = _firestoreSession;
    final isInitiator = fs?.myUid == initiator;
    _syncSetState(() {
      _abortProposalInitiatorUid = null;
      _abortProposalExpiresAt = null;
      _abortVoteYesUids.clear();
    });
    if (isInitiator) {
      _toast('試合中止は成立しませんでした（賛成が過半数に達しませんでした）');
    }
  }

  Future<void> _showAbortVotePromptDialog({required String initiatorLabel}) async {
    if (_abortVoteDialogShowing) return;
    _abortVoteDialogShowing = true;
    try {
    final n = _activeMatchPlayerCount;
    final need = (n ~/ 2) + 1;
    final expires = _abortProposalExpiresAt;
    final remainSec = expires == null
        ? GameConfig.abortProposalTimeoutSeconds
        : expires.difference(DateTime.now()).inSeconds.clamp(
            0,
            GameConfig.abortProposalTimeoutSeconds,
          );
    final choice = await showAppDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        final theme = Theme.of(ctx);
        return AppDialog(
          title: '試合中止の投票',
          icon: Icons.how_to_vote_rounded,
          accent: theme.colorScheme.error,
          actions: [
            AppDialogAction(
              label: '反対',
              filled: false,
              icon: Icons.thumb_down_alt_outlined,
              onPressed: () => Navigator.pop(ctx, 'no'),
            ),
            AppDialogAction(
              label: '賛成',
              icon: Icons.thumb_up_alt_rounded,
              onPressed: () => Navigator.pop(ctx, 'yes'),
            ),
          ],
          child: Text(
            '$initiatorLabel が試合中止を提案しました。\n'
            '賛成が試合参加者 $n 人の過半数（$need 票以上）で中止されます。\n'
            '残り時間: 約 $remainSec 秒\n'
            '現在の賛成: ${_abortVoteYesUids.length} 票',
            style: theme.textTheme.bodyMedium,
          ),
        );
      },
    );
    if (!mounted || choice == null) return;
    await _submitAbortVote(choice == 'yes');
    } finally {
      _abortVoteDialogShowing = false;
    }
  }

  Future<void> _submitAbortVote(bool agree) async {
    final fs = _firestoreSession;
    final sk = _activeMatchSessionKey;
    if (fs == null || sk == null) return;
    final err = await fs.publishRoomEvent(
      type: RoomMatchEventTypes.abortVote,
      payload: {'agree': agree},
      sessionKey: sk,
    );
    if (err != null && mounted) {
      _toast(err);
      return;
    }
    if (agree && mounted) {
      final uid = fs.myUid;
      if (uid != null) {
        _syncSetState(() => _abortVoteYesUids.add(uid));
        _maybeFinalizeAbortVoteByMajority();
      }
    }
    if (mounted) {
      _toast(agree ? '賛成を送信しました' : '反対を送信しました');
    }
  }

  void _handleAbortProposalEvent(RoomMatchEvent ev) {
    if (!_matchSyncArmed && _gameState == GameState.waiting) return;
    final ms = ev.payload['expiresAtMs'];
    if (ms is! num) return;
    final expiresAt = DateTime.fromMillisecondsSinceEpoch(ms.toInt());
    if (!expiresAt.isAfter(DateTime.now())) return;
    final myUid = _firestoreSession?.myUid;
    final existingInitiator = _abortProposalInitiatorUid;
    final existingExpires = _abortProposalExpiresAt;
    if (existingInitiator != null &&
        existingExpires != null &&
        existingExpires.isAfter(DateTime.now())) {
      if (expiresAt.isAfter(existingExpires)) {
        _abortProposalExpiresAt = expiresAt;
        _abortProposalTimer?.cancel();
        final wait = expiresAt.difference(DateTime.now());
        if (!wait.isNegative) {
          _abortProposalTimer = Timer(wait, _onAbortProposalTimedOut);
        }
      }
      if (mounted && myUid != null && ev.actorUid != myUid) {
        unawaited(
          _showAbortVotePromptDialog(initiatorLabel: '他の参加者'),
        );
      }
      return;
    }
    if (existingInitiator == ev.actorUid &&
        existingExpires != null &&
        existingExpires.isAfter(DateTime.now())) {
      return;
    }
    _beginAbortProposal(initiatorUid: ev.actorUid, expiresAt: expiresAt);
    if (!mounted || ev.actorUid == myUid) return;
    unawaited(
      _showAbortVotePromptDialog(initiatorLabel: '他の参加者'),
    );
  }

  void _handleAbortVoteEvent(RoomMatchEvent ev) {
    if (!_matchSyncArmed && _gameState == GameState.waiting) return;
    if (_abortProposalInitiatorUid == null) return;
    final agree = ev.payload['agree'] == true;
    if (!mounted) return;
    _syncSetState(() {
      if (agree) {
        _abortVoteYesUids.add(ev.actorUid);
      } else {
        _abortVoteYesUids.remove(ev.actorUid);
      }
    });
    _maybeFinalizeAbortVoteByMajority();
  }

  void _maybeFinalizeAbortVoteByMajority() {
    final roomRunning =
        _isOnlineFirestore &&
        _firestoreSession?.currentPhase == RoomPhase.running;
    if (!_isOnlineFirestore ||
        (_gameState != GameState.running &&
            !roomRunning &&
            !_matchSyncArmed)) {
      return;
    }
    final initiatorUid = _abortProposalInitiatorUid;
    if (initiatorUid == null) return;
    final n = _activeMatchPlayerCount;
    final need = (n ~/ 2) + 1;
    if (_abortVoteYesUids.length >= need) {
      _abortProposalTimer?.cancel();
      _abortProposalTimer = null;
      _abortProposalExpiresAt = null;
      final myUid = _firestoreSession?.myUid;
      final shouldPublish = _isHost || myUid == initiatorUid;
      _abortProposalInitiatorUid = null;
      _abortVoteYesUids.clear();
      if (shouldPublish) {
        unawaited(
          _finalizeAbortByMajority('参加者の過半数が賛成し、試合を中止しました'),
        );
      }
    }
  }

  Future<void> _finalizeAbortByMajority(String message) async {
    if (_abortMajorityFinalizeInFlight) return;
    _abortMajorityFinalizeInFlight = true;
    try {
      final fs = _firestoreSession;
      final sk = _matchEventSessionKey;
      if (_isOnlineFirestore && fs != null && sk != null) {
        await fs.publishRoomEvent(
          type: RoomMatchEventTypes.abortMajority,
          payload: {'message': message},
          sessionKey: sk,
        );
      }
      await _applyAbortMajority(message, fromSelf: true);
    } finally {
      _abortMajorityFinalizeInFlight = false;
    }
  }

  Future<void> _applyAbortMajority(
    String message, {
    required bool fromSelf,
  }) async {
    if (!fromSelf) {
      if (!_isHost) {
        await _claimHostIfAbsent();
      }
      if (_isHost) {
        _abortMatch(message);
      } else {
        if (_hostUnavailableForRescue()) {
          await _attemptAbortEndRescue(message);
        }
        _abortMatchLocalReset(message);
      }
      return;
    }
    if (!_isHost) {
      await _claimHostIfAbsent();
    }
    if (_isHost) {
      _abortMatch(message);
    } else {
      if (_hostUnavailableForRescue()) {
        await _attemptAbortEndRescue(message);
      }
      _abortMatchLocalReset(message);
    }
  }

  void _abortMatchLocalReset(String message) {
    _matchTimer?.cancel();
    _cancelCaptureBoundTimers();
    _afterCatchRule = null;
    _finalizeRecordingFuture = Future<void>.microtask(
      () => _finalizeMatchRecording(
        GameState.waiting,
        endReason: MatchEndReason.hostAbort,
        winningFaction: null,
      ),
    );
    _matchPresentationActive = false;
    _matchRoleBriefingShown = false;
    _syncSetState(() {
      _gameState = GameState.waiting;
      _statusMessage = message;
      _prepControlSheetOpen = false;
      _prepMapMode = PrepMapMode.hidden;
    });
    _retuneGpsIfNeeded();
    unawaited(
      WorldAudioDirector.instance.enter(
        WorldAudioState.returnTitle,
        profile: _activeProfile,
      ),
    );
  }

  void _endGameForTimeUp() {
    final counts = WerewolfFactionLogic.countAliveFactions(
      players: _matchParticipants(),
    );
    if (counts.humanAlive == 0 && counts.oniAlive > 0) {
      _endGame(
        GameState.caughtByOni,
        MatchHudCopy.matchEndAllHumansEliminated(),
        endReason: MatchEndReason.allHumansEliminated,
      );
      return;
    }
    _endGame(
      GameState.runnerWin,
      MatchTickEvaluator.endMessageFor(MatchTickAction.endRunnerWin),
      endReason: MatchEndReason.timeUp,
    );
  }

  void _maybeEndMatchForFactionElimination() {
    if (_gameState != GameState.running &&
        !(_gameState == GameState.caughtByOni && _afterCatchRule != null)) {
      return;
    }
    final counts = WerewolfFactionLogic.countAliveFactions(
      players: _matchParticipants(),
    );
    if (_isHost) {
      if (counts.humanAlive == 0) {
        _endGame(
          GameState.caughtByOni,
          counts.oniAlive > 0
              ? MatchHudCopy.matchEndAllHumansEliminated()
              : MatchHudCopy.matchEndAllHumansEliminated(),
          endReason: MatchEndReason.allHumansEliminated,
        );
        return;
      }
      if (counts.oniAlive == 0 && counts.humanAlive > 0) {
        _endGame(
          GameState.runnerWin,
          MatchHudCopy.matchEndOniEliminated(),
          endReason: MatchEndReason.oniEliminated,
        );
      }
      return;
    }
    unawaited(_maybeParticipantFactionEndRescue());
  }

  void _abortMatch(String message) {
    if (_isOnlineFirestore && _isHost) {
      unawaited(
        _firestoreSession!.publishMatchEnd(
          outcome: GameState.runnerWin,
          endReason: MatchEndReason.hostAbort,
          message: message,
        ),
      );
    }
    _abortMatchLocalReset(message);
  }

  Future<bool?> _showAbortVoteDialog() async {
    final participants = _isOnlineFirestore ? _activeMatchPlayerCount : 1;
    final requiredYes = (participants ~/ 2) + 1;
    int yesVotes = requiredYes;
    return showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => AlertDialog(
          title: const Text('試合中止の投票'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('参加者: $participants人 / 必要同意: $requiredYes票'),
              const SizedBox(height: 8),
              Text('同意票(テスト): $yesVotes'),
              Slider(
                min: 0,
                max: participants.toDouble(),
                divisions: participants,
                value: yesVotes.toDouble(),
                onChanged: (v) {
                  setModalState(() => yesVotes = v.round());
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, null),
              child: const Text('キャンセル'),
            ),
            OutlinedButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('否決'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, yesVotes >= requiredYes),
              child: const Text('投票確定'),
            ),
          ],
        ),
      ),
    );
  }

  void _endGame(
    GameState result,
    String message, {
    String? endReason,
    bool skipFirestoreSync = false,
    bool skipResultScreen = false,
  }) {
    _matchTimer?.cancel();
    _cancelCaptureBoundTimers();
    final outcome = result;
    _afterCatchRule = null;
    _matchPresentationActive = false;
    _matchStartInFlight = false;
    _syncSetState(() {
      _gameState = result;
      _statusMessage = message;
      _prepControlSheetOpen = false;
      _prepMapMode = PrepMapMode.browse;
    });
    HapticFeedback.mediumImpact();
    _logDebug('match_end outcome=${result.name}');
    _retuneGpsIfNeeded();
    if (!_isRoomInspector) {
      _emitMatchEvent(
        type: 'match_end',
        message: message,
        position: _currentPosition,
        syncFirestore: false,
      );
    }
    if (_isRoomInspector) {
      unawaited(() async {
        await _finalizeSpectatorRecording(outcome);
        if (mounted) await _openMatchResultScreen(spectator: true);
        if (mounted) {
          unawaited(
            WorldAudioDirector.instance.enter(
              WorldAudioState.resultSpectator,
              profile: _activeProfile,
            ),
          );
        }
      }());
      return;
    }
    _finalizeRecordingFuture = Future<void>.microtask(
      () => _finalizeMatchRecording(
        outcome,
        endReason: endReason,
        winningFaction: _winningFactionForEnd(outcome, endReason),
      ),
    );
    if (!skipFirestoreSync && _isOnlineFirestore && _isHost) {
      unawaited(
        _firestoreSession!.publishMatchEnd(
          outcome: result,
          endReason: endReason ?? _inferEndReason(result, message),
          message: message,
        ),
      );
    }
  if (skipResultScreen) {
      if (mounted) {
        unawaited(
          WorldAudioDirector.instance.enter(
            WorldAudioState.returnTitle,
            profile: _activeProfile,
          ),
        );
      }
      return;
    }
    unawaited(() async {
      await _playMatchEndFlash();
      if (mounted) {
        await _openMatchResultScreen(endReason: endReason);
      }
    }());
  }

  FactionSide? _winningFactionForEnd(GameState outcome, String? endReason) {
    return switch (endReason) {
      MatchEndReason.allHumansEliminated => FactionSide.oniTeam,
      MatchEndReason.oniEliminated ||
      MatchEndReason.accusationSuccess ||
      MatchEndReason.timeUp =>
        FactionSide.humanTeam,
      _ => outcome == GameState.runnerWin ? FactionSide.humanTeam : null,
    };
  }

  String _inferEndReason(GameState result, String message) {
    if (message.contains('ホストが試合を終了')) {
      return MatchEndReason.hostEnded;
    }
    return switch (result) {
      GameState.runnerWin => MatchEndReason.timeUp,
      GameState.caughtByOni => MatchEndReason.caught,
      _ => MatchEndReason.hostEnded,
    };
  }

  bool get _isMatchStillActiveForLocalPlayer =>
      _gameState == GameState.running ||
      (_gameState == GameState.caughtByOni && _afterCatchRule != null);

  void _evaluateGame() {
    if (_isRoomInspector) return;
    if (_gameState == GameState.caughtByOni) {
      _evaluateEliminationAftermathCharges();
      _maybePublishInspectorFeed();
      return;
    }
    if (_gameState != GameState.running) return;
    if (_appInBackground && _isOnlineFirestore) {
      _maybeWerewolfForcedTransform();
      _evaluateProximityWhileBackground();
      return;
    }
    if (_inResumeCatchUpGrace && _isOnlineFirestore) return;

    _advanceFakePositionDrift();
    _maybePeriodicAnonymousReveal();

    final distance = _distanceToOni();
    _proximityService.ingestGpsDistanceMeters(distance);
    _evaluateSafeZone();
    _evaluateInfoBroker();
    _maybePublishAccusationUnlock();
    _evaluateAccusationFacility();
    _maybeWerewolfForcedTransform();
    _maybeOniPublishProximityCaptures();

    final now = DateTime.now();
    _applyDueGimmickRelocates(now);
    _tickGimmickRelocateHintUi();

    final effects = _matchCtrl.evaluateRunningTick(
      playArea: _playArea,
      playerPosition: _currentPosition,
      oniPosition: _nearestPerceivedOniPosition,
      testMode: _testMode,
      oniKnown: _anyPerceivedOniPositionKnown,
      isHunterNow: _isPerceivedOniNow,
      runnerProximityActive:
          _chaseTargetsPresent && !_isPerceivedOniNow,
      applyOutsideAreaRules: _gameState == GameState.running,
      oniOutsideEndsMatch: _isPerceivedOniNow,
      proximityBand: _latestProximityBand,
      proximityCapturePermitted: _proximityCapturePermittedForRunner(),
      now: DateTime.now(),
    );
    _applyMatchTickEffects(effects);
    _syncHunterBroadcastForBodyThrow();
    _updateDangerPulse();
    _maybeRefreshBleAdvertiseOnRoleChange();
  }

  /// 通話アプリ前面・画面ロック中でも近接・捕獲・パニックと危機通知だけ継続する。
  ///
  /// スキル操作・告発 UI・ホスト専用処理は前面復帰まで待つ（[ _evaluateGame ] 側）。
  void _evaluateProximityWhileBackground() {
    if (_isRoomInspector) return;
    if (_gameState != GameState.running) return;
    if (!_isOnlineFirestore || !_appInBackground) return;
    if (_inResumeCatchUpGrace) return;

    final distance = _distanceToOni();
    _proximityService.ingestGpsDistanceMeters(distance);

    final effects = _matchCtrl.evaluateRunningTick(
      playArea: _playArea,
      playerPosition: _currentPosition,
      oniPosition: _nearestPerceivedOniPosition,
      testMode: _testMode,
      oniKnown: _anyPerceivedOniPositionKnown,
      isHunterNow: _isPerceivedOniNow,
      runnerProximityActive:
          _chaseTargetsPresent && !_isPerceivedOniNow,
      applyOutsideAreaRules: true,
      oniOutsideEndsMatch: _isPerceivedOniNow,
      proximityBand: _latestProximityBand,
      proximityCapturePermitted: _proximityCapturePermittedForRunner(),
      now: DateTime.now(),
    );
    _applyMatchTickEffects(effects);
  }

  void _applyMatchTickEffects(List<MatchTickEffect> effects) {
    for (final effect in effects) {
      switch (effect) {
        case MatchEndEffect(:final state, :final message, :final heavyHaptic):
          if (heavyHaptic) {
            HapticFeedback.heavyImpact();
          } else {
            HapticFeedback.mediumImpact();
          }
          if (state == GameState.caughtByOni) {
            GameAudio.instance.playWorldSfx(
              SfxId.capture,
              profile: _activeProfile,
            );
            _triggerCaptureMoment();
            final cause = message.contains(MatchTickEvaluator.outsideEliminationMarker)
                ? 'outside'
                : 'caught';
            _maybeBackgroundCrisisAlert(
              kind: BackgroundCrisisKind.eliminated,
              title: '捕獲されました',
              body: message,
            );
            _eliminateLocalParticipant(message, cause: cause);
            _maybeEndMatchForFactionElimination();
            return;
          }
          _maybeBackgroundCrisisAlert(
            kind: BackgroundCrisisKind.matchEnded,
            title: '試合終了',
            body: message,
          );
          _endGame(state, message);
          return;
        case MatchStatusMessageEffect(:final message):
          _syncSetState(() {
            _statusMessage = message;
            if (message.contains('偽情報暴露の配置をキャンセル')) {
              _skillPlacementPreviewLatLng = null;
            }
          });
        case MatchConsumeSafeChargeEffect():
          break;
        case MatchAreaRevealEffect(:final overflowMeters):
          _maybeBackgroundCrisisAlert(
            kind: BackgroundCrisisKind.outsideAreaReveal,
            title: MatchUiTerms.namedReveal,
            body: MatchHudCopy.namedRevealStatus(
              _localPlayerLabel,
              'エリア外',
            ),
          );
          _triggerLocationReveal(overflowMeters);
        case MatchResetOutsideTrackingEffect():
          break;
        case MatchOniCueEffect(:final level):
          _emitOniCue(level: level);
          if (level == 'warning') {
            _logDebug('danger_warning_enter');
            _maybeBackgroundCrisisAlert(
              kind: BackgroundCrisisKind.proximityWarning,
              title: '接触圏内',
              body: MatchHudCopy.contactRingEntered,
            );
          } else if (level == 'danger') {
            _logDebug('danger_close_enter');
            _maybeBackgroundCrisisAlert(
              kind: BackgroundCrisisKind.proximityDanger,
              title: 'ごく至近です',
              body: MatchHudCopy.panicExposureImminent,
            );
          }
        case MatchEmitEventEffect(:final type, :final message, :final position):
          if (type == 'panic_start') {
            _maybeBackgroundCrisisAlert(
              kind: BackgroundCrisisKind.panicStarted,
              title: 'パニック発生',
              body: message,
            );
          }
          _emitMatchEvent(type: type, message: message, position: position);
        case MatchLocationRevealEmitEffect(
          :final type,
          :final message,
          :final position,
        ):
          final escapeReason = message.contains(' — ')
              ? message.split(' — ').first
              : null;
          _emitLocationReveal(
            type: type,
            message: message,
            overridePosition: position,
            reasonSummary: escapeReason,
          );
        case MatchInfectionPulseRevealEffect():
          _maybeBackgroundCrisisAlert(
            kind: BackgroundCrisisKind.panicTrace,
            title: GuideTerms.anonTrace,
            body: MatchHudCopy.panicTraceSnack,
          );
          _appendInfectionPulseReveal();
        case MatchInfectionExposureWarnEffect(:final level):
          if (_localRole == PlayerRole.hunter) break;
          final msg = level == 'imminent'
              ? '${MatchHudCopy.panicExposureImminent} — '
                  '${MatchHudCopy.panicExposureImminentDetail}'
              : '${MatchHudCopy.panicExposureStart} — '
                  '${MatchHudCopy.panicExposureStartDetail}';
          _maybeBackgroundCrisisAlert(
            kind: level == 'imminent'
                ? BackgroundCrisisKind.panicImminent
                : BackgroundCrisisKind.panicWarning,
            title: level == 'imminent' ? 'パニック間近' : '鬼が近くにいます',
            body: msg,
          );
          if (!mounted) break;
          _syncSetState(() => _statusMessage = msg);
          if (_suppressMatchFeedback) break;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(msg), duration: const Duration(seconds: 4)),
          );
        case MatchTouchLockStartEffect():
          _maybeBackgroundCrisisAlert(
            kind: BackgroundCrisisKind.touchLock,
            title: '拘束されました',
            body: '円の外へ出ないと位置が暴露されます',
          );
          HapticFeedback.mediumImpact();
          GameAudio.instance.playSfx(SfxId.skillCast);
        case MatchCameraSpottedEffect(:final message):
          if (!mounted) return;
          _maybeBackgroundCrisisAlert(
            kind: BackgroundCrisisKind.panicTrace,
            title: '監視カメラ',
            body: message,
          );
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(message)));
          _emitAnonymousReveal(
            position: _positionForReveal,
            pick: RevealReasonPool.cameraPick(),
            source: 'camera',
          );
      }
    }
    _maybePublishInspectorFeed();
  }

  void _updateOniHeadingFromPosition(
    LatLng pos, {
    double? deviceHeading,
    bool updateAssignedHunter = false,
  }) {
    if (deviceHeading != null && deviceHeading >= 0 && deviceHeading <= 360) {
      _lastKnownOniHeadingDegrees = deviceHeading;
      if (updateAssignedHunter || _localRole == PlayerRole.hunter) {
        _lastKnownAssignedHunterHeadingDegrees = deviceHeading;
      }
      return;
    }
    final prev = _prevOniSampleForHeading;
    _prevOniSampleForHeading = pos;
    if (prev == null) return;
    final moved = Geolocator.distanceBetween(
      prev.latitude,
      prev.longitude,
      pos.latitude,
      pos.longitude,
    );
    if (moved < GameConfig.hackerHeadingMinMoveMeters) return;
    final bearing = Geolocator.bearingBetween(
      prev.latitude,
      prev.longitude,
      pos.latitude,
      pos.longitude,
    );
    _lastKnownOniHeadingDegrees = bearing;
    if (updateAssignedHunter || _localRole == PlayerRole.hunter) {
      _lastKnownAssignedHunterHeadingDegrees = bearing;
    }
  }

  AnonymousTraceSource _traceSourceFromKey(String source) {
    if (source == 'periodic') return AnonymousTraceSource.periodic;
    if (source == 'camera') return AnonymousTraceSource.camera;
    if (source == 'panic') return AnonymousTraceSource.panic;
    return AnonymousTraceSource.other;
  }

  bool get _isEliminatedSpectator =>
      _gameState == GameState.caughtByOni || _afterCatchRule != null;
}
