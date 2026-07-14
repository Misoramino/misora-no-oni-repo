part of 'game_map_screen.dart';

/// 試合イベント送信・定期匿名暴露・Firestore reveal/gimmick publish。
///
/// online_sync が受信し、ここ（と reveals_gimmicks）が送信・適用の片側。
extension _GameMapMatchEvents on _GameMapScreenState {

  int? get _matchEventSessionKey =>
      _boundMatchSessionKey ?? _firestoreSession?.currentMatchStart?.gimmickSeed;

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
      position: _positionForReveal,
      pick: _reasonPickAt(_positionForReveal, periodic: true),
      source: 'periodic',
    );
  }

  void _emitAnonymousReveal({
    required LatLng position,
    required RevealReasonPick pick,
    required String source,
  }) {
    final shown = _mapRevealPosition(position, periodic: source == 'periodic');
    final errorMeters = Geolocator.distanceBetween(
      position.latitude,
      position.longitude,
      shown.latitude,
      shown.longitude,
    );
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
          errorMeters: errorMeters,
        ),
      );
      if (_rt.anonymousRevealTraces.length > 24) {
        _rt.anonymousRevealTraces.removeLast();
      }
      _statusMessage = MatchHudCopy.anonTraceFallback;
    });
    if (source == 'panic' || source == 'periodic' || source == 'camera') {
      _maybeBackgroundCrisisAlert(
        kind: BackgroundCrisisKind.panicTrace,
        title: GuideTerms.anonTrace,
        body: pick.summary,
      );
    }
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
        errorMeters: errorMeters,
      ),
    );
  }

  Future<void> _publishFirestoreAnonymousReveal({
    required LatLng position,
    required RevealReasonPick pick,
    required String source,
    required double errorMeters,
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
        'errorMeters': errorMeters,
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
    final errorRaw = ev.payload['errorMeters'];
    final errorMeters = errorRaw is num ? errorRaw.toDouble() : 0.0;
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
          errorMeters: errorMeters,
        ),
      );
      if (_rt.anonymousRevealTraces.length > 24) {
        _rt.anonymousRevealTraces.removeLast();
      }
    });
    _remoteLightFeedback();
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
    String? subjectUid,
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
        'subjectUid': ?subjectUid,
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
        'reasonSummary': '',
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

  Future<void> _publishFirestoreSafeZonePickup({
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
    final err = await fs.publishRoomEvent(
      type: RoomMatchEventTypes.safeZonePickup,
      payload: {
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
    final err = await fs.publishRoomEvent(
      type: RoomMatchEventTypes.oniInfoBroker,
      payload: {
        'targetUid': targetUid,
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

}
