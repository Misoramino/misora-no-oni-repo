part of 'game_map_screen.dart';

/// スキル「捕獲結界」の配置・ack・bound・リモート適用。
///
/// ランタイムは歴史的に `lockZone*`（接触拘束と共用）。
/// Firestore イベントは `capture_zone_*`。致死可否は `capturePermitted`。
extension _GameMapCaptureZone on _GameMapScreenState {
  void _activateCaptureZone() {
    if (_gameState != GameState.running) return;
    if (!_skillLoadout.contains(SkillIds.captureZone)) return;
    if (_bodyThrowBlocksOtherSkills) {
      _toast('体投げの設置・回収が終わるまで使えません', denied: true);
      return;
    }
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
      _capturePlacedTargetsByPlace[placeId] =
          _captureTargetUidsForFirestore(rawTargets);
      _capturePermittedByPlace[placeId] = _captureZoneLethalForLocal;
      _captureAcksByPlace.putIfAbsent(placeId, () => <String>{});
      _scheduleCaptureBoundOnce(placeId: placeId, center: pos);
    }
  }

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
    _scheduleCaptureBoundOnce(placeId: placeId, center: center);
  }

  List<String> _captureTargetUidsFromPayload(Map<String, dynamic> payload) {
    final raw = payload['targetUids'];
    if (raw is! List) return const [];
    return raw.map((e) => e.toString()).toList(growable: false);
  }

  void _rememberCapturePlacedTargets(
    String placeId,
    List<String> targetUids, {
    bool? capturePermitted,
  }) {
    if (targetUids.isEmpty) return;
    _capturePlacedTargetsByPlace[placeId] = targetUids;
    if (capturePermitted != null) {
      _capturePermittedByPlace[placeId] = capturePermitted;
    }
  }

  List<String> _captureBoundTargetsSnapshot(String placeId) {
    final placed = _capturePlacedTargetsByPlace[placeId] ?? const [];
    final acked = _captureAcksByPlace[placeId]?.toList() ?? const [];
    return {...placed, ...acked}.toList(growable: false);
  }

  void _clearCaptureBoundTargets(String placeId) {
    _capturePlacedTargetsByPlace.remove(placeId);
    _captureAcksByPlace.remove(placeId);
    _capturePermittedByPlace.remove(placeId);
  }

  void _scheduleCaptureBoundOnce({
    required String placeId,
    required LatLng center,
    int rescueRetryAttempt = 0,
    Duration wait = const Duration(milliseconds: 6000),
  }) {
    if (_captureBoundTimers.containsKey(placeId)) return;
    final fs = _firestoreSession;
    final sk = _matchEventSessionKey;
    if (fs == null || sk == null) return;
    _captureBoundTimers[placeId] = Timer(
      wait,
      () async {
        _captureBoundTimers.remove(placeId);
        if (!mounted || _gameState != GameState.running) return;
        final targets = _captureBoundTargetsSnapshot(placeId);
        if (targets.isEmpty) {
          _clearCaptureBoundTargets(placeId);
          return;
        }
        final payload = {
          'placeId': placeId,
          'targetUids': targets,
          'centerLat': center.latitude,
          'centerLng': center.longitude,
          'durationSec': GameConfig.captureZoneDurationSeconds,
          'capturePermitted': _capturePermittedByPlace[placeId] ?? true,
          'fromSkill': true,
        };
        final String? err;
        if (_isHost) {
          err = await fs.publishHostRoomEvent(
            type: RoomMatchEventTypes.captureZoneBound,
            payload: payload,
            sessionKey: sk,
          );
        } else {
          // 非ホスト救済は「配置時」ではなく「発火時」にホスト不在を判定する。
          if (!_hostUnavailableForRescue()) {
            if (rescueRetryAttempt < 2) {
              _scheduleCaptureBoundOnce(
                placeId: placeId,
                center: center,
                rescueRetryAttempt: rescueRetryAttempt + 1,
                wait: const Duration(milliseconds: 2200),
              );
            }
            return;
          }
          final key = HostLightRescueKeys.captureBound(sk, placeId);
          if (_hostLightRescueEmittedKeys.contains(key)) {
            _clearCaptureBoundTargets(placeId);
            return;
          }
          err = await fs.publishHostLightRescueEvent(
            type: HostLightRescueEventTypes.captureZoneBoundRescue,
            idempotencyKey: key,
            payload: payload,
            sessionKey: sk,
          );
          if (err == null) {
            _rememberHostLightRescueKey(key);
          }
        }
        if (err == null) {
          _clearCaptureBoundTargets(placeId);
          return;
        }
        if (mounted) {
          _toast(err);
        }
        if (!_isHost && rescueRetryAttempt < 2) {
          _scheduleCaptureBoundOnce(
            placeId: placeId,
            center: center,
            rescueRetryAttempt: rescueRetryAttempt + 1,
            wait: const Duration(milliseconds: 2200),
          );
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

  void _applyRemoteCaptureZonePlaced(RoomMatchEvent ev) {
    final cLat = ev.payload['centerLat'];
    final cLng = ev.payload['centerLng'];
    final dur =
        (ev.payload['durationSec'] as num?)?.toInt() ??
        GameConfig.captureZoneDurationSeconds;
    if (cLat is! num || cLng is! num) return;
    final center = LatLng(cLat.toDouble(), cLng.toDouble());
    final now = DateTime.now();
    final fs = _firestoreSession;
    final myUid = fs?.myUid;
    final targetRaw = ev.payload['targetUids'];
    var boundSelf = false;
    if (myUid != null && targetRaw is List) {
      for (final t in targetRaw) {
        if (t.toString() == myUid) {
          boundSelf = true;
          break;
        }
      }
    }
    if (!mounted) return;
    _syncSetState(() {
      _rt.waitingSkillLockMapTap = false;
      _rt.lockZoneCenter = center;
      _rt.lockZoneFromSkill = CaptureZoneEventPayload.fromSkill(ev.payload);
      _rt.lockZoneBoundIds = boundSelf ? const {'self'} : const {};
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
    final dur =
        (ev.payload['durationSec'] as num?)?.toInt() ??
        GameConfig.captureZoneDurationSeconds;
    _recordGloballyBoundTargets(raw, durationSec: dur);
    final myUid = fs.myUid;
    final cLat = ev.payload['centerLat'];
    final cLng = ev.payload['centerLng'];
    final now = DateTime.now();
    if (!mounted) return;
    _syncSetState(() {
      if (cLat is num && cLng is num) {
        _rt.lockZoneCenter = LatLng(cLat.toDouble(), cLng.toDouble());
        _rt.lockZoneEndsAt = now.add(Duration(seconds: dur));
        _rt.lockZoneFromSkill = CaptureZoneEventPayload.fromSkill(ev.payload);
        _rt.lockZoneCapturePermitted =
            CaptureZoneEventPayload.capturePermitted(ev.payload);
      }
      if (myUid != null && targets.contains(myUid)) {
        _rt.lockZoneBoundIds = const {'self'};
        _rt.lockZoneTargetLeftAt = null;
        _rt.lockZoneEscapeRevealed = false;
      }
    });
    if (myUid != null && targets.contains(myUid)) {
      _maybeBackgroundCrisisAlert(
        kind: BackgroundCrisisKind.captureZoneBound,
        title: '捕獲結界',
        body: '結界内に拘束されました — アプリを開いて離脱してください',
      );
    }
  }
}
