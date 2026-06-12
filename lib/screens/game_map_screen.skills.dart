part of 'game_map_screen.dart';

/// スキル発動・情報屋・地図タップ操作。
extension _GameMapSkills on _GameMapScreenState {
  void _applyHunterInfoBroker({
    required int hitIndex,
    required LatLng hit,
    required DateTime now,
  }) {
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
    final nextInfoBroker = _relocateInfoBroker(hitIndex);
    _markInfoBrokerUsed(
      hitIndex: hitIndex,
      hit: hit,
      nextInfoBroker: nextInfoBroker,
      now: now,
      hunterLastAt: now,
      statusMessage: '情報屋: $targetLabel を標的に',
    );
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
    if (_skillLoadout.contains(SkillIds.werewolfTransform)) {
      _rt.lastWerewolfTransformAt = null;
      _rt.lastWerewolfTransformCooldownSec = null;
    }
    if (_skillLoadout.contains(SkillIds.captureZone)) {
      _rt.lastSkillLockPlacementAt = null;
    }
    if (_skillLoadout.contains(SkillIds.bodyThrow)) {
      _rt.lastBodyThrowAt = null;
    }
  }

  double _distanceToOni() => MatchGeoHelpers.distanceToOni(
    player: _currentPosition,
    oni: _oniPosition,
    oniKnown: _remoteOniKnown,
    testMode: _testMode,
  );

  bool get _showGimmickMapMarkers =>
      _testMode ||
      _gameState == GameState.running ||
      (_gameState == GameState.caughtByOni && _afterCatchRule != null);

  bool get _showOniMarker => _testMode || _remoteOniKnown;

  void _activateFakeSkill() {
    if (_gameState != GameState.running) {
      _toast('ゲーム中のみ使えます', denied: true);
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

  void _activateWerewolfHunter() {
    if (_gameState != GameState.running || _localRole != PlayerRole.werewolf) {
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
    _rt.lastWerewolfTransformCooldownSec =
        WerewolfForcedSchedule.voluntaryTransformCooldownSeconds(
      _matchDurationSeconds,
    );
    _rt.werewolfInOniForm = inOniForm;
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
  }

  bool _isAccusationSiteBlockedByLiveHunter(int siteIndex) {
    if (!_rt.accusationUnlocked) return false;
    if (siteIndex < 0 || siteIndex >= _rt.accusationFacilityPositions.length) {
      return false;
    }
    final hunterUid = _hunterUidFromAssignments;
    if (hunterUid == null) return false;
    final facility = _rt.accusationFacilityPositions[siteIndex];
    LatLng? hunterPos;
    if (_localRole == PlayerRole.hunter) {
      hunterPos = _currentPosition;
    } else if (hunterUid == _firestoreSession?.myUid) {
      hunterPos = _currentPosition;
    } else {
      hunterPos = _lastKnownHunterPositions[hunterUid];
    }
    return AccusationBlockLogic.isHunterBlockingSite(
      facilityPosition: facility,
      hunterPosition: hunterPos,
      hunterPositionKnown: hunterPos != null,
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
            '・自分（鬼）… 別地点に自分の名前で露出\n'
            '・逃走者ランダム… 誰か1人の名前で別地点に露出\n'
                '相手からは偽情報とは分かりません。',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
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
    late final LatLng raw;
    late final String label;
    String? targetUid;
    if (self) {
      raw = LatLng(
        _currentPosition.latitude + 0.0007,
        _currentPosition.longitude - 0.0005,
      );
      label = _localPlayerLabel;
    } else {
      final victim = _pickRandomOtherMatchMember();
      if (victim == null) {
        _toast('自分以外の試合参加者がいません');
        return;
      }
      targetUid = victim.uid;
      label = victim.label;
      raw = _randomFakeRevealPointInPlayArea();
    }
    final p = _displayRevealPosition(raw);
    final pick = _reasonPickAt(p);
    _rt.lastFakeIntelRevealAt = now;
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

  LatLng _randomFakeRevealPointInPlayArea() {
    final center = GeneratedGimmicks.centerOf(_playArea);
    final radius =
        GeneratedGimmicks.effectiveRadiusMeters(_playArea, center) * 0.45;
    final angle = math.Random().nextDouble() * 360;
    return GeneratedGimmicks.pointInArea(
      area: _playArea,
      center: center,
      angleDegrees: angle,
      distanceMeters: radius,
      avoid: const [],
      minGapMeters: 30,
    );
  }

  /// 体投げ作動中は「鬼として配信する座標」を人形位置にずらす。
  ///
  /// 捕獲判定は逃走者側が同期された鬼位置（[_oniPosition]）で行うため、
  /// 配信座標を人形にすることで“一時的に判定の中心をそこへ移す”挙動になる。
  LatLng _effectiveHunterBroadcastPos(LatLng real) {
    final puppet = _rt.bodyThrowPosition;
    final ends = _rt.bodyThrowEndsAt;
    if (puppet != null && ends != null && DateTime.now().isBefore(ends)) {
      return puppet;
    }
    return real;
  }

  /// 体投げの開始/終了の瞬間に、鬼の配信位置を即時に切り替える（実位置⇄人形）。
  void _syncHunterBroadcastForBodyThrow() {
    if (!_isOnlineFirestore || _localRole != PlayerRole.hunter) return;
    final ends = _rt.bodyThrowEndsAt;
    final active = _rt.bodyThrowPosition != null &&
        ends != null &&
        DateTime.now().isBefore(ends);
    if (active == _bodyThrowBroadcastActive) return;
    _bodyThrowBroadcastActive = active;
    _maybePublishHunterPosition(_currentPosition, force: true);
  }

  void _maybePublishHunterPosition(
    LatLng pos, {
    double? heading,
    bool force = false,
  }) {
    if (!_isOnlineFirestore || _gameState != GameState.running) return;
    // 向きは実際の移動から、配信座標は体投げ中なら人形位置から。
    _updateOniHeadingFromPosition(pos, deviceHeading: heading);
    final broadcast = _effectiveHunterBroadcastPos(pos);
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
    unawaited(
      _publishFirestoreMatchEventInner(
        innerType: 'hunter_position',
        message: '鬼位置更新',
        position: broadcast,
        headingDeg: _lastKnownOniHeadingDegrees,
      ),
    );
  }

  void _activateCaptureZone() {
    if (_gameState != GameState.running) return;
    if (!_skillLoadout.contains(SkillIds.captureZone)) return;
    if (_rt.waitingSkillLockMapTap) {
      _toast('地図を押し続けて範囲を確認し、離して設置');
      return;
    }
    final remain = _cooldownRemainingSeconds(
      _rt.lastSkillLockPlacementAt,
      GameConfig.captureZoneCooldownSeconds,
    );
    if (remain > 0) {
      _toast('捕獲結界の再使用まで $remain 秒');
      return;
    }
    _syncSetState(() {
      _rt.waitingSkillLockMapTap = true;
      _statusMessage =
          '地図を押し続けて範囲を確認し、指を離して設置（${GameConfig.bodyThrowDistanceMeters.toStringAsFixed(0)} m 以内）';
    });
  }

  void _activateBodyThrow() {
    if (_gameState != GameState.running) return;
    if (!_skillLoadout.contains(SkillIds.bodyThrow)) return;
    if (_rt.bodyThrowAwaitingMapTap) {
      _toast('地図を押し続けて位置を決め、離して設置');
      return;
    }
    if (_rt.bodyThrowPosition != null || _rt.bodyThrowEndsAt != null) {
      _toast('体投げは展開中です');
      return;
    }
    final now = DateTime.now();
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
      _rt.bodyThrowTapDeadline = now.add(
        const Duration(seconds: GameConfig.bodyThrowMapTapWindowSeconds),
      );
      _rt.bodyThrowSkillOriginLatLng = LatLng(
        _currentPosition.latitude,
        _currentPosition.longitude,
      );
      _statusMessage =
          '地図を押し続けて人形の位置を決め、指を離して設置（${GameConfig.bodyThrowDistanceMeters.toStringAsFixed(0)} m 以内）';
    });
  }

  bool get _skillMapPlacementActive =>
      _rt.waitingSkillLockMapTap || _rt.bodyThrowAwaitingMapTap;

  void _cancelSkillMapPlacement() {
    if (!_skillMapPlacementActive) return;
    _syncSetState(() {
      _rt.waitingSkillLockMapTap = false;
      _rt.bodyThrowAwaitingMapTap = false;
      _rt.bodyThrowTapDeadline = null;
      _rt.bodyThrowSkillOriginLatLng = null;
      _skillPlacementPreviewLatLng = null;
      _statusMessage = 'スキル設置をキャンセルしました';
    });
  }

  void _confirmSkillMapPlacementAt(LatLng pos) {
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
      _rt.lastBodyThrowAt = now;
      _rt.bodyThrowPosition = pos;
      _rt.bodyThrowEndsAt = now.add(
        const Duration(seconds: GameConfig.bodyThrowDurationSeconds),
      );
      _skillPlacementPreviewLatLng = null;
      _statusMessage = '人形稼働中（回収まで ${GameConfig.bodyThrowDurationSeconds} 秒）';
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

  void _placeCaptureZoneAt(LatLng pos) {
    final now = DateTime.now();
    final d = Geolocator.distanceBetween(
      _currentPosition.latitude,
      _currentPosition.longitude,
      pos.latitude,
      pos.longitude,
    );
    if (d > GameConfig.bodyThrowDistanceMeters) {
      _toast(
        '結界は現在地から ${GameConfig.bodyThrowDistanceMeters.toStringAsFixed(0)} m 以内に置けます',
      );
      return;
    }
    final rawTargets = _captureZoneTargetsAt(pos, d);
    final placeId =
        'cz_${now.millisecondsSinceEpoch}_${_firestoreSession?.myUid ?? 'local'}';
    _rt.lastSkillLockPlacementAt = now;
    _syncSetState(() {
      _rt.waitingSkillLockMapTap = false;
      _rt.lockZoneCenter = pos;
      _rt.lockZoneFromSkill = true;
      _rt.lockZoneCapturePermitted = _captureZoneLethalForLocal;
      _rt.lockZoneBoundIds = rawTargets;
      _rt.lockZoneTargetLeftAt = null;
      _rt.lockZoneEscapeRevealed = false;
      _rt.lockZoneEndsAt = now.add(
        const Duration(seconds: GameConfig.captureZoneDurationSeconds),
      );
      _skillPlacementPreviewLatLng = null;
      _statusMessage = _captureZoneLethalForLocal
          ? MatchHudCopy.captureZonePlacedStatus
          : MatchHudCopy.disruptionZonePlaced;
    });
    _emitMatchEvent(
      type: 'capture_zone_start',
      message: MatchHudCopy.captureZonePlaced,
      position: pos,
      syncFirestore: !_isOnlineFirestore,
    );
    if (_isOnlineFirestore) {
      unawaited(
        _publishCaptureZonePlaced(placeId, pos, rawTargets, fromSkill: true),
      );
      if (_isHost) {
        _captureAcksByPlace.putIfAbsent(placeId, () => <String>{});
        _scheduleHostCaptureBoundOnce(placeId: placeId, center: pos);
      }
    }
  }

  int? get _matchEventSessionKey =>
      _firestoreSession?.currentMatchStart?.gimmickSeed;

  static const _fsMatchEventInnerTypes = <String>{
    'gimmicks_generated',
    'trace_drop',
    'after_catch_rule',
    'safe_charge',
    'body_throw_start',
    'werewolf_transform_start',
    'fake_start',
    'hunter_position',
  };

  void _cancelCaptureBoundTimers() {
    for (final t in _captureBoundTimers.values) {
      t.cancel();
    }
    _captureBoundTimers.clear();
  }

  void _scheduleHostCaptureBoundOnce({
    required String placeId,
    required LatLng center,
  }) {
    if (!_isHost) return;
    if (_captureBoundTimers.containsKey(placeId)) return;
    final fs = _firestoreSession;
    final sk = _matchEventSessionKey;
    if (fs == null || sk == null) return;
    _captureBoundTimers[placeId] = Timer(
      const Duration(milliseconds: 2000),
      () async {
        _captureBoundTimers.remove(placeId);
        if (!mounted || _gameState != GameState.running) return;
        final acked = _captureAcksByPlace.remove(placeId)?.toList() ?? [];
        final err = await fs.publishHostRoomEvent(
          type: RoomMatchEventTypes.captureZoneBound,
          payload: {
            'placeId': placeId,
            'targetUids': acked,
            'centerLat': center.latitude,
            'centerLng': center.longitude,
            'durationSec': GameConfig.captureZoneDurationSeconds,
          },
          sessionKey: sk,
        );
        if (err != null && mounted) {
          _toast(err);
        }
      },
    );
  }

  List<String> _captureTargetUidsForFirestore(Set<String> raw) {
    final myUid = _firestoreSession?.myUid;
    return raw
        .map((id) => id == 'self' ? (myUid ?? 'self') : id)
        .toList(growable: false);
  }

  Future<void> _publishCaptureZonePlaced(
    String placeId,
    LatLng pos,
    Set<String> rawTargets, {
    required bool fromSkill,
  }) async {
    final fs = _firestoreSession;
    final sk = _matchEventSessionKey;
    if (fs == null || sk == null) return;
    final err = await fs.publishRoomEvent(
      type: RoomMatchEventTypes.captureZonePlaced,
      payload: {
        'placeId': placeId,
        'centerLat': pos.latitude,
        'centerLng': pos.longitude,
        'durationSec': GameConfig.captureZoneDurationSeconds,
        'targetUids': _captureTargetUidsForFirestore(rawTargets),
        'fromSkill': fromSkill,
        'capturePermitted': _captureZoneLethalForLocal,
      },
      sessionKey: sk,
    );
    if (err != null && mounted) _toast(err);
  }

  Future<void> _publishCaptureZoneAckIfNeeded(
    RoomMatchEvent ev,
    FirestoreRoomSession fs,
    String placeId,
  ) async {
    final sk = _matchEventSessionKey;
    if (sk == null) return;
    final cLat = ev.payload['centerLat'];
    final cLng = ev.payload['centerLng'];
    if (cLat is! num || cLng is! num) return;
    final center = LatLng(cLat.toDouble(), cLng.toDouble());
    final d = Geolocator.distanceBetween(
      _currentPosition.latitude,
      _currentPosition.longitude,
      center.latitude,
      center.longitude,
    );
    if (d > GameConfig.captureZoneRadiusMeters) return;
    final myUid = fs.myUid;
    if (myUid == null) return;
    final err = await fs.publishRoomEvent(
      type: RoomMatchEventTypes.captureZoneAck,
      payload: {'placeId': placeId},
      sessionKey: sk,
    );
    if (err != null && mounted) _toast(err);
  }

  List<String> _sortedMatchMemberUids() {
    final assignments = _firestoreSession?.currentMatchStart?.assignments;
    if (assignments != null && assignments.isNotEmpty) {
      return assignments.keys.toList()..sort();
    }
    final my = _firestoreSession?.myUid;
    if (my != null) return [my];
    return const ['solo'];
  }

  String? _periodicRevealTargetUid(int bucket) {
    final members = _sortedMatchMemberUids();
    if (members.isEmpty) return null;
    final seed = _matchEventSessionKey ?? 0;
    final idx = (bucket * 1103515245 + seed) % members.length;
    return members[idx];
  }

  void _maybePeriodicAnonymousReveal() {
    if (_gameState != GameState.running) return;
    final interval = MatchDurationScaling.periodicRevealIntervalSeconds(
      _matchDurationSeconds,
    );
    if (interval <= 0) return;
    final bucket = _rt.elapsedSeconds ~/ interval;
    if (bucket <= 0 || bucket <= _rt.lastPeriodicAnonymousBucket) return;
    _rt.lastPeriodicAnonymousBucket = bucket;
    final target = _periodicRevealTargetUid(bucket);
    final myUid = _firestoreSession?.myUid ?? 'solo';
    if (target != myUid) return;
    _emitAnonymousReveal(
      position: _currentPosition,
      pick: _reasonPickAt(_currentPosition),
      source: 'periodic',
    );
  }

  void _emitAnonymousReveal({
    required LatLng position,
    required RevealReasonPick pick,
    required String source,
  }) {
    final shown = _displayRevealPosition(position);
    if (!mounted) return;
    _syncSetState(() {
      _rt.anonymousRevealTraces.insert(
        0,
        AnonymousRevealTrace(
          timestamp: DateTime.now(),
          position: shown,
          reasonSummary: pick.summary,
          narrative: pick.narrative,
          source: _traceSourceFromKey(source),
        ),
      );
      if (_rt.anonymousRevealTraces.length > 24) {
        _rt.anonymousRevealTraces.removeLast();
      }
      _statusMessage = '不明な痕跡（${pick.summary}）';
    });
    _emitMatchEvent(
      type: 'anonymous_$source',
      message: pick.narrative,
      position: shown,
      syncFirestore: false,
    );
    unawaited(
      _publishFirestoreAnonymousReveal(
        position: shown,
        pick: pick,
        source: source,
      ),
    );
  }

  Future<void> _publishFirestoreAnonymousReveal({
    required LatLng position,
    required RevealReasonPick pick,
    required String source,
  }) async {
    final fs = _firestoreSession;
    final sk = _matchEventSessionKey;
    if (fs == null ||
        sk == null ||
        !_isOnlineFirestore ||
        _gameState != GameState.running) {
      return;
    }
    final err = await fs.publishRoomEvent(
      type: RoomMatchEventTypes.anonymousReveal,
      payload: {
        'source': source,
        'message': pick.narrative,
        'reasonSummary': pick.summary,
        'lat': position.latitude,
        'lng': position.longitude,
      },
      sessionKey: sk,
    );
    if (err != null && mounted) _toast(err);
  }

  void _applyRemoteAnonymousReveal(RoomMatchEvent ev) {
    final pos = RoomMatchEvent.latLngFromPayload(ev.payload);
    if (pos == null) return;
    final summary = ev.payload['reasonSummary'] as String? ?? '通信混線';
    final narrative = ev.payload['message'] as String? ?? '';
    final sourceKey = ev.payload['source'] as String? ?? 'other';
    if (!mounted) return;
    _syncSetState(() {
      _rt.anonymousRevealTraces.insert(
        0,
        AnonymousRevealTrace(
          timestamp: DateTime.now(),
          position: pos,
          reasonSummary: summary,
          narrative: narrative,
          source: _traceSourceFromKey(sourceKey),
        ),
      );
      if (_rt.anonymousRevealTraces.length > 24) {
        _rt.anonymousRevealTraces.removeLast();
      }
    });
    HapticFeedback.lightImpact();
    GameAudio.instance.playSfx(SfxId.anonReveal);
  }

  Iterable<AnonymousRevealTrace> _recentAnonymousTraces() {
    final cutoff = DateTime.now().subtract(const Duration(minutes: 10));
    return _rt.anonymousRevealTraces
        .where((e) => e.timestamp.isAfter(cutoff))
        .take(12);
  }

  Future<void> _publishFirestoreReveal({
    required String revealKind,
    required String message,
    required LatLng position,
    required String playerLabel,
    required double overflowMeters,
    String? reasonSummary,
  }) async {
    final fs = _firestoreSession;
    final sk = _matchEventSessionKey;
    if (fs == null ||
        sk == null ||
        !_isOnlineFirestore ||
        _gameState != GameState.running) {
      return;
    }
    final msg = message.length > 400 ? message.substring(0, 400) : message;
    final err = await fs.publishRoomEvent(
      type: RoomMatchEventTypes.reveal,
      payload: {
        'revealKind': revealKind,
        'message': msg,
        'lat': position.latitude,
        'lng': position.longitude,
        'playerLabel': playerLabel,
        'overflowMeters': overflowMeters,
        'reasonSummary': ?reasonSummary,
      },
      sessionKey: sk,
    );
    if (err != null && mounted) _toast(err);
  }

  Future<void> _publishFirestoreFakeIntelReveal({
    required String message,
    required LatLng position,
    required String playerLabel,
    required bool pickedSelf,
    required String reasonSummary,
    String? targetUid,
  }) async {
    final fs = _firestoreSession;
    final sk = _matchEventSessionKey;
    if (fs == null ||
        sk == null ||
        !_isOnlineFirestore ||
        _gameState != GameState.running) {
      return;
    }
    final msg = message.length > 400 ? message.substring(0, 400) : message;
    final err = await fs.publishRoomEvent(
      type: RoomMatchEventTypes.fakeIntelReveal,
      payload: {
        'message': msg,
        'lat': position.latitude,
        'lng': position.longitude,
        'playerLabel': playerLabel,
        'pickedSelf': pickedSelf,
        'reasonSummary': reasonSummary,
        'targetUid': ?targetUid,
      },
      sessionKey: sk,
    );
    if (err != null && mounted) _toast(err);
  }

  Future<void> _publishFirestoreInfoBroker({
    required String intel,
    required int hitIndex,
    required double pickupLat,
    required double pickupLng,
    required double nextLat,
    required double nextLng,
  }) async {
    final fs = _firestoreSession;
    final sk = _matchEventSessionKey;
    if (fs == null ||
        sk == null ||
        !_isOnlineFirestore ||
        _gameState != GameState.running) {
      return;
    }
    final text = intel.length > 400 ? intel.substring(0, 400) : intel;
    final err = await fs.publishRoomEvent(
      type: RoomMatchEventTypes.infoBroker,
      payload: {
        'intel': text,
        'hitIndex': hitIndex,
        'pickupLat': pickupLat,
        'pickupLng': pickupLng,
        'nextLat': nextLat,
        'nextLng': nextLng,
      },
      sessionKey: sk,
    );
    if (err != null && mounted) _toast(err);
  }

  Future<void> _publishFirestoreOniInfoBroker({
    required String targetUid,
    required String targetLabel,
    required int hitIndex,
    required double pickupLat,
    required double pickupLng,
    required double nextLat,
    required double nextLng,
  }) async {
    final fs = _firestoreSession;
    final sk = _matchEventSessionKey;
    if (fs == null ||
        sk == null ||
        !_isOnlineFirestore ||
        _gameState != GameState.running) {
      return;
    }
    final label = targetLabel.length > 80
        ? targetLabel.substring(0, 80)
        : targetLabel;
    final err = await fs.publishRoomEvent(
      type: RoomMatchEventTypes.oniInfoBroker,
      payload: {
        'targetUid': targetUid,
        'targetLabel': label,
        'hitIndex': hitIndex,
        'pickupLat': pickupLat,
        'pickupLng': pickupLng,
        'nextLat': nextLat,
        'nextLng': nextLng,
      },
      sessionKey: sk,
    );
    if (err != null && mounted) _toast(err);
  }

  Future<void> _publishFirestoreMatchEventInner({
    required String innerType,
    required String message,
    required LatLng position,
    int? endsAtMs,
    double? headingDeg,
  }) async {
    final fs = _firestoreSession;
    final sk = _matchEventSessionKey;
    if (fs == null ||
        sk == null ||
        !_isOnlineFirestore ||
        _gameState != GameState.running) {
      return;
    }
    final msg = message.length > 400 ? message.substring(0, 400) : message;
    final payload = <String, dynamic>{
      'innerType': innerType,
      'message': msg,
      'lat': position.latitude,
      'lng': position.longitude,
      'endsAtMs': ?endsAtMs,
      'headingDeg': ?headingDeg,
    };
    final err = await fs.publishRoomEvent(
      type: RoomMatchEventTypes.matchEvent,
      payload: payload,
      sessionKey: sk,
    );
    if (err != null && mounted) _toast(err);
  }

  void _applyRemoteCaptureZonePlaced(RoomMatchEvent ev) {
    final cLat = ev.payload['centerLat'];
    final cLng = ev.payload['centerLng'];
    final dur =
        (ev.payload['durationSec'] as num?)?.toInt() ??
        GameConfig.captureZoneDurationSeconds;
    if (cLat is! num || cLng is! num) return;
    final center = LatLng(cLat.toDouble(), cLng.toDouble());
    final now = DateTime.now();
    if (!mounted) return;
    _syncSetState(() {
      _rt.waitingSkillLockMapTap = false;
      _rt.lockZoneCenter = center;
      _rt.lockZoneFromSkill = CaptureZoneEventPayload.fromSkill(ev.payload);
      _rt.lockZoneBoundIds = {};
      _rt.lockZoneTargetLeftAt = null;
      _rt.lockZoneEscapeRevealed = false;
      _rt.lockZoneCapturePermitted =
          CaptureZoneEventPayload.capturePermitted(ev.payload);
      _rt.lockZoneEndsAt = now.add(Duration(seconds: dur));
    });
    HapticFeedback.mediumImpact();
    GameAudio.instance.playSfx(SfxId.skillCast);
  }

  void _applyRemoteCaptureZoneBound(
    RoomMatchEvent ev,
    FirestoreRoomSession fs,
  ) {
    final raw = ev.payload['targetUids'];
    if (raw is! List) return;
    final targets = raw.map((e) => e.toString()).toSet();
    final myUid = fs.myUid;
    if (!mounted) return;
    _syncSetState(() {
      if (myUid != null && targets.contains(myUid)) {
        _rt.lockZoneBoundIds = const {'self'};
      }
    });
  }

  void _emitMatchEvent({
    required String type,
    required String message,
    required LatLng position,
    bool syncFirestore = true,
    bool queueOffline = true,
    int? endsAtMs,
  }) {
    final event = MatchEvent(
      type: type,
      atUtc: DateTime.now().toUtc(),
      message: message,
      position: position,
    );
    _rt.matchEvents.insert(0, event);
    if (_rt.matchEvents.length > 120) {
      _rt.matchEvents.removeLast();
    }
    if (queueOffline) {
      _offlineQueue
          .push(
            OfflineSyncItem(
              id: 'ev_${event.atUtc.microsecondsSinceEpoch}_${event.type}',
              kind: 'match_event',
              createdAtUtc: event.atUtc.toIso8601String(),
              payload: event.toJson(),
            ),
          )
          .then((_) => _refreshOfflineQueueCount());
    }
    if (syncFirestore &&
        _isOnlineFirestore &&
        _gameState == GameState.running &&
        _fsMatchEventInnerTypes.contains(type)) {
      unawaited(
        _publishFirestoreMatchEventInner(
          innerType: type,
          message: message,
          position: position,
          endsAtMs: endsAtMs,
        ),
      );
    }
  }

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
      message: '地図上の痕跡・暴露ログ・匿名痕跡・鬼情報トレースを消しますか？',
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
    if (_gameState == GameState.running &&
        accusationEnabledForPlayerCount(_activeMatchPlayerCount) &&
        !_isEliminatedSpectator) {
      final copy = _accusationCopy;
      if (!_rt.accusationUnlocked) {
        return copy.lockedHint;
      }
      if (_rt.accusationSpentByMe) return '告発: この試合では使用済み';
      if (canLocalPlayerAccuse(
        localRole: _localRole,
        accusationUnlocked: _rt.accusationUnlocked,
        accusationSpent: _rt.accusationSpentByMe,
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
      return '偽位置展開中 残り$left秒 — 露出は偽座標（進行方向へ移動）';
    }
    return '異常なし';
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
      _oniRoleEnabled = s.roleEnabled;
      _oniNotifyVibration = s.notifyVibration;
      _oniNotifySound = s.notifySound;
      _oniNotifyAggressive = s.notifyAggressive;
    });
  }

  void _emitOniCue({required String level}) {
    final useAdvanced =
        _oniRoleEnabled || _afterCatchRule == EliminationAftermathRule.joinOni;
    if (!useAdvanced) {
      if (level == 'danger') {
        HapticFeedback.mediumImpact();
        SystemSound.play(SystemSoundType.alert);
        GameAudio.instance.playSfx(SfxId.proximityDanger);
      } else {
        HapticFeedback.selectionClick();
        SystemSound.play(SystemSoundType.click);
        GameAudio.instance.playSfx(SfxId.proximityWarning);
      }
      return;
    }
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

  String _playAreaSummary() => _playArea.shapeSummary();

  void _toggleAreaEditor() {
    if (_gameState == GameState.running) {
      _toast('ゲーム中はエリアを編集できません');
      return;
    }
    _syncSetState(() {
      final opening = !_editingArea;
      _editingArea = opening;
      if (opening) {
        _prepMapMode = PrepMapMode.edit;
        _prepControlSheetOpen = true;
        _areaEditorPanelExpanded = true;
        _polygonDraft.clear();
        _polygonDraftClosed = false;
        _waitingCircleCenterTap = false;
        _editCircleMode = _playArea.type == PlayAreaType.circle;
        if (_playArea.type == PlayAreaType.circle) {
          _circleDraftCenter = _playArea.center;
          _circleDraftRadiusMeters = _playArea.radiusMeters.clamp(50, 2000);
        } else {
          _polygonDraft.addAll(_playArea.points);
          _circleDraftCenter = _currentPosition;
        }
        _statusMessage = 'エリア編集モード（地図をタップして頂点追加 / 円はスライダー）';
      } else {
        _exitAreaEditKeepMap();
      }
    });
    _retuneRenderPump();
  }

  Future<void> _applyEditedArea() async {
    await _saveEditedAreaAsSlot();
  }
}
