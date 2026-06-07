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
    await _replayHistoricalMatchEvents(snap.gimmickSeed);
    if (!mounted) return;
    _startGameCore(rejoin: true);
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
    await _replayHistoricalMatchEvents(snap.gimmickSeed);
    if (!mounted) return;
    _startGameCore(rejoin: true, inspector: true);
    final fs = _firestoreSession;
    if (fs != null) {
      fs.startInspectorFeedListener();
      _bindInspectorFeed(fs);
    }
    _toast(toastMessage ?? 'インスペクターとして観戦中');
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
      unawaited(_enterRoomInspectorMode(snap, toastMessage: inspectorToast));
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
    for (final ev in events) {
      _onRemoteRoomMatchEvent(ev);
    }
  }
}
