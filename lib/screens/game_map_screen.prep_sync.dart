part of 'game_map_screen.dart';

/// 準備完了・試合開始同期・バックグラウンド presence。
extension _GameMapPrepSync on _GameMapScreenState {
  bool get _appInBackground =>
      _appLifecycleState != AppLifecycleState.resumed;

  void _maybeBackgroundCrisisAlert({
    required BackgroundCrisisKind kind,
    required String title,
    required String body,
  }) {
    if (!_crisisNotifyVibration && !_crisisNotifyLocal) return;

    if (_suppressMatchFeedback) {
      _resumeCrisisCollector.record(kind: kind, title: title, body: body);
      return;
    }

    if (!_appInBackground) return;
    unawaited(
      BackgroundCrisisAlert.notify(
        kind: kind,
        title: title,
        body: body,
        vibrate: _crisisNotifyVibration,
        showNotification: _crisisNotifyLocal,
      ),
    );
  }

  void _presentResumeCrisisSummary() {
    if (_resumeCrisisCollector.isEmpty) return;
    final entries = _resumeCrisisCollector.drainPrioritized();
    if (entries.isEmpty || !mounted) return;

    final primary = entries.first;
    _showInlineStatus(
      primary.summaryLine,
      duration: const Duration(seconds: 5),
    );
    final countLine = entries.length > 1
        ? '通話中の出来事を反映しました（${entries.length}件）'
        : '通話中の出来事を反映しました';
    _toast(countLine);

    if (_crisisNotifyVibration || _crisisNotifyLocal) {
      unawaited(
        BackgroundCrisisAlert.notifyResumeSummary(
          title: '通話中の出来事',
          body: primary.summaryLine,
          vibrate: _crisisNotifyVibration,
          showNotification: _crisisNotifyLocal,
        ),
      );
    }
  }

  /// Firestore 上で試合が終了済みならローカル状態を同期（復帰時の取りこぼし対策）。
  bool _tryApplyRemoteRoomEnded({bool fromResume = false}) {
    if (!_isOnlineFirestore) return false;
    final rm = _firestoreSession?.currentRoomMatch;
    if (rm == null || rm.phase != RoomPhase.ended || rm.matchEnd == null) {
      return false;
    }
    final end = rm.matchEnd!;

    if (!_wasActiveInCurrentOnlineMatch && _gameState == GameState.waiting) {
      unawaited(_dismissStaleEndedRoom(end));
      return true;
    }

    if (_gameState == GameState.runnerWin) return true;

    if (!_isMatchStillActiveForLocalPlayer && !_wasActiveInCurrentOnlineMatch) {
      return false;
    }

    if (fromResume &&
        (_gameState == GameState.caughtByOni && _afterCatchRule == null)) {
      return true;
    }

    if (end.endReason == MatchEndReason.hostAbort) {
      _matchTimer?.cancel();
      _afterCatchRule = null;
      _finalizeRecordingFuture = Future<void>.microtask(
        () => _finalizeMatchRecording(
          GameState.waiting,
          endReason: MatchEndReason.hostAbort,
          winningFaction: null,
        ),
      );
      _syncSetState(() {
        _gameState = GameState.waiting;
        _statusMessage = end.message.isNotEmpty
            ? end.message
            : _messageForMatchEnd(end);
        _prepControlSheetOpen = true;
        _prepMapMode = PrepMapMode.hidden;
      });
      _wasActiveInCurrentOnlineMatch = false;
      unawaited(
        WorldAudioDirector.instance.enter(
          WorldAudioState.returnTitle,
          profile: _activeProfile,
        ),
      );
      return true;
    }

    _endGame(
      end.outcome,
      end.message.isNotEmpty ? end.message : _messageForMatchEnd(end),
      endReason: end.endReason,
      skipFirestoreSync: true,
    );
    return true;
  }

  Future<void> _maybeWarnBatterySaverOnResume() async {
    if (!mounted) return;
    final lowPower = await BatteryPowerMode.isLowPowerModeEnabled();
    if (!mounted || !lowPower) return;
    _toast('低電力モード中です — 位置更新・同期が遅れることがあります');
  }

  bool get _nonHostPrepLocked =>
      !_isHost &&
      _gameState == GameState.waiting &&
      _localPrepReady &&
      _isOnlineFirestore;

  int get _remotePrepReadyCount {
    if (!_isHost || !_isOnlineFirestore) return 0;
    final fs = _firestoreSession;
    if (fs == null) return 0;
    var count = 0;
    for (final m in fs.currentLobbyMembers) {
      if (!m.isSelf && m.prepReady) count++;
    }
    return count;
  }

  String? _prepReadySummaryLine() {
    if (!_isHost || !_isOnlineFirestore) return null;
    final total = _lobbyParticipantCount();
    if (total <= 1) return null;
    final ready = _remotePrepReadyCount;
    return '準備完了 $ready / ${total - 1} 人（ホスト除く）';
  }

  List<String> _notReadyNonHostNicknames() {
    if (!_isOnlineFirestore) return const [];
    final fs = _firestoreSession;
    if (fs == null) return const [];
    return [
      for (final m in fs.currentLobbyMembers)
        if (!m.isSelf && !m.prepReady)
          m.nickname.trim().isEmpty ? '参加者' : m.nickname.trim(),
    ];
  }

  Future<bool> _confirmHostStartWithNotReadyPlayers(
    List<String> notReady,
  ) async {
    if (!mounted || notReady.isEmpty) return true;
    final names = notReady.join('、');
    final result = await showAppDialog<bool>(
      context: context,
      builder: (ctx) => AppDialog(
        title: '未準備の参加者がいます',
        icon: Icons.hourglass_empty_rounded,
        actions: [
          AppDialogAction(
            label: '待つ',
            filled: false,
            onPressed: () => Navigator.pop(ctx, false),
          ),
          AppDialogAction(
            label: 'このまま開始',
            onPressed: () => Navigator.pop(ctx, true),
          ),
        ],
        child: Text(
          '準備完了を押していない参加者:\n$names\n\n'
          '全員が準備完了するまで待つなら、開始を見送ってください。',
        ),
      ),
    );
    return result ?? false;
  }

  void _dismissBlockingOverlaysForMatchJoin() {
    if (!mounted) return;
    Navigator.of(context).popUntil((route) => route is! PopupRoute);
  }

  Future<void> _replayMissedMatchEventsOnResume() async {
    if (!_isOnlineFirestore || !_isMatchStillActiveForLocalPlayer) return;
    final sk = _matchEventSessionKey;
    final fs = _firestoreSession;
    if (sk == null || fs == null) return;

    final events = await fs.fetchMatchEvents(sk);
    if (!mounted) return;
    events.sort((a, b) => a.emittedAtMs.compareTo(b.emittedAtMs));

    var applied = 0;
    _suppressMatchFeedback = true;
    try {
      for (final ev in events) {
        if (_roomEventDeduper.contains(ev.id)) continue;
        final before = _roomEventDeduper.length;
        _onRemoteRoomMatchEvent(ev);
        if (_roomEventDeduper.length > before) applied++;
      }
    } finally {
      _suppressMatchFeedback = false;
    }

    if (applied > 0 && mounted) {
      _publishMapOverlay(force: true);
    }
  }

  void _catchUpRunningTicksOnResume(DateTime pausedAtUtc) {
    if (_gameState != GameState.running) return;
    final delta = DateTime.now()
        .toUtc()
        .difference(pausedAtUtc)
        .inSeconds
        .clamp(0, 90);
    if (delta <= 1) return;

    _suppressMatchFeedback = true;
    try {
      for (var i = 0; i < delta; i++) {
        _evaluateGame();
      }
    } finally {
      _suppressMatchFeedback = false;
    }
  }

  void _catchUpGameStateOnResume() {
    if (!_isMatchStillActiveForLocalPlayer) {
      _backgroundPausedAtUtc = null;
      return;
    }

    final pausedAt = _backgroundPausedAtUtc;
    _backgroundPausedAtUtc = null;
    unawaited(_catchUpGameStateOnResumeAsync(pausedAt));
  }

  Future<void> _catchUpGameStateOnResumeAsync(DateTime? pausedAt) async {
    final resumeFlow = pausedAt != null;
    if (resumeFlow) {
      _resumeCatchUpUntilUtc = DateTime.now().toUtc().add(
        const Duration(seconds: GameConfig.resumeCatchUpGraceSeconds),
      );
      _showInlineStatus('同期中…', duration: const Duration(seconds: 8));
    }
    if (_tryApplyRemoteRoomEnded(fromResume: true)) {
      if (mounted && pausedAt != null) {
        _toast('試合は終了していました — 結果を確認してください');
      }
      _resumeCatchUpUntilUtc = null;
      return;
    }

    await _maybeWarnBatterySaverOnResume();
    if (!mounted) return;

    if (_isOnlineFirestore) {
      final snap = _firestoreSession?.currentMatchStart;
      if (snap != null) {
        _syncMatchTimerFromSnapshot(snap);
      }
    } else if (pausedAt != null) {
      final delta = DateTime.now()
          .toUtc()
          .difference(pausedAt)
          .inSeconds
          .clamp(0, _matchDurationSeconds);
      if (delta > 0) {
        _rt.elapsedSeconds = (_rt.elapsedSeconds + delta)
            .clamp(0, _matchDurationSeconds);
        _rt.remainingSeconds = (_matchDurationSeconds - _rt.elapsedSeconds)
            .clamp(0, _matchDurationSeconds);
      }
    }

    if (resumeFlow && _isOnlineFirestore) {
      if (mounted) {
        _showInlineStatus(
          '通話中の移動を反映しています',
          duration: const Duration(seconds: 8),
        );
      }
      await _replayMissedMatchEventsOnResume();
      if (mounted) _presentResumeCrisisSummary();
    } else if (resumeFlow && !_isOnlineFirestore) {
      _catchUpRunningTicksOnResume(pausedAt);
    }

    if (!mounted) return;
    _bindGpsSubscription(force: true);

    if (resumeFlow) {
      await Future<void>.delayed(const Duration(milliseconds: 1200));
      if (!mounted) return;
      _showInlineStatus(
        '最新の状態に追いつきました',
        duration: const Duration(seconds: 4),
      );
    }

    final until = _resumeCatchUpUntilUtc;
    if (until != null) {
      final wait = until.difference(DateTime.now().toUtc());
      if (wait.inMilliseconds > 0) {
        await Future<void>.delayed(wait);
      }
    }

    if (!mounted) return;
    _resumeCatchUpUntilUtc = null;

    if (_gameState == GameState.running) {
      _evaluateGame();
    } else if (_gameState == GameState.caughtByOni && _afterCatchRule != null) {
      _evaluateEliminationAftermathCharges();
    }

    if ((_gameState == GameState.running ||
            _gameState == GameState.caughtByOni) &&
        resumeFlow) {
      unawaited(_syncBleMatchContext(forceAdvertiseRestart: true));
    }
  }

  void _maybeCatchUpRunningMatch({String? toastMessage}) {
    if (!_isOnlineFirestore || _isHost || _gameState != GameState.waiting) {
      return;
    }
    if (_editingArea) return;
    final fs = _firestoreSession;
    if (fs == null) return;
    final rm = _pendingRunningMatch ?? fs.currentRoomMatch;
    if (rm.phase != RoomPhase.running || rm.matchStart == null) return;
    _pendingRunningMatch = null;
    _matchStartWhileEditingPromptOpen = false;
    _tryEnterRunningMatch(
      rm,
      playerToast: toastMessage ?? '試合に参加しました',
    );
  }

  Future<void> _promptJoinMatchAfterAreaEdit() async {
    if (!mounted || _isHost || _gameState != GameState.waiting) return;
    if (!_editingArea || _matchStartWhileEditingPromptOpen) return;
    _matchStartWhileEditingPromptOpen = true;
    final join = await showAppDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AppDialog(
        title: '試合が開始されました',
        icon: Icons.play_circle_fill_rounded,
        actions: [
          AppDialogAction(
            label: '編集を続ける',
            filled: false,
            onPressed: () => Navigator.pop(ctx, false),
          ),
          AppDialogAction(
            label: '終了して参加',
            onPressed: () => Navigator.pop(ctx, true),
          ),
        ],
        child: const Text(
          'ホストが試合を開始しました。\n'
          'エリア編集を終了すると、カウントダウンと役職案内のあと試合に参加できます。',
        ),
      ),
    );
    _matchStartWhileEditingPromptOpen = false;
    if (!mounted) return;
    if (join == true) {
      if (_editingArea) {
        _leavePrepMapToPanel();
      }
      _maybeCatchUpRunningMatch(
        toastMessage: 'ホストが試合を開始しました',
      );
    }
  }

  Future<void> _toggleLocalPrepReady() async {
    if (_isHost || _gameState != GameState.waiting) return;
    final next = !_localPrepReady;
    _syncSetState(() => _localPrepReady = next);
    final fs = _firestoreSession;
    if (fs != null) {
      await fs.publishPrepReady(next);
    }
    _toast(next ? '準備完了 — ホストの開始を待っています' : '準備完了を解除しました');
  }

  void _clearLocalPrepReady({bool publish = true}) {
    if (!_localPrepReady) return;
    _localPrepReady = false;
    if (publish) {
      unawaited(_firestoreSession?.publishPrepReady(false));
    }
  }

  bool _blockIfNonHostPrepLocked(String actionLabel) {
    if (!_nonHostPrepLocked) return false;
    _toast('準備完了中は$actionLabelできません。解除してから操作してください。');
    return true;
  }

  void _publishBackgroundIfMatchRunning() {
    if (!_isOnlineFirestore) return;
    final fs = _firestoreSession;
    if (fs == null) return;
    if (_gameState == GameState.running ||
        _gameState == GameState.caughtByOni) {
      unawaited(fs.publishAppLifecycle(background: true));
    } else if (_gameState == GameState.waiting) {
      unawaited(fs.publishPresence(tension: false));
    }
  }

  void _publishResumePresence() {
    if (!_isOnlineFirestore) return;
    final fs = _firestoreSession;
    if (fs == null) return;
    if (_gameState == GameState.running ||
        _gameState == GameState.caughtByOni) {
      unawaited(fs.publishAppLifecycle(background: false));
    } else {
      unawaited(fs.publishPresence(tension: false));
    }
  }

  Future<void> _maybeShowMatchPlayabilityHints() async {
    if (!mounted) return;
    await showMatchPlayabilityHintsIfNeeded(
      context,
      locationService: _locationService,
    );
  }

  /// 快適プレイ案内 → HUDコーチマークを順番に表示（重なり防止）。
  Future<void> _runPostMatchStartOnboarding() async {
    await _maybeShowMatchPlayabilityHints();
    if (!mounted || _gameState != GameState.running) return;
    await _maybeShowMatchCoachMarks();
  }
}
