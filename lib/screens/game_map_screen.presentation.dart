part of 'game_map_screen.dart';

/// 試合開始・終了の演出シーケンス。
extension _GameMapPresentation on _GameMapScreenState {
  List<MatchStartRosterEntry> _matchStartRosterEntries() {
    final snap = _firestoreSession?.currentMatchStart;
    final myUid = _firestoreSession?.myUid;
    if (snap != null) {
      final entries = <MatchStartRosterEntry>[];
      for (final e in snap.assignments.entries) {
        final uid = e.key;
        final remote = _remoteMembers[uid];
        var label = remote?.nickname.trim() ?? '';
        if (label.isEmpty) {
          label = uid == myUid ? _localPlayerLabel : 'Player';
        }
        entries.add(
          MatchStartRosterEntry(
            label: label,
            role: e.value.role,
            avatarThumbB64: remote?.avatarThumbB64,
            avatarImagePath: uid == myUid ? _avatarImagePath : null,
            isSelf: uid == myUid,
          ),
        );
      }
      entries.sort((a, b) {
        if (a.isSelf != b.isSelf) return a.isSelf ? -1 : 1;
        return a.label.compareTo(b.label);
      });
      return entries;
    }
    return [
      MatchStartRosterEntry(
        label: _localPlayerLabel,
        role: _localRole,
        avatarImagePath: _avatarImagePath,
        isSelf: true,
      ),
    ];
  }

  bool _shouldShowMatchStartRoster({
    required bool rejoin,
    required bool shortCeremony,
    int elapsedSeconds = 0,
  }) {
    if (shortCeremony || (rejoin && elapsedSeconds > 20)) return false;
    return _matchStartRosterEntries().isNotEmpty;
  }

  bool _shouldShowAreaOrbitCinema({
    required bool rejoin,
    required bool shortCeremony,
    int elapsedSeconds = 0,
  }) {
    if (shortCeremony || (rejoin && elapsedSeconds > 12)) return false;
    return true;
  }

  Future<void> _maybeShowPreMatchRoleBriefing({required bool rejoin}) async {
    if (!mounted || rejoin || _matchRoleBriefingShown) return;
    _matchRoleBriefingShown = true;
    final followUp = await showRoleBriefingDialog(
      context,
      role: _localRole,
      worldProfile: _activeProfile,
      skillLabels: _skillLoadout.map(_skillLabelForUi).toList(),
      werewolfCurrentFaction: _localRole == PlayerRole.werewolf
          ? _localFactionNow()
          : null,
      runnerModifier: _localRole == PlayerRole.runner
          ? _localRunnerModifier
          : RunnerModifier.none,
    );
    if (!mounted) return;
    if (followUp == 'learn_more') {
      await showHowToPlaySheet(
        context,
        yourRole: _localRole,
        initialSectionId: 'roles',
      );
    }
  }

  Future<GoogleMapController?> _ensureMapControllerForPresentation() async {
    if (_mapController != null) return _mapController;
    _syncSetState(() {
      _prepMapMode = PrepMapMode.browse;
      _prepControlSheetOpen = false;
    });
    final deadline = DateTime.now().add(const Duration(seconds: 4));
    while (mounted && _mapController == null) {
      await Future<void>.delayed(const Duration(milliseconds: 80));
      if (DateTime.now().isAfter(deadline)) break;
    }
    return _mapController;
  }

  Future<void> _runMatchStartPresentation({
    required bool rejoin,
    required bool inspector,
    int elapsedSeconds = 0,
    bool remoteSyncJoin = false,
  }) async {
    if (!mounted) return;

    _matchPresentationActive = true;
    _dismissBlockingOverlaysForMatchJoin();
    _syncSetState(() {
      _prepMapMode = PrepMapMode.browse;
      _prepControlSheetOpen = false;
    });

    try {
      if (inspector) {
        await WorldPhaseFlash.pulse(context, profile: _activeProfile);
        return;
      }

      if (remoteSyncJoin) {
        if (elapsedSeconds > GameConfig.syncJoinRoleBriefingMaxSeconds) {
          if (mounted) {
            await showMatchRejoinNotice(
              context: context,
              remainingSeconds: _rt.remainingSeconds,
              roleLabel: _localRole.displayName,
            );
          }
        } else if (elapsedSeconds >
            GameConfig.syncJoinFullPresentationMaxSeconds) {
          if (mounted) {
            await showMatchRejoinNotice(
              context: context,
              remainingSeconds: _rt.remainingSeconds,
              roleLabel: _localRole.displayName,
            );
          }
          if (mounted) {
            await _maybeShowPreMatchRoleBriefing(rejoin: false);
          }
        } else {
          final shortCeremony =
              await MatchPresentationPrefs.shortMatchStartCeremony();
          if (_shouldShowMatchStartRoster(
            rejoin: false,
            shortCeremony: shortCeremony,
            elapsedSeconds: elapsedSeconds,
          )) {
            await showMatchStartRoster(
              context: context,
              profile: _activeProfile,
              entries: _matchStartRosterEntries(),
            );
            if (!mounted) return;
          }
          if (mounted) {
            await _maybeShowPreMatchRoleBriefing(rejoin: false);
          }
        }
        if (mounted) {
          await WorldPhaseFlash.pulse(context, profile: _activeProfile);
        }
        return;
      }

    if (rejoin && elapsedSeconds > 15) {
      if (mounted) {
        await showMatchRejoinNotice(
          context: context,
          remainingSeconds: _rt.remainingSeconds,
          roleLabel: _localRole.displayName,
        );
      }
      return;
    }

    final shortCeremony = await MatchPresentationPrefs.shortMatchStartCeremony();

    if (_shouldShowMatchStartRoster(
      rejoin: rejoin,
      shortCeremony: shortCeremony,
      elapsedSeconds: elapsedSeconds,
    )) {
      await showMatchStartRoster(
        context: context,
        profile: _activeProfile,
        entries: _matchStartRosterEntries(),
      );
      if (!mounted) return;
    }

    if (_shouldShowAreaOrbitCinema(
      rejoin: rejoin,
      shortCeremony: shortCeremony,
      elapsedSeconds: elapsedSeconds,
    )) {
      final mapController =
          _mapController ?? await _ensureMapControllerForPresentation();
      await runPlayAreaOrbitCinema(
        context: context,
        area: _playArea,
        profile: _activeProfile,
        mapStyleJson: _mapVisual.mapStyleJson,
        tokens: _mapVisual.pack.tokens,
        mapController: mapController,
        onApplyMapStyle: _applyTransientMapStyle,
      );
      if (!mounted) return;
    }

    if (!rejoin) {
      await showMatchStartCountdown(
        context: context,
        profile: _activeProfile,
        pack: _mapVisual.pack,
      );
      if (!mounted) return;
      await _maybeShowPreMatchRoleBriefing(rejoin: rejoin);
      if (!mounted) return;
    }

    await WorldPhaseFlash.pulse(context, profile: _activeProfile);
    } finally {
      _matchPresentationActive = false;
    }
  }

  Future<void> _playMatchEndFlash() async {
    if (!mounted || _isRoomInspector) return;
    await WorldPhaseFlash.pulse(
      context,
      profile: _activeProfile,
      kind: WorldPhaseFlashKind.end,
    );
  }

  Future<void> _uploadOnlineMatchArchive(SavedMatchRecord rec) async {
    final fs = _firestoreSession;
    if (fs == null || !_isOnlineFirestore) return;
    // ソロ（参加者が自分だけ）のときは共有先がないため、端末保存のみで終了。
    // 権限エラー等のオンライン共有失敗メッセージをユーザーに見せない。
    if (!_isRoomInspector && _lobbyParticipantCount() <= 1) return;
    final sessionKey = fs.currentMatchStart?.gimmickSeed;
    if (sessionKey == null) return;

    try {
      if (_isRoomInspector) {
        final err = await fs.publishMatchArchiveFull(
          sessionKey: sessionKey,
          record: rec,
        );
        if (err != null && mounted) {
          _toast('観戦記録の共有に失敗: $err');
        }
        await _fetchAndSaveMergedArchive(rec, sessionKey);
        return;
      }

      if (!rec.consentedToTrajectory) {
        await _fetchAndSaveMergedArchive(rec, sessionKey);
        return;
      }

      final samples = _trackSamplesForArchiveUpload(rec);
      if (samples.length >= 2) {
        final err = await fs.publishMatchTrackChunk(
          sessionKey: sessionKey,
          nickname: _localPlayerLabel,
          role: _localRole,
          samples: samples,
        );
        if (err != null && mounted) {
          _toast('軌跡の共有に失敗: $err');
        }
      }

      final metaErr = await fs.publishMatchArchiveMeta(
        sessionKey: sessionKey,
        record: rec,
      );
      if (metaErr != null && mounted) {
        final solo = _lobbyParticipantCount() <= 1;
        _toast(
          solo
              ? 'この端末には記録を保存しました。オンライン共有はできませんでした（$metaErr）'
              : '試合ログの共有に失敗: $metaErr',
        );
      }

      await _fetchAndSaveMergedArchive(rec, sessionKey);
    } catch (_) {}
  }

  List<TrajectorySample> _trackSamplesForArchiveUpload(SavedMatchRecord rec) {
    if (_localRole == PlayerRole.hunter) {
      return rec.tracks[MatchTrackIds.oniLocal] ??
          rec.tracks[MatchTrackIds.runnerLocal] ??
          const [];
    }
    return rec.tracks[MatchTrackIds.runnerLocal] ?? const [];
  }

  Future<void> _fetchAndSaveMergedArchive(
    SavedMatchRecord local,
    int sessionKey,
  ) async {
    final fs = _firestoreSession;
    if (fs == null || !_isOnlineFirestore) return;
    await Future<void>.delayed(const Duration(seconds: 3));
    if (!mounted) return;
    try {
      final remote = await fs.fetchMergedMatchArchive(
        sessionKey,
        localFallback: local,
      );
      if (remote == null || !mounted) return;
      final merged = MatchArchiveMerger.merge(local: local, remote: remote);
      _lastMergedMatchRecord = merged;
      await _matchArchive.save(merged);
      if (mounted && merged.tracks.length > local.tracks.length) {
        _toast('全員の軌跡を取得しました（ギャラリーで再生）');
      }
    } catch (_) {}
  }

  Future<void> _openMatchReplay({SavedMatchRecord? prefer}) async {
    final local = prefer ?? _lastMergedMatchRecord ?? _lastSavedMatchRecord;
    if (local == null) {
      if (mounted) _toast('再生できる軌跡がありません');
      return;
    }

    final fs = _firestoreSession;
    final sessionKey =
        fs?.currentMatchStart?.gimmickSeed ?? _lastMatchSessionKey;
    final attemptRemote =
        fs != null && sessionKey != null && _isOnlineFirestore;

    var loadingShown = false;
    if (attemptRemote && mounted) {
      loadingShown = true;
      unawaited(
        showDialog<void>(
          context: context,
          barrierDismissible: false,
          builder: (ctx) => PopScope(
            canPop: false,
            child: AlertDialog(
              content: Row(
                children: [
                  const CircularProgressIndicator(),
                  const SizedBox(width: 20),
                  Expanded(
                    child: Text(
                      '試合記録を更新しています…',
                      style: Theme.of(ctx).textTheme.bodyMedium,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    final firestore = fs;
    final key = sessionKey;

    MatchReplayResolveResult resolved;
    try {
      resolved = await MatchReplayLatestFetch.resolveForResultReplay(
        local: local,
        attemptRemote: attemptRemote,
        fetchRemote: attemptRemote && firestore != null && key != null
            ? () => firestore.fetchMergedMatchArchive(
                  key,
                  localFallback: local,
                )
            : null,
      );
    } finally {
      if (loadingShown && mounted) {
        Navigator.of(context, rootNavigator: true).pop();
      }
    }

    if (!mounted) return;

    final toast = MatchReplayLatestFetch.toastAfterResolve(
      resolved,
      attemptedRemote: attemptRemote,
    );
    if (toast != null) _toast(toast);

    final rec = resolved.record;
    if (rec == null) {
      _toast('再生できる軌跡がありません');
      return;
    }

    if (resolved.source == MatchReplayFetchSource.remoteMerged) {
      _lastMergedMatchRecord = rec;
      await _matchArchive.save(rec);
    }

    if (!mounted) return;
    await AppNav.push<void>(
      context,
      (_) => MatchReplayScreen(record: rec),
      worldProfile: rec.effectiveWorldProfile,
    );
  }
}
