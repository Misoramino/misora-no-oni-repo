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
    await showRoleBriefingDialog(
      context,
      role: _localRole,
      skillLabels: _skillLoadout.map(_skillLabelForUi).toList(),
      werewolfCurrentFaction: _localRole == PlayerRole.werewolf
          ? _localFactionNow()
          : null,
    );
  }

  Future<void> _runMatchStartPresentation({
    required bool rejoin,
    required bool inspector,
    int elapsedSeconds = 0,
  }) async {
    if (!mounted) return;

    _syncSetState(() {
      _prepMapMode = PrepMapMode.browse;
      _prepControlSheetOpen = false;
    });

    if (inspector) {
      await WorldPhaseFlash.pulse(context, profile: _activeProfile);
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
      await runPlayAreaOrbitCinema(
        context: context,
        area: _playArea,
        profile: _activeProfile,
        mapStyleJson: _mapVisual.mapStyleJson,
        tokens: _mapVisual.pack.tokens,
        mapController: _mapController,
      );
      if (!mounted) return;
    }

    if (!rejoin) {
      await _maybeShowPreMatchRoleBriefing(rejoin: rejoin);
      if (!mounted) return;
    }

    await showMatchStartCountdown(
      context: context,
      profile: _activeProfile,
      pack: _mapVisual.pack,
    );
    if (!mounted) return;
    await WorldPhaseFlash.pulse(context, profile: _activeProfile);
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
        return;
      }

      if (!rec.consentedToTrajectory) return;
      final samples = rec.tracks[MatchTrackIds.runnerLocal] ?? const [];
      if (samples.length < 2) return;
      final err = await fs.publishMatchTrackChunk(
        sessionKey: sessionKey,
        nickname: _localPlayerLabel,
        role: _localRole,
        samples: samples,
      );
      if (err != null && mounted) {
        _toast('軌跡の共有に失敗: $err');
      }
    } catch (_) {}
  }
}
