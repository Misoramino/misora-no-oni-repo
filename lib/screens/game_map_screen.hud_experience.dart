part of 'game_map_screen.dart';

/// HUD フェーズ表示・イベント履歴・第二ゲーム導入・トースト・条件文。
///
/// 装備スキル本体は `skills`、エリア編集は `play_area`。
extension _GameMapHudExperience on _GameMapScreenState {
  int _lobbyParticipantCount() {
    if (_isOnlineFirestore) {
      final fs = _firestoreSession;
      if (fs != null) {
        return math.max(1, fs.currentLobbyMembers.length);
      }
    }
    return 1;
  }

  String _prepSettingsSummaryLine() => MatchSetupSummary.prepSummaryLine(
        durationMinutes: _matchDurationSeconds / 60,
        gimmickDensity: _gimmickDensity,
        participantCount: _lobbyParticipantCount(),
      );

  String _rulesOverviewLineForLobby() => MatchSetupSummary.rulesOverviewLine(
        durationMinutes: _matchDurationSeconds / 60,
        accusationWeight: _accusationWeight,
        participantCount: _lobbyParticipantCount(),
        gimmickDensity: _gimmickDensity,
      );

  String? _matchPhaseLabel() {
    if (_gameState != GameState.running) return null;
    return MatchPhase.label(
      accusationUnlocked: _rt.accusationUnlocked,
      remainingSeconds: _rt.remainingSeconds,
      matchDurationSeconds: _matchDurationSeconds,
    );
  }

  void _recordMatchFeed(String message) {
    if (!mounted) return;
    _syncSetState(() => _matchEventFeedLine = message);
    _toast(message, duration: const Duration(seconds: 2));
  }

  Future<void> _maybeShowHostQuickPresetPicker() async {
    if (!_isHost || _gameState != GameState.waiting || !mounted) return;
    final prefs = await SharedPreferences.getInstance();
    final roomKey = _firestoreSession?.roomId ?? 'offline';
    if (prefs.getString(GameMapPrefs.hostQuickPresetPromptRoom) == roomKey) {
      return;
    }
    await prefs.setString(GameMapPrefs.hostQuickPresetPromptRoom, roomKey);
    if (!mounted || _gameState != GameState.waiting) return;
    final preset = await showMatchQuickPresetPicker(context);
    if (!mounted || preset == null) return;
    _applyQuickPreset(preset);
    _toast('${MatchSetupSummary.presetAppliedLabel(preset)} を適用しました');
  }

  void _applyQuickPreset(MatchQuickPreset preset) {
    _syncSetState(() {
      _matchDurationSeconds = (preset.durationMinutes.round() * 60).clamp(
        MatchDurationScaling.minMatchSeconds,
        MatchDurationScaling.maxMatchSeconds,
      );
      _gimmickDensity = preset.gimmickDensity.clamp(0.45, 1.55);
      if (_playArea.type == PlayAreaType.circle) {
        _playArea = preset.playAreaFromCenter(_playArea.center);
        _circleDraftCenter = _playArea.center;
        _circleDraftRadiusMeters = _playArea.radiusMeters;
      }
    });
    unawaited(
      SharedPreferences.getInstance().then((prefs) async {
        await prefs.setDouble(
          GameMapPrefs.gimmickDensity,
          _gimmickDensity,
        );
      }),
    );
    unawaited(_persistMatchDuration());
  }

  Future<void> _onSecondGameIntroAfterElimination() async {
    final rule = _afterCatchRule;
    if (rule == null || !mounted) return;
    _secondGameHighlightTimer?.cancel();
    _syncSetState(() => _secondGameIntroHighlight = true);
    _secondGameHighlightTimer = Timer(const Duration(seconds: 45), () {
      if (!mounted) return;
      _syncSetState(() => _secondGameIntroHighlight = false);
    });
    await showSecondGameIntroOverlay(
      context,
      rule: rule,
      worldProfile: _mapVisual.pack.profile,
    );
    if (!mounted) return;
    await offerSecondGameTutorialIfNeeded(context, rule: rule);
  }

  void _openSecondGameTutorialFromMatch() {
    final rule = _afterCatchRule;
    if (rule == null || !mounted) return;
    final kind = secondGameTutorialKindForRule(rule);
    if (kind == null) return;
    unawaited(openSecondGameTutorial(context, kind));
  }

  /// 初回で告発施設に入ったときのみ、使い方を1回だけ案内する。
  Future<void> _maybeShowAccusationIntro() async {
    if (!mounted || _gameState != GameState.running) return;
    if (await OnboardingPrefs.accusationIntroSeen()) return;

    final copy = _accusationCopy;
    await showAppDialog<void>(
      context: context,
      builder: (ctx) {
        final theme = Theme.of(ctx);
        return AppDialog(
          title: '告発施設: ${copy.facilityName}',
          icon: Icons.account_balance_outlined,
          actions: [
            AppDialogAction(
              label: '了解',
              onPressed: () => Navigator.pop(ctx),
            ),
          ],
          child: Text(
            AccusationIntroCopy.body(
              accuseActionLabel: copy.accuseActionLabel,
              weight: _accusationWeight,
            ),
            style: theme.textTheme.bodyMedium,
          ),
        );
      },
    );
    await OnboardingPrefs.markAccusationIntroSeen();
  }

  bool get _secondGameCanUseCameraJack =>
      _afterCatchRule?.supportsCameraJack == true;

  bool get _secondGameCanUseAccusationTerritory =>
      _afterCatchRule?.supportsSpectralTerritoryCharge == true;

  bool get _secondGameCanUseFacilitySabotage =>
      _afterCatchRule?.supportsFacilitySabotage == true;

  bool get _secondGameCanUseCameraShutdown =>
      _afterCatchRule?.supportsFacilitySabotage == true;


  Future<void> _clearTracePoints() async {
    if (_tracePoints.isEmpty &&
        _rt.revealLog.isEmpty &&
        _rt.anonymousRevealTraces.isEmpty &&
        _rt.oniIntelTraces.isEmpty) {
      _toast('痕跡はありません');
      return;
    }
    final ok = await _confirmDialog(
      title: '痕跡をクリア',
      message: '地図上の痕跡・暴露ログ・不明な痕跡・鬼情報トレースを消しますか？',
      confirmLabel: 'クリア',
    );
    if (!ok) return;
    _syncSetState(() {
      _tracePoints.clear();
      _rt.revealLog.clear();
      _rt.anonymousRevealTraces.clear();
      _rt.oniIntelTraces.clear();
      _statusMessage = '痕跡をクリアしました';
    });
  }

  Iterable<LocationRevealEvent> _recentRevealTraces() {
    final cutoff = DateTime.now().subtract(const Duration(minutes: 3));
    return _rt.revealLog.where((e) => e.timestamp.isAfter(cutoff)).take(12);
  }

  Iterable<OniIntelTrace> _recentOniIntelTraces() {
    final cutoff = DateTime.now().subtract(const Duration(minutes: 10));
    return _rt.oniIntelTraces
        .where((e) => e.timestamp.isAfter(cutoff))
        .take(12);
  }

  String _latestIntelLine() {
    final text = _rt.lastOniIntelText;
    final at = _rt.lastOniIntelAt;
    if (text == null || at == null) {
      return '鬼情報: 未入手（情報屋エリアで取得）';
    }
    final ageSeconds = DateTime.now().difference(at).inSeconds;
    if (ageSeconds < 60) {
      return '鬼情報: $text（$ageSeconds秒前）';
    }
    return '鬼情報: $text（${ageSeconds ~/ 60}分前）';
  }

  String? _accusationPhaseHudLine() {
    if (_gameState != GameState.running) return null;
    if (!accusationEnabledForPlayerCount(_activeMatchPlayerCount)) return null;
    if (_rt.accusationUnlocked) {
      final total = _rt.accusationFacilityPositions.length;
      final bonus = _rt.accusationTerritoryBonus;
      final bonusHint =
          bonus == 0 ? '' : ' · 陣取り${bonus > 0 ? '+' : ''}$bonus';
      return '告発: 解禁 — ${_accusationCopy.facilityName}（有効${_rt.activeAccusationSiteIndices.length}/${total > 0 ? total : "?"}箇所$bonusHint）';
    }
    final siteTotal = _rt.accusationFacilityPositions.length;
    final sec = secondsUntilAccusationUnlock(
      playerCount: _activeMatchPlayerCount,
      eliminationCount: _rt.syncedEliminationCount,
      elapsedSeconds: _rt.elapsedSeconds,
      remainingSeconds: _rt.remainingSeconds,
      matchDurationSeconds: _matchDurationSeconds,
    );
    if (sec == null) return null;
    final min = (sec / 60).ceil();
    final scaleHint = siteTotal > 0
        ? '（解禁時 有効1箇所・陣取りで増減）'
        : '';
    final elimMin = (MatchDurationScaling.accusationUnlockMinElapsedSeconds(
              _matchDurationSeconds,
            ) /
            60)
        .ceil();
    if (_rt.syncedEliminationCount < 1) {
      return '情報収集フェーズ — 告発は約$min分後（脱落1人+${elimMin}分、または試合60%）$scaleHint';
    }
    return '情報収集フェーズ — 告発は約$min分後（脱落後${elimMin}分経過で解禁）$scaleHint';
  }

  String? _conditionGuideCardId() {
    if (_gameState != GameState.running || _isEliminatedSpectator) {
      return null;
    }
    if (_rt.lockZoneBoundIds.contains('self') && _rt.lockZoneEndsAt != null) {
      return 'restraint';
    }
    if (_rt.touchLockNoticeShown && _rt.touchLockStartedAt != null) {
      return 'restraint';
    }
    if (_rt.isInfectedNow || _rt.infectionExposureSeconds > 0) {
      return 'panic';
    }
    if (_rt.fakePositionActive) {
      return 'anon_trace';
    }
    if (_rt.bodyThrowPosition != null) {
      return 'body_throw';
    }
    if (accusationEnabledForPlayerCount(_activeMatchPlayerCount) &&
        !_rt.accusationUnlocked) {
      return 'unlock';
    }
    if (accusationEnabledForPlayerCount(_activeMatchPlayerCount) &&
        canLocalPlayerAccuse(
          localRole: _localRole,
          accusationUnlocked: _rt.accusationUnlocked,
          accusationSpent: _rt.accusationSpentByMe,
          accusationPending: _rt.accusationAwaitingResolution,
          isEliminated: _isEliminatedSpectator,
          playerCount: _activeMatchPlayerCount,
        )) {
      return 'what';
    }
    return null;
  }

  void _openConditionGuide() {
    final cardId = _conditionGuideCardId();
    if (cardId == null) return;
    showHowToPlaySheet(
      context,
      yourRole: _localRole,
      initialGuideCardId: cardId,
    );
  }

  String _conditionLine() {
    if (_gameState == GameState.running &&
        _bleProximityIssue != null &&
        _bleProximityIssue!.isNotEmpty) {
      return _bleProximityIssue!;
    }
    final phase = _accusationPhaseHudLine();
    if (phase != null && _localRole == PlayerRole.runner && !_isEliminatedSpectator) {
      return phase;
    }
    if (_gameState == GameState.running &&
        _localRunnerModifier != RunnerModifier.none &&
        !_isEliminatedSpectator) {
      return '特化: ${_localRunnerModifier.label}';
    }
    // 告発できるのは逃走者のみ。鬼・人狼には告発ヒントを出さない。
    if (_gameState == GameState.running &&
        _localRole == PlayerRole.runner &&
        accusationEnabledForPlayerCount(_activeMatchPlayerCount) &&
        !_isEliminatedSpectator) {
      final copy = _accusationCopy;
      if (!_rt.accusationUnlocked) {
        return copy.lockedHint;
      }
      if (_rt.accusationSpentByMe) return '告発: この試合では使用済み';
      if (_rt.accusationAwaitingResolution) return '告発: 判定待ち…';
      if (canLocalPlayerAccuse(
        localRole: _localRole,
        accusationUnlocked: _rt.accusationUnlocked,
        accusationSpent: _rt.accusationSpentByMe,
        accusationPending: _rt.accusationAwaitingResolution,
        isEliminated: _isEliminatedSpectator,
        playerCount: _activeMatchPlayerCount,
      )) {
        return '告発: ${copy.facilityName} 付近で利用可';
      }
    }
    if (_rt.lockZoneBoundIds.contains('self') &&
        _rt.lockZoneEndsAt != null) {
      return '${MatchHudCopy.restraintLockStatusPrefix} '
          '${_secondsUntil(_rt.lockZoneEndsAt)}'
          '${MatchHudCopy.restraintLockStatusSuffix}';
    }
    if (_rt.touchLockNoticeShown && _rt.touchLockStartedAt != null) {
      final held = DateTime.now().difference(_rt.touchLockStartedAt!).inSeconds;
      final remain = (GameConfig.touchLockRequiredSeconds - held).clamp(0, 99);
      return '${MatchHudCopy.contactRingCountdownPrefix} $remain'
          '${MatchHudCopy.contactRingCountdownSuffix}';
    }
    if (_rt.isInfectedNow) {
      final fakeNote = _rt.fakePositionActive ? ' — 露出は偽位置側' : '';
      return '${MatchHudCopy.panicActiveCountdown(_secondsUntil(_rt.infectionEndsAt))}$fakeNote';
    }
    if (_localRole != PlayerRole.hunter && _rt.infectionExposureSeconds > 0) {
      final left =
          GameConfig.infectionExposureSeconds - _rt.infectionExposureSeconds;
      return '${MatchHudCopy.panicDangerCountdown(left)}';
    }
    if (_rt.fakePositionActive) {
      final left = _secondsUntil(_rt.fakePositionEndsAt);
      return '偽位置を展開中 残り$left秒 — 暴露されても、おとりの位置に表示されます';
    }
    if (_rt.bodyThrowPosition != null) {
      return _rt.bodyThrowOverdueRevealed
          ? '体投げ — 人形が未回収（位置が暴露済み・回収するまで他スキル不可）'
          : '体投げ — 人形が稼働中（回収するまで他スキル不可）';
    }
    return '異常なし（追跡・拘束を受けていません）';
  }

  String get _localPlayerLabel {
    final fs = _roomSession is FirestoreRoomSession
        ? _roomSession as FirestoreRoomSession
        : null;
    final fsName = fs?.nickname?.trim();
    if (fsName != null && fsName.isNotEmpty) return fsName;
    final local = _localNicknameOverride?.trim();
    if (local != null && local.isNotEmpty) return local;
    return 'player1';
  }

  Future<void> _loadLocalNicknameFromPrefs() async {
    final form = await SessionPrefs.loadForm();
    if (!mounted) return;
    _syncSetState(() {
      _localNicknameOverride = form.nickname;
    });
  }

  Future<void> _loadOniOperatorPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final s = OniOperatorPrefs.fromPrefs(prefs);
    if (!mounted) return;
    _syncSetState(() {
      _oniNotifyVibration = s.notifyVibration;
      _oniNotifySound = s.notifySound;
      _oniNotifyAggressive = s.notifyAggressive;
      _crisisNotifyVibration = s.crisisVibration;
      _crisisNotifyLocal = s.crisisNotification;
    });
  }

  void _emitOniCue({required String level}) {
    if (!_oniNotifyVibration && !_oniNotifySound) return;
    final aggressive = _oniNotifyAggressive;
    if (_oniNotifyVibration) {
      if (level == 'danger' || aggressive) {
        HapticFeedback.heavyImpact();
      } else {
        HapticFeedback.selectionClick();
      }
    }
    if (_oniNotifySound) {
      SystemSound.play(
        level == 'danger' ? SystemSoundType.alert : SystemSoundType.click,
      );
      GameAudio.instance.playSfx(
        level == 'danger' ? SfxId.proximityDanger : SfxId.proximityWarning,
      );
      unawaited(WorldAudioDirector.instance.setDangerActive(level == 'danger'));
    }
  }

  Offset _clampControlFabOffset(Offset? raw, Size screenSize) {
    const fabWidth = 132.0;
    const fabHeight = 64.0;
    final fallback = Offset(16, math.max(96, screenSize.height - 190));
    final next = raw ?? fallback;
    return Offset(
      next.dx.clamp(0.0, math.max(0, screenSize.width - fabWidth)),
      next.dy.clamp(72.0, math.max(72, screenSize.height - fabHeight - 16)),
    );
  }

  void _moveOniForTest() {
    if (_editingArea) {
      _toast('エリア編集中は使えません');
      return;
    }
    const step = 0.00035;
    _syncSetState(() {
      _oniPosition = LatLng(
        _oniPosition.latitude + step,
        _oniPosition.longitude - step,
      );
      _statusMessage = 'テスト用に鬼の位置を移動しました。';
    });
    _matchRecorder?.tryAppendOni(_oniPosition);
    _evaluateGame();
    _retuneGpsIfNeeded();
  }

  void _dismissInlineStatus() {
    _inlineStatusTimer?.cancel();
    _inlineStatusTimer = null;
    if (_inlineStatusMessage == null) return;
    _syncSetState(() => _inlineStatusMessage = null);
  }

  void _showInlineStatus(String msg, {Duration? duration}) {
    if (_inlineStatusMessage == msg && _inlineStatusTimer?.isActive == true) {
      return;
    }
    _inlineStatusTimer?.cancel();
    _syncSetState(() {
      _inlineStatusMessage = msg;
      _statusMessage = msg;
    });
    _inlineStatusTimer = Timer(
      duration ?? const Duration(seconds: 4),
      () {
        if (!mounted) return;
        _syncSetState(() => _inlineStatusMessage = null);
        _inlineStatusTimer = null;
      },
    );
    _logDebug('inline:$msg');
  }

  void _toast(
    String msg, {
    Duration? duration,
    bool forceSnackBar = false,
    bool denied = false,
  }) {
    if (denied && _gameState == GameState.running) {
      GameAudio.instance.playSfx(SfxId.denied);
    }
    final preferInline = !forceSnackBar && _gameState == GameState.waiting;
    if (preferInline) {
      _showInlineStatus(msg, duration: duration);
      return;
    }
    final messenger = ScaffoldMessenger.of(context);
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(
      SnackBar(
        content: Text(msg),
        duration:
            duration ??
            Duration(seconds: GameConfig.shortToastSeconds),
      ),
    );
    _logDebug('toast:$msg');
  }

  void _toastBodyThrowAreaHint() {
    final now = DateTime.now();
    if (_lastBodyThrowAreaToastAt != null &&
        now.difference(_lastBodyThrowAreaToastAt!).inMilliseconds < 1200) {
      return;
    }
    _lastBodyThrowAreaToastAt = now;
    _toast(
      'プレイエリア内に置いてください',
      duration: const Duration(milliseconds: 1400),
      denied: true,
    );
  }

}
