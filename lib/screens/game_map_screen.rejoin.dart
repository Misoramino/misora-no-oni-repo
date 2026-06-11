part of 'game_map_screen.dart';

/// 進行中試合への再参加・インスペクター（観戦）モード。
extension _GameMapRejoin on _GameMapScreenState {
  void _maybeSyncRunningMatchOnAttach(RoomMatchState rm) {
    _tryEnterRunningMatch(rm);
  }

  Future<void> _rejoinRunningMatch(
    SharedMatchSnapshot snap, {
    String? toastMessage,
  }) async {
    if (!mounted || _gameState != GameState.waiting) return;
    _isRoomInspector = false;
    await _applySharedMatchStart(snap);
    if (!mounted || _gameState != GameState.waiting) return;
    _syncMatchTimerFromSnapshot(snap);
    _processedRoomEventDocIds.clear();
    if (!mounted) return;
    _ensureMatchRecorder(discardExisting: true);
    await _runMatchStartPresentation(
      rejoin: true,
      inspector: false,
      elapsedSeconds: _rt.elapsedSeconds,
    );
    if (!mounted) return;
    _startGameCore(rejoin: true);
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
    await _applySharedMatchStart(snap);
    if (!mounted || _gameState != GameState.waiting) return;
    _syncMatchTimerFromSnapshot(snap);
    _processedRoomEventDocIds.clear();
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
    final startedRaw = snap.startedAtUtc;
    if (startedRaw == null) return;
    final started = DateTime.tryParse(startedRaw);
    if (started == null) return;
    final elapsed = DateTime.now()
        .toUtc()
        .difference(started.toUtc())
        .inSeconds
        .clamp(0, snap.matchDurationSeconds);
    _rt.elapsedSeconds = elapsed;
    _rt.remainingSeconds = (snap.matchDurationSeconds - elapsed)
        .clamp(0, snap.matchDurationSeconds);
  }

  Future<void> _replayHistoricalMatchEvents(int sessionKey) async {
    final fs = _firestoreSession;
    if (fs == null) return;
    final events = await fs.fetchMatchEvents(sessionKey);
    if (!mounted) return;
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
        _processedRoomEventDocIds.add(ev.id);
        continue;
      }
      _onRemoteRoomMatchEvent(ev);
    }
  }
}
