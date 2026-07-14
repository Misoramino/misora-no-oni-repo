part of 'game_map_screen.dart';

/// オンライン（Firestore ルーム）から受信したマッチイベントのディスパッチ。
///
/// 実際の適用ロジックは型ごとに他 part に置く。ここは **入り口の一覧**。
///
/// | イベント | 適用先（目安） |
/// |---|---|
/// | `reveal` / `anonymous_reveal` / `fake_intel_reveal` | match_events / reveals_gimmicks |
/// | `info_broker` / `oni_info_broker` / `safe_zone_pickup` | match_events / reveals_gimmicks |
/// | `capture_zone_placed` / `bound` / `ack` | capture_zone |
/// | `accusation_*` | accusation |
/// | `player_eliminated` / host-light rescue | online_sync 内 + second_game |
/// | `camera_jack` / `spectral_territory` / sabotage / shutdown | second_game |
/// | `match_end_rescue` / abort* | match_lifecycle / host_light |
/// | lobby `lobby_play_area*` | play_area |
extension _GameMapOnlineSyncEvents on _GameMapScreenState {
  DateTime _eventTimestamp(RoomMatchEvent ev) =>
      DateTime.fromMillisecondsSinceEpoch(ev.emittedAtMs, isUtc: true).toLocal();

  void _onRemoteRoomMatchEvent(RoomMatchEvent ev) {
    if (!mounted) return;

    if (_gameState == GameState.waiting &&
        ev.sessionKey == lobbySessionKey) {
      if (!_roomEventDeduper.markIfNew(ev.id)) return;
      _onRemoteLobbyPhaseEvent(ev);
      return;
    }

    final sk = _boundMatchSessionKey ?? _matchEventSessionKey;
    if (sk == null || ev.sessionKey != sk) return;

    if (MatchSyncGate.shouldBufferMatchEvent(
      syncArmed: _matchSyncArmed,
      stillActive: _isMatchStillActiveForLocalPlayer,
      eventSessionKey: ev.sessionKey,
      boundSessionKey: sk,
    )) {
      _bufferedMatchEvents.add(ev);
      return;
    }

    if (!_roomEventDeduper.markIfNew(ev.id)) return;
    _applyRemoteRoomMatchEvent(ev);
  }

  void _applyRemoteRoomMatchEvent(RoomMatchEvent ev) {
    if (!mounted) return;

    final sk = _boundMatchSessionKey ?? _matchEventSessionKey;
    if (sk == null || ev.sessionKey != sk) return;
    // 捕獲後も残響体/鬼影として戦線に残るため、試合継続中はイベントを受け取る
    // （マップの暴露・鬼位置・他ゴーストの行動を反映し続ける）。
    final roomRunning =
        _firestoreSession?.currentPhase == RoomPhase.running;
    final syncLive = _matchSyncArmed && roomRunning;
    if (!_isMatchStillActiveForLocalPlayer && !syncLive && !roomRunning) {
      return;
    }
    final running = _gameState == GameState.running;
    final secondGameActive = _isMatchStillActiveForLocalPlayer && !running;
    final matchActive = running || syncLive || secondGameActive;
    final fs = _firestoreSession;
    if (fs == null) return;

    switch (ev.type) {
      case RoomMatchEventTypes.matchStart:
      case RoomMatchEventTypes.matchEnd:
        return;
      case RoomMatchEventTypes.matchEndRescue:
        final outcomeRaw = ev.payload['outcome'] as String?;
        if (outcomeRaw == null) return;
        final outcome = GameState.values.firstWhere(
          (s) => s.name == outcomeRaw,
          orElse: () => GameState.waiting,
        );
        if (outcome == GameState.waiting) return;
        final message =
            ev.payload['message'] as String? ?? MatchHudCopy.matchEndTimeUp();
        final endReason =
            ev.payload['endReason'] as String? ?? MatchEndReason.timeUp;
        _maybeBackgroundCrisisAlert(
          kind: BackgroundCrisisKind.matchEnded,
          title: '試合終了',
          body: message,
        );
        _endGame(
          outcome,
          message,
          endReason: endReason,
          skipFirestoreSync: true,
        );
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
      case RoomMatchEventTypes.safeZonePickup:
        if (ev.actorUid == fs.myUid) return;
        _applyRemoteSafeZonePickup(ev);
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
        _rememberCapturePlacedTargets(
          placeId,
          _captureTargetUidsFromPayload(ev.payload),
          capturePermitted:
              CaptureZoneEventPayload.capturePermitted(ev.payload),
        );
        if (ev.actorUid != fs.myUid) {
          _applyRemoteCaptureZonePlaced(ev);
        }
        // 捕獲対象になり得るのは生存者のみ（ゴーストはackしない）。
        if (matchActive) {
          unawaited(_publishCaptureZoneAckIfNeeded(ev, fs, placeId));
        }
        if (_isHost && !_captureBoundTimers.containsKey(placeId)) {
          final cLat = ev.payload['centerLat'];
          final cLng = ev.payload['centerLng'];
          if (cLat is num && cLng is num) {
            _captureAcksByPlace.putIfAbsent(placeId, () => <String>{});
            _scheduleCaptureBoundOnce(
              placeId: placeId,
              center: LatLng(cLat.toDouble(), cLng.toDouble()),
            );
          }
        } else if (!_isHost) {
          final cLat = ev.payload['centerLat'];
          final cLng = ev.payload['centerLng'];
          if (cLat is num && cLng is num) {
            _captureAcksByPlace.putIfAbsent(placeId, () => <String>{});
            _maybeScheduleCaptureBoundRescue(
              placeId: placeId,
              center: LatLng(cLat.toDouble(), cLng.toDouble()),
            );
          }
        }
        return;
      case RoomMatchEventTypes.captureZoneBound:
      case HostLightRescueEventTypes.captureZoneBoundRescue:
        // 束縛→捕獲は生存者のみ（ゴーストは対象外）。
        if (matchActive) _applyRemoteCaptureZoneBound(ev, fs);
        return;
      case RoomMatchEventTypes.captureZoneAck:
        final placeId = ev.payload['placeId'] as String?;
        if (placeId != null &&
            (_isHost || (!_isHost && _hostUnavailableForRescue()))) {
          _captureAcksByPlace
              .putIfAbsent(placeId, () => <String>{})
              .add(ev.actorUid);
        }
        return;
      case RoomMatchEventTypes.abortProposal:
        _handleAbortProposalEvent(ev);
        return;
      case RoomMatchEventTypes.abortVote:
        _handleAbortVoteEvent(ev);
        return;
      case RoomMatchEventTypes.abortMajority:
        if (ev.actorUid == fs.myUid) return;
        unawaited(
          _applyAbortMajority(
            ev.payload['message'] as String? ?? '試合を中止しました',
            fromSelf: false,
          ),
        );
        return;
      case RoomMatchEventTypes.playerEliminated:
      case HostLightRescueEventTypes.playerEliminatedRescue:
      case HostLightRescueEventTypes.oniCaptureElimination:
        _applyRemotePlayerEliminated(ev);
        return;
      case RoomMatchEventTypes.accusationUnlocked:
      case HostLightRescueEventTypes.accusationUnlockedRescue:
        _applyAccusationUnlocked(ev);
        return;
      case RoomMatchEventTypes.accusationAttempt:
        if (_gameState != GameState.running) return;
        final accusedUid = ev.payload['accusedUid'] as String?;
        if (accusedUid == null || accusedUid.isEmpty) return;
        if (_isHost) {
          _hostResolveAccusationAttempt(
            accuserUid: ev.actorUid,
            accusedUid: accusedUid,
          );
          return;
        }
        // ホスト不通時: ホストを引き継いで解決（告発消費の宙吊り防止）。
        if (_hostUnavailableForRescue()) {
          unawaited(
            _maybeParticipantResolveAccusationAttempt(
              accuserUid: ev.actorUid,
              accusedUid: accusedUid,
              eventId: ev.id,
            ),
          );
        }
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
    if (_rt.accusationAwaitingResolution &&
        (cause == 'accusation_hunter' || cause == 'accusation_failed')) {
      _syncSetState(() {
        _rt.accusationSpentByMe = true;
        _rt.accusationAwaitingResolution = false;
      });
    }
    if (uid == myUid && _gameState == GameState.running) {
      final msg = switch (cause) {
        'accusation_hunter' =>
          '${MatchHudCopy.accusationSuccess} — ${GuideTerms.vengefulShadow}として戦線に残る',
        'disconnect' => MatchHudCopy.eliminatedByDisconnect,
        _ => '${MatchHudCopy.captureSucceeded} — ${GuideTerms.secondGame}へ',
      };
      _maybeBackgroundCrisisAlert(
        kind: BackgroundCrisisKind.eliminated,
        title: '脱落',
        body: msg,
      );
      _eliminateLocalParticipant(msg, cause: cause, publishOnline: false);
      return;
    }
    _syncSetState(() {
      _rt.syncedEliminationCount += 1;
      _eliminatedUids.add(uid);
    });
    final label =
        ev.payload['playerLabel'] as String? ?? _displayNameForUid(uid);
    final lat = ev.payload['lat'];
    final lng = ev.payload['lng'];
    final overflow =
        (ev.payload['overflowMeters'] as num?)?.toDouble() ?? 0;
    final reasonSummary = switch (cause) {
      'outside' => 'エリア外',
      'caught' => '捕獲',
      'disconnect' => '切断',
      _ => '脱落',
    };
    if (lat is num && lng is num) {
      final revealPos = LatLng(lat.toDouble(), lng.toDouble());
      _syncSetState(() {
        _rt.revealCount += 1;
        _rt.revealLog.insert(
          0,
          LocationRevealEvent(
            sequence: _rt.revealCount,
            timestamp: _eventTimestamp(ev),
            position: revealPos,
            overflowMeters: overflow,
            playerLabel: label,
            reasonSummary: reasonSummary,
            subjectUid: uid,
          ),
        );
        if (_rt.revealLog.length > 50) _rt.revealLog.removeLast();
      });
      unawaited(_ingestRemoteAvatarThumbs(_remoteMembers));
      _pushHudRevealAlert(MatchHudCopy.namedRevealAlert(label, reasonSummary));
      _remoteRevealFeedback(heavy: true);
    } else {
      _pushHudRevealAlert('$labelが脱落しました');
    }
    _recordMatchFeed(MatchHudCopy.eliminatedFeed);
    _maybePublishAccusationUnlock();
    _maybeEndMatchForFactionElimination();
  }

  void _applyRemoteAccusationPointScored(RoomMatchEvent ev) {
    final total = (ev.payload['total'] as num?)?.toInt();
    if (total == null || !mounted) return;
    _syncSetState(() {
      _rt.accusationPointsHuman = total;
      if (_rt.accusationAwaitingResolution) {
        _rt.accusationSpentByMe = true;
        _rt.accusationAwaitingResolution = false;
      }
    });
  }

  void _applyRemoteAccusationFailed(RoomMatchEvent ev) {
    final accuserUid = ev.payload['accuserUid'] as String?;
    final myUid = _firestoreSession?.myUid;
    if (accuserUid == myUid) {
      _applyAccusationFailureToAccuser(accuserUid!);
      return;
    }
    if (_localRole == PlayerRole.hunter) {
      _pushHudRevealAlert(
        '${MatchHudCopy.accusationFailed} — ${MatchHudCopy.accusationFailedDetail}',
      );
    }
  }

  void _applyRemoteReveal(RoomMatchEvent ev) {
    final pos = RoomMatchEvent.latLngFromPayload(ev.payload);
    if (pos == null) return;
    final label = ev.payload['playerLabel'] as String? ?? 'player1';
    final overflow = (ev.payload['overflowMeters'] as num?)?.toDouble() ?? 0;
    final reasonSummary = ev.payload['reasonSummary'] as String? ?? '通信混線';
    final subjectUid =
        ev.payload['subjectUid'] as String? ?? ev.actorUid;
    if (!mounted) return;
    _syncSetState(() {
      _rt.revealCount += 1;
      _rt.revealLog.insert(
        0,
        LocationRevealEvent(
          sequence: _rt.revealCount,
          timestamp: _eventTimestamp(ev),
          position: pos,
          overflowMeters: overflow,
          playerLabel: label,
          reasonSummary: reasonSummary,
          subjectUid: subjectUid,
        ),
      );
      if (_rt.revealLog.length > 50) _rt.revealLog.removeLast();
      _statusMessage = ev.payload['message'] as String? ?? '位置情報を受信';
    });
    unawaited(_ingestRemoteAvatarThumbs(_remoteMembers));
    _pushHudRevealAlert(MatchHudCopy.namedRevealAlert(label, reasonSummary));
    _remoteRevealFeedback();
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
    final summary = ev.payload['reasonSummary'] as String? ?? '';
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
          timestamp: _eventTimestamp(ev),
          position: pos,
          overflowMeters: 0,
          playerLabel: label,
          reasonSummary: summary,
          subjectUid: subjectUid,
        ),
      );
      if (_rt.revealLog.length > 50) _rt.revealLog.removeLast();
      _statusMessage =
          narrative.isNotEmpty ? narrative : MatchHudCopy.anonTraceFallback;
    });
    unawaited(_ingestRemoteAvatarThumbs(_remoteMembers));
    if (targetUid == myUid) {
      _maybeBackgroundCrisisAlert(
        kind: BackgroundCrisisKind.selfNamedReveal,
        title: MatchUiTerms.namedReveal,
        body: MatchHudCopy.namedRevealAlert(label, summary),
      );
    }
    _pushHudRevealAlert(MatchHudCopy.namedRevealAlert(label, summary));
    _remoteRevealFeedback();
  }

  void _applyRemoteInfoBroker(RoomMatchEvent ev) {
    final hitIndex = (ev.payload['hitIndex'] as num?)?.toInt();
    final nextLat = (ev.payload['nextLat'] as num?)?.toDouble();
    final nextLng = (ev.payload['nextLng'] as num?)?.toDouble();
    if (hitIndex == null || nextLat == null || nextLng == null) {
      return;
    }
    if (hitIndex < 0 || hitIndex >= _rt.infoBrokerPositions.length) return;
    if (!mounted) return;
    // 他プレイヤーの鬼情報は共有しない。地点移動だけ同期する。
    _applyRemoteGimmickRelocate(
      kind: 'info_broker',
      hitIndex: hitIndex,
      nextPosition: LatLng(nextLat, nextLng),
    );
  }

  void _applyRemoteSafeZonePickup(RoomMatchEvent ev) {
    final hitIndex = (ev.payload['hitIndex'] as num?)?.toInt();
    final nextLat = (ev.payload['nextLat'] as num?)?.toDouble();
    final nextLng = (ev.payload['nextLng'] as num?)?.toDouble();
    if (hitIndex == null || nextLat == null || nextLng == null) {
      return;
    }
    if (hitIndex < 0 || hitIndex >= _rt.safeZonePositions.length) return;
    if (!mounted) return;
    _applyRemoteGimmickRelocate(
      kind: 'safe_zone',
      hitIndex: hitIndex,
      nextPosition: LatLng(nextLat, nextLng),
    );
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
    if (!mounted) return;
    final myUid = _firestoreSession?.myUid;

    _applyRemoteGimmickRelocate(
      kind: 'info_broker',
      hitIndex: hitIndex,
      nextPosition: LatLng(nextLat, nextLng),
    );

    unawaited(_ingestRemoteAvatarThumbs(_remoteMembers));

    if (myUid != targetUid) return;

    const pick = RevealReasonPick.exactLocation;
    _maybeBackgroundCrisisAlert(
      kind: BackgroundCrisisKind.selfNamedReveal,
      title: '情報屋 — 位置暴露',
      body: MatchHudCopy.namedRevealAlert(_localPlayerLabel, pick.summary),
    );
    final raw = _positionForReveal;
    _emitIdentifiedReveal(
      revealKind: 'oni_info_broker',
      position: raw,
      playerLabel: _localPlayerLabel,
      pick: pick,
      syncLocalEventType: 'oni_info_broker',
      subjectUid: targetUid,
    );
    _remoteRevealFeedback(heavy: true);
  }

  void _applyRemoteMatchEventLog(RoomMatchEvent ev) {
    final inner = ev.payload['innerType'] as String? ?? 'match_event';
    final msg = ev.payload['message'] as String? ?? '';
    final pos =
        RoomMatchEvent.latLngFromPayload(ev.payload) ?? _currentPosition;
    final endsAtMs = (ev.payload['endsAtMs'] as num?)?.toInt();
    final now = DateTime.now();
    final hunterUid = _hunterUidFromAssignments;

    if (inner == 'hunter_position' && _isPerceivedOniActor(ev.actorUid)) {
      _lastKnownHunterPositions[ev.actorUid] = pos;
      final isAssignedHunter = ev.actorUid == hunterUid;
      if (isAssignedHunter) {
        _recordAssignedHunterPathSample(pos);
      }
      _recordOniPathSample(pos);
      final h = ev.payload['headingDeg'];
      if (isAssignedHunter) {
        if (h is num) {
          _lastKnownAssignedHunterHeadingDegrees = h.toDouble();
          _lastKnownOniHeadingDegrees = h.toDouble();
        } else {
          _updateOniHeadingFromPosition(pos, updateAssignedHunter: true);
        }
      } else if (h is num) {
        _lastKnownOniHeadingDegrees = h.toDouble();
      }
      if (!mounted) return;
      _syncSetState(() {
        _oniPosition = _nearestPerceivedOniPosition;
        _remoteOniKnown = true;
      });
      _publishMapOverlay(force: true);
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

  int? get _activeMatchSessionKey =>
      _boundMatchSessionKey ?? _matchEventSessionKey;

  Future<void> _armMatchSync() async {
    if (!_isOnlineFirestore || !mounted) return;
    final sk = _activeMatchSessionKey;
    if (sk != null && sk != _armedSyncSessionKey) {
      _lastOnlineEventSyncAtMs = 0;
      _armedSyncSessionKey = sk;
    }
    _matchSyncArmed = true;
    final pending = MatchSyncGate.sortedForReplay(_bufferedMatchEvents);
    _bufferedMatchEvents.clear();
    for (final ev in pending) {
      if (!mounted) return;
      if (!_roomEventDeduper.markIfNew(ev.id)) continue;
      _applyRemoteRoomMatchEvent(ev);
    }
    _startOnlineEventSyncPump();
    await _bootstrapOnlineMatchEvents();
    if (!mounted) return;
    if (_isPerceivedOniNow && !_isRoomInspector) {
      _maybePublishHunterPosition(_currentPosition, force: true);
    }
  }

  void _disarmMatchSync() {
    _matchSyncArmed = false;
    _armedSyncSessionKey = null;
    _bufferedMatchEvents.clear();
  }

  Future<void> _recoverOnlineMatchSync() async {
    if (!_isOnlineFirestore || !mounted || !_matchSyncArmed) return;
    final sk = _activeMatchSessionKey;
    final fs = _firestoreSession;
    if (sk == null || fs == null) return;
    fs.restartRoomEventsListener(sk);
    _lastOnlineEventSyncAtMs = 0;
    await _bootstrapOnlineMatchEvents();
  }

  Future<void> _bootstrapOnlineMatchEvents() async {
    if (!_isOnlineFirestore || !mounted) return;
    final sk = _activeMatchSessionKey;
    final fs = _firestoreSession;
    if (sk == null || fs == null) return;
    List<RoomMatchEvent> events;
    try {
      events = await fs.fetchMatchEvents(sk);
    } catch (_) {
      return;
    }
    if (!mounted) return;
    events.sort((a, b) => a.emittedAtMs.compareTo(b.emittedAtMs));
    for (final ev in events) {
      if (ev.emittedAtMs < _lastOnlineEventSyncAtMs) continue;
      _onRemoteRoomMatchEvent(ev);
      _lastOnlineEventSyncAtMs = ev.emittedAtMs;
    }
  }

  void _startOnlineEventSyncPump() {
    _onlineEventSyncTimer?.cancel();
    if (!_isOnlineFirestore) return;
    _onlineEventSyncTimer = Timer.periodic(const Duration(seconds: 8), (_) {
      if (!mounted) return;
      if (!_matchSyncArmed &&
          _gameState != GameState.running &&
          _gameState != GameState.caughtByOni) {
        return;
      }
      unawaited(_bootstrapOnlineMatchEvents());
    });
  }

  void _stopOnlineEventSyncPump() {
    _onlineEventSyncTimer?.cancel();
    _onlineEventSyncTimer = null;
    _lastOnlineEventSyncAtMs = 0;
  }
}
