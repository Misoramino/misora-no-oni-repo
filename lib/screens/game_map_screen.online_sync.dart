part of 'game_map_screen.dart';

/// オンライン（Firestore ルーム）から受信したマッチイベントの適用処理。
///
/// `game_map_screen.dart` 本体（`_GameMapScreenState`）から物理的に切り出した
/// 受信ハンドラ群。挙動は本体にあった頃と完全に同一（同一ライブラリの extension）。
extension _GameMapOnlineSyncEvents on _GameMapScreenState {
  void _onRemoteRoomMatchEvent(RoomMatchEvent ev) {
    if (!mounted) return;
    if (_processedRoomEventDocIds.contains(ev.id)) return;
    _processedRoomEventDocIds.add(ev.id);

    if (_gameState == GameState.waiting &&
        ev.sessionKey == lobbySessionKey) {
      _onRemoteLobbyPhaseEvent(ev);
      return;
    }

    final sk = _matchEventSessionKey;
    if (sk == null || ev.sessionKey != sk) return;
    // 捕獲後も残響体/鬼影として戦線に残るため、試合継続中はイベントを受け取る
    // （マップの暴露・鬼位置・他ゴーストの行動を反映し続ける）。
    if (!_isMatchStillActiveForLocalPlayer) return;
    final running = _gameState == GameState.running;
    final fs = _firestoreSession;
    if (fs == null) return;

    switch (ev.type) {
      case RoomMatchEventTypes.matchStart:
      case RoomMatchEventTypes.matchEnd:
        return;
      case RoomMatchEventTypes.reveal:
        if (ev.actorUid == fs.myUid) return;
        _applyRemoteReveal(ev);
        return;
      case RoomMatchEventTypes.anonymousReveal:
        if (ev.actorUid == fs.myUid) return;
        _applyRemoteAnonymousReveal(ev);
        return;
      case RoomMatchEventTypes.fakeIntelReveal:
        if (ev.actorUid == fs.myUid) return;
        _applyRemoteFakeIntelReveal(ev);
        return;
      case RoomMatchEventTypes.infoBroker:
        if (ev.actorUid == fs.myUid) return;
        _applyRemoteInfoBroker(ev);
        return;
      case RoomMatchEventTypes.oniInfoBroker:
        if (ev.actorUid == fs.myUid) return;
        _applyRemoteOniInfoBroker(ev);
        return;
      case RoomMatchEventTypes.matchEvent:
        if (ev.actorUid == fs.myUid) return;
        _applyRemoteMatchEventLog(ev);
        return;
      case RoomMatchEventTypes.captureZonePlaced:
        final placeId = ev.payload['placeId'] as String?;
        if (placeId == null) return;
        if (ev.actorUid != fs.myUid) {
          _applyRemoteCaptureZonePlaced(ev);
        }
        // 捕獲対象になり得るのは生存者のみ（ゴーストはackしない）。
        if (running) {
          unawaited(_publishCaptureZoneAckIfNeeded(ev, fs, placeId));
        }
        if (_isHost && !_captureBoundTimers.containsKey(placeId)) {
          final cLat = ev.payload['centerLat'];
          final cLng = ev.payload['centerLng'];
          if (cLat is num && cLng is num) {
            _captureAcksByPlace.putIfAbsent(placeId, () => <String>{});
            _scheduleHostCaptureBoundOnce(
              placeId: placeId,
              center: LatLng(cLat.toDouble(), cLng.toDouble()),
            );
          }
        }
        return;
      case RoomMatchEventTypes.captureZoneBound:
        // 束縛→捕獲は生存者のみ（ゴーストは対象外）。
        if (running) _applyRemoteCaptureZoneBound(ev, fs);
        return;
      case RoomMatchEventTypes.captureZoneAck:
        if (_isHost) {
          final placeId = ev.payload['placeId'] as String?;
          if (placeId != null) {
            _captureAcksByPlace
                .putIfAbsent(placeId, () => <String>{})
                .add(ev.actorUid);
          }
        }
        return;
      case RoomMatchEventTypes.abortProposal:
        _handleAbortProposalEvent(ev);
        return;
      case RoomMatchEventTypes.abortVote:
        _handleAbortVoteEvent(ev);
        return;
      case RoomMatchEventTypes.playerEliminated:
        _applyRemotePlayerEliminated(ev);
        return;
      case RoomMatchEventTypes.accusationUnlocked:
        _applyAccusationUnlocked(ev);
        return;
      case RoomMatchEventTypes.accusationAttempt:
        if (!_isHost || _gameState != GameState.running) return;
        final accusedUid = ev.payload['accusedUid'] as String?;
        if (accusedUid == null || accusedUid.isEmpty) return;
        _hostResolveAccusationAttempt(
          accuserUid: ev.actorUid,
          accusedUid: accusedUid,
        );
        return;
      case RoomMatchEventTypes.accusationFailed:
        _applyRemoteAccusationFailed(ev);
        return;
      case RoomMatchEventTypes.accusationPointScored:
        _applyRemoteAccusationPointScored(ev);
        return;
      case RoomMatchEventTypes.cameraJack:
        _applyRemoteCameraJack(ev);
        return;
      case RoomMatchEventTypes.facilitySabotage:
        if (ev.actorUid == fs.myUid) return;
        _applyRemoteFacilitySabotage(ev);
        return;
      case RoomMatchEventTypes.spectralTerritory:
        if (ev.actorUid == fs.myUid) return;
        _applyRemoteSpectralTerritory(ev);
        return;
      case RoomMatchEventTypes.cameraShutdown:
        if (ev.actorUid == fs.myUid) return;
        _applyRemoteCameraShutdown(ev);
        return;
      default:
        return;
    }
  }

  void _applyRemotePlayerEliminated(RoomMatchEvent ev) {
    if (!mounted) return;
    final uid = ev.payload['uid'] as String? ?? ev.actorUid;
    final myUid = _firestoreSession?.myUid;
    final cause = ev.payload['cause'] as String? ?? 'eliminated';
    if (uid == myUid && _gameState == GameState.running) {
      final msg = cause == 'accusation_hunter'
          ? '告発により脱落 — 復讐の鬼影として戦線に残る'
          : '脱落 — 第二ゲームへ';
      _eliminateLocalParticipant(msg, cause: cause, publishOnline: false);
      return;
    }
    _syncSetState(() {
      _rt.syncedEliminationCount += 1;
      _eliminatedUids.add(uid);
    });
    _recordMatchFeed('誰かが脱落しました');
    _maybeHostPublishAccusationUnlock();
  }

  void _applyRemoteAccusationPointScored(RoomMatchEvent ev) {
    final total = (ev.payload['total'] as num?)?.toInt();
    if (total == null || !mounted) return;
    _syncSetState(() => _rt.accusationPointsHuman = total);
  }

  void _applyRemoteAccusationFailed(RoomMatchEvent ev) {
    final accuserUid = ev.payload['accuserUid'] as String?;
    final myUid = _firestoreSession?.myUid;
    if (accuserUid == myUid) {
      if (!_rt.accusationSpentByMe) {
        _syncSetState(() => _rt.accusationSpentByMe = true);
      }
      _applyAccusationFailureToAccuser(accuserUid!);
      return;
    }
    if (_localRole == PlayerRole.hunter) {
      _pushHudRevealAlert('告発失敗 — 誤った標的');
    }
  }

  void _applyRemoteReveal(RoomMatchEvent ev) {
    final pos = RoomMatchEvent.latLngFromPayload(ev.payload);
    if (pos == null) return;
    final label = ev.payload['playerLabel'] as String? ?? 'player1';
    final overflow = (ev.payload['overflowMeters'] as num?)?.toDouble() ?? 0;
    final reasonSummary = ev.payload['reasonSummary'] as String? ?? '通信混線';
    if (!mounted) return;
    _syncSetState(() {
      _rt.revealCount += 1;
      _rt.revealLog.insert(
        0,
        LocationRevealEvent(
          sequence: _rt.revealCount,
          timestamp: DateTime.now(),
          position: pos,
          overflowMeters: overflow,
          playerLabel: label,
          reasonSummary: reasonSummary,
          subjectUid: ev.actorUid,
        ),
      );
      if (_rt.revealLog.length > 50) _rt.revealLog.removeLast();
      _statusMessage = ev.payload['message'] as String? ?? '位置情報を受信';
    });
    unawaited(_ingestRemoteAvatarThumbs(_remoteMembers));
    _pushHudRevealAlert('$label の位置が露見しました（$reasonSummary）');
    HapticFeedback.mediumImpact();
    GameAudio.instance.playSfx(SfxId.reveal);
  }

  void _applyRemoteFakeIntelReveal(RoomMatchEvent ev) {
    final pos = RoomMatchEvent.latLngFromPayload(ev.payload);
    if (pos == null) return;
    final pickedSelf = ev.payload['pickedSelf'] == true;
    final targetUid = ev.payload['targetUid'] as String?;
    final myUid = _firestoreSession?.myUid;
    var label = ev.payload['playerLabel'] as String? ?? '不明なプレイヤー';
    if (!pickedSelf && targetUid != null && targetUid.isNotEmpty) {
      if (targetUid == myUid) {
        label = _localPlayerLabel;
      } else {
        label = _displayNameForUid(targetUid);
      }
    }
    final narrative = ev.payload['message'] as String? ?? '';
    final summary = ev.payload['reasonSummary'] as String? ?? '通信混線';
    final subjectUid = (targetUid != null && targetUid.isNotEmpty)
        ? targetUid
        : ev.actorUid;
    if (!mounted) return;
    _syncSetState(() {
      _rt.revealCount += 1;
      _rt.revealLog.insert(
        0,
        LocationRevealEvent(
          sequence: _rt.revealCount,
          timestamp: DateTime.now(),
          position: pos,
          overflowMeters: 0,
          playerLabel: label,
          reasonSummary: summary,
          subjectUid: subjectUid,
        ),
      );
      if (_rt.revealLog.length > 50) _rt.revealLog.removeLast();
      _statusMessage = narrative.isNotEmpty ? narrative : '位置が露見';
    });
    unawaited(_ingestRemoteAvatarThumbs(_remoteMembers));
    _pushHudRevealAlert('$label の位置が露見しました（$summary）');
    HapticFeedback.mediumImpact();
    GameAudio.instance.playSfx(SfxId.reveal);
  }

  void _applyRemoteInfoBroker(RoomMatchEvent ev) {
    final intel = ev.payload['intel'] as String?;
    final hitIndex = (ev.payload['hitIndex'] as num?)?.toInt();
    final nextLat = (ev.payload['nextLat'] as num?)?.toDouble();
    final nextLng = (ev.payload['nextLng'] as num?)?.toDouble();
    final pickupLat = (ev.payload['pickupLat'] as num?)?.toDouble();
    final pickupLng = (ev.payload['pickupLng'] as num?)?.toDouble();
    if (intel == null ||
        hitIndex == null ||
        nextLat == null ||
        nextLng == null ||
        pickupLat == null ||
        pickupLng == null) {
      return;
    }
    final tracePos = LatLng(pickupLat, pickupLng);
    if (hitIndex < 0 || hitIndex >= _rt.infoBrokerPositions.length) return;
    final now = DateTime.now();
    if (!mounted) return;
    _syncSetState(() {
      _rt.lastInfoBrokerAt = now;
      _rt.infoBrokerAvailable = false;
      _rt.infoBrokerRespawnAt = now.add(
        const Duration(seconds: GameConfig.infoBrokerRespawnSeconds),
      );
      _rt.lastOniIntelText = intel;
      _rt.lastOniIntelAt = now;
      _rt.showOniIntelCard = true;
      _rt.oniIntelTraces.insert(
        0,
        OniIntelTrace(timestamp: now, position: tracePos, text: intel),
      );
      if (_rt.oniIntelTraces.length > 20) {
        _rt.oniIntelTraces.removeLast();
      }
      _rt.infoBrokerPositions[hitIndex] = LatLng(nextLat, nextLng);
      _statusMessage = '情報屋: $intel';
    });
    HapticFeedback.lightImpact();
    GameAudio.instance.playSfx(SfxId.anonReveal);
  }

  void _applyRemoteOniInfoBroker(RoomMatchEvent ev) {
    final targetUid = ev.payload['targetUid'] as String?;
    final hitIndex = (ev.payload['hitIndex'] as num?)?.toInt();
    final nextLat = (ev.payload['nextLat'] as num?)?.toDouble();
    final nextLng = (ev.payload['nextLng'] as num?)?.toDouble();
    if (targetUid == null ||
        targetUid.isEmpty ||
        hitIndex == null ||
        nextLat == null ||
        nextLng == null) {
      return;
    }
    if (hitIndex < 0 || hitIndex >= _rt.infoBrokerPositions.length) return;
    final now = DateTime.now();
    final myUid = _firestoreSession?.myUid;
    if (!mounted) return;

    _syncSetState(() {
      _rt.infoBrokerAvailable = false;
      _rt.infoBrokerRespawnAt = now.add(
        const Duration(seconds: GameConfig.infoBrokerRespawnSeconds),
      );
      _rt.infoBrokerPositions[hitIndex] = LatLng(nextLat, nextLng);
    });

    if (myUid != targetUid) return;

    final raw = _positionForReveal;
    final pick = _reasonPickAt(raw);
    _emitIdentifiedReveal(
      revealKind: 'oni_info_broker',
      position: raw,
      playerLabel: _localPlayerLabel,
      pick: pick,
      syncLocalEventType: 'oni_info_broker',
    );
    HapticFeedback.heavyImpact();
    GameAudio.instance.playSfx(SfxId.reveal);
  }

  void _applyRemoteMatchEventLog(RoomMatchEvent ev) {
    final inner = ev.payload['innerType'] as String? ?? 'match_event';
    final msg = ev.payload['message'] as String? ?? '';
    final pos =
        RoomMatchEvent.latLngFromPayload(ev.payload) ?? _currentPosition;
    final endsAtMs = (ev.payload['endsAtMs'] as num?)?.toInt();
    final now = DateTime.now();
    final hunterUid = _hunterUidFromAssignments;

    if (inner == 'hunter_position' &&
        (hunterUid == null || ev.actorUid == hunterUid)) {
      _lastKnownHunterPositions[ev.actorUid] = pos;
      _recordOniPathSample(pos);
      final h = ev.payload['headingDeg'];
      if (h is num) {
        _lastKnownOniHeadingDegrees = h.toDouble();
      } else {
        _updateOniHeadingFromPosition(pos);
      }
      if (!mounted) return;
      _syncSetState(() {
        _oniPosition = pos;
        _remoteOniKnown = true;
      });
    } else if (inner == 'trace_drop') {
      if (!mounted) return;
      _syncSetState(() => _tracePoints.add(pos));
    } else if (inner == 'fake_start' &&
        endsAtMs != null &&
        ev.actorUid == _firestoreSession?.myUid) {
      final endsAt = DateTime.fromMillisecondsSinceEpoch(endsAtMs);
      if (!endsAt.isAfter(now)) return;
      if (!mounted) return;
      _syncSetState(() {
        _rt.fakePositionActive = true;
        _rt.fakePositionLatLng = pos;
        _rt.fakePositionEndsAt = endsAt;
        _lastFakeDriftAt = now;
      });
    } else if (inner == 'body_throw_start' && endsAtMs != null) {
      final endsAt = DateTime.fromMillisecondsSinceEpoch(endsAtMs);
      if (!endsAt.isAfter(now)) return;
      if (!mounted) return;
      _syncSetState(() {
        _rt.bodyThrowAwaitingMapTap = false;
        _rt.bodyThrowTapDeadline = null;
        _rt.bodyThrowPosition = pos;
        _rt.bodyThrowEndsAt = endsAt;
      });
    }

    final event = MatchEvent(
      type: inner,
      atUtc: now.toUtc(),
      message: msg,
      position: pos,
    );
    if (!mounted) return;
    _syncSetState(() {
      _rt.matchEvents.insert(0, event);
      if (_rt.matchEvents.length > 120) {
        _rt.matchEvents.removeLast();
      }
    });
  }

  void _onRemoteLobbyPhaseEvent(RoomMatchEvent ev) {
    if (!mounted || _gameState != GameState.waiting) return;
    final fs = _firestoreSession;
    switch (ev.type) {
      case RoomMatchEventTypes.lobbyPlayArea:
        if (fs != null && ev.actorUid == fs.myUid) return;
        _applyRemoteLobbyPlayArea(ev);
      case RoomMatchEventTypes.lobbyPlayAreaProposal:
        _applyRemotePlayAreaProposal(ev);
      default:
        break;
    }
  }
}
