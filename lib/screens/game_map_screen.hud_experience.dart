part of 'game_map_screen.dart';

/// HUD フェーズ表示・イベント履歴・第二ゲーム導入・プリセット導線。
extension _GameMapHudExperience on _GameMapScreenState {
  int _lobbyParticipantCount() {
    if (_isOnlineFirestore) {
      final fs = _firestoreSession;
      if (fs != null) {
        return math.max(1, fs.currentLobbyMembers.length);
      }
    }
    return 1;
  }

  String _prepSettingsSummaryLine() => MatchSetupSummary.prepSummaryLine(
        durationMinutes: _matchDurationSeconds / 60,
        gimmickDensity: _gimmickDensity,
        participantCount: _lobbyParticipantCount(),
      );

  String _rulesOverviewLineForLobby() => MatchSetupSummary.rulesOverviewLine(
        durationMinutes: _matchDurationSeconds / 60,
        accusationWeight: _accusationWeight,
        participantCount: _lobbyParticipantCount(),
        gimmickDensity: _gimmickDensity,
      );

  String? _matchPhaseLabel() {
    if (_gameState != GameState.running) return null;
    return MatchPhase.label(
      accusationUnlocked: _rt.accusationUnlocked,
      remainingSeconds: _rt.remainingSeconds,
      matchDurationSeconds: _matchDurationSeconds,
    );
  }

  void _recordMatchFeed(String message) {
    if (!mounted) return;
    _syncSetState(() => _matchEventFeedLine = message);
    _toast(message, duration: const Duration(seconds: 2));
  }

  Future<void> _maybeShowHostQuickPresetPicker() async {
    if (!_isHost || _gameState != GameState.waiting || !mounted) return;
    final prefs = await SharedPreferences.getInstance();
    final roomKey = _firestoreSession?.roomId ?? 'offline';
    if (prefs.getString(GameMapPrefs.hostQuickPresetPromptRoom) == roomKey) {
      return;
    }
    await prefs.setString(GameMapPrefs.hostQuickPresetPromptRoom, roomKey);
    if (!mounted || _gameState != GameState.waiting) return;
    final preset = await showMatchQuickPresetPicker(context);
    if (!mounted || preset == null) return;
    _applyQuickPreset(preset);
    _toast('${MatchSetupSummary.presetAppliedLabel(preset)} を適用しました');
  }

  void _applyQuickPreset(MatchQuickPreset preset) {
    _syncSetState(() {
      _matchDurationSeconds = (preset.durationMinutes.round() * 60).clamp(
        MatchDurationScaling.minMatchSeconds,
        MatchDurationScaling.maxMatchSeconds,
      );
      _gimmickDensity = preset.gimmickDensity.clamp(0.45, 1.55);
      if (_playArea.type == PlayAreaType.circle) {
        _playArea = preset.playAreaFromCenter(_playArea.center);
        _circleDraftCenter = _playArea.center;
        _circleDraftRadiusMeters = _playArea.radiusMeters;
      }
    });
    unawaited(
      SharedPreferences.getInstance().then((prefs) async {
        await prefs.setDouble(
          GameMapPrefs.gimmickDensity,
          _gimmickDensity,
        );
      }),
    );
  }

  Future<void> _onSecondGameIntroAfterElimination() async {
    final rule = _afterCatchRule;
    if (rule == null || !mounted) return;
    _secondGameHighlightTimer?.cancel();
    _syncSetState(() => _secondGameIntroHighlight = true);
    _secondGameHighlightTimer = Timer(const Duration(seconds: 45), () {
      if (!mounted) return;
      _syncSetState(() => _secondGameIntroHighlight = false);
    });
    await showSecondGameIntroOverlay(
      context,
      rule: rule,
      worldProfile: _mapVisual.pack.profile,
    );
  }

  /// 初回で告発施設に入ったときのみ、使い方を1回だけ案内する。
  Future<void> _maybeShowAccusationIntro() async {
    if (!mounted || _gameState != GameState.running) return;
    if (await OnboardingPrefs.accusationIntroSeen()) return;

    final copy = _accusationCopy;
    await showAppDialog<void>(
      context: context,
      builder: (ctx) {
        final theme = Theme.of(ctx);
        return AppDialog(
          title: '${copy.facilityName} に到着',
          icon: Icons.account_balance_outlined,
          actions: [
            AppDialogAction(
              label: 'OK',
              onPressed: () => Navigator.pop(ctx),
            ),
          ],
          child: Text(
            'このあと告発画面が開きます。'
            '「${copy.accuseActionLabel}」で相手を選べます。\n'
            '正解・失敗の影響は試合前のルール設定で決まります。',
            style: theme.textTheme.bodyMedium,
          ),
        );
      },
    );
    await OnboardingPrefs.markAccusationIntroSeen();
  }

  bool get _secondGameCanUseCameraJack =>
      _afterCatchRule?.supportsCameraJack == true;

  bool get _secondGameCanUseAccusationTerritory =>
      _afterCatchRule?.supportsSpectralTerritoryCharge == true;

  bool get _secondGameCanUseFacilitySabotage =>
      _afterCatchRule?.supportsFacilitySabotage == true;

  bool get _secondGameCanUseCameraShutdown =>
      _afterCatchRule?.supportsFacilitySabotage == true;
}
