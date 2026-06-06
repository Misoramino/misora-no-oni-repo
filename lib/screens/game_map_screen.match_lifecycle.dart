part of 'game_map_screen.dart';

/// 試合開始・終了・リセット・ティック評価・中止投票。
extension _GameMapMatchLifecycle on _GameMapScreenState {
  Future<void> _startGame() async {
    if (_gameState != GameState.waiting) {
      if (_gameState == GameState.running) return;
      _toast('新しい試合を始めるには「リセット」で結果を閉じてからにしてください');
      return;
    }
    if (_editingArea) {
      _toast('エリア編集中は開始できません');
      return;
    }
    if (_isOnlineFirestore && !_isHost) {
      _toast('試合の開始はホストのみできます');
      return;
    }

    _progressRecordedForMatch = false;
    _lastNewlyUnlockedTitles = const [];
    _matchRecorder?.discard();
    _matchRecorder = null;
    if (_trajectoryConsent) {
      _matchRecorder = MatchRecorder(
        playAreaSnapshot: _playArea,
        consentedToTrajectory: true,
        initialRunner: _currentPosition,
        initialOni: _oniPosition,
      );
    }

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
        googleMapsApiKey: _GameMapScreenState._googleMapsApiKey,
      );
      _rt.applyStartGimmicks(
        gimmicks: gimmicks,
        matchDurationSeconds: _matchDurationSeconds,
      );
    }

    _retuneGpsIfNeeded();
    _startGameCore();
  }

  void _startGameCore() {
    _processedRoomEventDocIds.clear();
    _eliminatedUids.clear();
    _factionAtDeath = null;
    _syncSetState(() {
      _gameState = GameState.running;
      _afterCatchRule = null;
      _statusMessage = RoleBriefingCatalog.matchStartStatusLine(_localRole);
      _controlSheetMode = ControlSheetMode.skillsOnly;
      _hudExpanded = false;
      _rt.showOniIntelCard = true;
      _abortVoteYesUids.clear();
      _abortProposalInitiatorUid = null;
      _abortProposalExpiresAt = null;
    });
    _abortProposalTimer?.cancel();
    _abortProposalTimer = null;
    _captureAcksByPlace.clear();
    _lastKnownHunterPositions.clear();
    _oniPathSamples.clear();
    _bodyThrowBroadcastActive = false;
    _oniMatchStartAnchor = null;
    if (_localRole == PlayerRole.hunter) {
      _oniMatchStartAnchor = _currentPosition;
    }
    if (_isOnlineFirestore) {
      final sk = _matchEventSessionKey;
      if (sk != null) {
        _firestoreSession?.startRoomEventsListener(sk);
      }
    }
    unawaited(_syncBleMatchContext());
    _retuneRenderPump();
    _emitMatchEvent(
      type: 'gimmicks_generated',
      message:
          'ギミック生成: 安全地帯${_rt.safeZonePositions.length} / 情報屋${_rt.infoBrokerPositions.length} / 監視カメラ${_rt.cameraPositions.length} / イベントエリア${_rt.commJammingZonePositions.length}',
      position: _playAreaAnchor,
    );
    _showRoleSkillDialog();
    _logDebug('match_start scale=${_timeScale}x online=$_isOnlineFirestore');
    HapticFeedback.selectionClick();
    SystemSound.play(SystemSoundType.click);
    GameAudio.instance.playSfx(SfxId.matchStart);
    GameAudio.instance.playMatchAmbient(_activeProfile);

    _matchTimer?.cancel();
    _matchTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted || !_isMatchStillActiveForLocalPlayer) return;
      if (_gameState == GameState.running) {
        _matchRecorder?.tryAppendOni(_oniPosition);
      }
      _syncSetState(() {
        _rt.remainingSeconds -= _timeScale;
        _rt.elapsedSeconds += _timeScale;
        if (_gameState == GameState.running) {
          _estimatedBatteryScore += _batteryCostPerSecond() * _timeScale;
        }
      });
      if (_rt.remainingSeconds <= 0) {
        if (_gameState == GameState.running) {
          _endGame(
            GameState.runnerWin,
            MatchTickEvaluator.endMessageFor(MatchTickAction.endRunnerWin),
            endReason: MatchEndReason.timeUp,
          );
        } else if (_isHost) {
          _endGame(
            GameState.runnerWin,
            MatchTickEvaluator.endMessageFor(MatchTickAction.endRunnerWin),
            endReason: MatchEndReason.timeUp,
          );
        }
        return;
      }
      if (_gameState == GameState.running) {
        _evaluateGame();
      } else {
        _evaluateEliminationAftermathCharges();
        _maybeHostPublishAccusationUnlock();
      }
      _retuneGpsIfNeeded();
    });
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
      googleMapsApiKey: _GameMapScreenState._googleMapsApiKey,
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
      _maybePublishHunterPosition(_currentPosition);
    }
  }

  void _resetGame({bool skipFirestoreSync = false}) {
    _matchTimer?.cancel();
    _cancelCaptureBoundTimers();
    _processedRoomEventDocIds.clear();
    _hostAccusationUnlockSent = false;
    _accusationPromptOpen = false;
    _matchRecorder?.discard();
    _matchRecorder = null;
    _finalizeRecordingFuture = null;
    _retuneGpsIfNeeded();
    _rt.resetToLobby(matchDurationSeconds: _matchDurationSeconds);
    _syncSetState(() {
      _gameState = GameState.waiting;
      _mapVisibleInLobby = false;
      _afterCatchRule = null;
      _statusMessage = 'リセットしました。開始ボタンでゲーム開始。';
      _prepControlSheetOpen = false;
      _abortVoteYesUids.clear();
      _abortProposalInitiatorUid = null;
      _abortProposalExpiresAt = null;
    });
    _abortProposalTimer?.cancel();
    _abortProposalTimer = null;
    _captureAcksByPlace.clear();
    _eliminatedUids.clear();
    _factionAtDeath = null;
    unawaited(_syncBleMatchContext());
    _retuneRenderPump();
    if (!skipFirestoreSync && _isOnlineFirestore && _isHost) {
      unawaited(_firestoreSession!.updateRoomPhase(RoomPhase.lobby));
    }
    _logDebug('match_reset');
  }

  void _showRoleSkillDialog() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _gameState != GameState.running) return;
      unawaited(
        showRoleBriefingDialog(
          context,
          role: _localRole,
          skillLabels: _skillLoadout.map(_skillLabelForUi).toList(),
          werewolfCurrentFaction: _localRole == PlayerRole.werewolf
              ? _localFactionNow()
              : null,
        ),
      );
    });
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
    if (_gameState != GameState.running) {
      _toast('ゲーム中のみ中止提案できます');
      return;
    }
    final sk = _matchEventSessionKey;
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
    if (!mounted || _gameState != GameState.running) return;
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
  }

  Future<void> _submitAbortVote(bool agree) async {
    final fs = _firestoreSession;
    final sk = _matchEventSessionKey;
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
    if (mounted) {
      _toast(agree ? '賛成を送信しました' : '反対を送信しました');
    }
  }

  void _handleAbortProposalEvent(RoomMatchEvent ev) {
    final ms = ev.payload['expiresAtMs'];
    if (ms is! num) return;
    final expiresAt = DateTime.fromMillisecondsSinceEpoch(ms.toInt());
    if (!expiresAt.isAfter(DateTime.now())) return;
    if (_abortProposalInitiatorUid == ev.actorUid &&
        _abortProposalExpiresAt != null &&
        _abortProposalExpiresAt!.isAfter(DateTime.now())) {
      return;
    }
    _beginAbortProposal(initiatorUid: ev.actorUid, expiresAt: expiresAt);
    if (!mounted || ev.actorUid == _firestoreSession?.myUid) return;
    unawaited(
      _showAbortVotePromptDialog(initiatorLabel: '他の参加者'),
    );
  }

  void _handleAbortVoteEvent(RoomMatchEvent ev) {
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
    if (_isHost) {
      _maybeFinalizeAbortVoteByMajority();
    }
  }

  void _maybeFinalizeAbortVoteByMajority() {
    if (!_isHost || !_isOnlineFirestore || _gameState != GameState.running) {
      return;
    }
    if (_abortProposalInitiatorUid == null) return;
    final n = _activeMatchPlayerCount;
    final need = (n ~/ 2) + 1;
    if (_abortVoteYesUids.length >= need) {
      _abortProposalTimer?.cancel();
      _abortProposalTimer = null;
      _abortProposalInitiatorUid = null;
      _abortProposalExpiresAt = null;
      _abortVoteYesUids.clear();
      _endGame(
        GameState.runnerWin,
        '参加者の過半数が賛成し、試合を中止しました',
        endReason: MatchEndReason.hostAbort,
      );
    }
  }

  Future<bool?> _showAbortVoteDialog() async {
    final requiredYes = (_mockPlayerCount ~/ 2) + 1;
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
              Text('参加者: $_mockPlayerCount人 / 必要同意: $requiredYes票'),
              const SizedBox(height: 8),
              Text('同意票(テスト): $yesVotes'),
              Slider(
                min: 0,
                max: _mockPlayerCount.toDouble(),
                divisions: _mockPlayerCount,
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
  }) {
    _matchTimer?.cancel();
    _cancelCaptureBoundTimers();
    final outcome = result;
    _afterCatchRule = null;
    _syncSetState(() {
      _gameState = result;
      _statusMessage = message;
      _prepControlSheetOpen = false;
    });
    HapticFeedback.mediumImpact();
    SystemSound.play(SystemSoundType.alert);
    final localFaction = _effectiveLocalFaction();
    final humanWon = result == GameState.runnerWin;
    final personalWin = (humanWon && localFaction == FactionSide.humanTeam) ||
        (!humanWon && localFaction == FactionSide.oniTeam);
    GameAudio.instance.playSfx(personalWin ? SfxId.matchWin : SfxId.matchLose);
    GameAudio.instance.playMenuBgm(_activeProfile);
    _logDebug('match_end outcome=${result.name}');
    _retuneGpsIfNeeded();
    _finalizeRecordingFuture = Future<void>.microtask(
      () => _finalizeMatchRecording(outcome),
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
    unawaited(_openMatchResultScreen());
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
    if (_gameState == GameState.caughtByOni) {
      _evaluateEliminationAftermathCharges();
      return;
    }
    if (_gameState != GameState.running) return;

    _advanceFakePositionDrift();
    _maybePeriodicAnonymousReveal();

    final distance = _distanceToOni();
    _proximityService.ingestGpsDistanceMeters(distance);
    _evaluateSafeZone();
    _evaluateInfoBroker(distance);
    _maybeHostPublishAccusationUnlock();
    _evaluateAccusationFacility();
    _maybeWerewolfForcedTransform();

    final effects = _matchCtrl.evaluateRunningTick(
      playArea: _playArea,
      playerPosition: _currentPosition,
      oniPosition: _oniPosition,
      testMode: _testMode,
      oniKnown: _remoteOniKnown,
      isHunterNow: _isPerceivedOniNow,
      runnerProximityActive:
          _chaseTargetsPresent && !_isPerceivedOniNow,
      applyRunnerOutsideRules:
          WerewolfFactionLogic.subjectToOniProximityRules(
            assignmentRole: _localRole,
            werewolfInOniForm: _rt.werewolfInOniForm,
          ),
      proximityBand: _latestProximityBand,
      proximityCapturePermitted: _proximityCapturePermittedForRunner(),
      now: DateTime.now(),
    );
    _applyMatchTickEffects(effects);
    _syncHunterBroadcastForBodyThrow();
    _updateDangerPulse();
    _maybeRefreshBleAdvertiseOnRoleChange();
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
            GameAudio.instance.playSfx(SfxId.capture);
            _eliminateLocalParticipant(message, cause: 'caught');
            return;
          }
          _endGame(state, message);
          return;
        case MatchStatusMessageEffect(:final message):
          _syncSetState(() => _statusMessage = message);
        case MatchConsumeSafeChargeEffect():
          break;
        case MatchAreaRevealEffect(:final overflowMeters):
          _triggerLocationReveal(overflowMeters);
        case MatchResetOutsideTrackingEffect():
          break;
        case MatchOniCueEffect(:final level):
          _emitOniCue(level: level);
          if (level == 'warning') {
            _logDebug('danger_warning_enter');
          } else if (level == 'danger') {
            _logDebug('danger_close_enter');
          }
        case MatchEmitEventEffect(:final type, :final message, :final position):
          _emitMatchEvent(type: type, message: message, position: position);
        case MatchLocationRevealEmitEffect(
          :final type,
          :final message,
          :final position,
        ):
          _emitLocationReveal(
            type: type,
            message: message,
            overridePosition: position,
          );
        case MatchInfectionPulseRevealEffect():
          _appendInfectionPulseReveal();
        case MatchInfectionExposureWarnEffect(:final level):
          if (_localRole == PlayerRole.hunter) break;
          final msg = level == 'imminent'
              ? 'まもなくパニック… このままだと名前のない痕跡が残ります'
              : '鬼が至近… 長くいるとパニックし、位置痕跡が出やすくなります';
          if (!mounted) break;
          _syncSetState(() => _statusMessage = msg);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(msg), duration: const Duration(seconds: 4)),
          );
        case MatchTouchLockStartEffect():
          HapticFeedback.mediumImpact();
          GameAudio.instance.playSfx(SfxId.skillCast);
        case MatchCameraSpottedEffect(:final message):
          if (!mounted) return;
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(message)));
          _emitAnonymousReveal(
            position: _currentPosition,
            pick: RevealReasonPool.cameraPick(),
            source: 'camera',
          );
      }
    }
  }

  void _updateOniHeadingFromPosition(LatLng pos, {double? deviceHeading}) {
    if (deviceHeading != null && deviceHeading >= 0 && deviceHeading <= 360) {
      _lastKnownOniHeadingDegrees = deviceHeading;
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
    _lastKnownOniHeadingDegrees = Geolocator.bearingBetween(
      prev.latitude,
      prev.longitude,
      pos.latitude,
      pos.longitude,
    );
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
