import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../audio/game_audio.dart';
import '../audio/sfx_id.dart';
import '../progression/player_progress.dart';
import '../progression/player_title.dart';
import '../progression/progress_store.dart';
import '../session/onboarding_prefs.dart';
import '../features/onboarding/coach_marks.dart';
import '../features/onboarding/welcome_flow.dart';
import '../features/tutorial/tutorial_entry.dart';
import '../widgets/app_dialog.dart';
import '../features/game_map/control_sheet_mode.dart';
import '../features/game_map/map/game_map_layer_toggles.dart';
import '../features/game_map/map/game_map_overlay_builder.dart';
import '../features/game_map/map/game_map_overlay_snapshot.dart';
import '../features/game_map/map/map_geo_format.dart';
import '../features/game_map/logic/gimmick_relocator.dart';
import '../features/game_map/logic/map_geo_utils.dart';
import '../features/game_map/logic/oni_intel_text_builder.dart';
import '../features/game_map/logic/reveal_reason_pool.dart';
import '../game/anonymous_reveal_trace.dart';
import '../features/game_map/match/game_map_match_controller.dart';
import '../features/game_map/match/gimmick_pickup_evaluator.dart';
import '../features/game_map/match/match_geo_helpers.dart';
import '../features/game_map/match/match_runtime_state.dart';
import '../features/game_map/match/match_tick_effects.dart';
import '../features/game_map/match/match_tick_evaluator.dart';
import '../features/game_map/play_area/geo_json_actions.dart';
import '../features/game_map/prep/prep_lobby_panel.dart';
import '../features/game_map/widgets/how_to_play_sheet.dart';
import '../game/role_briefing.dart';
import '../features/game_map/widgets/role_briefing_dialog.dart';
import '../features/game_map/settings/game_custom_settings_models.dart';
import '../features/game_map/settings/game_custom_settings_sheet.dart';
import '../features/game_map/settings/player_personal_settings_models.dart';
import '../features/game_map/settings/player_personal_settings_sheet.dart';
import '../session/avatar_image_store.dart';
import '../session/avatar_thumb_codec.dart';
import '../features/game_map/map/reveal_avatar_icon_cache.dart';
import '../session/session_prefs.dart';
import '../features/game_map/widgets/diagnostics_card.dart';
import '../features/game_map/widgets/game_control_panel.dart';
import '../features/game_map/hud/hud_compact_line.dart';
import '../features/game_map/hud/match_phase.dart';
import '../features/game_map/hud/second_game_intro_overlay.dart';
import '../features/game_map/settings/match_quick_preset_picker.dart';
import '../features/game_map/widgets/game_info_panel.dart';
import '../session/hud_display_prefs.dart';
import '../features/game_map/widgets/game_map_overflow_menu.dart';
import '../features/game_map/widgets/map_layer_toggle_strip.dart';
import '../features/game_map/widgets/prep_map_bottom_panel.dart';
import '../features/game_map/widgets/elimination_support_bar.dart';
import '../game/accusation_sites.dart';
import '../game/camera_jack_logic.dart';
import '../game/match_ui_terms.dart';
import '../game/camera_shutdown_logic.dart';
import '../game/facility_sabotage_logic.dart';
import '../game/spectral_territory_logic.dart';
import '../game/elimination_aftermath_rule.dart';
import '../game/game_config.dart';
import '../game/accusation_block_logic.dart';
import '../game/accusation_logic.dart';
import '../game/accusation_weight.dart';
import '../game/oni_path_trail.dart';
import '../game/werewolf_forced_schedule.dart';
import '../game/werewolf_faction_logic.dart';
import '../game/analyst_trace_format.dart';
import '../game/match_duration_scaling.dart';
import '../game/match_quick_preset.dart';
import '../game/match_setup_summary.dart';
import '../game/match_role_mix.dart';
import '../game/oni_info_broker.dart';
import '../game/runner_modifier.dart';
import '../game/runner_modifier_assign.dart';
import '../features/game_map/widgets/accusation_sheet.dart';
import '../theme/accusation_facility_copy.dart';
import '../game/game_state.dart';
import '../game/generated_gimmicks.dart';
import '../game/location_reveal_event.dart';
import '../game/match_event.dart';
import '../game/oni_intel_mode.dart';
import '../game/oni_intel_trace.dart';
import '../game/play_area.dart';
import '../game/player_role.dart';
import '../game/polygon_area_resolver.dart';
import '../game/sampling_tier.dart';
import '../game/skill_ids.dart';
import '../map/runner_display_smooth.dart';
import '../proximity/ble_game_advertiser.dart';
import '../proximity/ble_game_protocol.dart';
import '../proximity/ble_scan_proximity_service.dart';
import '../proximity/hybrid_proximity_service.dart';
import '../proximity/idle_proximity_service.dart';
import '../proximity/proximity_service.dart';
import '../proximity/proximity_signal.dart';
import '../sync/firestore_room_session.dart';
import '../sync/firestore_room_blueprint.dart';
import '../sync/room_phase.dart';
import '../sync/shared_match_snapshot.dart';
import '../sync/room_match_event.dart';
import '../sync/remote_member_snapshot.dart';
import '../sync/room_member_view.dart';
import '../services/location_service.dart';
import '../services/match_archive_store.dart';
import '../services/match_recorder.dart';
import '../services/play_area_slot_store.dart';
import '../services/play_area_store.dart';
import '../sync/room_session_port.dart';
import '../sync/offline_sync_queue.dart';
import '../features/game_map/visual/map_visual_controller.dart';
import '../features/game_map/visual/reveal_flash_controller.dart';
import '../features/game_map/widgets/world_map_atmosphere.dart';
import '../theme/elimination_role_copy.dart';
import '../theme/world_profile.dart';
import '../theme/world_profile_tokens.dart';
import '../widgets/confirm_dialog.dart';
import '../session/game_map_prefs.dart';
import '../session/world_profile_prefs.dart';
import '../settings/oni_operator_prefs.dart';
import 'match_gallery_screen.dart';
import 'match_result_screen.dart';
import 'oni_operator_screen.dart';
import 'privacy_control_screen.dart';
import 'room_lobby_screen.dart';

/// ゲームマップ画面 — 実装は `part` ファイルにドメイン別に分割されています。
///
/// | ファイル | 担当 |
/// |---|---|
/// | [game_map_screen.dart] | 状態フィールド・init/build・GPS・近接・UI骨格 |
/// | `game_map_screen.online_sync.dart` | Firestore ルームイベント受信 |
/// | `game_map_screen.reveals_gimmicks.dart` | 位置暴露発行・ギミック取得 |
/// | `game_map_screen.hud_experience.dart` | HUD フェーズ・イベント履歴・第二ゲーム導入 |
/// | `game_map_screen.play_area.dart` | プレイエリア編集・保存 |
/// | `game_map_screen.match_lifecycle.dart` | 試合開始/終了・ティック・中止投票 |
/// | `game_map_screen.accusation.dart` | 告発施設 |
/// | `game_map_screen.second_game.dart` | 脱落後（残響体/鬼影） |
/// | `game_map_screen.skills.dart` | スキル・地図タップ |
/// | `game_map_screen.overlay.dart` | 地図オーバーレイスナップショット |
///
/// 修正時は上表の part を開いてください。詳細索引は
/// `lib/features/game_map/game_map_screen_index.dart` を参照。
///
/// `_GameMapScreenState` の private フィールドは本体に集約されています。
part 'game_map_screen.online_sync.dart';
part 'game_map_screen.reveals_gimmicks.dart';
part 'game_map_screen.hud_experience.dart';
part 'game_map_screen.play_area.dart';
part 'game_map_screen.match_lifecycle.dart';
part 'game_map_screen.accusation.dart';
part 'game_map_screen.second_game.dart';
part 'game_map_screen.skills.dart';
part 'game_map_screen.overlay.dart';

class GameMapScreen extends StatefulWidget {
  const GameMapScreen({required this.profile, this.onlineSession, super.key});

  final WorldProfile profile;

  /// ロビーで参加済みの Firestore セッション（本番マルチプレイ用）。
  final FirestoreRoomSession? onlineSession;

  @override
  State<GameMapScreen> createState() => _GameMapScreenState();
}

class _GameMapScreenState extends State<GameMapScreen>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  static const LatLng _defaultOniPosition = LatLng(35.6805, 139.7690);

  /// Roads API 用（Maps と同じキーで可）。未設定時はイベントエリアは従来のランダム配置。
  static const String _googleMapsApiKey = String.fromEnvironment(
    'GOOGLE_MAPS_API_KEY',
  );

  // --- Services & controllers ---
  final LocationService _locationService = LocationService();
  final PlayAreaStore _areaStore = PlayAreaStore();
  final PlayAreaSlotStore _areaSlotStore = PlayAreaSlotStore();
  final MatchArchiveStore _matchArchive = MatchArchiveStore();
  final OfflineSyncQueue _offlineQueue = OfflineSyncQueue();
  final GameMapMatchController _matchCtrl = GameMapMatchController();
  late HybridProximityService _proximityService = HybridProximityService(
    bleDelegate: IdleProximityService(),
  );
  BleScanProximityService? _bleScanDelegate;
  final BleGameAdvertiser _bleAdvertiser = BleGameAdvertiser();
  bool _useBleScanPref = false;
  bool? _lastBleAdvertisedAsOni;
  RoomSessionPort _roomSession = LocalOnlyRoomSession();

  MatchRuntimeState get _rt => _matchCtrl.runtime;

  GoogleMapController? _mapController;
  StreamSubscription<Position>? _positionSubscription;
  StreamSubscription<ProximitySignal>? _proximitySubscription;
  Timer? _matchTimer;
  Timer? _renderPump;

  // --- GPS & player position ---
  LocationSamplingTier _gpsTier = LocationSamplingTier.relaxed;
  RunnerDisplaySmoothing? _runnerSmooth;

  LatLng _currentPosition = const LatLng(35.681236, 139.767125);
  LatLng? _lastPositionForBearing;
  double? _movementBearingDegrees;
  DateTime? _lastFakeDriftAt;
  LatLng _oniPosition = _defaultOniPosition;

  // --- Play area (logic: game_map_screen.play_area.dart) ---
  PlayArea _playArea = const PlayArea.circle(
    center: LatLng(35.681236, 139.767125),
    radiusMeters: GameConfig.playAreaRadiusMeters,
  );

  /// エリア編集中の下書き（多角形の頂点 / 円の中心候補）
  bool _editingArea = false;
  bool _editCircleMode = true;
  final List<LatLng> _polygonDraft = [];
  bool _polygonDraftClosed = false;
  LatLng _circleDraftCenter = const LatLng(35.681236, 139.767125);
  double _circleDraftRadiusMeters = GameConfig.playAreaRadiusMeters;
  bool _waitingCircleCenterTap = false;

  /// 待機中は地図を隠してロビー表示。エリア編集・試合中・試合終了後は地図を表示する。
  bool _mapVisibleInLobby = false;

  // --- Match rules & roles (logic: match_lifecycle, accusation parts) ---
  GameState _gameState = GameState.waiting;
  String _statusMessage = '現在地を取得中...';
  DateTime? _lastAcceptedPositionAt;
  OniIntelMode _oniIntelMode = OniIntelMode.directionOnly;
  bool _customRuleMode = false;
  RoleAssignMode _roleAssignMode = RoleAssignMode.random;
  int _roleOniCount = 1;
  int _roleWerewolfCount = 1;
  int _matchDurationSeconds = GameConfig.matchDurationSeconds;
  PlayerRole _localRole = PlayerRole.runner;
  Set<String> _skillLoadout = const {SkillIds.fakePosition};
  final List<LatLng> _tracePoints = [];
  final List<OniPathSample> _oniPathSamples = [];
  LatLng? _oniMatchStartAnchor;

  // --- Recording & visuals ---
  MatchRecorder? _matchRecorder;
  Future<void>? _finalizeRecordingFuture;
  bool _trajectoryConsent = false;
  late WorldProfile _activeProfile;
  late MapVisualController _mapVisual;
  String? _avatarImagePath;
  String? _localNicknameOverride;
  late RevealFlashController _revealFlash;
  double _cameraPulsePhase = 0;
  ControlSheetMode _controlSheetMode = ControlSheetMode.skillsOnly;
  bool _hudExpanded = false;
  GameMapLayerToggles _mapLayerToggles = GameMapLayerToggles.allOn;
  String? _hudRevealAlert;
  Timer? _hudRevealAlertTimer;
  bool _areaEditorPanelExpanded = true;
  bool _hudShowIntelLine = true;
  bool _hudShowStatusLine = true;
  bool _hudShowConditionLine = true;
  double _mapMarkerIconScale = 1.0;
  HudCompactLineSlot _hudCompactLineSlot = HudCompactLineSlot.all;

  // --- Prep lobby & host settings ---
  /// ホストが参加者にカスタムルール（役職固定等）の編集を許可したか。
  bool _participantRulesOpen = false;
  List<SavedPlayArea> _savedPlayAreas = const [];
  String? _selectedPlayAreaSlotId;

  /// 準備・試合結果中は操作パネルを隠し、FAB「詳細設定」で開く。
  bool _prepControlSheetOpen = false;
  Offset? _controlFabOffset;
  bool _testMode = false;
  int _timeScale = 1;
  bool _bodyThrowBroadcastActive = false;
  final List<String> _debugLogs = [];
  double _fps = 60;
  double? _lastGpsAccuracyMeters;
  double _avgGpsAccuracyMeters = 0;
  int _gpsAccuracyCount = 0;
  double _estimatedBatteryScore = 0;
  int _offlineQueueCount = 0;
  String _proximityText = '近接: --';
  ProximityBand _latestProximityBand = ProximityBand.none;
  final int _mockPlayerCount = 6;
  double _gimmickDensity = 1.0;

  // --- Online sync (logic: game_map_screen.online_sync.dart) ---
  final Set<String> _abortVoteYesUids = {};
  String? _abortProposalInitiatorUid;
  DateTime? _abortProposalExpiresAt;
  Timer? _abortProposalTimer;
  final Map<String, Set<String>> _captureAcksByPlace = {};
  DateTime? _lastBodyThrowAreaToastAt;
  DateTime? _lastHunterPositionPublishAt;
  LatLng? _lastHunterPositionPublished;
  double? _lastKnownOniHeadingDegrees;
  LatLng? _prevOniSampleForHeading;
  RunnerModifier _localRunnerModifier = RunnerModifier.none;
  bool _hostAccusationUnlockSent = false;
  bool _accusationPromptOpen = false;
  bool _syncInFlight = false;
  Map<String, RemoteMemberSnapshot> _remoteMembers = {};
  final RevealAvatarIconCache _revealAvatarIcons = RevealAvatarIconCache();
  StreamSubscription<Map<String, RemoteMemberSnapshot>>? _remoteMembersSub;
  StreamSubscription<RoomMatchState>? _roomMatchSub;
  StreamSubscription<RoomMatchEvent>? _roomEventSub;
  final Set<String> _processedRoomEventDocIds = {};
  final Map<String, Timer> _captureBoundTimers = {};
  bool _ownsRoomSession = false;

  /// オンラインで鬼役の位置が members に載っている。
  bool _remoteOniKnown = false;
  bool _oniRoleEnabled = false;
  bool _oniNotifyVibration = true;
  bool _oniNotifySound = true;
  bool _oniNotifyAggressive = false;

  // --- Elimination & second game (logic: second_game, accusation parts) ---
  EliminationAftermathRule _eliminationAftermathRule =
      EliminationAftermathRule.spectralOperative;
  AccusationWeight _accusationWeight = AccusationWeight.instantWin;
  EliminationAftermathRule? _afterCatchRule;
  FactionSide? _factionAtDeath;
  final Set<String> _eliminatedUids = {};

  bool _progressRecordedForMatch = false;
  PlayerProgress? _lastProgress;
  List<PlayerTitle> _lastNewlyUnlockedTitles = const [];

  // --- Onboarding & HUD experience (logic: hud_experience.dart) ---
  final GlobalKey _prepStartKey = GlobalKey();
  final GlobalKey _prepCustomRulesKey = GlobalKey();
  final GlobalKey _prepMapFabKey = GlobalKey();
  bool _prepOnboardingChecked = false;
  String? _matchEventFeedLine;
  bool _secondGameIntroHighlight = false;
  Timer? _secondGameHighlightTimer;

  late final AnimationController _dangerPulseController;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _activeProfile = widget.profile;
    _mapVisual = MapVisualController(_activeProfile);
    _revealFlash = RevealFlashController(() {
      if (mounted) setState(() {});
    });
    _mapLayerToggles = _mapVisual.pack.layerDefaults;
    _dangerPulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _setupLocation();
    Future<void>.microtask(_loadTrajectoryConsent);
    Future<void>.microtask(_loadEliminationAftermathRule);
    Future<void>.microtask(_loadAccusationWeightConfig);
    Future<void>.microtask(_loadGimmickDensity);
    Future<void>.microtask(_loadRoleAssignConfig);
    Future<void>.microtask(_initProximityStack);
    Future<void>.microtask(_refreshOfflineQueueCount);
    if (widget.onlineSession != null) {
      Future<void>.microtask(_attachOnlineSession);
    }
    Future<void>.microtask(_loadOniOperatorPrefs);
    Future<void>.microtask(_loadPlayAreaSlots);
    Future<void>.microtask(_initWorldVisual);
    Future<void>.microtask(_loadHudDisplayPrefs);
    Future<void>.microtask(_loadLocalNicknameFromPrefs);
    _startRenderPump();
    SchedulerBinding.instance.addTimingsCallback(_onFrameTimings);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _maybeShowPrepOnboarding();
      _maybeShowHostQuickPresetPicker();
    });
  }

  /// 初回だけ、準備画面で「かんたんガイド」を案内する（軽量導入A）。
  Future<void> _maybeShowPrepOnboarding() async {
    if (_prepOnboardingChecked) return;
    _prepOnboardingChecked = true;
    if (!mounted || _gameState != GameState.waiting) return;
    if (await OnboardingPrefs.prepGuideSeen()) return;
    await OnboardingPrefs.markPrepGuideSeen();
    if (!mounted || _gameState != GameState.waiting) return;

    final seeGuide = await showAppDialog<bool>(
      context: context,
      builder: (ctx) {
        final theme = Theme.of(ctx);
        return AppDialog(
          title: 'はじめての準備画面',
          icon: Icons.waving_hand_rounded,
          actions: [
            AppDialogAction(
              label: 'スキップ',
              filled: false,
              sfx: SfxId.uiBack,
              onPressed: () => Navigator.pop(ctx, false),
            ),
            AppDialogAction(
              label: 'ガイドを見る',
              icon: Icons.auto_awesome_rounded,
              onPressed: () => Navigator.pop(ctx, true),
            ),
          ],
          child: Text(
            '30秒でわかる、かんたんガイドを見てみませんか？\n'
            'あとからタイトルの「遊び方」やメニューからも見られます。',
            style: theme.textTheme.bodyMedium,
          ),
        );
      },
    );
    if (!mounted) return;
    if (seeGuide == true) {
      final result = await showWelcomeFlow(context, offerTutorial: true);
      if (!mounted) return;
      if (result == WelcomeResult.tutorial) {
        await openTutorialPicker(context);
        if (!mounted) return;
      }
    }
    await _showPrepCoachMarks(markSeen: true);
  }

  Future<void> _showPrepCoachMarks({bool markSeen = false}) async {
    if (!mounted || _gameState != GameState.waiting) return;
    if (markSeen) await OnboardingPrefs.markCoachMarksSeen();
    if (!mounted) return;
    await showCoachMarks(context, [
      CoachStep(
        targetKey: _prepStartKey,
        icon: Icons.play_circle_fill_rounded,
        title: 'ここで試合開始',
        body: '準備ができたら「試合を開始」。まずは1戦やってみよう！',
      ),
      CoachStep(
        targetKey: _prepCustomRulesKey,
        icon: Icons.tune_rounded,
        title: 'ルールを調整',
        body: '役職・制限時間・ギミックは「カスタムルール」で変えられます。',
      ),
      CoachStep(
        targetKey: _prepMapFabKey,
        icon: Icons.map_rounded,
        title: 'エリアを編集',
        body: '右下の「マップパネル」から、遊ぶエリアの形を編集・保存できます。',
      ),
    ]);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _logDebug('lifecycle:resumed');
      _setupLocation();
      if (_testMode) {
        _simulateOfflineFlush();
      }
    } else if (state == AppLifecycleState.paused) {
      _logDebug('lifecycle:paused');
    }
  }

  void _onFrameTimings(List<FrameTiming> timings) {
    if (timings.isEmpty) return;
    final totalMs = timings
        .map((t) => t.totalSpan.inMicroseconds / 1000.0)
        .fold<double>(0, (a, b) => a + b);
    final avgMs = totalMs / timings.length;
    if (avgMs <= 0) return;
    _fps = 1000 / avgMs;
  }

  Future<void> _loadTrajectoryConsent() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      _trajectoryConsent =
          prefs.getBool(GameMapPrefs.trajectoryConsent) ?? false;
    });
  }

  Future<void> _loadGimmickDensity() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    final v = prefs.getDouble(GameMapPrefs.gimmickDensity);
    if (v != null && v > 0) {
      setState(() => _gimmickDensity = v.clamp(0.45, 1.55));
    }
  }

  Future<void> _loadRoleAssignConfig() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      _roleAssignMode =
          RoleAssignMode.fromName(prefs.getString(GameMapPrefs.roleAssignMode));
      _roleOniCount = (prefs.getInt(GameMapPrefs.roleOniCount) ?? 1).clamp(0, 12);
      _roleWerewolfCount =
          (prefs.getInt(GameMapPrefs.roleWerewolfCount) ?? 1).clamp(0, 12);
    });
  }

  Future<void> _loadEliminationAftermathRule() async {
    final prefs = await SharedPreferences.getInstance();
    final parsed = EliminationAftermathRule.tryParseName(
      prefs.getString(GameMapPrefs.eliminationAftermathRule),
    );
    if (!mounted) return;
    if (parsed != null) {
      setState(() => _eliminationAftermathRule = parsed);
    }
  }

  Future<void> _loadAccusationWeightConfig() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      _accusationWeight = AccusationWeight.fromName(
        prefs.getString(GameMapPrefs.accusationWeight),
      );
    });
  }

  Future<void> _setTrajectoryConsent(bool value) async {
    setState(() => _trajectoryConsent = value);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(GameMapPrefs.trajectoryConsent, value);
  }

  Future<void> _refreshOfflineQueueCount() async {
    final list = await _offlineQueue.load();
    if (!mounted) return;
    setState(() {
      _offlineQueueCount = list.length;
    });
  }

  Future<void> _simulateOfflineFlush() async {
    if (_syncInFlight) return;
    _syncInFlight = true;
    _logDebug('sync:flush_start');
    final pending = await _offlineQueue.load();
    if (pending.isEmpty) {
      _syncInFlight = false;
      _logDebug('sync:empty');
      await _refreshOfflineQueueCount();
      return;
    }

    // 擬似送信: 80%成功として成功IDだけキューから削除。
    final okIds = <String>{};
    for (final item in pending) {
      final r = (item.id.hashCode & 0x7fffffff) % 10;
      if (r <= 7) {
        okIds.add(item.id);
      }
    }
    if (okIds.isNotEmpty) {
      await _offlineQueue.removeByIds(okIds);
    }
    await _refreshOfflineQueueCount();
    _logDebug('sync:flush_done ok=${okIds.length} all=${pending.length}');
    _syncInFlight = false;
    if (mounted && _testMode) {
      _toast('オフライン復帰: ${okIds.length}/${pending.length} 件を送信');
    }
  }

  Future<void> _initProximityStack() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    final useBle = prefs.getBool(GameMapPrefs.useBleScanProximity) ?? false;
    _useBleScanPref = useBle;
    await _proximitySubscription?.cancel();
    await _proximityService.stop();
    await _bleAdvertiser.stop();
    final ProximityService bleDelegate;
    if (useBle) {
      _bleScanDelegate = BleScanProximityService(scanFilter: _bleGameScanFilter());
      bleDelegate = _bleScanDelegate!;
    } else {
      _bleScanDelegate = null;
      if (_testMode) {
        bleDelegate = MockProximityService();
      } else {
        bleDelegate = IdleProximityService();
      }
    }
    _proximityService = HybridProximityService(bleDelegate: bleDelegate);
    await _setupProximity();
    await _syncBleMatchContext();
  }

  BleGameScanFilter? _bleGameScanFilter() {
    if (_gameState != GameState.running) return null;
    final roomId = _firestoreSession?.roomId;
    final sk = _matchEventSessionKey;
    if (roomId == null || sk == null) return null;
    return BleGameScanFilter(
      roomId: roomId,
      sessionKey: sk,
      advertiseAsOni: _isPerceivedOniNow,
    );
  }

  Future<void> _syncBleMatchContext({bool forceAdvertiseRestart = false}) async {
    final filter = _bleGameScanFilter();
    _bleScanDelegate?.scanFilter = filter;
    if (_useBleScanPref && filter != null) {
      final oni = filter.advertiseAsOni;
      if (forceAdvertiseRestart || _lastBleAdvertisedAsOni != oni) {
        await _bleAdvertiser.start(filter);
        _lastBleAdvertisedAsOni = oni;
      }
    } else {
      _lastBleAdvertisedAsOni = null;
      await _bleAdvertiser.stop();
    }
  }

  void _maybeRefreshBleAdvertiseOnRoleChange() {
    if (!_useBleScanPref || _gameState != GameState.running) return;
    final oni = _isHunterNow;
    if (_lastBleAdvertisedAsOni == oni) return;
    unawaited(_syncBleMatchContext(forceAdvertiseRestart: true));
  }

  Future<void> _reloadProximityStackFromPrefs() async {
    await _initProximityStack();
  }

  Future<void> _attachOnlineSession() async {
    final fs = widget.onlineSession;
    if (fs == null || fs.roomId == null) return;
    if (!mounted) return;
    setState(() {
      _roomSession = fs;
      _ownsRoomSession = false;
    });
    _bindRemoteMembers(fs);
    _statusMessage = 'ルーム ${fs.roomId} に接続済み';
    unawaited(_syncAvatarThumbToFirestore());
  }

  Future<void> _ingestRemoteAvatarThumbs(
    Map<String, RemoteMemberSnapshot> members,
  ) async {
    await _revealAvatarIcons.ingestMembers(
      members,
      tokens: _mapVisual.pack.tokens,
      onUpdated: () {
        if (mounted) setState(() {});
      },
    );
  }

  Future<void> _syncAvatarThumbToFirestore() async {
    final fs = _firestoreSession;
    if (fs is! FirestoreRoomSession || fs.myUid == null) return;
    String? b64;
    if (_avatarImagePath != null && _avatarImagePath!.isNotEmpty) {
      b64 = await AvatarThumbCodec.encodeFile(_avatarImagePath!);
    }
    final err = await fs.updateAvatarThumb(b64);
    if (err != null && mounted) _toast(err);
  }

  void _bindRemoteMembers(FirestoreRoomSession session) {
    _remoteMembersSub?.cancel();
    final seed = session.currentRemoteMembers;
    setState(() {
      _remoteMembers = Map<String, RemoteMemberSnapshot>.from(seed);
      _applyRemoteOniPosition(_remoteMembers);
    });
    unawaited(_ingestRemoteAvatarThumbs(_remoteMembers));
    _remoteMembersSub = session.remoteMembers.listen((map) {
      if (!mounted) return;
      setState(() {
        _remoteMembers = map;
        _applyRemoteOniPosition(map);
      });
      unawaited(_ingestRemoteAvatarThumbs(map));
    });
    _roomMatchSub?.cancel();
    _roomMatchSub = session.roomMatchState.listen(_onRemoteRoomMatchState);

    _roomEventSub?.cancel();
    _roomEventSub =
        session.roomMatchEvents.listen((ev) => _onRemoteRoomMatchEvent(ev));

    final rm = session.currentRoomMatch;
    if (rm.phase == RoomPhase.lobby) {
      session.startRoomEventsListener(lobbySessionKey);
    } else if (rm.phase == RoomPhase.running && rm.matchStart != null) {
      session.startRoomEventsListener(rm.matchStart!.gimmickSeed);
    }
    if (!_isHost) {
      _onRemoteRoomMatchState(rm);
    }
  }

  void _onRemoteRoomMatchState(RoomMatchState state) {
    if (!mounted || _isHost) return;
    switch (state.phase) {
      case RoomPhase.lobby:
        _firestoreSession?.startRoomEventsListener(lobbySessionKey);
        if (_gameState != GameState.waiting) {
          _resetGame(skipFirestoreSync: true);
          _toast('ルームがロビーに戻りました');
        }
        break;
      case RoomPhase.running:
        if (state.matchStart != null) {
          _firestoreSession?.startRoomEventsListener(
            state.matchStart!.gimmickSeed,
          );
        }
        if (_gameState == GameState.waiting &&
            !_editingArea &&
            state.matchStart != null) {
          unawaited(() async {
            await _applySharedMatchStart(state.matchStart!);
            if (!mounted) return;
            _toast('ホストが試合を開始しました');
            _startGameCore();
          }());
        }
        break;
      case RoomPhase.ended:
        if (state.matchEnd != null && _isMatchStillActiveForLocalPlayer) {
          final end = state.matchEnd!;
          _endGame(
            end.outcome,
            end.message.isNotEmpty ? end.message : _messageForMatchEnd(end),
            endReason: end.endReason,
            skipFirestoreSync: true,
          );
        }
        break;
    }
  }

  String _messageForMatchEnd(SharedMatchEnd end) => switch (end.endReason) {
    MatchEndReason.timeUp => '逃走成功。時間切れです。',
    MatchEndReason.caught => '鬼に捕まりました。',
    MatchEndReason.hostAbort => 'ホストが試合を中止しました。',
    MatchEndReason.accusationSuccess =>
      '告発成功。逃走者陣営の勝利です。',
    _ => 'ホストが試合を終了しました。',
  };

  AccusationFacilityCopy get _accusationCopy =>
      AccusationFacilityCopy.forProfile(_mapVisual.pack.profile);

  void _applyRemoteOniPosition(Map<String, RemoteMemberSnapshot> map) {
    _remoteOniKnown = false;
    for (final m in map.values) {
      if ((m.role == 'oni' || m.role == 'hunter') &&
          m.lat != null &&
          m.lng != null) {
        _oniPosition = LatLng(m.lat!, m.lng!);
        _remoteOniKnown = true;
        return;
      }
    }
    final hunterUid = _hunterUidFromAssignments;
    if (hunterUid != null && _lastKnownHunterPositions.containsKey(hunterUid)) {
      _oniPosition = _lastKnownHunterPositions[hunterUid]!;
      _remoteOniKnown = true;
    }
  }

  final Map<String, LatLng> _lastKnownHunterPositions = {};

  String? get _hunterUidFromAssignments {
    final snap = _firestoreSession?.currentMatchStart;
    if (snap == null) return null;
    for (final e in snap.assignments.entries) {
      if (e.value.role == PlayerRole.hunter) return e.key;
    }
    return null;
  }

  /// 逃走者・人狼など、鬼が追う対象が試合にいるか。
  bool get _chaseTargetsPresent {
    final snap = _firestoreSession?.currentMatchStart;
    if (snap != null && snap.assignments.isNotEmpty) {
      return snap.assignments.values.any(
        (a) =>
            a.role == PlayerRole.runner || a.role == PlayerRole.werewolf,
      );
    }
    if (_localRole == PlayerRole.hunter) {
      return _testMode;
    }
    return _localRole != PlayerRole.hunter;
  }

  int get _activeMatchPlayerCount {
    final snap = _firestoreSession?.currentMatchStart;
    if (snap != null && snap.assignments.isNotEmpty) {
      return snap.assignments.length;
    }
    final fs = _firestoreSession;
    if (fs != null && fs.currentLobbyMembers.isNotEmpty) {
      return fs.currentLobbyMembers.length;
    }
    return math.max(1, _mockPlayerCount);
  }

  Future<void> _setupProximity() async {
    await _proximityService.start();
    _proximitySubscription?.cancel();
    _proximitySubscription = _proximityService.watch().listen((signal) {
      if (!mounted) return;
      final prev = _latestProximityBand;
      setState(() {
        _proximityText =
            '近接: ${signal.band.name} (${(signal.confidence * 100).toStringAsFixed(0)}%)';
        _latestProximityBand = signal.band;
      });
      _logDebug(
        'proximity:${signal.band.name}:${signal.confidence.toStringAsFixed(2)}',
      );
      if (_gameState == GameState.running && signal.band != prev) {
        _evaluateGame();
        if (_isOnlineFirestore) {
          unawaited(_publishPresenceBandIfNeeded(signal.band));
        }
      }
    });
  }

  DateTime? _lastPresenceBandPublishAt;

  Future<void> _publishPresenceBandIfNeeded(ProximityBand band) async {
    final fs = _firestoreSession;
    if (fs == null || _gameState != GameState.running) return;
    final now = DateTime.now();
    if (_lastPresenceBandPublishAt != null &&
        now.difference(_lastPresenceBandPublishAt!).inSeconds < 5) {
      return;
    }
    _lastPresenceBandPublishAt = now;
    await fs.publishPresence(
      tension: band == ProximityBand.contact || band == ProximityBand.near,
      proximityBandName: band.name,
    );
  }

  /// extension は `@protected` な `setState` を直接呼べないため経由する。
  void _syncSetState(void Function() fn) => setState(fn);

  void _pushHudRevealAlert(String message) {
    _hudRevealAlertTimer?.cancel();
    setState(() {
      _hudRevealAlert = message;
      _hudExpanded = true;
    });
    _revealFlash.trigger(_mapVisual.pack);
    unawaited(_refreshPlayerAvatarIcon());
    _hudRevealAlertTimer = Timer(const Duration(seconds: 14), () {
      if (!mounted) return;
      setState(() => _hudRevealAlert = null);
    });
  }

  Future<void> _initWorldVisual() async {
    final prefs = await SharedPreferences.getInstance();
    _avatarImagePath = prefs.getString(GameMapPrefs.avatarImagePath);
    final profile = await WorldProfilePrefs.load();
    final hud = await HudDisplayPrefs.load();
    _mapMarkerIconScale = hud.markerIconScale;
    _mapVisual.markerIconScale = hud.markerIconScale;
    await _mapVisual.reloadForProfile(profile);
    await _refreshPlayerAvatarIcon();
    if (!mounted) return;
    setState(() {
      _activeProfile = profile;
      _mapLayerToggles = _mapVisual.pack.layerDefaults;
    });
    unawaited(_syncAvatarThumbToFirestore());
  }

  Future<void> _loadHudDisplayPrefs() async {
    final hud = await HudDisplayPrefs.load();
    if (!mounted) return;
    setState(() {
      _hudCompactLineSlot = hud.compactLineSlot;
      _hudShowIntelLine = hud.showIntelLine;
      _hudShowStatusLine = hud.showStatusLine;
      _hudShowConditionLine = hud.showConditionLine;
      _mapMarkerIconScale = hud.markerIconScale;
    });
    if (_mapVisual.markerIconScale != hud.markerIconScale) {
      await _applyMapMarkerIconScale(hud.markerIconScale);
    }
  }

  Future<void> _applyMapMarkerIconScale(double scale) async {
    final clamped = HudDisplaySettings.clampMarkerIconScale(scale);
    _mapVisual.markerIconScale = clamped;
    await _mapVisual.applyMarkerIconScale(clamped);
    await _refreshPlayerAvatarIcon();
    if (mounted) setState(() => _mapMarkerIconScale = clamped);
  }

  String _hudCompactLineText() {
    final intel = _latestIntelLine();
    final showIntel =
        _rt.showOniIntelCard && _hudShowIntelLine && intel.isNotEmpty;
    return resolveHudCompactLineText(
      slot: _hudCompactLineSlot,
      showIntelLine: showIntel,
      showStatusLine: _hudShowStatusLine,
      showConditionLine: _hudShowConditionLine,
      intelLine: intel,
      statusText: _statusMessage,
      conditionText: _conditionLine(),
    );
  }

  Future<void> _applyWorldProfile(WorldProfile profile) async {
    await _mapVisual.reloadForProfile(profile);
    await _refreshPlayerAvatarIcon();
    if (!mounted) return;
    setState(() => _mapLayerToggles = _mapVisual.pack.layerDefaults);
  }

  bool _isPlayerRevealedForPhoto() {
    final cutoff = DateTime.now().subtract(const Duration(seconds: 50));
    return _rt.revealLog.any(
      (e) => e.timestamp.isAfter(cutoff) && e.playerLabel == _localPlayerLabel,
    );
  }

  /// 自分の地図ピン用。写真があれば常に表示（他プレイヤーには送らない）。
  bool _shouldUsePhotoPlayerPin() {
    return _avatarImagePath != null && _avatarImagePath!.isNotEmpty;
  }

  Future<void> _refreshPlayerAvatarIcon() async {
    await _mapVisual.refreshPlayerAvatar(
      localPath: _avatarImagePath,
      usePhoto: _shouldUsePhotoPlayerPin(),
      revealedStyle: _isPlayerRevealedForPhoto(),
      iconScale: _mapVisual.markerIconScale,
    );
  }

  Future<void> _onMapCreated(GoogleMapController controller) async {
    _mapController = controller;
    try {
      _mapVisual.updateZoom(await controller.getZoomLevel());
    } catch (_) {}
    if (mounted) setState(() {});
  }

  Future<void> _onCameraIdle() async {
    final controller = _mapController;
    if (controller == null) return;
    try {
      final z = await controller.getZoomLevel();
      if ((z - _mapVisual.mapZoom).abs() < 0.15) return;
      _mapVisual.updateZoom(z);
      if (mounted) setState(() {});
    } catch (_) {}
  }

  LatLng _displayRevealPosition(LatLng raw) =>
      MapGeoUtils.displayRevealPositionWithJamming(
        raw: raw,
        viewerPosition: _currentPosition,
        jammingZoneCenters: _rt.commJammingZonePositions,
      );

  bool _isPointInCommJammingZone(LatLng point) => MapGeoUtils.isPointInZone(
    point,
    _rt.commJammingZonePositions,
    GameConfig.commJammingZoneRadiusMeters,
  );

  bool get _oniInCommJammingZone => _isPointInCommJammingZone(_oniPosition);

  Future<void> _setupLocation() async {
    final granted = await _locationService.ensurePermission();
    if (!granted) {
      if (!mounted) return;
      setState(() {
        _statusMessage = '位置情報の許可が必要です（設定を確認してください）';
      });
      return;
    }

    await _loadSavedArea();

    final position = await _locationService.getCurrentPosition();
    if (!mounted) return;

    _acceptPosition(position, animateCamera: true);
    _bindGpsSubscription();
  }

  /// 課金とバッテリーに優しいよう、状況ごとにGPSの距離フィルタだけ切り替える。
  void _bindGpsSubscription({bool force = false}) {
    final nextTier = _resolveGpsTier();
    if (!force && _positionSubscription != null && nextTier == _gpsTier) {
      return;
    }
    _positionSubscription?.cancel();
    _gpsTier = nextTier;
    _positionSubscription = _locationService
        .watchPosition(_gpsTier)
        .listen((pos) => _acceptPosition(pos, animateCamera: false));
  }

  LocationSamplingTier _resolveGpsTier() {
    if (!_editingArea && _gameState == GameState.running) {
      final d = _distanceToOni();
      if (_rt.revealedInCurrentOutside) {
        return LocationSamplingTier.standard;
      }
      if (d <= GameConfig.dangerDistanceMeters + 25) {
        return LocationSamplingTier.chase;
      }
      if (d <= GameConfig.warningDistanceMeters + 35) {
        return LocationSamplingTier.standard;
      }
    }
    return LocationSamplingTier.relaxed;
  }

  void _retuneGpsIfNeeded() => _bindGpsSubscription();

  /// マーカー平滑化用。試合中のみ高頻度、それ以外は省電力寄り。
  void _startRenderPump() {
    _renderPump?.cancel();
    _renderPump = Timer.periodic(
      Duration(milliseconds: _renderPumpIntervalMs),
      (_) => _pulseVisualSmoothing(),
    );
  }

  int get _renderPumpIntervalMs {
    if (_gameState == GameState.running) return 50;
    if (_editingArea) return 100;
    return 250;
  }

  void _retuneRenderPump() {
    final interval = _renderPumpIntervalMs;
    if (_renderPump == null) {
      _startRenderPump();
      return;
    }
    // 間隔が変わったときだけタイマーを作り直す。
    _renderPump?.cancel();
    _renderPump = Timer.periodic(
      Duration(milliseconds: interval),
      (_) => _pulseVisualSmoothing(),
    );
  }

  void _pulseVisualSmoothing() {
    if (!mounted || _editingArea) return;
    final running = _gameState == GameState.running;
    final s = _runnerSmooth;
    if (s == null) {
      if (running &&
          (_rt.bodyThrowAwaitingMapTap ||
              (_rt.bodyThrowPosition != null && _rt.bodyThrowEndsAt != null))) {
        setState(() {});
      }
      return;
    }
    final blend = _visualSmoothBlend(_distanceToOni());
    final before = s.residualMeters;
    s.stepTowardTarget(blend);
    final after = s.residualMeters;
    var shouldRepaint =
        running || (before - after).abs() > 0.25 || !s.isNearlyThere;
    if (running && _mapLayerToggles.cameras && _rt.cameraPositions.isNotEmpty) {
      _cameraPulsePhase = (_cameraPulsePhase + 0.04) % 1.0;
      shouldRepaint = true;
    }
    if (running &&
        (_rt.bodyThrowAwaitingMapTap ||
            (_rt.bodyThrowPosition != null && _rt.bodyThrowEndsAt != null))) {
      shouldRepaint = true;
    }
    if (shouldRepaint && (running || after > 1.2 || !s.isNearlyThere)) {
      setState(() {});
    }
  }

  double _visualSmoothBlend(double distanceToOni) {
    if (_gameState != GameState.running) {
      return _editingArea ? 0.12 : 0.10;
    }
    if (distanceToOni <= GameConfig.dangerDistanceMeters) {
      return 0.48;
    }
    if (distanceToOni <= GameConfig.warningDistanceMeters) {
      return 0.32;
    }
    if (_rt.revealedInCurrentOutside) {
      return 0.24;
    }
    if (distanceToOni <= 240) {
      return 0.18;
    }
    return 0.11;
  }

  LatLng get _playerMarkerPosition =>
      _runnerSmooth?.display ?? _currentPosition;
  LatLng get _positionForReveal =>
      _rt.bodyThrowPosition ??
      (_rt.fakePositionActive && _rt.fakePositionLatLng != null
          ? _rt.fakePositionLatLng!
          : _currentPosition);

  /// 体投げの配置猶予 / 回収までの残り秒（なければ null）。
  int? _bodyThrowHudSeconds() {
    final now = DateTime.now();
    if (_rt.bodyThrowAwaitingMapTap && _rt.bodyThrowTapDeadline != null) {
      final left = _rt.bodyThrowTapDeadline!.difference(now).inSeconds;
      return left.clamp(0, GameConfig.bodyThrowMapTapWindowSeconds);
    }
    if (_rt.bodyThrowPosition != null && _rt.bodyThrowEndsAt != null) {
      final left = _rt.bodyThrowEndsAt!.difference(now).inSeconds;
      return left.clamp(0, GameConfig.bodyThrowDurationSeconds);
    }
    return null;
  }

  String? _bodyThrowHudPhaseLabel() {
    if (_rt.bodyThrowAwaitingMapTap) return '人形を置くまで';
    if (_rt.bodyThrowPosition != null && _rt.bodyThrowEndsAt != null) {
      return '体を回収するまで';
    }
    return null;
  }

  bool get _isPerceivedOniNow =>
      WerewolfFactionLogic.isPerceivedOni(
        assignmentRole: _localRole,
        werewolfInOniForm: _rt.werewolfInOniForm,
      );

  bool get _isHunterNow => _isPerceivedOniNow;

  List<MatchParticipantState> _matchParticipants() {
    final fs = _firestoreSession;
    final assignments = fs?.currentMatchStart?.assignments ?? {};
    final myUid = fs?.myUid ?? 'local';
    if (assignments.isEmpty) {
      return [
        MatchParticipantState(
          uid: myUid,
          assignmentRole: _localRole,
          werewolfInOniForm: _rt.werewolfInOniForm,
          eliminated: false,
        ),
      ];
    }
    final remoteWolf = fs?.werewolfOniFormByUid ?? const {};
    return assignments.entries
        .map(
          (e) => MatchParticipantState(
            uid: e.key,
            assignmentRole: e.value.role,
            werewolfInOniForm: e.key == myUid
                ? _rt.werewolfInOniForm
                : (remoteWolf[e.key] ?? false),
            eliminated: _eliminatedUids.contains(e.key),
          ),
        )
        .toList(growable: false);
  }

  FactionSide _localFactionNow() => WerewolfFactionLogic.factionFor(
        assignmentRole: _localRole,
        players: _matchParticipants(),
        uid: _firestoreSession?.myUid ?? 'local',
      );

  /// 脱落後は [ _factionAtDeath ] を固定（第二ゲーム中に人数変動で変わらない）。
  FactionSide _effectiveLocalFaction() =>
      _factionAtDeath ?? _localFactionNow();

  bool get _werewolfCanCaptureNow =>
      _localRole == PlayerRole.hunter ||
      (_localRole == PlayerRole.werewolf &&
          _rt.werewolfInOniForm &&
          WerewolfFactionLogic.werewolfCanCaptureInOniForm(
            _effectiveLocalFaction(),
          ));

  bool _proximityCapturePermittedForRunner() {
    return WerewolfFactionLogic.proximityCapturePermittedForRunner(
      gpsDistanceToHunterMeters: _distanceToOni(),
      captureDistanceMeters: GameConfig.captureDistanceMeters,
      bleContactBand: _latestProximityBand == ProximityBand.contact,
      participants: _matchParticipants(),
      runnerUid: _firestoreSession?.myUid ?? 'local',
    );
  }

  String? _werewolfHudSummary() {
    if (_localRole != PlayerRole.werewolf || _gameState != GameState.running) {
      return null;
    }
    final faction = _effectiveLocalFaction().label;
    final form = _rt.werewolfInOniForm ? '鬼化' : '人';
    if (_rt.werewolfInOniForm) {
      final cap = _werewolfCanCaptureNow ? '捕獲可' : MatchUiTerms.panicOnly;
      return '$faction・$form・$cap';
    }
    return '$faction・$form';
  }

  bool get _captureZoneLethalForLocal {
    if (_localRole == PlayerRole.hunter || _localRole == PlayerRole.runner) {
      return true;
    }
    if (_localRole == PlayerRole.werewolf) {
      return _rt.werewolfInOniForm && _werewolfCanCaptureNow;
    }
    return true;
  }

  String _werewolfStatusSuffix() {
    if (_localRole != PlayerRole.werewolf) return '';
    final faction = _effectiveLocalFaction();
    final perceived = WerewolfFactionLogic.perceivedRoleFor(
      MatchParticipantState(
        uid: _firestoreSession?.myUid ?? 'local',
        assignmentRole: _localRole,
        werewolfInOniForm: _rt.werewolfInOniForm,
        eliminated: _factionAtDeath != null,
      ),
    );
    final capture = _rt.werewolfInOniForm && _werewolfCanCaptureNow
        ? '捕獲可'
        : (_rt.werewolfInOniForm ? MatchUiTerms.panicOnly : '');
    final frozen = _factionAtDeath != null ? '（固定）' : '';
    return ' / ${faction.label}$frozen / ${perceived.label}${capture.isEmpty ? "" : "・$capture"}';
  }

  void _acceptPosition(Position position, {required bool animateCamera}) {
    final next = LatLng(position.latitude, position.longitude);
    final now = DateTime.now();

    if (_lastAcceptedPositionAt != null) {
      final dt = now.difference(_lastAcceptedPositionAt!).inSeconds;
      final moved = Geolocator.distanceBetween(
        _currentPosition.latitude,
        _currentPosition.longitude,
        next.latitude,
        next.longitude,
      );
      if (dt <= GameConfig.gpsJumpIgnoreWindowSeconds &&
          moved > GameConfig.gpsJumpIgnoreMeters) {
        return;
      }
    }

    _recordMovementBearing(next);
    setState(() {
      _currentPosition = next;
      if (!_editingArea) {
        _statusMessage = '追跡中（GPS更新あり）';
      }
      _lastAcceptedPositionAt = now;
      _updateGpsAccuracy(position.accuracy);
    });
    _advanceFakePositionDrift();

    _runnerSmooth ??= RunnerDisplaySmoothing(initial: next);
    _runnerSmooth!.setTarget(next);
    if (animateCamera) {
      _runnerSmooth!.snapDisplayToTarget();
      _mapController?.animateCamera(CameraUpdate.newLatLng(next));
    }

    _evaluateGame();

    if (_gameState == GameState.running) {
      _matchRecorder?.tryAppendRunner(next);
      if (_localRole == PlayerRole.hunter) {
        _oniPosition = next;
        _remoteOniKnown = true;
        _updateOniHeadingFromPosition(
          next,
          deviceHeading: position.heading,
        );
        _maybePublishHunterPosition(next, heading: position.heading);
      }
      if (_roomSession is FirestoreRoomSession) {
        final dist = Geolocator.distanceBetween(
          next.latitude,
          next.longitude,
          _oniPosition.latitude,
          _oniPosition.longitude,
        );
        final fs = _roomSession as FirestoreRoomSession;
        unawaited(
          fs.publishPresence(
            tension:
                _remoteOniKnown && dist <= GameConfig.warningDistanceMeters,
            proximityBandName: _latestProximityBand.name,
          ),
        );
      }
    }
    _retuneGpsIfNeeded();
  }

  void _updateGpsAccuracy(double accuracy) {
    _lastGpsAccuracyMeters = accuracy;
    _gpsAccuracyCount += 1;
    _avgGpsAccuracyMeters =
        ((_avgGpsAccuracyMeters * (_gpsAccuracyCount - 1)) + accuracy) /
        _gpsAccuracyCount;
  }

  Future<void> _finalizeMatchRecording(GameState outcome) async {
    final rec = _matchRecorder?.finalize(
      outcome: outcome,
      reveals: List<LocationRevealEvent>.from(_rt.revealLog),
      events: List<MatchEvent>.from(_rt.matchEvents),
    );
    _matchRecorder = null;
    if (rec == null) return;
    try {
      await _matchArchive.save(rec);
      await _offlineQueue.push(
        OfflineSyncItem(
          id: 'rec_${rec.id}',
          kind: 'match_record',
          createdAtUtc: DateTime.now().toUtc().toIso8601String(),
          payload: {
            'matchId': rec.id,
            'outcome': rec.outcome.name,
            'endedAtUtc': rec.endedAtUtc.toIso8601String(),
          },
        ),
      );
      await _refreshOfflineQueueCount();
      if (mounted) {
        _toast('軌跡を端末に保存しました（試合ギャラリーで再生）');
      }
    } catch (e) {
      if (mounted) {
        _toast('軌跡の保存に失敗: $e');
      }
    }
  }

  void _onMapTap(LatLng pos) {
    if (_rt.bodyThrowAwaitingMapTap) {
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
      setState(() {
        _rt.bodyThrowAwaitingMapTap = false;
        _rt.bodyThrowTapDeadline = null;
        _rt.bodyThrowSkillOriginLatLng = null;
        _rt.lastBodyThrowAt = now;
        _rt.bodyThrowPosition = pos;
        _rt.bodyThrowEndsAt = now.add(
          const Duration(seconds: GameConfig.bodyThrowDurationSeconds),
        );
        _statusMessage = '人形稼働中（回収まで ${GameConfig.bodyThrowDurationSeconds} 秒）';
      });
      _emitMatchEvent(
        type: 'body_throw_start',
        message: '体投げ発動',
        position: pos,
        endsAtMs: _rt.bodyThrowEndsAt!.millisecondsSinceEpoch,
      );
      GameAudio.instance.playSfx(SfxId.skillCast);
      // 鬼の配信位置を即座に人形へ（捕獲判定の中心を移す）。
      _syncHunterBroadcastForBodyThrow();
      return;
    }
    if (_rt.waitingSkillLockMapTap) {
      final now = DateTime.now();
      final d = Geolocator.distanceBetween(
        _currentPosition.latitude,
        _currentPosition.longitude,
        pos.latitude,
        pos.longitude,
      );
      final rawTargets = _captureZoneTargetsAt(pos, d);
      final placeId =
          'cz_${now.millisecondsSinceEpoch}_${_firestoreSession?.myUid ?? 'local'}';
      setState(() {
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
        _statusMessage = _captureZoneLethalForLocal
            ? '捕獲結界を設置しました'
            : '攪乱結界を設置（${MatchUiTerms.panicMechanic}・拘束のみ・捕獲不可）';
      });
      _emitMatchEvent(
        type: 'capture_zone_start',
        message: '捕獲結界を設置',
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
      return;
    }
    if (!_editingArea) return;
    setState(() {
      if (_editCircleMode && _waitingCircleCenterTap) {
        _circleDraftCenter = pos;
        _waitingCircleCenterTap = false;
        _statusMessage = '円の中心を設定しました';
      } else if (!_editCircleMode) {
        _polygonDraftClosed = false;
        _polygonDraft.add(pos);
        _statusMessage = '頂点 ${_polygonDraft.length} 点目（閉じるで確定）';
      }
    });
  }

  Set<String> _captureZoneTargetsAt(LatLng center, double selfDistance) {
    final ids = <String>{};
    if (selfDistance <= GameConfig.captureZoneRadiusMeters) ids.add('self');
    for (final e in _remoteMembers.entries) {
      final lat = e.value.lat;
      final lng = e.value.lng;
      if (lat == null || lng == null) continue;
      final d = Geolocator.distanceBetween(
        lat,
        lng,
        center.latitude,
        center.longitude,
      );
      if (d <= GameConfig.captureZoneRadiusMeters) ids.add(e.key);
    }
    return ids;
  }

  void _undoLastVertex() {
    if (_polygonDraft.isEmpty) return;
    setState(() {
      _polygonDraft.removeLast();
      _polygonDraftClosed = false;
      _statusMessage = '頂点を1つ戻しました（${_polygonDraft.length}点）';
    });
  }

  void _clearPolygonDraft() {
    setState(() {
      _polygonDraft.clear();
      _polygonDraftClosed = false;
      _statusMessage = '頂点をクリアしました';
    });
  }

  Future<void> _showImportGeoJsonDialog() async {
    try {
      final area = await GeoJsonActions.showImportDialog(context);
      if (area == null || !mounted) return;
      await _areaStore.save(area);
      setState(() {
        _playArea = area;
        if (area.type == PlayAreaType.circle) {
          _circleDraftCenter = area.center;
          _circleDraftRadiusMeters = area.radiusMeters;
        }
        _statusMessage = 'GeoJSON からプレイエリアを読み込みました';
      });
      if (_isHost) {
        unawaited(
          _publishLobbyPlayArea(slotName: 'GeoJSON', slotId: 'geojson_import'),
        );
      }
      _toast('保存済み。必要ならエリア編集で微調整してください。');
    } catch (e) {
      _toast('パース失敗: $e');
    }
  }

  Future<void> _exportGeoJson() async {
    await GeoJsonActions.exportToClipboard(
      context,
      _playArea,
      onCopied: _toast,
    );
  }

  Future<void> _copyDiscordStatusSummary() async {
    final lines = [
      '**Oni Game 状況共有**',
      '- 状態: ${_gameState.label}',
      '- ルーム: ${_roomSession.modeLabel}',
      '- エリア: ${_playAreaSummary()}',
      '- 役職: ${_localRole.displayName}${_isPerceivedOniNow && _localRole != PlayerRole.hunter ? "（鬼化中）" : ""}${_werewolfStatusSuffix()}',
      '- スキル: ${_skillLoadout.map(_skillLabelForUi).join(" / ")}',
      '- 残り時間: ${MapGeoUtils.formatClock(_rt.remainingSeconds)}',
      '- 位置暴露: $_rt.revealCount 回',
      '- 情報屋: ${_rt.lastOniIntelText == null ? "未取得" : _latestIntelLine()}',
      '- ギミック: 安全地帯 ${_rt.safeZonePositions.length} / 情報屋 ${_rt.infoBrokerPositions.length} / カメラ ${_rt.cameraPositions.length} / イベント ${_rt.commJammingZonePositions.length}',
      '',
      '現在地共有は必要な時だけ別途行ってください。',
    ];
    await Clipboard.setData(ClipboardData(text: lines.join('\n')));
    if (!mounted) return;
    _toast('Discord貼り付け用の状況メモをコピーしました');
  }

  void _showRevealLog() {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (ctx) => ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            '位置暴露ログ（ローカル・最大50件・将来はクラウド同期）',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          if (_rt.revealLog.isEmpty) const Text('まだありません'),
          for (final e in _rt.revealLog)
            ListTile(
              dense: true,
              title: Text(
                '${e.playerLabel} #${e.sequence}  +${e.overflowMeters.toStringAsFixed(0)}m',
              ),
              subtitle: Text(
                [
                  if (e.reasonSummary != null && e.reasonSummary!.isNotEmpty)
                    e.reasonSummary!,
                  e.timestamp.toIso8601String(),
                  MapGeoFormat.latLng(e.position),
                ].join('\n'),
              ),
            ),
        ],
      ),
    );
  }

  void _openCombinedIntelRevealLogSheet() {
    final tab = ValueNotifier(0);
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (ctx) {
        final theme = Theme.of(ctx);
        final h = (MediaQuery.sizeOf(ctx).height * 0.52).clamp(300.0, 540.0);
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.viewInsetsOf(ctx).bottom,
          ),
          child: SizedBox(
            height: h,
            child: ValueListenableBuilder<int>(
              valueListenable: tab,
              builder: (context, t, _) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                      child: Text(
                        '鬼情報・位置暴露',
                        style: theme.textTheme.titleMedium,
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      child: SegmentedButton<int>(
                        segments: const [
                          ButtonSegment(value: 0, label: Text('概要')),
                          ButtonSegment(value: 1, label: Text('暴露ログ')),
                          ButtonSegment(value: 2, label: Text('鬼情報履歴')),
                        ],
                        selected: {t},
                        onSelectionChanged: (s) => tab.value = s.first,
                      ),
                    ),
                    Expanded(
                      child: switch (t) {
                        0 => ListView(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            children: [
                              Text(
                                '現在の鬼情報',
                                style: theme.textTheme.titleSmall,
                              ),
                              Text(
                                _latestIntelLine().isEmpty
                                    ? '（まだありません）'
                                    : _latestIntelLine(),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                '直近の位置暴露',
                                style: theme.textTheme.titleSmall,
                              ),
                              if (_rt.revealLog.isEmpty)
                                const Text('まだありません')
                              else
                                _revealLogListTile(theme, _rt.revealLog.first),
                              if (_localRunnerModifier ==
                                  RunnerModifier.analyst) ...[
                                const SizedBox(height: 16),
                                Text(
                                  '匿名痕跡（アナリスト）',
                                  style: theme.textTheme.titleSmall,
                                ),
                                if (_rt.anonymousRevealTraces.isEmpty)
                                  const Text('まだありません')
                                else
                                  for (final tr in _recentAnonymousTraces())
                                    ListTile(
                                      dense: true,
                                      title: Text(tr.reasonSummary),
                                      subtitle: Text(
                                        AnalystTraceFormat.summaryLine(
                                          tr,
                                          DateTime.now(),
                                        ),
                                      ),
                                    ),
                              ],
                            ],
                          ),
                        1 => ListView(
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            children: [
                              if (_rt.revealLog.isEmpty)
                                const ListTile(title: Text('まだありません'))
                              else
                                for (final e in _rt.revealLog)
                                  _revealLogListTile(theme, e),
                            ],
                          ),
                        _ => ListView(
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            children: [
                              if (_rt.oniIntelTraces.isEmpty)
                                const ListTile(title: Text('まだありません'))
                              else
                                for (final tr in _rt.oniIntelTraces)
                                  ListTile(
                                    dense: true,
                                    title: Text(tr.text),
                                    subtitle: Text(
                                      tr.timestamp.toIso8601String(),
                                    ),
                                  ),
                            ],
                          ),
                      },
                    ),
                  ],
                );
              },
            ),
          ),
        );
      },
    ).whenComplete(tab.dispose);
  }

  Widget _revealLogListTile(ThemeData theme, LocationRevealEvent e) {
    return ListTile(
      dense: true,
      title: Text(
        '${e.playerLabel} #${e.sequence}  +${e.overflowMeters.toStringAsFixed(0)}m',
      ),
      subtitle: Text(
        [
          if (e.reasonSummary != null && e.reasonSummary!.isNotEmpty)
            e.reasonSummary!,
          e.timestamp.toIso8601String(),
          MapGeoFormat.latLng(e.position),
        ].join('\n'),
        style: theme.textTheme.bodySmall,
      ),
    );
  }

  void _toggleTestMode() {
    setState(() {
      _testMode = !_testMode;
    });
    _logDebug('test_mode=${_testMode ? 'on' : 'off'}');
    unawaited(_reloadProximityStackFromPrefs());
  }

  void _cycleControlSheetMode() {
    setState(() {
      _controlSheetMode = _controlSheetMode == ControlSheetMode.expanded
          ? ControlSheetMode.skillsOnly
          : ControlSheetMode.expanded;
    });
  }

  void _hideControlPanel() {
    setState(() => _controlSheetMode = ControlSheetMode.hidden);
  }

  void _showControlPanel() {
    setState(() {
      _controlSheetMode = ControlSheetMode.skillsOnly;
      if (_gameState == GameState.waiting) {
        _prepControlSheetOpen = true;
      }
    });
  }

  String _matchDurationLabel() {
    final m = (_matchDurationSeconds / 60).round();
    return '$m 分';
  }

  int _cooldownRemainingSeconds(DateTime? lastUsedAt, int cooldownSeconds) {
    if (lastUsedAt == null) return 0;
    final remain =
        cooldownSeconds - DateTime.now().difference(lastUsedAt).inSeconds;
    return remain < 0 ? 0 : remain;
  }

  void _dismissOpenModals() {
    if (!mounted) return;
    final navigator = Navigator.of(context);
    navigator.popUntil((route) => route is! PopupRoute);
  }

  Future<void> _openMatchResultScreen() async {
    if (!mounted) return;
    if (_gameState == GameState.caughtByOni && _isMatchStillActiveForLocalPlayer) {
      _toast('リザルトは試合終了後に表示できます');
      return;
    }
    final winningFaction = _gameState == GameState.runnerWin
        ? FactionSide.humanTeam
        : FactionSide.oniTeam;
    final localFaction = _effectiveLocalFaction();
    await _recordMatchProgressOnce(
      won: winningFaction == localFaction,
      faction: localFaction,
    );
    _dismissOpenModals();
    if (!mounted) return;
    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => MatchResultScreen(
          outcome: _gameState,
          detail: _statusMessage,
          roleSummary:
              '$_localPlayerLabel / ${_localRole.displayName}${_werewolfStatusSuffix()} / ${_skillLoadout.map(_skillLabelForUi).join("・")}',
          factionAtDeath: _factionAtDeath,
          playerFactionAtEnd: localFaction,
          winningFaction: winningFaction,
          progress: _lastProgress,
          newlyUnlockedTitles: _lastNewlyUnlockedTitles,
          matchDurationLabel: _matchDurationLabel(),
          accusationPointsHuman: _rt.accusationPointsHuman,
          afterCatchRule: _afterCatchRule,
          onPrepareNext: () {
            Navigator.of(context).pop();
            _resetGame();
          },
          onOpenGallery: () async {
            Navigator.of(context).pop();
            await _openMatchGallery();
          },
          onOpenLobby: () async {
            Navigator.of(context).pop();
            await _openRoomLobby();
          },
        ),
      ),
    );
  }

  Future<void> _recordMatchProgressOnce({
    required bool won,
    required FactionSide faction,
  }) async {
    if (_progressRecordedForMatch) return;
    _progressRecordedForMatch = true;
    try {
      final update = await ProgressStore.recordMatch(won: won, faction: faction);
      _lastProgress = update.progress;
      _lastNewlyUnlockedTitles = update.newlyUnlocked;
      if (update.newlyUnlocked.isNotEmpty) {
        GameAudio.instance.playSfx(SfxId.unlock);
      }
    } catch (e) {
      _logDebug('progress record failed: $e');
    }
  }

  void _recenterMapOnGps() {
    if (_mapController == null) return;
    unawaited(
      _mapController!.animateCamera(
        CameraUpdate.newLatLngZoom(_currentPosition, 16),
      ),
    );
    _toast('現在地へ移動しました');
  }

  Future<void> _openPersonalSettings() async {
    final prefs0 = await SharedPreferences.getInstance();
    final form = await SessionPrefs.loadForm();
    if (!mounted) return;
    final result = await showPlayerPersonalSettingsSheet(
      context: context,
      initial: PlayerPersonalSettingsInitial(
        displayName: _localPlayerLabel,
        profile: _activeProfile,
        useBleScan: prefs0.getBool(GameMapPrefs.useBleScanProximity) ?? false,
        trajectoryConsent: _trajectoryConsent,
        avatarImagePath: _avatarImagePath,
      ),
    );
    if (!mounted || result == null) return;

    await SessionPrefs.saveForm(
      nickname: result.displayName,
      roomId: form.roomId,
      role: form.role,
    );
    if (mounted) {
      setState(() => _localNicknameOverride = result.displayName);
    }

    final fs = _firestoreSession;
    if (fs is FirestoreRoomSession) {
      final err = await fs.updateNickname(result.displayName);
      if (err != null && mounted) _toast(err);
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(GameMapPrefs.useBleScanProximity, result.useBleScan);
    if (result.avatarImagePath != null && result.avatarImagePath!.isNotEmpty) {
      await prefs.setString(GameMapPrefs.avatarImagePath, result.avatarImagePath!);
    } else {
      await prefs.remove(GameMapPrefs.avatarImagePath);
      await AvatarImageStore.deleteStored();
    }
    if (!mounted) return;

    setState(() {
      _avatarImagePath = result.avatarImagePath;
      _activeProfile = result.profile;
    });
    await _applyWorldProfile(result.profile);
    await _refreshPlayerAvatarIcon();
    unawaited(_syncAvatarThumbToFirestore());
    await _reloadProximityStackFromPrefs();
    if (_trajectoryConsent != result.trajectoryConsent) {
      await _setTrajectoryConsent(result.trajectoryConsent);
    }
    if (mounted) _toast('個人設定を適用しました');
  }

  Future<void> _openCustomMenu() async {
    if (_gameState == GameState.running) {
      _toast('ゲーム中はカスタム設定を変更できません');
      return;
    }
    if (!_isHost && !_participantRulesOpen) {
      _toast('カスタムルールの編集はホストが開放するまで待ってください');
      return;
    }
    final result = await showGameCustomSettingsSheet(
      context: context,
      initial: GameCustomSettingsInitial(
        oniIntelMode: _oniIntelMode,
        eliminationAftermathRule: _eliminationAftermathRule,
        localRole: _localRole,
        customRuleMode: _customRuleMode,
        participantRulesOpen: _participantRulesOpen,
        matchDurationMinutes: _matchDurationSeconds / 60,
        skillLoadout: _skillLoadout,
        gimmickDensity: _gimmickDensity,
        roleAssignMode: _roleAssignMode,
        oniCount: _roleOniCount,
        werewolfCount: _roleWerewolfCount,
        accusationWeight: _accusationWeight,
      ),
      isHost: _isHost,
      onRequestGameDefaultsReset: _isHost
          ? () async {
              final ok = await showDialog<bool>(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text('設定をデフォルトに戻す'),
                  content: const Text('試合時間・役職・スキル・ギミック初期配置などを初期状態に戻します。'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx, false),
                      child: const Text('キャンセル'),
                    ),
                    FilledButton(
                      onPressed: () => Navigator.pop(ctx, true),
                      child: const Text('戻す'),
                    ),
                  ],
                ),
              );
              if (ok == true && mounted) {
                _resetGame();
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('ゲーム設定をリセットしました')),
                  );
                }
              }
            }
          : null,
    );
    if (!mounted || result == null) return;
    final prefsPersist = await SharedPreferences.getInstance();
    await prefsPersist.setDouble(
      GameMapPrefs.gimmickDensity,
      result.gimmickDensity.clamp(0.45, 1.55),
    );
    if (!mounted) return;
    setState(() {
      _oniIntelMode = result.oniIntelMode;
      _eliminationAftermathRule = result.eliminationAftermathRule;
      _customRuleMode = result.customRuleMode;
      if (_isHost) {
        _participantRulesOpen = result.participantRulesOpen;
        _roleAssignMode = result.roleAssignMode;
        _roleOniCount = result.oniCount;
        _roleWerewolfCount = result.werewolfCount;
        _accusationWeight = result.accusationWeight;
      }
      _gimmickDensity = result.gimmickDensity.clamp(0.45, 1.55);
      _matchDurationSeconds = (result.matchDurationMinutes.round() * 60).clamp(
        MatchDurationScaling.minMatchSeconds,
        MatchDurationScaling.maxMatchSeconds,
      );
      if (result.quickPresetApplied != null && _playArea.type == PlayAreaType.circle) {
        _playArea = result.quickPresetApplied!.playAreaFromCenter(_playArea.center);
        _circleDraftCenter = _playArea.center;
        _circleDraftRadiusMeters = _playArea.radiusMeters;
      }
      if (_customRuleMode) {
        _localRole = result.localRole;
        _skillLoadout = result.skillLoadout.isEmpty
            ? skillCandidatesForRole(_localRole).take(1).toSet()
            : result.skillLoadout;
      }
    });
    if (_isOnlineFirestore && result.customRuleMode) {
      final err = await _firestoreSession!.publishRulePreferences(
        preferredRole: result.localRole,
        preferredSkills: result.skillLoadout.toList(),
      );
      if (err != null && mounted) _toast(err);
    }
    _toast('カスタム設定を適用しました');
  }

  void _cycleTimeScale() {
    setState(() {
      const scales = [1, 2, 4, 8];
      final idx = scales.indexOf(_timeScale);
      _timeScale = scales[(idx + 1) % scales.length];
    });
    _logDebug('time_scale=${_timeScale}x');
  }

  double _batteryCostPerSecond() {
    final tierBase = switch (_gpsTier) {
      LocationSamplingTier.relaxed => 0.25,
      LocationSamplingTier.standard => 0.55,
      LocationSamplingTier.chase => 0.95,
    };
    final pulse = _rt.isInfectedNow ? 0.25 : 0.0;
    return tierBase + pulse;
  }

  Future<void> _backToTitle() async {
    if (!await _confirmLeaveActiveMatch('タイトルへ戻りますか？')) return;
    _matchTimer?.cancel();
    _matchRecorder?.discard();
    _matchRecorder = null;
    _finalizeRecordingFuture = null;
    _remoteMembersSub?.cancel();
    _remoteMembersSub = null;
    if (_roomSession is FirestoreRoomSession) {
      await (_roomSession as FirestoreRoomSession).disconnect();
    }
    if (!mounted) return;
    setState(() {
      _roomSession = LocalOnlyRoomSession();
      _remoteMembers = {};
      _remoteOniKnown = false;
      _ownsRoomSession = false;
    });
    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  Future<void> _openRoomLobby() async {
    if (_gameState == GameState.running) {
      if (!await _confirmLeaveActiveMatch('ルームロビーへ移動しますか？')) return;
    } else {
      final go = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('ルームロビー'),
          content: const Text(
            'ルームからは退出せず、メンバー一覧とゲーム画面へ進むボタンを開きます。\n'
            '画面上部の「Home」でタイトルに戻ると、ルームから退出した扱いになります。',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('キャンセル'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('開く'),
            ),
          ],
        ),
      );
      if (go != true || !mounted) return;
    }
    if (!mounted) return;
    if (_gameState == GameState.running) {
      _discardActiveMatchForNavigation();
    }
    final fs = _roomSession is FirestoreRoomSession
        ? _roomSession as FirestoreRoomSession
        : null;
    final returned = await Navigator.of(context).push<FirestoreRoomSession?>(
      MaterialPageRoute<FirestoreRoomSession?>(
        builder: (_) => RoomLobbyScreen(existingSession: fs),
      ),
    );
    if (!mounted) return;
    if (returned != null && returned.roomId != null) {
      setState(() {
        _roomSession = returned;
        _ownsRoomSession = false;
      });
      _bindRemoteMembers(returned);
      _statusMessage = 'ルーム ${returned.roomId} に接続済み';
    } else if (_roomSession is FirestoreRoomSession &&
        (_roomSession as FirestoreRoomSession).roomId == null) {
      setState(() {
        _roomSession = LocalOnlyRoomSession();
        _remoteMembers = {};
        _remoteOniKnown = false;
        _ownsRoomSession = false;
      });
    }
  }

  void _leaveMapViewToPrep() {
    if (_gameState == GameState.running) return;
    if (_editingArea) {
      setState(() {
        _editingArea = false;
        _polygonDraft.clear();
        _polygonDraftClosed = false;
        _waitingCircleCenterTap = false;
      });
    }
    setState(() {
      _mapVisibleInLobby = false;
      _prepControlSheetOpen = false;
      _statusMessage = '準備画面に戻りました';
    });
  }

  Future<void> _openMatchGallery() async {
    final pending = _finalizeRecordingFuture;
    if (pending != null) {
      _toast('軌跡保存を完了してから開きます');
      await pending;
      if (!mounted) return;
    }
    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(builder: (_) => const MatchGalleryScreen()),
    );
  }

  void _discardActiveMatchForNavigation() {
    _matchTimer?.cancel();
    _matchRecorder?.discard();
    _matchRecorder = null;
    _finalizeRecordingFuture = null;
    setState(() {
      _gameState = GameState.waiting;
      _prepControlSheetOpen = true;
      _statusMessage = '試合を中断しました';
    });
  }

  Future<bool> _confirmLeaveActiveMatch(String title) async {
    if (_gameState != GameState.running) return true;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: const Text('試合中の移動です。現在の試合記録は破棄されます。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('キャンセル'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('移動する'),
          ),
        ],
      ),
    );
    return ok ?? false;
  }

  void _showHowToPlaySheet() =>
      showHowToPlaySheet(context, yourRole: _localRole);

  Future<void> _openHudDisplaySheet() async {
    if (_gameState != GameState.running) return;
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (ctx) {
        var showIntel = _hudShowIntelLine;
        var showStatus = _hudShowStatusLine;
        var showCondition = _hudShowConditionLine;
        var compactSlot = _hudCompactLineSlot;
        var layers = _mapLayerToggles;
        var iconScale = _mapMarkerIconScale;
        var compactLineExpanded = false;
        return StatefulBuilder(
          builder: (ctx, setModal) {
            return Padding(
              padding: EdgeInsets.fromLTRB(
                16,
                8,
                16,
                16 + MediaQuery.viewInsetsOf(ctx).bottom,
              ),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'HUD・地図の表示',
                      style: Theme.of(ctx).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('鬼情報'),
                      subtitle: const Text(
                        '一行表示・展開パネル。OFFで上部から非表示',
                      ),
                      value: showIntel,
                      onChanged: (v) => setModal(() => showIntel = v),
                    ),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('状態メッセージ'),
                      value: showStatus,
                      onChanged: (v) => setModal(() => showStatus = v),
                    ),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('コンディション行'),
                      value: showCondition,
                      onChanged: (v) => setModal(() => showCondition = v),
                    ),
                    const Divider(),
                    Text(
                      '地図のピン・円',
                      style: Theme.of(ctx).textTheme.titleSmall,
                    ),
                    const SizedBox(height: 4),
                    MapLayerToggleStrip(
                      dense: true,
                      showTitle: false,
                      toggles: layers,
                      onChanged: (t) => setModal(() => layers = t),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            '地図アイコンの大きさ',
                            style: Theme.of(ctx).textTheme.titleSmall,
                          ),
                        ),
                        Text(
                          '${(iconScale * 100).round()}%',
                          style: Theme.of(ctx).textTheme.labelLarge,
                        ),
                      ],
                    ),
                    Slider(
                      value: iconScale,
                      min: HudDisplaySettings.markerIconScaleMin,
                      max: HudDisplaySettings.markerIconScaleMax,
                      divisions: 17,
                      label: '${(iconScale * 100).round()}%',
                      onChanged: (v) {
                        final next =
                            HudDisplaySettings.clampMarkerIconScale(v);
                        setModal(() => iconScale = next);
                        unawaited(_applyMapMarkerIconScale(next));
                      },
                    ),
                    Text(
                      'ズームで見え方が変わるルールはそのまま。基準サイズだけ調整します。',
                      style: Theme.of(ctx).textTheme.bodySmall?.copyWith(
                            color: Theme.of(ctx).colorScheme.onSurfaceVariant,
                          ),
                    ),
                    const SizedBox(height: 4),
                    ExpansionTile(
                      tilePadding: EdgeInsets.zero,
                      initiallyExpanded: compactLineExpanded,
                      onExpansionChanged: (v) =>
                          setModal(() => compactLineExpanded = v),
                      title: Text(
                        '一行表示の内容',
                        style: Theme.of(ctx).textTheme.titleSmall,
                      ),
                      subtitle: Text(
                        compactSlot.label,
                        style: Theme.of(ctx).textTheme.bodySmall?.copyWith(
                              color:
                                  Theme.of(ctx).colorScheme.onSurfaceVariant,
                            ),
                      ),
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Text(
                            'タイマー背景でエリア内外は分かります。「すべて」は有効な情報を続けてスクロールします。',
                            style: Theme.of(ctx).textTheme.bodySmall?.copyWith(
                                  color: Theme.of(ctx)
                                      .colorScheme
                                      .onSurfaceVariant,
                                ),
                          ),
                        ),
                        ...HudCompactLineSlot.values.map(
                          (s) => ListTile(
                            contentPadding: EdgeInsets.zero,
                            dense: true,
                            title: Text(s.label),
                            trailing: compactSlot == s
                                ? Icon(
                                    Icons.check_circle,
                                    color:
                                        Theme.of(ctx).colorScheme.primary,
                                    size: 20,
                                  )
                                : null,
                            onTap: () => setModal(() => compactSlot = s),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    FilledButton(
                      onPressed: () async {
                        final hud = HudDisplaySettings(
                          compactLineSlot: compactSlot,
                          showIntelLine: showIntel,
                          showStatusLine: showStatus,
                          showConditionLine: showCondition,
                          markerIconScale: iconScale,
                        );
                        setState(() {
                          _hudShowIntelLine = showIntel;
                          _hudShowStatusLine = showStatus;
                          _hudShowConditionLine = showCondition;
                          _hudCompactLineSlot = compactSlot;
                          _mapLayerToggles = layers;
                          _mapMarkerIconScale = iconScale;
                        });
                        await HudDisplayPrefs.save(hud);
                        if (ctx.mounted) Navigator.pop(ctx);
                      },
                      child: const Text('適用'),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _onOverflowMenuSelected(String value) async {
    switch (value) {
      case 'discord':
        await _copyDiscordStatusSummary();
        break;
      case 'help':
        _showHowToPlaySheet();
        break;
      case 'oni':
        await Navigator.of(context).push<void>(
          MaterialPageRoute<void>(builder: (_) => const OniOperatorScreen()),
        );
        await _loadOniOperatorPrefs();
        break;
      case 'gallery':
        await _openMatchGallery();
        break;
      case 'history':
        _showRevealLog();
        break;
      case 'privacy':
        if (!context.mounted) return;
        await Navigator.of(context).push<void>(
          MaterialPageRoute<void>(builder: (_) => const PrivacyControlScreen()),
        );
        break;
      case 'abort_vote':
        await _requestAbortByVote();
        break;
      case 'test':
        _toggleTestMode();
        break;
      case 'result':
        final ended =
            _gameState == GameState.runnerWin ||
            _gameState == GameState.caughtByOni;
        if (ended) await _openMatchResultScreen();
        break;
      case 'dev_reset':
        if (_testMode) _resetGame();
        break;
      case 'dev_oni_move':
        if (_testMode) _moveOniForTest();
        break;
      case 'import':
        if (_gameState == GameState.running) {
          _toast('ゲーム中は GeoJSON をインポートできません');
        } else {
          await _showImportGeoJsonDialog();
        }
        break;
      case 'export':
        await _exportGeoJson();
        break;
      case 'show_panel':
        _showControlPanel();
        break;
    }
  }

  @override
  void dispose() {
    SchedulerBinding.instance.removeTimingsCallback(_onFrameTimings);
    WidgetsBinding.instance.removeObserver(this);
    _positionSubscription?.cancel();
    _proximitySubscription?.cancel();
    _remoteMembersSub?.cancel();
    _roomMatchSub?.cancel();
    _roomEventSub?.cancel();
    _matchTimer?.cancel();
    _hudRevealAlertTimer?.cancel();
    _secondGameHighlightTimer?.cancel();
    _renderPump?.cancel();
    _cancelCaptureBoundTimers();
    _dangerPulseController.dispose();
    _revealFlash.dispose();
    _proximityService.stop();
    unawaited(_bleAdvertiser.stop());
    if (_ownsRoomSession) {
      unawaited(_roomSession.disconnect());
    }
    _mapController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tokens = WorldProfileTokenFactory.of(_activeProfile);
    final screenSize = MediaQuery.sizeOf(context);
    final controlFabOffset = _clampControlFabOffset(
      _controlFabOffset,
      screenSize,
    );
    final overflowMeters = _playArea.overflowDistanceMeters(_currentPosition);
    final bool isOutBeyondGrace =
        overflowMeters > GameConfig.outsideAreaGraceMeters;
    final running = _gameState == GameState.running;
    final locallyEliminated =
        _gameState == GameState.caughtByOni && _afterCatchRule != null;
    final ended =
        _gameState == GameState.runnerWin ||
        (_gameState == GameState.caughtByOni && _afterCatchRule == null);
    final showHudPanel = running;
    final panelHidden = _controlSheetMode == ControlSheetMode.hidden;
    // 準備中のマップツール／試合中コントロール。脱落後は _prepControlSheetOpen を閉じる。
    final showBottomControlSheet = !locallyEliminated &&
        !panelHidden &&
        (running || _prepControlSheetOpen);
    final showControlFab = !locallyEliminated &&
        ((!running && !_prepControlSheetOpen) || (running && panelHidden));
    final eliminationCopy = locallyEliminated
        ? EliminationRoleCopy.forProfile(
            _mapVisual.pack.profile,
            _afterCatchRule!,
          )
        : null;
    final showGameMap =
        _editingArea || _mapVisibleInLobby || _gameState != GameState.waiting;
    final mq = MediaQuery.of(context);
    final narrow = mq.size.width < 400;
    final appTitle = narrow
        ? switch (_gameState) {
            GameState.waiting => '準備',
            GameState.running => 'プレイ中',
            GameState.runnerWin => '逃走成功',
            GameState.caughtByOni => locallyEliminated
                ? eliminationCopy!.roleTitle
                : '捕獲',
          }
        : switch (_gameState) {
            GameState.waiting => 'Oni Game ・ 準備',
            GameState.running => 'Oni Game ・ プレイ中',
            GameState.runnerWin => 'Oni Game ・ 逃走成功',
            GameState.caughtByOni => locallyEliminated
                ? 'Oni Game ・ ${eliminationCopy!.roleTitle}'
                : 'Oni Game ・ 捕獲',
          };

    return PopScope(
      canPop: !running,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop && running) {
          _toast('試合中は端末の「戻る」では抜けません。右上の More（⋮）から「試合中止の投票」を使ってください。');
        }
      },
      child: Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: false,
          leading: running
              ? const SizedBox.shrink()
              : (showGameMap || _editingArea)
              ? IconButton(
                  tooltip: '準備画面に戻る',
                  icon: const Icon(Icons.arrow_back),
                  onPressed: _leaveMapViewToPrep,
                )
              : IconButton(
                  tooltip: '戻る',
                  icon: const Icon(Icons.arrow_back),
                  onPressed: () => Navigator.of(context).maybePop(),
                ),
          title: Text(appTitle),
          actions: [
            if (!running) ...[
              TextButton.icon(
                onPressed: _backToTitle,
                icon: const Icon(Icons.home_outlined, size: 18),
                label: const Text('Home'),
              ),
              TextButton.icon(
                onPressed: _openRoomLobby,
                icon: const Icon(Icons.groups_outlined, size: 18),
                label: const Text('Lobby'),
              ),
            ],
            GameMapOverflowMenu(
              gameState: _gameState,
              editingArea: _editingArea,
              testMode: _testMode,
              panelHidden: panelHidden,
              prepControlSheetOpen: _prepControlSheetOpen,
              onSelected: (value) => unawaited(_onOverflowMenuSelected(value)),
            ),
          ],
        ),
        body: Stack(
          children: [
            if (showGameMap)
              Positioned.fill(
                child: Builder(
                  builder: (context) {
                    final overlay = _overlaySnapshot(tokens);
                    return GoogleMap(
                      style: _mapVisual.mapStyleJson,
                      initialCameraPosition: CameraPosition(
                        target: _currentPosition,
                        zoom: 16,
                      ),
                      myLocationEnabled: true,
                      myLocationButtonEnabled: true,
                      markers: GameMapOverlayBuilder.buildMarkers(overlay),
                      polylines: GameMapOverlayBuilder.buildPolylines(overlay),
                      circles: GameMapOverlayBuilder.buildCircles(overlay),
                      polygons: GameMapOverlayBuilder.buildPolygons(overlay),
                      onTap: _onMapTap,
                      onMapCreated: _onMapCreated,
                      onCameraIdle: _onCameraIdle,
                    );
                  },
                ),
              )
            else
              Positioned.fill(
                child: PrepLobbyPanel(
                  roomLabel: _roomSession.modeLabel,
                  playAreaLabel: _playAreaSummary(),
                  matchDurationMinutes: _matchDurationSeconds / 60,
                  isHost: _isHost,
                  settingsSummaryLine: _prepSettingsSummaryLine(),
                  rulesOverviewLine:
                      _isHost ? null : _rulesOverviewLineForLobby(),
                  onDurationChanged: _setPrepDurationMinutes,
                  savedAreas: _savedPlayAreas,
                  selectedAreaId: _selectedPlayAreaSlotId,
                  onSelectArea: (id) =>
                      setState(() => _selectedPlayAreaSlotId = id),
                  onHostApplyArea: _hostApplySelectedPlayArea,
                  onDeleteSavedArea: _deleteSavedPlayArea,
                  activePlayArea: _playArea,
                  onStart: _startGame,
                  canStart: !_editingArea && _isHost,
                  onOpenCustomSettings: _openCustomMenu,
                  onOpenPersonalSettings: _openPersonalSettings,
                  displayName: _localPlayerLabel,
                  avatarImagePath: _avatarImagePath,
                  participantRulesOpen: _participantRulesOpen,
                  worldVisualProfile: _mapVisual.pack.profile,
                  startButtonKey: _prepStartKey,
                  customRulesKey: _prepCustomRulesKey,
                ),
              ),
            if (showGameMap)
              Positioned.fill(
                child: IgnorePointer(
                  child: AnimatedBuilder(
                    animation: _dangerPulseController,
                    builder: (_, child) {
                      final dangerExtra = running
                          ? (_dangerPulseController.value * 0.35) +
                                (_rt.isInfectedNow ? 0.20 : 0.0)
                          : 0.0;
                      return Stack(
                        fit: StackFit.expand,
                        children: [
                          WorldMapAtmosphere(
                            pack: _mapVisual.pack,
                            dangerPulse: dangerExtra,
                            revealFlashActive: _revealFlash.active,
                            scanPhase: _cameraPulsePhase,
                            revealNoiseSeed: _revealFlash.noiseSeed,
                          ),
                          if (dangerExtra > 0.05)
                            DecoratedBox(
                              decoration: BoxDecoration(
                                gradient: RadialGradient(
                                  center: const Alignment(0, -0.2),
                                  radius: 1.0,
                                  colors: [
                                    _mapVisual.pack.tokens.alertColor
                                        .withValues(alpha: dangerExtra),
                                    Colors.transparent,
                                  ],
                                ),
                              ),
                            ),
                        ],
                      );
                    },
                  ),
                ),
              ),
            if (_testMode)
              Positioned(
                top: 120,
                right: 12,
                child: DiagnosticsCard(
                  fps: _fps,
                  gpsTier: _gpsTier.name,
                  gpsAccuracyLast: _lastGpsAccuracyMeters,
                  gpsAccuracyAvg: _avgGpsAccuracyMeters,
                  batteryScore: _estimatedBatteryScore,
                  timeScale: _timeScale,
                  onCycleTimeScale: _cycleTimeScale,
                  onFlushSync: _simulateOfflineFlush,
                  debugLogs: _debugLogs,
                  queueCount: _offlineQueueCount,
                  proximityText: _proximityText,
                  roomSessionText: _roomSession.modeLabel,
                  syncInFlight: _syncInFlight,
                ),
              ),
            if (ended)
              Positioned(
                top: 12,
                left: 12,
                right: 12,
                child: Material(
                  elevation: 2,
                  borderRadius: BorderRadius.circular(10),
                  color: Theme.of(context).colorScheme.surfaceContainerHigh,
                  child: ListTile(
                    dense: true,
                    leading: const Icon(Icons.emoji_events_outlined),
                    title: Text(_gameState.label),
                    subtitle: Text(
                      _statusMessage,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    trailing: TextButton(
                      onPressed: _openMatchResultScreen,
                      child: const Text('リザルト'),
                    ),
                  ),
                ),
              ),
            if (locallyEliminated && !ended) ...[
              Positioned(
                top: 8,
                left: 12,
                right: 12,
                child: Material(
                  elevation: 3,
                  borderRadius: BorderRadius.circular(12),
                  color: Theme.of(context)
                      .colorScheme
                      .secondaryContainer
                      .withValues(alpha: 0.96),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 12,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '捕獲 — 第二ゲーム',
                          style: Theme.of(context).textTheme.labelLarge,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          eliminationCopy!.roleTitle,
                          style: Theme.of(context)
                              .textTheme
                              .titleMedium
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          eliminationCopy.roleSubtitle,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                        const SizedBox(height: 6),
                        Text(
                          '試合は続行中です。下の操作で仲間を支援し、終了後にリザルトへ進みます。',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: Theme.of(context)
                                    .colorScheme
                                    .onSurfaceVariant,
                              ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              Positioned(
                left: 16,
                right: 16,
                bottom: 16,
                child: EliminationSupportBar(
                  rule: _afterCatchRule!,
                  worldProfile: _mapVisual.pack.profile,
                  chargeActive: _eliminationChargeActive,
                  chargeProgress: _eliminationChargeProgress,
                  chargeActionLabel: _eliminationChargeActionLabel,
                  matchJackUses: _eliminationPrimaryMatchUses,
                  matchJackLimit: _eliminationPrimaryMatchLimit,
                  secondaryActionLine: _eliminationSecondaryLine,
                  personalCooldownSeconds: _eliminationPersonalCooldownSeconds,
                  statusLine: _statusMessage,
                ),
              ),
            ],
            if (showHudPanel)
              Positioned(
                top: 18,
                left: 16,
                right: 16,
                child: GameInfoPanel(
                  expanded: _hudExpanded,
                  onToggleExpanded: () =>
                      setState(() => _hudExpanded = !_hudExpanded),
                  revealAlert: _hudRevealAlert,
                  onDismissRevealAlert: () => setState(() {
                    _hudRevealAlert = null;
                    _hudRevealAlertTimer?.cancel();
                  }),
                  onOpenRevealLog: _showRevealLog,
                  compactLineText: _hudCompactLineText(),
                  intelLine: _latestIntelLine(),
                  showIntelLine:
                      _rt.showOniIntelCard &&
                      _hudShowIntelLine &&
                      _latestIntelLine().isNotEmpty,
                  onOpenIntelLog: _openCombinedIntelRevealLogSheet,
                  onOpenDisplaySettings: _openHudDisplaySheet,
                  showStatusLine: _hudShowStatusLine,
                  showConditionLine: _hudShowConditionLine,
                  timerText: MapGeoUtils.formatClock(_rt.remainingSeconds),
                  gameStateText: _gameState.label,
                  statusText: _statusMessage,
                  areaText: isOutBeyondGrace
                      ? 'エリア外 +${overflowMeters.toStringAsFixed(0)}m（境界から離れすぎ）'
                      : 'エリア内',
                  areaColor: isOutBeyondGrace
                      ? Colors.red.shade700
                      : Colors.green.shade700,
                  revealCount: _rt.revealCount,
                  editing: _editingArea,
                  safeZoneCharges: _rt.safeZoneCharges,
                  conditionText: _conditionLine(),
                  werewolfOniActive: _rt.werewolfInOniForm,
                  werewolfHudSummary: _werewolfHudSummary(),
                  werewolfCooldownSeconds: _cooldownRemainingSeconds(
                    _rt.lastWerewolfTransformAt,
                    _werewolfTransformCooldownSeconds,
                  ),
                  fakeCooldownSeconds: _cooldownRemainingSeconds(
                    _rt.lastFakeSkillAt,
                    GameConfig.fakeSkillCooldownSeconds,
                  ),
                  fakeIntelRevealCooldownSeconds: _cooldownRemainingSeconds(
                    _rt.lastFakeIntelRevealAt,
                    GameConfig.fakeIntelRevealCooldownSeconds,
                  ),
                  phaseLabel: _matchPhaseLabel(),
                  eventFeedLine: _matchEventFeedLine,
                  mapWorldProfile: _mapVisual.pack.profile,
                ),
              ),
            if (running && _rt.remainingSeconds <= 10)
              Positioned(
                top: 110,
                left: 0,
                right: 0,
                child: Center(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.72),
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 22,
                        vertical: 10,
                      ),
                      child: Text(
                        _rt.remainingSeconds.clamp(0, 10).toString(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 42,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            if (running && _bodyThrowHudSeconds() != null)
              Positioned(
                top: (running && _rt.remainingSeconds <= 10) ? 188 : 110,
                left: 12,
                right: 12,
                child: Center(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: Colors.deepOrange.shade900.withValues(alpha: 0.88),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: Colors.white24),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            _bodyThrowHudPhaseLabel() ?? '',
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 12,
                            ),
                          ),
                          Text(
                            '${_bodyThrowHudSeconds()}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const Text(
                            '秒',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            if (showBottomControlSheet)
              Positioned(
                bottom: 16,
                left: 16,
                right: 16,
                child: running
                    ? GameControlPanel(
                  sheetMode: _controlSheetMode,
                  onCycleSheetMode: _cycleControlSheetMode,
                  onStart: _startGame,
                  onReset: _resetGame,
                  onOpenResult: _openMatchResultScreen,
                  onFakeSkill: _activateFakeSkill,
                  onFakeIntelReveal: _activateFakeIntelReveal,
                  onWerewolfHunter: _activateWerewolfHunter,
                  onCaptureZone: _activateCaptureZone,
                  onBodyThrow: _activateBodyThrow,
                  onRecenterGps: _recenterMapOnGps,
                  onRefreshGps: _setupLocation,
                  onClearTraces: _clearTracePoints,
                  onToggleAreaEdit: _toggleAreaEditor,
                  onOpenCustomMenu: _openCustomMenu,
                  onOpenPersonalSettings: _openPersonalSettings,
                  onOpenHelp: _showHowToPlaySheet,
                  onDismissPrepSheet: () => setState(() {
                    _prepControlSheetOpen = false;
                  }),
                  onHidePanel: _hideControlPanel,
                  isHost: _isHost,
                  isRunning: running,
                  matchEnded: ended,
                  canStartMatch: _gameState == GameState.waiting,
                  isEditing: _editingArea,
                  fakeSkillActive: _rt.fakePositionActive,
                  fakeActiveSeconds: _rt.fakePositionActive
                      ? _secondsUntil(_rt.fakePositionEndsAt)
                      : 0,
                  roleLabel: _isHunterNow ? '鬼' : _localRole.displayName,
                  matchDurationLabel: _matchDurationLabel(),
                  canFakeSkill: _skillLoadout.contains(SkillIds.fakePosition),
                  canFakeIntelReveal:
                      _skillLoadout.contains(SkillIds.fakeIntelReveal),
                  canWerewolfHunter: _skillLoadout.contains(
                    SkillIds.werewolfTransform,
                  ),
                  canCaptureZone: _skillLoadout.contains(SkillIds.captureZone),
                  canBodyThrow: _skillLoadout.contains(SkillIds.bodyThrow),
                  fakeCooldownSeconds: _cooldownRemainingSeconds(
                    _rt.lastFakeSkillAt,
                    GameConfig.fakeSkillCooldownSeconds,
                  ),
                  fakeIntelCooldownSeconds: _cooldownRemainingSeconds(
                    _rt.lastFakeIntelRevealAt,
                    GameConfig.fakeIntelRevealCooldownSeconds,
                  ),
                  captureCooldownSeconds: _cooldownRemainingSeconds(
                    _rt.lastSkillLockPlacementAt,
                    GameConfig.captureZoneCooldownSeconds,
                  ),
                  bodyThrowCooldownSeconds: _cooldownRemainingSeconds(
                    _rt.lastBodyThrowAt,
                    GameConfig.bodyThrowCooldownSeconds,
                  ),
                  werewolfOniActive: _rt.werewolfInOniForm,
                  werewolfCooldownSeconds: _cooldownRemainingSeconds(
                    _rt.lastWerewolfTransformAt,
                    _werewolfTransformCooldownSeconds,
                  ),
                  prepLobbyMapHidden:
                      _gameState == GameState.waiting && !showGameMap,
                  mapToolsOnlyPanel:
                      _gameState == GameState.waiting && showGameMap,
                  mapWorldProfile: _mapVisual.pack.profile,
                  onPrepShowMap: () => setState(() {
                    _mapVisibleInLobby = true;
                    _prepControlSheetOpen = true;
                    _controlSheetMode = ControlSheetMode.skillsOnly;
                    _statusMessage =
                        '地図を表示しました。エリアの編集と保存ができます。';
                  }),
                    )
                    : showGameMap
                    ? PrepMapBottomPanel(
                        isEditing: _editingArea,
                        areaEditorExpanded: _areaEditorPanelExpanded,
                        onToggleAreaEditorExpanded: () => setState(
                          () => _areaEditorPanelExpanded =
                              !_areaEditorPanelExpanded,
                        ),
                        editCircleMode: _editCircleMode,
                        onModeChanged: (circle) {
                          setState(() {
                            _editCircleMode = circle;
                            _waitingCircleCenterTap = false;
                          });
                        },
                        circleRadiusMeters: _circleDraftRadiusMeters,
                        onRadiusChanged: (v) => setState(() {
                          _circleDraftRadiusMeters = v;
                        }),
                        waitingCenterTap: _waitingCircleCenterTap,
                        onRequestCenterTap: () => setState(() {
                          _waitingCircleCenterTap = true;
                          _statusMessage = '地図をタップして円の中心を指定';
                        }),
                        onCenterGps: () => setState(() {
                          _circleDraftCenter = _currentPosition;
                          _statusMessage = '円の中心を現在地にしました';
                        }),
                        onUndo: _undoLastVertex,
                        onClear: _clearPolygonDraft,
                        polygonClosed: _polygonDraftClosed,
                        onClosePolygon: _closePolygonDraft,
                        onReopenPolygon: _reopenPolygonDraft,
                        vertexCount: _polygonDraft.length,
                        onApply: _applyEditedArea,
                        onCancelEdit: _exitAreaEditKeepMap,
                        onToggleAreaEdit: _toggleAreaEditor,
                        onRecenterGps: _recenterMapOnGps,
                        onRefreshGps: _setupLocation,
                        onClearTraces: _clearTracePoints,
                        onOpenHelp: _showHowToPlaySheet,
                        onDismissPrepSheet: () => setState(() {
                          _prepControlSheetOpen = false;
                          if (_editingArea) _exitAreaEditKeepMap();
                        }),
                      )
                    : GameControlPanel(
                        sheetMode: _controlSheetMode,
                        onCycleSheetMode: _cycleControlSheetMode,
                        onStart: _startGame,
                        onReset: _resetGame,
                        onOpenResult: _openMatchResultScreen,
                        onFakeSkill: _activateFakeSkill,
                        onFakeIntelReveal: _activateFakeIntelReveal,
                        onWerewolfHunter: _activateWerewolfHunter,
                        onCaptureZone: _activateCaptureZone,
                        onBodyThrow: _activateBodyThrow,
                        onRecenterGps: _recenterMapOnGps,
                        onRefreshGps: _setupLocation,
                        onClearTraces: _clearTracePoints,
                        onToggleAreaEdit: _toggleAreaEditor,
                        onOpenCustomMenu: _openCustomMenu,
                        onOpenPersonalSettings: _openPersonalSettings,
                        onOpenHelp: _showHowToPlaySheet,
                        onDismissPrepSheet: () => setState(() {
                          _prepControlSheetOpen = false;
                        }),
                        onHidePanel: _hideControlPanel,
                        isHost: _isHost,
                        isRunning: false,
                        matchEnded: ended,
                        canStartMatch: _gameState == GameState.waiting,
                        isEditing: _editingArea,
                        fakeSkillActive: _rt.fakePositionActive,
                        roleLabel: _isHunterNow ? '鬼' : _localRole.displayName,
                        matchDurationLabel: _matchDurationLabel(),
                        canFakeSkill: false,
                        canFakeIntelReveal: false,
                        canWerewolfHunter: false,
                        canCaptureZone: false,
                        canBodyThrow: false,
                        fakeCooldownSeconds: 0,
                        fakeIntelCooldownSeconds: 0,
                        captureCooldownSeconds: 0,
                        bodyThrowCooldownSeconds: 0,
                        werewolfOniActive: false,
                        werewolfCooldownSeconds: 0,
                        prepLobbyMapHidden: true,
                        mapWorldProfile: _mapVisual.pack.profile,
                        onPrepShowMap: () => setState(() {
                          _mapVisibleInLobby = true;
                          _prepControlSheetOpen = true;
                        }),
                      ),
              ),
            if (showControlFab)
              Positioned(
                left: controlFabOffset.dx,
                top: controlFabOffset.dy,
                child: SafeArea(
                  child: GestureDetector(
                    onPanUpdate: (details) {
                      setState(() {
                        _controlFabOffset = _clampControlFabOffset(
                          controlFabOffset + details.delta,
                          screenSize,
                        );
                      });
                    },
                    child: FloatingActionButton.extended(
                      key: _prepMapFabKey,
                      onPressed: _showControlPanel,
                      icon: Icon(running ? Icons.expand_less : Icons.tune),
                      label: Text(running ? '展開' : 'マップパネル'),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
