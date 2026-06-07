part of 'game_map_screen.dart';

/// プレイエリアの読込・編集・保存・ロビー共有。
extension _GameMapPlayArea on _GameMapScreenState {
  Future<void> _loadSavedArea() async {
    final saved = await _areaStore.load();
    if (!mounted || saved == null) return;
    _syncSetState(() {
      _playArea = saved;
      if (_playArea.type == PlayAreaType.circle) {
        _circleDraftCenter = _playArea.center;
        _circleDraftRadiusMeters = _playArea.radiusMeters;
      }
      _statusMessage = '前回ホスト適用済みのプレイエリアを読み込みました';
    });
  }

  Future<void> _loadPlayAreaSlots() async {
    final slots = await _areaSlotStore.loadAll();
    if (!mounted) return;
    _syncSetState(() {
      _savedPlayAreas = slots;
      _selectedPlayAreaSlotId ??= slots.isNotEmpty ? slots.first.id : null;
    });
  }

  Future<bool> _confirmDialog({
    required String title,
    required String message,
    String confirmLabel = '削除',
  }) => showConfirmDialog(
    context,
    title: title,
    message: message,
    confirmLabel: confirmLabel,
  );

  Future<String?> _promptAreaName(String defaultName) => showTextPromptDialog(
    context,
    title: 'エリアの名前',
    labelText: '名前',
    hintText: '例: 公園A・駅前',
    defaultValue: defaultName,
    confirmLabel: '保存',
  );

  void _closePolygonDraft() {
    if (_polygonDraft.length < 3) {
      _toast('3点以上打ってから閉じてください');
      return;
    }
    try {
      final resolved = PolygonAreaResolver.resolveBoundedRing(
        _polygonDraft,
        seed: _polygonDraft.first,
      );
      _syncSetState(() {
        _polygonDraft
          ..clear()
          ..addAll(resolved);
        _polygonDraftClosed = true;
        _statusMessage = 'エリアを閉じました（${_polygonDraft.length} 頂点）';
      });
    } catch (e) {
      _toast('閉じられませんでした: $e');
    }
  }

  void _reopenPolygonDraft() {
    _syncSetState(() {
      _polygonDraftClosed = false;
      _statusMessage = '頂点を追加してから再度「閉じる」';
    });
  }

  Future<void> _deleteSavedPlayArea(String id, String name) async {
    final ok = await _confirmDialog(
      title: '保存エリアを削除',
      message: '「$name」を削除しますか？\n試合に適用済みの形は変わりません。',
    );
    if (!ok) return;
    await _areaSlotStore.remove(id);
    if (!mounted) return;
    _syncSetState(() {
      if (_selectedPlayAreaSlotId == id) {
        _selectedPlayAreaSlotId = null;
      }
    });
    await _loadPlayAreaSlots();
    _toast('保存エリアを削除しました');
  }

  Future<void> _saveEditedAreaAsSlot() async {
    try {
      late final PlayArea next;
      if (_editCircleMode) {
        next = PlayArea.circle(
          center: _circleDraftCenter,
          radiusMeters: _circleDraftRadiusMeters,
        );
      } else {
        if (!_polygonDraftClosed || _polygonDraft.length < 3) {
          _toast('多角形は「閉じる」してから保存してください');
          return;
        }
        next = PlayArea.polygon(points: List.from(_polygonDraft));
      }
      final stamp = DateTime.now();
      final defaultName =
          'エリア ${stamp.month}/${stamp.day} ${stamp.hour}:${stamp.minute.toString().padLeft(2, '0')}';
      final name = await _promptAreaName(defaultName);
      if (!mounted || name == null) return;
      final slot = SavedPlayArea(
        id: 'area_${stamp.microsecondsSinceEpoch}',
        name: name,
        area: next,
        savedAtUtc: stamp.toUtc(),
      );
      await _areaSlotStore.upsert(slot);
      if (!mounted) return;
      _syncSetState(() {
        _editingArea = false;
        _waitingCircleCenterTap = false;
        _selectedPlayAreaSlotId = slot.id;
        _statusMessage = 'エリアを保存しました（ホストが適用するまで試合には反映されません）';
      });
      await _loadPlayAreaSlots();
      _returnToPrepAfterAreaEdit();
    } catch (e) {
      _toast('保存に失敗しました: $e');
    }
  }

  FirestoreRoomSession? get _firestoreSession =>
      _roomSession is FirestoreRoomSession
      ? _roomSession as FirestoreRoomSession
      : null;

  bool get _isOnlineFirestore => _firestoreSession?.roomId != null;

  bool get _isHost {
    final fs = _firestoreSession;
    if (fs != null && fs.roomId != null) {
      return fs.isHost;
    }
    return true;
  }

  void _hostApplySelectedPlayArea() {
    if (!_isHost) {
      _toast('エリアの適用はホストのみできます');
      return;
    }
    final id = _selectedPlayAreaSlotId;
    if (id == null) {
      _toast('適用する保存エリアを選んでください');
      return;
    }
    SavedPlayArea? slot;
    for (final s in _savedPlayAreas) {
      if (s.id == id) {
        slot = s;
        break;
      }
    }
    if (slot == null) {
      _toast('保存エリアが見つかりません');
      return;
    }
    final applied = slot;
    _syncSetState(() {
      _playArea = applied.area;
      if (_playArea.type == PlayAreaType.circle) {
        _circleDraftCenter = _playArea.center;
        _circleDraftRadiusMeters = _playArea.radiusMeters;
      }
      _statusMessage = 'ホストが「${applied.name}」を適用しました';
    });
    unawaited(_areaStore.save(applied.area));
    unawaited(_publishLobbyPlayArea(slotName: applied.name, slotId: applied.id));
  }

  Future<void> _publishLobbyPlayArea({
    required String slotName,
    required String slotId,
  }) async {
    final fs = _firestoreSession;
    if (fs == null || !_isOnlineFirestore) return;
    final err = await fs.publishLobbyPlayArea(
      area: _playArea,
      slotName: slotName,
      slotId: slotId,
    );
    if (err != null && mounted) _toast(err);
  }

  void _applyLobbyPlayAreaSnapshot(LobbyPlayAreaSnapshot snap) {
    if (!mounted || _gameState != GameState.waiting) return;
    _syncSetState(() {
      _playArea = snap.area;
      if (_playArea.type == PlayAreaType.circle) {
        _circleDraftCenter = _playArea.center;
        _circleDraftRadiusMeters = _playArea.radiusMeters;
      }
      final name = snap.slotName ?? 'ホスト';
      _statusMessage = 'ホストが「$name」のエリアを共有しました';
    });
    unawaited(_areaStore.save(snap.area));
  }

  Future<void> _syncLobbyPlayAreaOnAttach() async {
    final fs = _firestoreSession;
    if (fs == null || !_isOnlineFirestore || _gameState != GameState.waiting) {
      return;
    }
    if (fs.currentPhase != RoomPhase.lobby) return;
    var snap = fs.currentLobbyPlayArea;
    snap ??= await fs.fetchLatestLobbyPlayAreaEvent();
    if (!mounted || snap == null) return;
    _applyLobbyPlayAreaSnapshot(snap);
  }

  void _applyRemoteLobbyPlayArea(RoomMatchEvent ev) {
    final snap = LobbyPlayAreaSnapshot.tryParseEvent(ev);
    if (snap == null) {
      _logDebug('lobby_play_area parse failed');
      return;
    }
    _applyLobbyPlayAreaSnapshot(snap);
  }

  void _setPrepDurationMinutes(double minutes) {
    if (!_isHost) return;
    _syncSetState(() {
      _matchDurationSeconds = (minutes.round() * 60).clamp(
        MatchDurationScaling.minMatchSeconds,
        MatchDurationScaling.maxMatchSeconds,
      );
      if (_gameState == GameState.waiting) {
        _rt.remainingSeconds = _matchDurationSeconds;
      }
    });
  }

  void _returnToPrepAfterAreaEdit() {
    if (_gameState != GameState.waiting) return;
    _syncSetState(() {
      _mapVisibleInLobby = false;
      _prepControlSheetOpen = false;
      _statusMessage = '準備画面に戻りました';
    });
  }

  /// エリア編集だけ終了し、地図表示＋マップパネルは維持する。
  void _exitAreaEditKeepMap() {
    if (_gameState != GameState.waiting) return;
    _syncSetState(() {
      _editingArea = false;
      _waitingCircleCenterTap = false;
      _polygonDraft.clear();
      _polygonDraftClosed = false;
      _statusMessage = 'エリア編集を終了しました（地図のまま）';
    });
    _retuneRenderPump();
  }
}
