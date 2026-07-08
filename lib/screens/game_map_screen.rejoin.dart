part of 'game_map_screen.dart';

/// 進行中試合への再参加・インスペクター（観戦）モード。
extension _GameMapRejoin on _GameMapScreenState {
  void _maybeSyncRunningMatchOnAttach(RoomMatchState rm) {
    if (!_isHost &&
        _editingArea &&
        rm.phase == RoomPhase.running &&
        rm.matchStart != null) {
      _pendingRunningMatch = rm;
      return;
    }
    _tryEnterRunningMatch(rm);
  }

  Future<void> _rejoinRunningMatch(
    SharedMatchSnapshot snap, {
    String? toastMessage,
  }) async {
    if (!mounted || _gameState != GameState.waiting) return;
    _dismissBlockingOverlaysForMatchJoin();
    _isRoomInspector = false;
    await _applySharedMatchStart(snap, armSync: false);
    if (!mounted || _gameState != GameState.waiting) return;
    _syncMatchTimerFromSnapshot(snap);
    _roomEventDeduper.clear();
    if (!mounted) return;
    _ensureMatchRecorder(discardExisting: true);
    final elapsed = _rt.elapsedSeconds;
    await _runCompactMatchStartPresentation(
      rejoin: elapsed > GameConfig.syncJoinFullPresentationMaxSeconds,
      inspector: false,
      elapsedSeconds: elapsed,
      remoteSyncJoin: true,
    );
    if (!mounted) return;
    _startGameCore(rejoin: true);
    unawaited(_runPostMatchStartOnboarding(rejoin: true));
    _rejoinRestoringEvents = true;
    await _replayHistoricalMatchEvents(snap.gimmickSeed);
    _rejoinRestoringEvents = false;
    _toast(toastMessage ?? '試合に再参加しました');
  }

  Future<void> _enterRoomInspectorMode(
    SharedMatchSnapshot snap, {
    String? toastMessage,
  }) async {
    if (!mounted || _gameState != GameState.waiting) return;
    _isRoomInspector = true;
    await _applySharedMatchStart(snap, armSync: false);
    if (!mounted || _gameState != GameState.waiting) return;
    _syncMatchTimerFromSnapshot(snap);
    _roomEventDeduper.clear();
    if (!mounted) return;
    final startedRaw = snap.startedAtUtc;
    final startedUtc = startedRaw != null
        ? DateTime.tryParse(startedRaw)?.toUtc()
        : null;
    _ensureSpectatorMatchRecorder(
      discardExisting: true,
      matchStartedAtUtc: startedUtc,
    );
    await _runMatchStartPresentation(
      rejoin: true,
      inspector: true,
      elapsedSeconds: _rt.elapsedSeconds,
    );
    if (!mounted) return;
    _startGameCore(rejoin: true, inspector: true);
    _rejoinRestoringEvents = true;
    await _replayHistoricalMatchEvents(snap.gimmickSeed);
    _rejoinRestoringEvents = false;
    final fs = _firestoreSession;
    if (fs != null) {
      fs.startInspectorFeedListener();
      _bindInspectorFeed(fs);
    }
    _toast(
      toastMessage ??
          '観戦モード — 全員の軌跡は観戦記録として保存されます',
    );
  }

  void _tryEnterRunningMatch(
    RoomMatchState rm, {
    String? playerToast,
    String? inspectorToast,
  }) {
    if (!_isOnlineFirestore || _gameState != GameState.waiting) return;
    if (rm.phase != RoomPhase.running || rm.matchStart == null) return;
    final snap = rm.matchStart!;
    final uid = _firestoreSession?.myUid;
    if (uid != null && snap.assignmentFor(uid) != null) {
      unawaited(_rejoinRunningMatch(snap, toastMessage: playerToast));
    } else {
      unawaited(_enterRoomInspectorMode(
        snap,
        toastMessage: inspectorToast ??
            '試合は既に開始済み — 観戦モードで参加します',
      ));
    }
  }

  void _syncMatchTimerFromSnapshot(SharedMatchSnapshot snap) {
    _rt.elapsedSeconds = MatchElapsedSync.elapsedSeconds(
      startedAtUtc: snap.startedAtUtc,
      matchDurationSeconds: snap.matchDurationSeconds,
    );
    _rt.remainingSeconds = MatchElapsedSync.remainingSeconds(
      startedAtUtc: snap.startedAtUtc,
      matchDurationSeconds: snap.matchDurationSeconds,
    );
  }

  Future<void> _replayHistoricalMatchEvents(int sessionKey) async {
    final fs = _firestoreSession;
    if (fs == null) return;
    final events = await fs.fetchMatchEvents(sessionKey);
    if (!mounted) return;
    events.sort((a, b) => a.emittedAtMs.compareTo(b.emittedAtMs));
    final myUid = fs.myUid;
    for (final ev in events) {
      if (ev.type == RoomMatchEventTypes.playerEliminated &&
          myUid != null &&
          (ev.payload['uid'] as String? ?? ev.actorUid) == myUid) {
        final cause = ev.payload['cause'] as String? ?? 'eliminated';
        final msg = cause == 'accusation_hunter'
            ? '告発により脱落 — 復讐の鬼影として戦線に残る'
            : '脱落 — 第二ゲームへ';
        _restoreLocalEliminationFromEvent(ev, message: msg);
        _roomEventDeduper.markIfNew(ev.id);
        continue;
      }
      _onRemoteRoomMatchEvent(ev);
    }
  }

  /// 終了済み試合に後から入った人向け — リザルトを出さずロビーへ。
  Future<void> _dismissStaleEndedRoom(SharedMatchEnd end) async {
    if (!mounted) return;
    _resetGame(skipFirestoreSync: true);
    if (_isHost) {
      await _firestoreSession?.updateRoomPhase(RoomPhase.lobby);
    }
    if (!mounted) return;
    _toast('前の試合は終了しています。新しい試合の準備ができます。');
  }
}
