part of 'game_map_screen.dart';

/// オンライン（Firestore ルーム）から受信したマッチイベントの適用処理。
///
/// `game_map_screen.dart` 本体（`_GameMapScreenState`）から物理的に切り出した
/// 受信ハンドラ群。挙動は本体にあった頃と完全に同一（同一ライブラリの extension）。
extension _GameMapOnlineSyncEvents on _GameMapScreenState {
  void _onRemoteRoomMatchEvent(RoomMatchEvent ev) {
    if (!mounted) return;
    if (!_roomEventDeduper.markIfNew(ev.id)) return;

    if (_gameState == GameState.waiting &&
        ev.sessionKey == lobbySessionKey) {
      _onRemoteLobbyPhaseEvent(ev);
      return;
    }

    final sk = _matchEventSessionKey;
    if (sk == null || ev.sessionKey != sk) return;
    // 捕獲後も残響体/鬼影として戦線に残るため、試合継続中はイベントを受け取る
    // （マップの暴露・鬼位置・他ゴーストの行動を反映し続ける）。
    final roomRunning =
        _firestoreSession?.currentPhase == RoomPhase.running;
    final acceptWhilePresenting =
        _matchPresentationActive && roomRunning;
    if (!_isMatchStillActiveForLocalPlayer && !acceptWhilePresenting) {
      return;
    }
    final running = _gameState == GameState.running;
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
        if (running) _applyRemoteCaptureZoneBound(ev, fs);
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
    _recordMatchFeed(MatchHudCopy.eliminatedFeed);
    _maybePublishAccusationUnlock();
    _maybeEndMatchForFactionElimination();
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
          timestamp: DateTime.now(),
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
