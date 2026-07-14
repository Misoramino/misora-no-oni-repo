part of 'game_map_screen.dart';

/// 装備スキル発動・体投げ・人狼・偽位置／偽情報・鬼位置 publish・軌跡。
/// 暴露 Firestore / 定期匿名 / match_event 送信は match_events。
extension _GameMapSkills on _GameMapScreenState {
  void _applyHunterInfoBroker({
    required int hitIndex,
    required LatLng hit,
    required DateTime now,
  }) {
    unawaited(
      _finalizeHunterInfoBroker(hitIndex: hitIndex, hit: hit, now: now),
    );
  }

  Future<void> _finalizeHunterInfoBroker({
    required int hitIndex,
    required LatLng hit,
    required DateTime now,
  }) async {
    if (!_isOnlineFirestore) {
      _toast('鬼の情報屋はオンライン試合でのみ使えます');
      return;
    }
    final assignments = _firestoreSession?.currentMatchStart?.assignments;
    if (assignments == null || assignments.isEmpty) {
      _toast('逃走者がいません');
      return;
    }
    final targetUid = pickRandomRunnerUid(assignments: assignments);
    if (targetUid == null) {
      _toast('逃走者がいません');
      return;
    }
    final targetLabel = _displayNameForUid(targetUid);
    final nextInfoBroker = await _relocateInfoBroker(hitIndex);
    if (!mounted || _gameState != GameState.running) return;
    final intelLine = '標的: $targetLabel — ${MatchUiTerms.namedReveal}を発動';
    _markInfoBrokerUsed(
      hitIndex: hitIndex,
      hit: hit,
      nextInfoBroker: nextInfoBroker,
      now: now,
      hunterLastAt: now,
      statusMessage: '情報屋: $targetLabel を標的に',
    );
    _syncSetState(() {
      _rt.lastOniIntelText = intelLine;
      _rt.lastOniIntelAt = now;
      _rt.showOniIntelCard = true;
      _rt.oniIntelTraces.insert(
        0,
        OniIntelTrace(timestamp: now, position: hit, text: intelLine),
      );
      if (_rt.oniIntelTraces.length > 20) {
        _rt.oniIntelTraces.removeLast();
      }
    });
    _emitMatchEvent(
      type: RoomMatchEventTypes.oniInfoBroker,
      message: '鬼が情報屋を利用: $targetLabel',
      position: hit,
      syncFirestore: false,
    );
    unawaited(
      _publishFirestoreOniInfoBroker(
        targetUid: targetUid,
        targetLabel: targetLabel,
        hitIndex: hitIndex,
        pickupLat: hit.latitude,
        pickupLng: hit.longitude,
        nextLat: nextInfoBroker.latitude,
        nextLng: nextInfoBroker.longitude,
      ),
    );
  }

  void _refreshSkillCooldownsFromSafeZone() {
    if (_skillLoadout.contains(SkillIds.fakePosition)) {
      _rt.lastFakeSkillAt = null;
    }
    if (_skillLoadout.contains(SkillIds.captureZone)) {
      _rt.lastSkillLockPlacementAt = null;
    }
    if (_skillLoadout.contains(SkillIds.bodyThrow)) {
      if (_rt.bodyThrowPosition == null) {
        _rt.lastBodyThrowAt = null;
      }
    }
  }

  bool get _bodyThrowPuppetActive => _rt.bodyThrowPosition != null;

  bool get _bodyThrowBlocksOtherSkills =>
      _rt.bodyThrowAwaitingMapTap || _bodyThrowPuppetActive;

  double _distanceToOni() {
    if (_testMode) {
      return MatchGeoHelpers.distanceToOni(
        player: _currentPosition,
        oni: _oniPosition,
        oniKnown: true,
        testMode: true,
      );
    }
    if (_isPerceivedOniNow) {
      return double.infinity;
    }
    if (!_anyPerceivedOniPositionKnown) {
      return double.infinity;
    }
    final myUid = _firestoreSession?.myUid ?? 'local';
    var best = double.infinity;
    for (final p in _matchParticipants()) {
      if (p.uid == myUid) continue;
      if (!WerewolfFactionLogic.isPerceivedOni(
        assignmentRole: p.assignmentRole,
        werewolfInOniForm: p.werewolfInOniForm,
      )) {
        continue;
      }
      final pos = _resolvedPerceivedOniPosition(p.uid) ??
          (p.uid == _hunterUidFromAssignments && _remoteOniKnown
              ? _oniPosition
              : null);
      if (pos == null) continue;
      final d = Geolocator.distanceBetween(
        _currentPosition.latitude,
        _currentPosition.longitude,
        pos.latitude,
        pos.longitude,
      );
      if (d < best) best = d;
    }
    return best;
  }

  bool get _showGimmickMapMarkers =>
      _testMode ||
      _gameState == GameState.running ||
      (_gameState == GameState.caughtByOni && _afterCatchRule != null);

  bool get _showOniMarker =>
      (_testMode || _remoteOniKnown) && _activeMatchPlayerCount > 1;

  bool get _bodyThrowRecoverInRange {
    final puppet = _rt.bodyThrowPosition;
    if (puppet == null) return false;
    final d = Geolocator.distanceBetween(
      _currentPosition.latitude,
      _currentPosition.longitude,
      puppet.latitude,
      puppet.longitude,
    );
    return d <= GameConfig.bodyThrowRecoveryDistanceMeters;
  }

  void _activateFakeSkill() {
    if (_gameState != GameState.running) {
      _toast('ゲーム中のみ使えます', denied: true);
      return;
    }
    if (_bodyThrowBlocksOtherSkills) {
      _toast('体投げの設置・回収が終わるまで使えません', denied: true);
      return;
    }
    if (!_skillLoadout.contains(SkillIds.fakePosition)) return;
    final now = DateTime.now();
    if (_rt.lastFakeSkillAt != null &&
        now.difference(_rt.lastFakeSkillAt!).inSeconds <
            GameConfig.fakeSkillCooldownSeconds) {
      final remain =
          GameConfig.fakeSkillCooldownSeconds -
          now.difference(_rt.lastFakeSkillAt!).inSeconds;
      _toast('偽位置スキル再使用まで $remain 秒', denied: true);
      return;
    }
    _rt.lastFakeSkillAt = now;
    _rt.fakePositionActive = true;
    _rt.fakePositionEndsAt = now.add(
      const Duration(seconds: GameConfig.fakeSkillDurationSeconds),
    );
    final bearing =
        _movementBearingDegrees ?? math.Random().nextDouble() * 360;
    _rt.fakePositionBearingDegrees = bearing;
    _rt.fakePositionLatLng = _offsetPosition(
      _currentPosition,
      bearing,
      GameConfig.fakePositionSpawnOffsetMeters,
    );
    _lastFakeDriftAt = now;
    _emitMatchEvent(
      type: 'fake_start',
      message: '偽位置を展開（進行方向へ移動）',
      position: _rt.fakePositionLatLng!,
      endsAtMs: _rt.fakePositionEndsAt!.millisecondsSinceEpoch,
      syncFirestore: false,
    );
    GameAudio.instance.playSfx(SfxId.skillCast);
    _syncSetState(() {
      _statusMessage =
          '偽位置を展開（進行方向へ移動・露出時は偽座標が名前付きで出ます）';
    });
  }

  String _skillLabelForUi(String id) {
    if (id == SkillIds.werewolfTransform) {
      return werewolfTransformActionLabel(inOniForm: _rt.werewolfInOniForm);
    }
    return skillLabel(id);
  }

  int _werewolfCooldownSecondsForUi() =>
      _rt.lastWerewolfTransformCooldownSec ??
      WerewolfForcedSchedule.voluntaryTransformCooldownSeconds(
        _matchDurationSeconds,
      );

  int _werewolfSecondsUntilForcedForUi() {
    if (_localRole != PlayerRole.werewolf || _gameState != GameState.running) {
      return 0;
    }
    return WerewolfForcedSchedule.secondsUntilForcedToggle(
      lastTransformAt: _rt.lastWerewolfTransformAt,
      now: DateTime.now(),
      matchDurationSeconds: _matchDurationSeconds,
    );
  }

  void _activateWerewolfHunter() {
    if (_gameState != GameState.running || _localRole != PlayerRole.werewolf) {
      return;
    }
    if (_bodyThrowBlocksOtherSkills) {
      _toast('体投げの設置・回収が終わるまで使えません', denied: true);
      return;
    }
    final target = !_rt.werewolfInOniForm;
    if (_rt.lastWerewolfTransformAt != null) {
      final remain = _cooldownRemainingSeconds(
        _rt.lastWerewolfTransformAt,
        _werewolfCooldownSecondsForUi(),
      );
      if (remain > 0) {
        _toast('切替の再発動まで $remain 秒', denied: true);
        return;
      }
    }
    _setWerewolfOniForm(target, voluntary: true);
  }

  void _maybeWerewolfForcedTransform() {
    if (_localRole != PlayerRole.werewolf || _gameState != GameState.running) {
      return;
    }
    if (_rt.lastWerewolfTransformAt == null) {
      _rt.lastWerewolfTransformAt = DateTime.now();
      return;
    }
    final now = DateTime.now();
    if (!WerewolfForcedSchedule.shouldForceToggle(
      lastTransformAt: _rt.lastWerewolfTransformAt,
      now: now,
      matchDurationSeconds: _matchDurationSeconds,
    )) {
      return;
    }
    final target = !_rt.werewolfInOniForm;
    _setWerewolfOniForm(target, voluntary: false);
    if (!mounted) return;
    _syncSetState(
      () => _statusMessage = target
          ? '強制鬼化 — 自発切替でタイマーリセット${_werewolfStatusSuffix()}'
          : '強制人化 — 自発切替でタイマーリセット${_werewolfStatusSuffix()}',
    );
  }

  void _setWerewolfOniForm(bool inOniForm, {required bool voluntary}) {
    final now = DateTime.now();
    _rt.lastWerewolfTransformAt = now;
    _rt.lastWerewolfTransformCooldownSec = voluntary
        ? WerewolfForcedSchedule.voluntaryTransformCooldownSeconds(
            _matchDurationSeconds,
          )
        : WerewolfForcedSchedule.voluntaryTransformCooldownAfterForcedSeconds(
            _matchDurationSeconds,
          );
    _rt.werewolfInOniForm = inOniForm;
    if (inOniForm) {
      _emitMatchEvent(
        type: 'werewolf_transform_start',
        message: voluntary ? '人狼 — 鬼化（自発）' : '人狼 — 鬼化（強制）',
        position: _currentPosition,
      );
    }
    unawaited(
      _firestoreSession?.publishPresence(
        tension: false,
        werewolfOniForm: inOniForm,
      ),
    );
    if (!mounted) return;
    _syncSetState(() {
      _statusMessage = inOniForm
          ? '鬼化中 — スキルで人化${_werewolfStatusSuffix()}'
          : '人の姿 — スキルで鬼化${_werewolfStatusSuffix()}';
    });
    unawaited(_syncBleMatchContext(forceAdvertiseRestart: true));
    if (inOniForm) {
      _maybePublishHunterPosition(_currentPosition, force: true);
    }
  }


  List<LatLng> _assignedHunterTrailPointsForMap() {
    final trail = MatchDurationScaling.oniTrail(_matchDurationSeconds);
    return OniPathTrailLogic.visibleTrailPoints(
      samples: _hunterPathSamples,
      now: DateTime.now(),
      minAgeSeconds: trail.minAgeSeconds,
      maxAgeSeconds: trail.maxAgeSeconds,
    );
  }

  List<LatLng> _oniTrailPointsForMap() {
    final trail = MatchDurationScaling.oniTrail(_matchDurationSeconds);
    return OniPathTrailLogic.visibleTrailPoints(
      samples: _oniPathSamples,
      now: DateTime.now(),
      minAgeSeconds: trail.minAgeSeconds,
      maxAgeSeconds: trail.maxAgeSeconds,
    );
  }

  bool get _showOniMatchStartAnchor {
    if (_oniMatchStartAnchor == null || _localRole == PlayerRole.hunter) {
      return false;
    }
    return _rt.elapsedSeconds <=
        MatchDurationScaling.oniStartAnchorMaxElapsedSeconds(
          _matchDurationSeconds,
        );
  }

  void _maybeCaptureOniMatchStartAnchor(LatLng pos) {
    if (_oniMatchStartAnchor != null) return;
    if (_rt.elapsedSeconds >
        MatchDurationScaling.oniStartAnchorMaxElapsedSeconds(
          _matchDurationSeconds,
        )) {
      return;
    }
    _oniMatchStartAnchor = pos;
  }

  void _recordOniPathSample(LatLng pos) {
    final now = DateTime.now();
    _maybeCaptureOniMatchStartAnchor(pos);
    _oniPathSamples.add(OniPathSample(recordedAt: now, position: pos));
    final trail = MatchDurationScaling.oniTrail(_matchDurationSeconds);
    final pruned = OniPathTrailLogic.prune(
      samples: _oniPathSamples,
      now: now,
      retainSeconds: trail.retainSeconds,
    );
    _oniPathSamples
      ..clear()
      ..addAll(pruned);
  }

  void _recordAssignedHunterPathSample(LatLng pos) {
    final now = DateTime.now();
    _hunterPathSamples.add(OniPathSample(recordedAt: now, position: pos));
    final trail = MatchDurationScaling.oniTrail(_matchDurationSeconds);
    final pruned = OniPathTrailLogic.prune(
      samples: _hunterPathSamples,
      now: now,
      retainSeconds: trail.retainSeconds,
    );
    _hunterPathSamples
      ..clear()
      ..addAll(pruned);
  }

  Future<void> _publishTraceDrop(LatLng position) async {
    final sk = _matchEventSessionKey;
    final fs = _firestoreSession;
    if (sk == null || fs == null || !_isOnlineFirestore) return;
    await _publishFirestoreMatchEventInner(
      innerType: 'trace_drop',
      message: '脱落・捕獲地点',
      position: position,
    );
  }

  Future<void> _activateFakeIntelReveal() async {
    if (_gameState != GameState.running) {
      _toast('ゲーム中のみ使えます');
      return;
    }
    if (_bodyThrowBlocksOtherSkills) {
      _toast('体投げの設置・回収が終わるまで使えません', denied: true);
      return;
    }
    if (_localRole != PlayerRole.hunter) {
      _toast('偽情報暴露は鬼のみ使えます');
      return;
    }
    if (!_skillLoadout.contains(SkillIds.fakeIntelReveal)) {
      _toast('この試合のスキルに偽情報暴露がありません');
      return;
    }
    final now = DateTime.now();
    final cdRemain = _cooldownRemainingSeconds(
      _rt.lastFakeIntelRevealAt,
      GameConfig.fakeIntelRevealCooldownSeconds,
    );
    if (cdRemain > 0) {
      _toast('偽情報暴露は $cdRemain 秒後に再使用できます');
      return;
    }
    final self = await showAppDialog<bool?>(
      context: context,
      builder: (ctx) {
        final theme = Theme.of(ctx);
        return AppDialog(
          title: '偽情報暴露',
          icon: Icons.theater_comedy_rounded,
          accent: theme.colorScheme.tertiary,
          actions: [
            AppDialogAction(
              label: 'キャンセル',
              filled: false,
              sfx: SfxId.uiBack,
              onPressed: () => Navigator.pop(ctx),
            ),
          ],
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'どちらも${MatchUiTerms.namedReveal}として地図に出ます。\n'
                '次の画面で地図を長押しし、指を離して位置を確定します。\n'
                '相手からは偽情報とは分かりません。',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: ctx.worldMuted,
                ),
              ),
              const SizedBox(height: 14),
              FilledButton.tonalIcon(
                onPressed: () => Navigator.pop(ctx, true),
                icon: const Icon(Icons.person_pin_circle_rounded),
                label: const Text('自分（鬼）を暴露'),
              ),
              const SizedBox(height: 8),
              FilledButton.icon(
                onPressed: () => Navigator.pop(ctx, false),
                icon: const Icon(Icons.shuffle_rounded),
                label: const Text('逃走者をランダム暴露'),
              ),
            ],
          ),
        );
      },
    );
    if (self == null) return;
    late final String label;
    String? targetUid;
    if (self) {
      label = _localPlayerLabel;
    } else {
      final victim = _pickRandomOtherMatchMember();
      if (victim == null) {
        _toast('自分以外の試合参加者がいません');
        return;
      }
      targetUid = victim.uid;
      label = victim.label;
    }
    _syncSetState(() {
      _rt.fakeIntelAwaitingMapTap = true;
      _rt.fakeIntelTapDeadline = now.add(
        const Duration(seconds: GameConfig.fakeIntelMapTapWindowSeconds),
      );
      _rt.fakeIntelPickedSelf = self;
      _rt.fakeIntelTargetLabel = label;
      _rt.fakeIntelTargetUid = targetUid;
      _statusMessage =
          '地図を長押しして暴露位置を決め、指を離して確定（プレイエリア内）';
    });
  }

  void _placeFakeIntelAt(LatLng pos) {
    if (!_playArea.contains(pos)) {
      _toast('プレイエリア内を選んでください');
      return;
    }
    final now = DateTime.now();
    final self = _rt.fakeIntelPickedSelf;
    final label = _rt.fakeIntelTargetLabel;
    final targetUid = _rt.fakeIntelTargetUid;
    final p = _displayRevealPosition(pos);
    const pick = RevealReasonPick.exactLocation;
    _rt.lastFakeIntelRevealAt = now;
    _syncSetState(() {
      _rt.fakeIntelAwaitingMapTap = false;
      _rt.fakeIntelTapDeadline = null;
      _rt.fakeIntelTargetLabel = '';
      _rt.fakeIntelTargetUid = null;
      _skillPlacementPreviewLatLng = null;
      _statusMessage = MatchHudCopy.namedRevealStatus(label, pick.summary);
    });
    _emitIdentifiedReveal(
      revealKind: 'fake_intel_reveal',
      position: p,
      playerLabel: label,
      pick: pick,
      syncLocalEventType: 'accidental_reveal',
      subjectUid: self ? _firestoreSession?.myUid : targetUid,
    );
    unawaited(
      _publishFirestoreFakeIntelReveal(
        message: pick.narrative,
        position: p,
        playerLabel: label,
        pickedSelf: self,
        targetUid: targetUid,
        reasonSummary: pick.summary,
      ),
    );
    HapticFeedback.mediumImpact();
    GameAudio.instance.playSfx(SfxId.skillCast);
  }

  /// 自分以外の試合参加者から1人をランダムに選ぶ（assignments 優先）。
  ({String uid, String label})? _pickRandomOtherMatchMember() {
    final fs = _firestoreSession;
    final myUid = fs?.myUid;
    final candidates = <({String uid, String label})>[];

    final assignments = fs?.currentMatchStart?.assignments;
    if (assignments != null && assignments.isNotEmpty) {
      for (final uid in assignments.keys) {
        if (uid == myUid) continue;
        candidates.add((uid: uid, label: _displayNameForUid(uid)));
      }
    } else if (fs != null) {
      for (final m in fs.currentLobbyMembers) {
        if (m.uid == myUid) continue;
        final nick = m.nickname.trim();
        candidates.add((
          uid: m.uid,
          label: nick.isNotEmpty
              ? nick
              : '参加者 ${m.uid.substring(0, math.min(6, m.uid.length))}',
        ));
      }
    }

    if (candidates.isEmpty) return null;
    return candidates[math.Random().nextInt(candidates.length)];
  }

  String _displayNameForUid(String uid) {
    final fs = _firestoreSession;
    if (fs != null) {
      for (final m in fs.currentLobbyMembers) {
        if (m.uid == uid) {
          final nick = m.nickname.trim();
          if (nick.isNotEmpty) return nick;
          break;
        }
      }
    }
    return '参加者 ${uid.substring(0, math.min(6, uid.length))}';
  }

  void _recordMovementBearing(LatLng next) {
    final prev = _lastPositionForBearing;
    if (prev != null) {
      final moved = Geolocator.distanceBetween(
        prev.latitude,
        prev.longitude,
        next.latitude,
        next.longitude,
      );
      if (moved >= 3) {
        _movementBearingDegrees = Geolocator.bearingBetween(
          prev.latitude,
          prev.longitude,
          next.latitude,
          next.longitude,
        );
      }
    }
    _lastPositionForBearing = next;
  }

  LatLng _offsetPosition(LatLng from, double bearingDegrees, double meters) {
    final rad = bearingDegrees * math.pi / 180;
    final dLat = (meters * math.cos(rad)) / 111320;
    final dLng =
        (meters * math.sin(rad)) /
        (111320 * math.cos(from.latitude * math.pi / 180));
    var p = LatLng(from.latitude + dLat, from.longitude + dLng);
    if (!_playArea.contains(p)) {
      p = GeneratedGimmicks.pointInArea(
        area: _playArea,
        center: from,
        angleDegrees: bearingDegrees,
        distanceMeters: meters,
        avoid: const [],
        minGapMeters: 8,
      );
    }
    return p;
  }

  void _advanceFakePositionDrift() {
    if (!_rt.fakePositionActive || _rt.fakePositionLatLng == null) return;
    final now = DateTime.now();
    final last = _lastFakeDriftAt ?? now;
    final dt = now.difference(last).inMilliseconds / 1000.0;
    if (dt <= 0.05) return;
    _lastFakeDriftAt = now;
    final bearing =
        _rt.fakePositionBearingDegrees ?? _movementBearingDegrees ?? 0;
    final meters = GameConfig.fakePositionDriftSpeedMps * dt.clamp(0, 2.5);
    final next = _offsetPosition(_rt.fakePositionLatLng!, bearing, meters);
    if (mounted) {
      _syncSetState(() => _rt.fakePositionLatLng = next);
    } else {
      _rt.fakePositionLatLng = next;
    }
  }

  /// 体投げ作動中は「鬼として配信する座標」を人形位置にずらす。
  ///
  /// 捕獲判定は逃走者側が同期された鬼位置（[_oniPosition]）で行うため、
  /// 配信座標を人形にすることで“一時的に判定の中心をそこへ移す”挙動になる。
  LatLng _effectiveHunterBroadcastPos(LatLng real) {
    final puppet = _rt.bodyThrowPosition;
    if (puppet != null) {
      return puppet;
    }
    return real;
  }

  /// 体投げの開始/終了の瞬間に、鬼の配信位置を即時に切り替える（実位置⇄人形）。
  void _syncHunterBroadcastForBodyThrow() {
    if (!_isOnlineFirestore || _localRole != PlayerRole.hunter) return;
    final active = _bodyThrowPuppetActive;
    if (active == _bodyThrowBroadcastActive) return;
    _bodyThrowBroadcastActive = active;
    _maybePublishHunterPosition(_currentPosition, force: true);
  }

  void _maybePublishHunterPosition(
    LatLng pos, {
    double? heading,
    bool force = false,
  }) {
    if (!_isOnlineFirestore || !_isPerceivedOniNow) return;
    final roomRunning =
        _firestoreSession?.currentPhase == RoomPhase.running;
    if (!_matchSyncArmed &&
        _gameState != GameState.running &&
        !(_matchPresentationActive && roomRunning)) {
      return;
    }
    if (_localRole == PlayerRole.hunter) {
      _updateOniHeadingFromPosition(pos, deviceHeading: heading);
    }
    final broadcast = _localRole == PlayerRole.hunter
        ? _effectiveHunterBroadcastPos(pos)
        : pos;
    final now = DateTime.now();
    final lastAt = _lastHunterPositionPublishAt;
    final lastPos = _lastHunterPositionPublished;
    if (!force &&
        lastAt != null &&
        now.difference(lastAt).inSeconds <
            GameConfig.hunterPositionPublishIntervalSeconds) {
      if (lastPos != null) {
        final moved = Geolocator.distanceBetween(
          lastPos.latitude,
          lastPos.longitude,
          broadcast.latitude,
          broadcast.longitude,
        );
        if (moved < 6) return;
      } else {
        return;
      }
    }
    _lastHunterPositionPublishAt = now;
    _lastHunterPositionPublished = broadcast;
    _recordOniPathSample(broadcast);
    if (_localRole == PlayerRole.hunter) {
      _recordAssignedHunterPathSample(broadcast);
    }
    unawaited(
      _publishFirestoreMatchEventInner(
        innerType: 'hunter_position',
        message: '鬼位置更新',
        position: broadcast,
        headingDeg: _lastKnownOniHeadingDegrees,
      ),
    );
  }

  void _activateBodyThrow() {
    if (_gameState != GameState.running) return;
    if (!_skillLoadout.contains(SkillIds.bodyThrow)) return;
    if (_bodyThrowPuppetActive) {
      _tryRecoverBodyThrow();
      return;
    }
    if (_rt.bodyThrowAwaitingMapTap) {
      _toast('地図を押し続けて位置を決め、離して設置');
      return;
    }
    final remain = _cooldownRemainingSeconds(
      _rt.lastBodyThrowAt,
      GameConfig.bodyThrowCooldownSeconds,
    );
    if (remain > 0) {
      _toast('体投げの再使用まで $remain 秒');
      return;
    }
    _syncSetState(() {
      _rt.bodyThrowAwaitingMapTap = true;
      _statusMessage =
          '地図を押し続けて人形の位置を決め、指を離して設置（${GameConfig.bodyThrowDistanceMeters.toStringAsFixed(0)} m 以内・右上×でキャンセル）';
    });
  }

  void _tryRecoverBodyThrow() {
    final puppet = _rt.bodyThrowPosition;
    if (puppet == null) return;
    final d = Geolocator.distanceBetween(
      _currentPosition.latitude,
      _currentPosition.longitude,
      puppet.latitude,
      puppet.longitude,
    );
    if (d > GameConfig.bodyThrowRecoveryDistanceMeters) {
      final need = (d - GameConfig.bodyThrowRecoveryDistanceMeters).round();
      _toast('人形の位置まであと約$need m');
      return;
    }
    _finishBodyThrowRecovery();
  }

  void _finishBodyThrowRecovery() {
    final now = DateTime.now();
    final puppet = _rt.bodyThrowPosition;
    _syncSetState(() {
      _rt.bodyThrowPosition = null;
      _rt.bodyThrowEndsAt = null;
      _rt.bodyThrowOverdueRevealed = false;
      _rt.bodyThrowSkillOriginLatLng = null;
      _rt.lastBodyThrowAt = now;
      _statusMessage = '体投げを回収しました';
    });
    if (puppet != null) {
      _emitMatchEvent(
        type: 'body_throw_end',
        message: '体投げ回収',
        position: puppet,
      );
    }
    _syncHunterBroadcastForBodyThrow();
    GameAudio.instance.playSfx(SfxId.uiTap);
  }

  bool get _skillMapPlacementActive =>
      _rt.waitingSkillLockMapTap ||
      _rt.bodyThrowAwaitingMapTap ||
      _rt.fakeIntelAwaitingMapTap;

  void _cancelSkillMapPlacement() {
    if (!_skillMapPlacementActive) return;
    _syncSetState(() {
      _rt.waitingSkillLockMapTap = false;
      _rt.bodyThrowAwaitingMapTap = false;
      _rt.bodyThrowTapDeadline = null;
      _rt.bodyThrowSkillOriginLatLng = null;
      _rt.fakeIntelAwaitingMapTap = false;
      _rt.fakeIntelTapDeadline = null;
      _rt.fakeIntelTargetLabel = '';
      _rt.fakeIntelTargetUid = null;
      _skillPlacementPreviewLatLng = null;
      _statusMessage = 'スキル設置をキャンセルしました';
    });
  }

  void _confirmSkillMapPlacementAt(LatLng pos) {
    if (_rt.fakeIntelAwaitingMapTap) {
      _placeFakeIntelAt(pos);
      return;
    }
    if (_rt.bodyThrowAwaitingMapTap) {
      _placeBodyThrowAt(pos);
      return;
    }
    if (_rt.waitingSkillLockMapTap) {
      _placeCaptureZoneAt(pos);
    }
  }

  void _placeBodyThrowAt(LatLng pos) {
    final d = Geolocator.distanceBetween(
      _currentPosition.latitude,
      _currentPosition.longitude,
      pos.latitude,
      pos.longitude,
    );
    if (d > GameConfig.bodyThrowDistanceMeters) {
      _toast(
        '人形は現在地から ${GameConfig.bodyThrowDistanceMeters.toStringAsFixed(0)} m 以内に置けます',
      );
      return;
    }
    if (!_playArea.contains(pos)) {
      _toastBodyThrowAreaHint();
      return;
    }
    final now = DateTime.now();
    _syncSetState(() {
      _rt.bodyThrowAwaitingMapTap = false;
      _rt.bodyThrowTapDeadline = null;
      _rt.bodyThrowSkillOriginLatLng = null;
      _rt.bodyThrowOverdueRevealed = false;
      _rt.bodyThrowPosition = pos;
      _rt.bodyThrowEndsAt = now.add(
        const Duration(seconds: GameConfig.bodyThrowDurationSeconds),
      );
      _skillPlacementPreviewLatLng = null;
      _statusMessage =
          '人形稼働中 — 人形の位置へ近づき、体投げボタンで回収（約${GameConfig.bodyThrowDurationSeconds}秒以内に回収しないと人形の位置が暴露）';
    });
    _emitMatchEvent(
      type: 'body_throw_start',
      message: '体投げ発動',
      position: pos,
      endsAtMs: _rt.bodyThrowEndsAt!.millisecondsSinceEpoch,
    );
    GameAudio.instance.playSfx(SfxId.skillCast);
    _syncHunterBroadcastForBodyThrow();
  }

}
