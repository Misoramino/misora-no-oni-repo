import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../features/game_map/control_sheet_mode.dart';
import '../features/game_map/map/game_map_layer_toggles.dart';
import '../features/game_map/map/game_map_overlay_builder.dart';
import '../features/game_map/map/game_map_overlay_snapshot.dart';
import '../features/game_map/map/map_geo_format.dart';
import '../features/game_map/logic/gimmick_relocator.dart';
import '../features/game_map/logic/map_geo_utils.dart';
import '../features/game_map/logic/oni_intel_text_builder.dart';
import '../features/game_map/match/game_map_match_controller.dart';
import '../features/game_map/match/gimmick_pickup_evaluator.dart';
import '../features/game_map/match/match_geo_helpers.dart';
import '../features/game_map/match/match_runtime_state.dart';
import '../features/game_map/match/match_tick_effects.dart';
import '../features/game_map/play_area/geo_json_actions.dart';
import '../features/game_map/prep/prep_lobby_panel.dart';
import '../features/game_map/widgets/how_to_play_sheet.dart';
import '../features/game_map/settings/game_custom_settings_models.dart';
import '../features/game_map/settings/game_custom_settings_sheet.dart';
import '../features/game_map/widgets/area_editor_card.dart';
import '../features/game_map/widgets/diagnostics_card.dart';
import '../features/game_map/widgets/game_control_panel.dart';
import '../features/game_map/widgets/game_info_panel.dart';
import '../features/game_map/widgets/game_map_overflow_menu.dart';
import '../features/game_map/widgets/ghost_spectator_bar.dart';
import '../game/elimination_aftermath_rule.dart';
import '../game/game_config.dart';
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

  final LocationService _locationService = LocationService();
  final PlayAreaStore _areaStore = PlayAreaStore();
  final PlayAreaSlotStore _areaSlotStore = PlayAreaSlotStore();
  final MatchArchiveStore _matchArchive = MatchArchiveStore();
  final OfflineSyncQueue _offlineQueue = OfflineSyncQueue();
  final GameMapMatchController _matchCtrl = GameMapMatchController();
  late HybridProximityService _proximityService = HybridProximityService(
    bleDelegate: IdleProximityService(),
  );
  RoomSessionPort _roomSession = LocalOnlyRoomSession();

  MatchRuntimeState get _rt => _matchCtrl.runtime;

  GoogleMapController? _mapController;
  StreamSubscription<Position>? _positionSubscription;
  StreamSubscription<ProximitySignal>? _proximitySubscription;
  Timer? _matchTimer;
  Timer? _renderPump;

  LocationSamplingTier _gpsTier = LocationSamplingTier.relaxed;
  RunnerDisplaySmoothing? _runnerSmooth;

  LatLng _currentPosition = const LatLng(35.681236, 139.767125);
  LatLng _oniPosition = _defaultOniPosition;

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

  GameState _gameState = GameState.waiting;
  String _statusMessage = '現在地を取得中...';
  DateTime? _lastAcceptedPositionAt;
  OniIntelMode _oniIntelMode = OniIntelMode.directionOnly;
  bool _customRuleMode = false;
  int _matchDurationSeconds = GameConfig.matchDurationSeconds;
  PlayerRole _localRole = PlayerRole.runner;
  Set<String> _skillLoadout = const {SkillIds.fakePosition};
  final List<LatLng> _tracePoints = [];

  MatchRecorder? _matchRecorder;
  Future<void>? _finalizeRecordingFuture;
  bool _trajectoryConsent = false;
  late WorldProfile _activeProfile;
  late MapVisualController _mapVisual;
  String? _avatarImagePath;
  late RevealFlashController _revealFlash;
  double _cameraPulsePhase = 0;
  ControlSheetMode _controlSheetMode = ControlSheetMode.skillsOnly;
  bool _hudExpanded = false;
  GameMapLayerToggles _mapLayerToggles = GameMapLayerToggles.allOn;
  String? _hudRevealAlert;
  Timer? _hudRevealAlertTimer;
  bool _oniIntelLineHidden = false;

  /// ホストが参加者にカスタムルール（役職固定等）の編集を許可したか。
  bool _participantRulesOpen = false;
  List<SavedPlayArea> _savedPlayAreas = const [];
  String? _selectedPlayAreaSlotId;

  /// 準備・試合結果中は操作パネルを隠し、FAB「詳細設定」で開く。
  bool _prepControlSheetOpen = false;
  Offset? _controlFabOffset;
  bool _testMode = false;
  int _timeScale = 1;
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
  final Set<String> _abortVoteYesUids = {};
  bool _syncInFlight = false;
  Map<String, RemoteMemberSnapshot> _remoteMembers = {};
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
  EliminationAftermathRule _eliminationAftermathRule =
      EliminationAftermathRule.ghostSpectator;
  EliminationAftermathRule? _afterCatchRule;

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
    Future<void>.microtask(_loadGimmickDensity);
    Future<void>.microtask(_initProximityStack);
    Future<void>.microtask(_refreshOfflineQueueCount);
    if (widget.onlineSession != null) {
      Future<void>.microtask(_attachOnlineSession);
    }
    Future<void>.microtask(_loadOniOperatorPrefs);
    Future<void>.microtask(_loadPlayAreaSlots);
    Future<void>.microtask(_initWorldVisual);
    _startRenderPump();
    SchedulerBinding.instance.addTimingsCallback(_onFrameTimings);
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

  Future<void> _loadEliminationAftermathRule() async {
    final prefs = await SharedPreferences.getInstance();
    final parsed = EliminationAftermathRuleX.tryParseName(
      prefs.getString(GameMapPrefs.eliminationAftermathRule),
    );
    if (!mounted) return;
    if (parsed != null) {
      setState(() => _eliminationAftermathRule = parsed);
    }
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
    await _proximitySubscription?.cancel();
    await _proximityService.stop();
    final ProximityService bleDelegate;
    if (useBle) {
      bleDelegate = BleScanProximityService();
    } else if (_testMode) {
      bleDelegate = MockProximityService();
    } else {
      bleDelegate = IdleProximityService();
    }
    _proximityService = HybridProximityService(bleDelegate: bleDelegate);
    await _setupProximity();
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
  }

  void _bindRemoteMembers(FirestoreRoomSession session) {
    _remoteMembersSub?.cancel();
    final seed = session.currentRemoteMembers;
    setState(() {
      _remoteMembers = Map<String, RemoteMemberSnapshot>.from(seed);
      _applyRemoteOniPosition(_remoteMembers);
    });
    _remoteMembersSub = session.remoteMembers.listen((map) {
      if (!mounted) return;
      setState(() {
        _remoteMembers = map;
        _applyRemoteOniPosition(map);
      });
    });
    _roomMatchSub?.cancel();
    _roomMatchSub = session.roomMatchState.listen(_onRemoteRoomMatchState);

    _roomEventSub?.cancel();
    _roomEventSub = session.roomMatchEvents.listen(_onRemoteRoomMatchEvent);

    final rm = session.currentRoomMatch;
    if (rm.phase == RoomPhase.running && rm.matchStart != null) {
      session.startRoomEventsListener(rm.matchStart!.gimmickSeed);
    }
    if (!_isHost) {
      _onRemoteRoomMatchState(rm);
    }
  }

  void _onRemoteRoomMatchState(RoomMatchState state) {
    if (!mounted || _isHost) return;
    switch (state.phase) {
      case RoomPhase.running:
        if (state.matchStart != null) {
          _firestoreSession?.startRoomEventsListener(
            state.matchStart!.gimmickSeed,
          );
        }
        if (_gameState == GameState.waiting &&
            !_editingArea &&
            state.matchStart != null) {
          _applySharedMatchStart(state.matchStart!);
          _toast('ホストが試合を開始しました');
          _startGameCore();
        }
        break;
      case RoomPhase.ended:
        if (_gameState == GameState.running && state.matchEnd != null) {
          final end = state.matchEnd!;
          _endGame(
            end.outcome,
            end.message.isNotEmpty ? end.message : _messageForMatchEnd(end),
            endReason: end.endReason,
            skipFirestoreSync: true,
          );
        }
        break;
      case RoomPhase.lobby:
        if (_gameState != GameState.waiting) {
          _resetGame(skipFirestoreSync: true);
          _toast('ルームがロビーに戻りました');
        }
        break;
    }
  }

  String _messageForMatchEnd(SharedMatchEnd end) => switch (end.endReason) {
    MatchEndReason.timeUp => '逃走成功。時間切れです。',
    MatchEndReason.caught => '鬼に捕まりました。',
    MatchEndReason.hostAbort => 'ホストが試合を中止しました。',
    _ => 'ホストが試合を終了しました。',
  };

  void _applyRemoteOniPosition(Map<String, RemoteMemberSnapshot> map) {
    _remoteOniKnown = false;
    for (final m in map.values) {
      if (m.role == 'oni') {
        _oniPosition = LatLng(m.lat, m.lng);
        _remoteOniKnown = true;
        return;
      }
    }
  }

  Future<void> _setupProximity() async {
    await _proximityService.start();
    _proximitySubscription?.cancel();
    _proximitySubscription = _proximityService.watch().listen((signal) {
      if (!mounted) return;
      setState(() {
        _proximityText =
            '近接: ${signal.band.name} (${(signal.confidence * 100).toStringAsFixed(0)}%)';
        _latestProximityBand = signal.band;
      });
      _logDebug(
        'proximity:${signal.band.name}:${signal.confidence.toStringAsFixed(2)}',
      );
    });
  }

  Future<void> _loadSavedArea() async {
    final saved = await _areaStore.load();
    if (!mounted || saved == null) return;
    setState(() {
      _playArea = saved;
      if (_playArea.type == PlayAreaType.circle) {
        _circleDraftCenter = _playArea.center;
        _circleDraftRadiusMeters = _playArea.radiusMeters;
      }
      _statusMessage = '前回ホスト適用済みのプレイエリアを読み込みました';
    });
  }

  Future<void> _loadPlayAreaSlots() async {
    final slots = await _areaSlotStore.loadAll();
    if (!mounted) return;
    setState(() {
      _savedPlayAreas = slots;
      _selectedPlayAreaSlotId ??= slots.isNotEmpty ? slots.first.id : null;
    });
  }

  Future<bool> _confirmDialog({
    required String title,
    required String message,
    String confirmLabel = '削除',
  }) => showConfirmDialog(
    context,
    title: title,
    message: message,
    confirmLabel: confirmLabel,
  );

  Future<String?> _promptAreaName(String defaultName) => showTextPromptDialog(
    context,
    title: 'エリアの名前',
    labelText: '名前',
    hintText: '例: 公園A・駅前',
    defaultValue: defaultName,
    confirmLabel: '保存',
  );

  void _closePolygonDraft() {
    if (_polygonDraft.length < 3) {
      _toast('3点以上打ってから閉じてください');
      return;
    }
    try {
      final resolved = PolygonAreaResolver.resolveBoundedRing(
        _polygonDraft,
        seed: _polygonDraft.first,
      );
      setState(() {
        _polygonDraft
          ..clear()
          ..addAll(resolved);
        _polygonDraftClosed = true;
        _statusMessage = 'エリアを閉じました（${_polygonDraft.length} 頂点）';
      });
    } catch (e) {
      _toast('閉じられませんでした: $e');
    }
  }

  void _reopenPolygonDraft() {
    setState(() {
      _polygonDraftClosed = false;
      _statusMessage = '頂点を追加してから再度「閉じる」';
    });
  }

  Future<void> _deleteSavedPlayArea(String id, String name) async {
    final ok = await _confirmDialog(
      title: '保存エリアを削除',
      message: '「$name」を削除しますか？\n試合に適用済みの形は変わりません。',
    );
    if (!ok) return;
    await _areaSlotStore.remove(id);
    if (!mounted) return;
    setState(() {
      if (_selectedPlayAreaSlotId == id) {
        _selectedPlayAreaSlotId = null;
      }
    });
    await _loadPlayAreaSlots();
    _toast('保存エリアを削除しました');
  }

  Future<void> _saveEditedAreaAsSlot() async {
    try {
      late final PlayArea next;
      if (_editCircleMode) {
        next = PlayArea.circle(
          center: _circleDraftCenter,
          radiusMeters: _circleDraftRadiusMeters,
        );
      } else {
        if (!_polygonDraftClosed || _polygonDraft.length < 3) {
          _toast('多角形は「閉じる」してから保存してください');
          return;
        }
        next = PlayArea.polygon(points: List.from(_polygonDraft));
      }
      final stamp = DateTime.now();
      final defaultName =
          'エリア ${stamp.month}/${stamp.day} ${stamp.hour}:${stamp.minute.toString().padLeft(2, '0')}';
      final name = await _promptAreaName(defaultName);
      if (!mounted || name == null) return;
      final slot = SavedPlayArea(
        id: 'area_${stamp.microsecondsSinceEpoch}',
        name: name,
        area: next,
        savedAtUtc: stamp.toUtc(),
      );
      await _areaSlotStore.upsert(slot);
      if (!mounted) return;
      setState(() {
        _editingArea = false;
        _waitingCircleCenterTap = false;
        _selectedPlayAreaSlotId = slot.id;
        _statusMessage = 'エリアを保存しました（ホストが適用するまで試合には反映されません）';
      });
      await _loadPlayAreaSlots();
      _returnToPrepAfterAreaEdit();
    } catch (e) {
      _toast('保存に失敗しました: $e');
    }
  }

  FirestoreRoomSession? get _firestoreSession =>
      _roomSession is FirestoreRoomSession
      ? _roomSession as FirestoreRoomSession
      : null;

  bool get _isOnlineFirestore => _firestoreSession?.roomId != null;

  bool get _isHost {
    final fs = _firestoreSession;
    if (fs != null && fs.roomId != null) {
      return fs.isHost;
    }
    return true;
  }

  void _hostApplySelectedPlayArea() {
    if (!_isHost) {
      _toast('エリアの適用はホストのみできます');
      return;
    }
    final id = _selectedPlayAreaSlotId;
    if (id == null) {
      _toast('適用する保存エリアを選んでください');
      return;
    }
    SavedPlayArea? slot;
    for (final s in _savedPlayAreas) {
      if (s.id == id) {
        slot = s;
        break;
      }
    }
    if (slot == null) {
      _toast('保存エリアが見つかりません');
      return;
    }
    final applied = slot;
    setState(() {
      _playArea = applied.area;
      if (_playArea.type == PlayAreaType.circle) {
        _circleDraftCenter = _playArea.center;
        _circleDraftRadiusMeters = _playArea.radiusMeters;
      }
      _statusMessage = 'ホストが「${applied.name}」を適用しました';
    });
    unawaited(_areaStore.save(applied.area));
  }

  void _setPrepDurationMinutes(double minutes) {
    if (!_isHost) return;
    setState(() {
      _matchDurationSeconds = (minutes.round() * 60).clamp(60, 20 * 60);
      if (_gameState == GameState.waiting) {
        _rt.remainingSeconds = _matchDurationSeconds;
      }
    });
  }

  void _returnToPrepAfterAreaEdit() {
    if (_gameState != GameState.waiting) return;
    setState(() {
      _mapVisibleInLobby = false;
      _prepControlSheetOpen = false;
      _statusMessage = '準備画面に戻りました';
    });
  }

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
    await _mapVisual.reloadForProfile(profile);
    await _refreshPlayerAvatarIcon();
    if (!mounted) return;
    setState(() {
      _activeProfile = profile;
      _mapLayerToggles = _mapVisual.pack.layerDefaults;
    });
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

  bool _shouldUsePhotoPlayerPin() {
    final p = _mapVisual.pack;
    if (_avatarImagePath == null || _avatarImagePath!.isEmpty) return false;
    if (p.showPhotoPinByDefault && !p.photoOnlyOnReveal) return true;
    return _isPlayerRevealedForPhoto();
  }

  Future<void> _refreshPlayerAvatarIcon() async {
    await _mapVisual.refreshPlayerAvatar(
      localPath: _avatarImagePath,
      usePhoto: _shouldUsePhotoPlayerPin(),
      revealedStyle: _isPlayerRevealedForPhoto(),
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

  bool get _isHunterNow =>
      _localRole == PlayerRole.hunter ||
      (_rt.werewolfTransformEndsAt != null &&
          DateTime.now().isBefore(_rt.werewolfTransformEndsAt!));

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

    setState(() {
      _currentPosition = next;
      if (!_editingArea) {
        _statusMessage = '追跡中（GPS更新あり）';
      }
      _lastAcceptedPositionAt = now;
      _updateGpsAccuracy(position.accuracy);
    });

    _runnerSmooth ??= RunnerDisplaySmoothing(initial: next);
    _runnerSmooth!.setTarget(next);
    if (animateCamera) {
      _runnerSmooth!.snapDisplayToTarget();
      _mapController?.animateCamera(CameraUpdate.newLatLng(next));
    }

    _evaluateGame();

    if (_gameState == GameState.running) {
      _matchRecorder?.tryAppendRunner(next);
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

  Future<void> _startGame() async {
    if (_gameState != GameState.waiting) {
      if (_gameState == GameState.running) return;
      _toast('新しい試合を始めるには「リセット」で結果を閉じてからにしてください');
      return;
    }
    if (_editingArea) {
      _toast('エリア編集中は開始できません');
      return;
    }
    if (_isOnlineFirestore && !_isHost) {
      _toast('試合の開始はホストのみできます');
      return;
    }

    _matchRecorder?.discard();
    _matchRecorder = null;
    if (_trajectoryConsent) {
      _matchRecorder = MatchRecorder(
        playAreaSnapshot: _playArea,
        consentedToTrajectory: true,
        initialRunner: _currentPosition,
        initialOni: _oniPosition,
      );
    }

    if (_isOnlineFirestore && _isHost) {
      final snapshot = _buildSharedMatchSnapshot();
      final err = await _firestoreSession!.publishMatchStart(snapshot);
      if (err != null) {
        _toast(err);
        return;
      }
      _applySharedMatchStart(snapshot);
    } else {
      _assignDefaultSetupIfNeeded();
      final gimmicks = GeneratedGimmicks.create(
        _playArea,
        density: _gimmickDensity,
      );
      _rt.applyStartGimmicks(
        gimmicks: gimmicks,
        matchDurationSeconds: _matchDurationSeconds,
      );
    }

    _retuneGpsIfNeeded();
    _startGameCore();
  }

  void _startGameCore() {
    _processedRoomEventDocIds.clear();
    setState(() {
      _gameState = GameState.running;
      _afterCatchRule = null;
      _statusMessage = 'ゲーム開始。鬼から逃げてください。';
      _controlSheetMode = ControlSheetMode.skillsOnly;
      _hudExpanded = false;
      _oniIntelLineHidden = false;
      _rt.showOniIntelCard = true;
      _abortVoteYesUids.clear();
    });
    _retuneRenderPump();
    _emitMatchEvent(
      type: 'gimmicks_generated',
      message:
          'ギミック生成: 安全地帯${_rt.safeZonePositions.length} / 情報屋${_rt.infoBrokerPositions.length} / 監視カメラ${_rt.cameraPositions.length} / イベントエリア${_rt.commJammingZonePositions.length}',
      position: _playAreaAnchor,
    );
    _showRoleSkillDialog();
    _logDebug('match_start scale=${_timeScale}x online=$_isOnlineFirestore');
    HapticFeedback.selectionClick();
    SystemSound.play(SystemSoundType.click);

    _matchTimer?.cancel();
    _matchTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted || _gameState != GameState.running) return;
      _matchRecorder?.tryAppendOni(_oniPosition);
      setState(() {
        _rt.remainingSeconds -= _timeScale;
        _rt.elapsedSeconds += _timeScale;
        _estimatedBatteryScore += _batteryCostPerSecond() * _timeScale;
      });
      _evaluateGame();
      _retuneGpsIfNeeded();
    });
  }

  SharedMatchSnapshot _buildSharedMatchSnapshot() {
    final fs = _firestoreSession!;
    final seed = DateTime.now().millisecondsSinceEpoch;
    final rnd = math.Random(seed);
    final oniIntel = _customRuleMode
        ? _oniIntelMode
        : OniIntelMode.values[rnd.nextInt(OniIntelMode.values.length)];
    final aftermath = _customRuleMode
        ? _eliminationAftermathRule
        : EliminationAftermathRule.values[rnd.nextInt(
            EliminationAftermathRule.values.length,
          )];
    final assignments = <String, SharedPlayerAssignment>{};
    final members = fs.currentLobbyMembers;
    if (members.isEmpty && fs.myUid != null) {
      assignments[fs.myUid!] = _assignmentForUid(
        fs.myUid!,
        null,
        rnd,
        isSelf: true,
      );
    } else {
      for (final m in members) {
        assignments[m.uid] = _assignmentForUid(
          m.uid,
          m,
          rnd,
          isSelf: m.uid == fs.myUid,
        );
      }
    }
    return SharedMatchSnapshot(
      gimmickSeed: seed,
      playArea: _playArea,
      matchDurationSeconds: _matchDurationSeconds,
      oniIntelMode: oniIntel,
      eliminationAftermathRule: aftermath,
      assignments: assignments,
      startedAtUtc: DateTime.now().toUtc().toIso8601String(),
      gimmickDensity: _gimmickDensity,
    );
  }

  SharedPlayerAssignment _assignmentForUid(
    String uid,
    RoomMemberView? member,
    math.Random rnd, {
    required bool isSelf,
  }) {
    if (_customRuleMode) {
      if (isSelf) {
        return SharedPlayerAssignment(
          role: _localRole,
          skills: _skillLoadout.toList(),
        );
      }
      final fromPref = member?.preferredAssignment;
      if (fromPref != null) return fromPref;
    }
    final role =
        assignablePlayerRoles[rnd.nextInt(assignablePlayerRoles.length)];
    return SharedPlayerAssignment(
      role: role,
      skills: _randomSkillsFor(role, rnd).toList(),
    );
  }

  void _applySharedMatchStart(SharedMatchSnapshot snapshot) {
    _playArea = snapshot.playArea;
    _matchDurationSeconds = snapshot.matchDurationSeconds;
    _oniIntelMode = snapshot.oniIntelMode;
    _eliminationAftermathRule = snapshot.eliminationAftermathRule;
    final mine = snapshot.assignmentFor(_firestoreSession?.myUid);
    if (mine != null) {
      _localRole = mine.role;
      _skillLoadout = mine.skills.toSet();
    }
    final gimmicks = GeneratedGimmicks.create(
      _playArea,
      seed: snapshot.gimmickSeed,
      density: snapshot.gimmickDensity,
    );
    _rt.applyStartGimmicks(
      gimmicks: gimmicks,
      matchDurationSeconds: snapshot.matchDurationSeconds,
    );
  }

  void _resetGame({bool skipFirestoreSync = false}) {
    _matchTimer?.cancel();
    _cancelCaptureBoundTimers();
    _processedRoomEventDocIds.clear();
    _matchRecorder?.discard();
    _matchRecorder = null;
    _finalizeRecordingFuture = null;
    _retuneGpsIfNeeded();
    _rt.resetToLobby(matchDurationSeconds: _matchDurationSeconds);
    setState(() {
      _gameState = GameState.waiting;
      _mapVisibleInLobby = false;
      _afterCatchRule = null;
      _statusMessage = 'リセットしました。開始ボタンでゲーム開始。';
      _prepControlSheetOpen = false;
      _abortVoteYesUids.clear();
    });
    _retuneRenderPump();
    if (!skipFirestoreSync && _isOnlineFirestore && _isHost) {
      unawaited(_firestoreSession!.updateRoomPhase(RoomPhase.lobby));
    }
    _logDebug('match_reset');
  }

  void _showRoleSkillDialog() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _gameState != GameState.running) return;
      showDialog<void>(
        context: context,
        builder: (ctx) {
          final scheme = Theme.of(ctx).colorScheme;
          final bodyStyle = TextStyle(color: scheme.onSurface, height: 1.4);
          return AlertDialog(
            title: Text(
              'あなたの役職 / スキル',
              style: TextStyle(color: scheme.onSurface),
            ),
            content: Text(
              '役職: ${_localRole.displayName}\n'
              'スキル: ${_skillLoadout.map(skillLabel).join(" / ")}',
              style: bodyStyle,
            ),
            actions: [
              FilledButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('OK'),
              ),
            ],
          );
        },
      );
    });
  }

  void _assignDefaultSetupIfNeeded() {
    if (_isOnlineFirestore) return;
    if (_customRuleMode) return;
    final seed = DateTime.now().millisecondsSinceEpoch;
    final rnd = math.Random(seed);
    const roles = assignablePlayerRoles;
    _localRole = roles[rnd.nextInt(roles.length)];
    _skillLoadout = _randomSkillsFor(_localRole, rnd);
    _oniIntelMode =
        OniIntelMode.values[rnd.nextInt(OniIntelMode.values.length)];
    _eliminationAftermathRule = EliminationAftermathRule
        .values[rnd.nextInt(EliminationAftermathRule.values.length)];
  }

  Set<String> _randomSkillsFor(PlayerRole role, math.Random rnd) {
    final list = skillCandidatesForRole(role).toList()..shuffle(rnd);
    return list.take(role == PlayerRole.hunter ? 2 : 1).toSet();
  }

  LatLng get _playAreaAnchor {
    switch (_playArea.type) {
      case PlayAreaType.circle:
        return _playArea.center;
      case PlayAreaType.polygon:
        return _playArea.points.isEmpty
            ? _currentPosition
            : _playArea.points.first;
    }
  }

  Future<void> _requestAbortByVote() async {
    if (_gameState != GameState.running) {
      _toast('ゲーム中のみ中止提案できます');
      return;
    }
    final sk = _matchEventSessionKey;
    if (_isOnlineFirestore && sk != null) {
      final fs = _firestoreSession;
      if (fs == null) {
        _toast('ルームに接続していません');
        return;
      }
      final n = math.max(1, fs.currentLobbyMembers.length);
      final need = (n ~/ 2) + 1;
      final choice = await showDialog<String>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('試合中止の投票'),
          content: Text(
            '賛成が接続中 $n 人の過半数（$need 票以上）に達すると、ホストが試合を終了します。\n'
            '現在の賛成: ${_abortVoteYesUids.length} 票',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, 'cancel'),
              child: const Text('閉じる'),
            ),
            OutlinedButton(
              onPressed: () => Navigator.pop(ctx, 'no'),
              child: const Text('反対'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, 'yes'),
              child: const Text('賛成'),
            ),
          ],
        ),
      );
      if (!mounted || choice == null || choice == 'cancel') return;
      final agree = choice == 'yes';
      final err = await fs.publishRoomEvent(
        type: RoomMatchEventTypes.abortVote,
        payload: {'agree': agree},
        sessionKey: sk,
      );
      if (err != null && mounted) {
        _toast(err);
        return;
      }
      if (mounted) {
        _toast(agree ? '賛成を送信しました' : '反対を送信しました');
      }
      return;
    }

    final approved = await _showAbortVoteDialog();
    if (!mounted || approved == null) return;
    if (approved) {
      _toast('過半数同意で中止しました');
      _logDebug('abort_vote:approved');
      _resetGame();
    } else {
      _toast('中止提案は否決されました');
      _logDebug('abort_vote:rejected');
    }
  }

  void _handleAbortVoteEvent(RoomMatchEvent ev) {
    final agree = ev.payload['agree'] == true;
    if (!mounted) return;
    setState(() {
      if (agree) {
        _abortVoteYesUids.add(ev.actorUid);
      } else {
        _abortVoteYesUids.remove(ev.actorUid);
      }
    });
    if (_isHost) {
      _maybeFinalizeAbortVoteByMajority();
    }
  }

  void _maybeFinalizeAbortVoteByMajority() {
    if (!_isHost || !_isOnlineFirestore || _gameState != GameState.running) {
      return;
    }
    final fs = _firestoreSession;
    if (fs == null) return;
    final n = math.max(1, fs.currentLobbyMembers.length);
    final need = (n ~/ 2) + 1;
    if (_abortVoteYesUids.length >= need) {
      _abortVoteYesUids.clear();
      _endGame(
        GameState.runnerWin,
        '参加者の過半数が賛成し、試合を中止しました',
        endReason: MatchEndReason.hostAbort,
      );
    }
  }

  Future<bool?> _showAbortVoteDialog() async {
    final requiredYes = (_mockPlayerCount ~/ 2) + 1;
    int yesVotes = requiredYes;
    return showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => AlertDialog(
          title: const Text('試合中止の投票'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('参加者: $_mockPlayerCount人 / 必要同意: $requiredYes票'),
              const SizedBox(height: 8),
              Text('同意票(テスト): $yesVotes'),
              Slider(
                min: 0,
                max: _mockPlayerCount.toDouble(),
                divisions: _mockPlayerCount,
                value: yesVotes.toDouble(),
                onChanged: (v) {
                  setModalState(() => yesVotes = v.round());
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, null),
              child: const Text('キャンセル'),
            ),
            OutlinedButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('否決'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, yesVotes >= requiredYes),
              child: const Text('投票確定'),
            ),
          ],
        ),
      ),
    );
  }

  void _endGame(
    GameState result,
    String message, {
    String? endReason,
    bool skipFirestoreSync = false,
  }) {
    _matchTimer?.cancel();
    _cancelCaptureBoundTimers();
    final outcome = result;
    if (result == GameState.caughtByOni) {
      _tracePoints.add(_currentPosition);
      _afterCatchRule = _eliminationAftermathRule;
      _emitMatchEvent(
        type: 'trace_drop',
        message: '痕跡が残った',
        position: _currentPosition,
      );
      _emitMatchEvent(
        type: 'after_catch_rule',
        message: '脱落後ルール: ${_eliminationAftermathRule.label}',
        position: _currentPosition,
      );
    } else {
      _afterCatchRule = null;
    }
    setState(() {
      _gameState = result;
      _statusMessage = message;
      _prepControlSheetOpen = false;
    });
    HapticFeedback.mediumImpact();
    SystemSound.play(SystemSoundType.alert);
    _logDebug('match_end outcome=${result.name}');
    _retuneGpsIfNeeded();
    _finalizeRecordingFuture = Future<void>.microtask(
      () => _finalizeMatchRecording(outcome),
    );
    if (!skipFirestoreSync && _isOnlineFirestore && _isHost) {
      unawaited(
        _firestoreSession!.publishMatchEnd(
          outcome: result,
          endReason: endReason ?? _inferEndReason(result, message),
          message: message,
        ),
      );
    }
    unawaited(_openMatchResultScreen());
  }

  String _inferEndReason(GameState result, String message) {
    if (message.contains('ホストが試合を終了')) {
      return MatchEndReason.hostEnded;
    }
    return switch (result) {
      GameState.runnerWin => MatchEndReason.timeUp,
      GameState.caughtByOni => MatchEndReason.caught,
      _ => MatchEndReason.hostEnded,
    };
  }

  void _evaluateGame() {
    if (_gameState != GameState.running) return;

    final distance = _distanceToOni();
    _proximityService.ingestGpsDistanceMeters(distance);
    _evaluateSafeZone();
    _evaluateInfoBroker(distance);

    final effects = _matchCtrl.evaluateRunningTick(
      playArea: _playArea,
      playerPosition: _currentPosition,
      oniPosition: _oniPosition,
      testMode: _testMode,
      oniKnown: _remoteOniKnown,
      isHunterNow: _isHunterNow,
      proximityBand: _latestProximityBand,
      now: DateTime.now(),
    );
    _applyMatchTickEffects(effects);
    _updateDangerPulse();
  }

  void _applyMatchTickEffects(List<MatchTickEffect> effects) {
    for (final effect in effects) {
      switch (effect) {
        case MatchEndEffect(:final state, :final message, :final heavyHaptic):
          if (heavyHaptic) {
            HapticFeedback.heavyImpact();
          } else {
            HapticFeedback.mediumImpact();
          }
          _endGame(state, message);
          return;
        case MatchStatusMessageEffect(:final message):
          setState(() => _statusMessage = message);
        case MatchConsumeSafeChargeEffect():
          break;
        case MatchAreaRevealEffect(:final overflowMeters):
          _triggerLocationReveal(overflowMeters);
        case MatchResetOutsideTrackingEffect():
          break;
        case MatchOniCueEffect(:final level):
          _emitOniCue(level: level);
          if (level == 'warning') {
            _logDebug('danger_warning_enter');
          } else if (level == 'danger') {
            _logDebug('danger_close_enter');
          }
        case MatchEmitEventEffect(:final type, :final message, :final position):
          _emitMatchEvent(type: type, message: message, position: position);
        case MatchLocationRevealEmitEffect(
          :final type,
          :final message,
          :final position,
        ):
          _emitLocationReveal(
            type: type,
            message: message,
            overridePosition: position,
            reasonSummary: _shortRevealReason(type, message),
          );
        case MatchInfectionPulseRevealEffect():
          _appendInfectionPulseReveal();
        case MatchTouchLockStartEffect():
          HapticFeedback.mediumImpact();
        case MatchCameraSpottedEffect(:final message):
          if (!mounted) return;
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(message)));
      }
    }
  }

  void _appendInfectionPulseReveal() {
    final now = DateTime.now();
    final ev = LocationRevealEvent(
      sequence: _rt.revealCount + 1,
      timestamp: now,
      position: _positionForReveal,
      overflowMeters: 0,
      playerLabel: _localPlayerLabel,
      reasonSummary: '感染',
    );
    _rt.revealCount += 1;
    _rt.revealLog.insert(0, ev);
    if (_rt.revealLog.length > 50) _rt.revealLog.removeLast();
    _emitMatchEvent(
      type: 'infection_reveal',
      message: '感染露出パルス',
      position: _positionForReveal,
      syncFirestore: false,
    );
    unawaited(
      _publishFirestoreReveal(
        revealKind: 'infection_reveal',
        message: '感染露出パルス',
        position: _positionForReveal,
        playerLabel: _localPlayerLabel,
        overflowMeters: 0,
        reasonSummary: '感染',
      ),
    );
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('感染反応: 位置が断続的に露出しています')));
  }

  void _updateDangerPulse() {
    final shouldPulse = _rt.dangerPulseActive;
    if (shouldPulse) {
      if (!_dangerPulseController.isAnimating) {
        _dangerPulseController.repeat(reverse: true);
      }
    } else {
      if (_dangerPulseController.isAnimating) {
        _dangerPulseController.stop();
        _dangerPulseController.value = 0;
      }
    }
  }

  void _triggerLocationReveal(double overflowMeters) {
    _rt.revealedInCurrentOutside = true;
    _rt.revealCount += 1;
    final playerLabel = _localPlayerLabel;
    final shown = _displayRevealPosition(_positionForReveal);
    final jammed = _isPointInCommJammingZone(_currentPosition);
    final ev = LocationRevealEvent(
      sequence: _rt.revealCount,
      timestamp: DateTime.now(),
      position: shown,
      overflowMeters: overflowMeters,
      playerLabel: playerLabel,
      reasonSummary: 'エリア外が続いたため露見',
    );
    final alert =
        '$playerLabel の位置が暴露されました'
        '${jammed ? '（通信障害で誤差大）' : ''}';
    setState(() {
      _rt.revealLog.insert(0, ev);
      if (_rt.revealLog.length > 50) {
        _rt.revealLog.removeLast();
      }
      _statusMessage = '$alert: ${MapGeoFormat.latLng(shown)}';
    });
    _pushHudRevealAlert(alert);
    HapticFeedback.heavyImpact();
    _emitMatchEvent(
      type: 'area_reveal',
      message: 'プレイエリアの外に留まり続けたため位置が露見',
      position: _positionForReveal,
      syncFirestore: false,
    );
    unawaited(
      _publishFirestoreReveal(
        revealKind: 'area_reveal',
        message: 'プレイエリアの外に留まり続けたため位置が露見',
        position: shown,
        playerLabel: playerLabel,
        overflowMeters: overflowMeters,
        reasonSummary: 'エリア外が続いたため露見',
      ),
    );
    _retuneGpsIfNeeded();
  }

  void _emitLocationReveal({
    required String type,
    required String message,
    LatLng? overridePosition,
    String? reasonSummary,
  }) {
    _rt.revealCount += 1;
    final playerLabel = _localPlayerLabel;
    final raw = overridePosition ?? _positionForReveal;
    final shown = _displayRevealPosition(raw);
    final summary = reasonSummary ?? _shortRevealReason(type, message);
    final ev = LocationRevealEvent(
      sequence: _rt.revealCount,
      timestamp: DateTime.now(),
      position: shown,
      overflowMeters: 0,
      playerLabel: playerLabel,
      reasonSummary: summary,
    );
    setState(() {
      _rt.revealLog.insert(0, ev);
      if (_rt.revealLog.length > 50) _rt.revealLog.removeLast();
      _statusMessage = message;
    });
    _pushHudRevealAlert('$playerLabel の位置情報を受信');
    _emitMatchEvent(
      type: type,
      message: message,
      position: shown,
      syncFirestore: false,
    );
    unawaited(
      _publishFirestoreReveal(
        revealKind: type,
        message: message,
        position: shown,
        playerLabel: playerLabel,
        overflowMeters: 0,
        reasonSummary: summary,
      ),
    );
  }

  void _evaluateSafeZone() {
    if (_rt.safeZoneCharges >= GameConfig.safeZoneMaxCharges) return;
    final now = DateTime.now();
    final hitIndex = GimmickPickupEvaluator.pickupIndexIfAllowed(
      available: _rt.safeZoneAvailable,
      positions: _rt.safeZonePositions,
      radiusMeters: GameConfig.safeZoneRadiusMeters,
      playerPosition: _currentPosition,
      lastPickupAt: _rt.lastSafeChargeAt,
      cooldownSeconds: GameConfig.safeZoneChargeCooldownSeconds,
      now: now,
    );
    if (hitIndex == null) return;
    final hit = _rt.safeZonePositions[hitIndex];
    final nextSafeZone = GimmickRelocator.relocate(
      area: _playArea,
      avoid: [
        ..._rt.safeZonePositions,
        ..._rt.infoBrokerPositions,
        ..._rt.cameraPositions,
        ..._rt.commJammingZonePositions,
      ],
      angleSeed: 35 + _rt.elapsedSeconds * 7 + hitIndex * 53,
      radiusFactor: 0.44,
    );
    setState(() {
      _rt.lastSafeChargeAt = now;
      _rt.safeZoneCharges += 1;
      _refreshSkillCooldownsFromSafeZone();
      _rt.safeZonePositions[hitIndex] = nextSafeZone;
      _rt.safeZoneAvailable = false;
      _rt.safeZoneRespawnAt = now.add(
        const Duration(seconds: GameConfig.safeZoneRespawnSeconds),
      );
      _statusMessage = '安全地帯: ステルス獲得 + スキル再使用可能（移動中）';
    });
    _emitMatchEvent(
      type: 'safe_charge',
      message: '安全地帯でチャージ獲得・スキル再使用可能・安全地帯移動',
      position: hit,
    );
  }

  void _evaluateInfoBroker(double distanceToOni) {
    final now = DateTime.now();
    final hitIndex = GimmickPickupEvaluator.pickupIndexIfAllowed(
      available: _rt.infoBrokerAvailable,
      positions: _rt.infoBrokerPositions,
      radiusMeters: GameConfig.infoBrokerRadiusMeters,
      playerPosition: _currentPosition,
      lastPickupAt: _rt.lastInfoBrokerAt,
      cooldownSeconds: GameConfig.infoBrokerCooldownSeconds,
      now: now,
    );
    if (hitIndex == null) return;
    final hit = _rt.infoBrokerPositions[hitIndex];
    final bearing = Geolocator.bearingBetween(
      _currentPosition.latitude,
      _currentPosition.longitude,
      _oniPosition.latitude,
      _oniPosition.longitude,
    );
    final direction = MapGeoUtils.bearingToDirection(bearing);
    final distBand = distanceToOni <= GameConfig.dangerDistanceMeters
        ? '至近'
        : distanceToOni <= GameConfig.warningDistanceMeters
        ? '中距離'
        : '遠距離';
    final intel = OniIntelTextBuilder.build(
      mode: _oniIntelMode,
      elapsedSeconds: _rt.elapsedSeconds,
      oniInCommJammingZone: _oniInCommJammingZone,
      playerPosition: _currentPosition,
      commJammingZoneCenters: _rt.commJammingZonePositions,
      direction: direction,
      distanceBand: distBand,
      bearingDegrees: bearing,
    );
    final nextInfoBroker = GimmickRelocator.relocate(
      area: _playArea,
      avoid: [
        ..._rt.safeZonePositions,
        ..._rt.infoBrokerPositions,
        ..._rt.cameraPositions,
        ..._rt.commJammingZonePositions,
      ],
      angleSeed: 150 + _rt.elapsedSeconds * 11 + hitIndex * 71,
      radiusFactor: 0.58,
    );
    setState(() {
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
        OniIntelTrace(timestamp: now, position: _oniPosition, text: intel),
      );
      if (_rt.oniIntelTraces.length > 20) {
        _rt.oniIntelTraces.removeLast();
      }
      _rt.infoBrokerPositions[hitIndex] = nextInfoBroker;
      _statusMessage = '情報屋: $intel';
    });
    _emitMatchEvent(
      type: 'info_broker',
      message: '情報屋を利用: $intel',
      position: hit,
      syncFirestore: false,
    );
    unawaited(
      _publishFirestoreInfoBroker(
        intel: intel,
        hitIndex: hitIndex,
        pickupLat: hit.latitude,
        pickupLng: hit.longitude,
        nextLat: nextInfoBroker.latitude,
        nextLng: nextInfoBroker.longitude,
        oniLat: _oniPosition.latitude,
        oniLng: _oniPosition.longitude,
      ),
    );
  }

  void _refreshSkillCooldownsFromSafeZone() {
    if (_skillLoadout.contains(SkillIds.fakePosition)) {
      _rt.lastFakeSkillAt = null;
    }
    if (_skillLoadout.contains(SkillIds.werewolfTransform)) {
      _rt.lastWerewolfTransformAt = null;
    }
    if (_skillLoadout.contains(SkillIds.captureZone)) {
      _rt.lastCaptureZoneAt = null;
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
      _testMode || _gameState == GameState.running;

  bool get _showOniMarker => _testMode || _remoteOniKnown;

  void _activateFakeSkill() {
    if (_gameState != GameState.running) {
      _toast('ゲーム中のみ使えます');
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
      _toast('偽位置スキル再使用まで $remain 秒');
      return;
    }
    _rt.lastFakeSkillAt = now;
    _rt.fakePositionActive = true;
    _rt.fakePositionEndsAt = now.add(
      const Duration(seconds: GameConfig.fakeSkillDurationSeconds),
    );
    _rt.fakePositionLatLng = LatLng(
      _currentPosition.latitude + 0.0012,
      _currentPosition.longitude - 0.0011,
    );
    _emitMatchEvent(
      type: 'fake_start',
      message: '偽位置スキル発動',
      position: _rt.fakePositionLatLng!,
    );
    setState(() {
      _statusMessage = '偽位置スキル発動（短時間）';
    });
  }

  void _activateWerewolfHunter() {
    if (_gameState != GameState.running || _localRole != PlayerRole.werewolf) {
      return;
    }
    final now = DateTime.now();
    if (_rt.lastWerewolfTransformAt != null &&
        now.difference(_rt.lastWerewolfTransformAt!).inSeconds <
            GameConfig.werewolfTransformCooldownSeconds) {
      return;
    }
    _rt.lastWerewolfTransformAt = now;
    _rt.werewolfTransformEndsAt = now.add(
      const Duration(seconds: GameConfig.werewolfTransformDurationSeconds),
    );
    _emitMatchEvent(
      type: 'werewolf_transform_start',
      message: '人狼が一時的に鬼化',
      position: _currentPosition,
    );
    setState(() => _statusMessage = '一時鬼化中');
  }

  Future<void> _activateFakeIntelReveal() async {
    if (_gameState != GameState.running) {
      _toast('ゲーム中のみ使えます');
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
    final self = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        final scheme = Theme.of(ctx).colorScheme;
        return AlertDialog(
          title: Text('偽情報暴露', style: TextStyle(color: scheme.onSurface)),
          content: Text(
            '地図に偽の位置露出を追加します。鬼側の混乱用です。',
            style: TextStyle(color: scheme.onSurfaceVariant),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('自分を暴露'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('他人を暴露'),
            ),
          ],
        );
      },
    );
    if (self == null) return;
    final raw = self
        ? LatLng(
            _currentPosition.latitude + 0.0007,
            _currentPosition.longitude - 0.0005,
          )
        : _randomOtherRevealPoint();
    final p = _displayRevealPosition(raw);
    final label = self ? _localPlayerLabel : '不明なプレイヤー';
    final narrative = _pickFakeIntelRevealNarrative(p);
    _rt.lastFakeIntelRevealAt = now;
    _rt.revealCount += 1;
    final ev = LocationRevealEvent(
      sequence: _rt.revealCount,
      timestamp: DateTime.now(),
      position: p,
      overflowMeters: 0,
      playerLabel: label,
      reasonSummary: '偽情報',
    );
    setState(() {
      _rt.revealLog.insert(0, ev);
      if (_rt.revealLog.length > 50) _rt.revealLog.removeLast();
      _statusMessage = '偽情報暴露: $narrative';
    });
    _pushHudRevealAlert('偽情報: $narrative（$label）');
    _emitMatchEvent(
      type: 'accidental_reveal',
      message: narrative,
      position: p,
      syncFirestore: false,
    );
    unawaited(
      _publishFirestoreFakeIntelReveal(
        message: narrative,
        position: p,
        playerLabel: label,
        pickedSelf: self,
      ),
    );
    HapticFeedback.mediumImpact();
  }

  LatLng _randomOtherRevealPoint() {
    final candidates = _remoteMembers.values
        .map((m) => LatLng(m.lat, m.lng))
        .toList();
    if (candidates.isNotEmpty) {
      return candidates[math.Random().nextInt(candidates.length)];
    }
    return LatLng(
      _currentPosition.latitude - 0.0008,
      _currentPosition.longitude + 0.0006,
    );
  }

  void _activateCaptureZone() {
    if (_gameState != GameState.running) return;
    if (!_skillLoadout.contains(SkillIds.captureZone)) return;
    final now = DateTime.now();
    if (_rt.lastCaptureZoneAt != null &&
        now.difference(_rt.lastCaptureZoneAt!).inSeconds <
            GameConfig.captureZoneCooldownSeconds) {
      return;
    }
    _rt.lastCaptureZoneAt = now;
    setState(() {
      _rt.waitingCaptureZoneTap = true;
      _statusMessage = '地図タップ地点に捕獲結界を設置';
    });
  }

  void _activateBodyThrow() {
    if (_gameState != GameState.running) return;
    if (!_skillLoadout.contains(SkillIds.bodyThrow)) return;
    if (_rt.bodyThrowAwaitingMapTap) return;
    if (_rt.bodyThrowPosition != null || _rt.bodyThrowEndsAt != null) {
      return;
    }
    final now = DateTime.now();
    if (_rt.lastBodyThrowAt != null &&
        now.difference(_rt.lastBodyThrowAt!).inSeconds <
            GameConfig.bodyThrowCooldownSeconds) {
      return;
    }
    setState(() {
      _rt.bodyThrowAwaitingMapTap = true;
      _rt.bodyThrowTapDeadline = now.add(
        const Duration(seconds: GameConfig.bodyThrowMapTapWindowSeconds),
      );
      _rt.bodyThrowSkillOriginLatLng = LatLng(
        _currentPosition.latitude,
        _currentPosition.longitude,
      );
      _statusMessage =
          '地図をタップして人形を置く（現在地から ${GameConfig.bodyThrowDistanceMeters.toStringAsFixed(0)} m 以内）';
    });
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
    required List<String> targetUids,
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
        final err = await fs.publishHostRoomEvent(
          type: RoomMatchEventTypes.captureZoneBound,
          payload: {
            'placeId': placeId,
            'targetUids': targetUids,
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
    Set<String> rawTargets,
  ) async {
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
    final raw = ev.payload['targetUids'];
    if (raw is! List) return;
    final targets = raw.map((e) => e.toString()).toList();
    final myUid = fs.myUid;
    if (myUid == null || !targets.contains(myUid)) return;
    final err = await fs.publishRoomEvent(
      type: RoomMatchEventTypes.captureZoneAck,
      payload: {'placeId': placeId},
      sessionKey: sk,
    );
    if (err != null && mounted) _toast(err);
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
    required double oniLat,
    required double oniLng,
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
        'oniLat': oniLat,
        'oniLng': oniLng,
      },
      sessionKey: sk,
    );
    if (err != null && mounted) _toast(err);
  }

  Future<void> _publishFirestoreMatchEventInner({
    required String innerType,
    required String message,
    required LatLng position,
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
      type: RoomMatchEventTypes.matchEvent,
      payload: {
        'innerType': innerType,
        'message': msg,
        'lat': position.latitude,
        'lng': position.longitude,
      },
      sessionKey: sk,
    );
    if (err != null && mounted) _toast(err);
  }

  void _onRemoteRoomMatchEvent(RoomMatchEvent ev) {
    if (!mounted) return;
    if (_processedRoomEventDocIds.contains(ev.id)) return;
    _processedRoomEventDocIds.add(ev.id);
    final sk = _matchEventSessionKey;
    if (sk == null || ev.sessionKey != sk) return;
    if (_gameState != GameState.running) return;
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
      case RoomMatchEventTypes.fakeIntelReveal:
        if (ev.actorUid == fs.myUid) return;
        _applyRemoteFakeIntelReveal(ev);
        return;
      case RoomMatchEventTypes.infoBroker:
        if (ev.actorUid == fs.myUid) return;
        _applyRemoteInfoBroker(ev);
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
        unawaited(_publishCaptureZoneAckIfNeeded(ev, fs, placeId));
        if (_isHost && !_captureBoundTimers.containsKey(placeId)) {
          final cLat = ev.payload['centerLat'];
          final cLng = ev.payload['centerLng'];
          final raw = ev.payload['targetUids'];
          if (cLat is num && cLng is num && raw is List) {
            _scheduleHostCaptureBoundOnce(
              placeId: placeId,
              center: LatLng(cLat.toDouble(), cLng.toDouble()),
              targetUids: raw.map((e) => e.toString()).toList(growable: false),
            );
          }
        }
        return;
      case RoomMatchEventTypes.captureZoneBound:
        _applyRemoteCaptureZoneBound(ev, fs);
        return;
      case RoomMatchEventTypes.captureZoneAck:
        return;
      case RoomMatchEventTypes.abortVote:
        _handleAbortVoteEvent(ev);
        return;
      default:
        return;
    }
  }

  void _applyRemoteReveal(RoomMatchEvent ev) {
    final pos = RoomMatchEvent.latLngFromPayload(ev.payload);
    if (pos == null) return;
    final label = ev.payload['playerLabel'] as String? ?? 'player1';
    final overflow = (ev.payload['overflowMeters'] as num?)?.toDouble() ?? 0;
    final reasonSummary =
        ev.payload['reasonSummary'] as String? ??
        _shortRevealReason(
          ev.payload['revealKind'] as String? ?? 'reveal',
          ev.payload['message'] as String? ?? '',
        );
    if (!mounted) return;
    setState(() {
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
        ),
      );
      if (_rt.revealLog.length > 50) _rt.revealLog.removeLast();
      _statusMessage = ev.payload['message'] as String? ?? '位置情報を受信';
    });
    final rk = ev.payload['revealKind'] as String? ?? 'reveal';
    final reason =
        ev.payload['reasonSummary'] as String? ??
        _shortRevealReason(rk, ev.payload['message'] as String? ?? '');
    _pushHudRevealAlert('$label の位置情報を受信（$reason）');
    HapticFeedback.mediumImpact();
  }

  void _applyRemoteFakeIntelReveal(RoomMatchEvent ev) {
    final pos = RoomMatchEvent.latLngFromPayload(ev.payload);
    if (pos == null) return;
    final label = ev.payload['playerLabel'] as String? ?? '不明なプレイヤー';
    if (!mounted) return;
    setState(() {
      _rt.revealCount += 1;
      _rt.revealLog.insert(
        0,
        LocationRevealEvent(
          sequence: _rt.revealCount,
          timestamp: DateTime.now(),
          position: pos,
          overflowMeters: 0,
          playerLabel: label,
          reasonSummary: '偽情報',
        ),
      );
      if (_rt.revealLog.length > 50) _rt.revealLog.removeLast();
      _statusMessage = ev.payload['message'] as String? ?? '偽情報暴露';
    });
    _pushHudRevealAlert('偽情報暴露: $label の位置情報を受信');
    HapticFeedback.mediumImpact();
  }

  void _applyRemoteInfoBroker(RoomMatchEvent ev) {
    final intel = ev.payload['intel'] as String?;
    final hitIndex = (ev.payload['hitIndex'] as num?)?.toInt();
    final nextLat = (ev.payload['nextLat'] as num?)?.toDouble();
    final nextLng = (ev.payload['nextLng'] as num?)?.toDouble();
    final oniLat = (ev.payload['oniLat'] as num?)?.toDouble();
    final oniLng = (ev.payload['oniLng'] as num?)?.toDouble();
    if (intel == null ||
        hitIndex == null ||
        nextLat == null ||
        nextLng == null) {
      return;
    }
    final tracePos = oniLat != null && oniLng != null
        ? LatLng(oniLat, oniLng)
        : _oniPosition;
    if (hitIndex < 0 || hitIndex >= _rt.infoBrokerPositions.length) return;
    final now = DateTime.now();
    if (!mounted) return;
    setState(() {
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
  }

  void _applyRemoteMatchEventLog(RoomMatchEvent ev) {
    final inner = ev.payload['innerType'] as String? ?? 'match_event';
    final msg = ev.payload['message'] as String? ?? '';
    final pos =
        RoomMatchEvent.latLngFromPayload(ev.payload) ?? _currentPosition;
    final event = MatchEvent(
      type: inner,
      atUtc: DateTime.now().toUtc(),
      message: msg,
      position: pos,
    );
    if (!mounted) return;
    setState(() {
      _rt.matchEvents.insert(0, event);
      if (_rt.matchEvents.length > 120) {
        _rt.matchEvents.removeLast();
      }
    });
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
    setState(() {
      _rt.waitingCaptureZoneTap = false;
      _rt.captureZoneCenter = center;
      _rt.captureZoneBoundIds = {};
      _rt.captureZoneTargetLeftAt = null;
      _rt.captureZoneEscapeRevealed = false;
      _rt.captureZoneEndsAt = now.add(Duration(seconds: dur));
    });
    HapticFeedback.mediumImpact();
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
    setState(() {
      if (myUid != null && targets.contains(myUid)) {
        _rt.captureZoneBoundIds = const {'self'};
      }
    });
  }

  void _emitMatchEvent({
    required String type,
    required String message,
    required LatLng position,
    bool syncFirestore = true,
    bool queueOffline = true,
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
        ),
      );
    }
  }

  Future<void> _clearTracePoints() async {
    if (_tracePoints.isEmpty &&
        _rt.revealLog.isEmpty &&
        _rt.oniIntelTraces.isEmpty) {
      _toast('痕跡はありません');
      return;
    }
    final ok = await _confirmDialog(
      title: '痕跡をクリア',
      message: '地図上の痕跡・暴露ログ・鬼情報トレースを消しますか？',
      confirmLabel: 'クリア',
    );
    if (!ok) return;
    setState(() {
      _tracePoints.clear();
      _rt.revealLog.clear();
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

  String _conditionLine() {
    if (_rt.captureZoneBoundIds.contains('self') &&
        _rt.captureZoneEndsAt != null) {
      return '捕捉ロック中: 残り ${_secondsUntil(_rt.captureZoneEndsAt)}秒 / BLE接触で捕獲';
    }
    if (_rt.touchLockNoticeShown && _rt.touchLockStartedAt != null) {
      final held = DateTime.now().difference(_rt.touchLockStartedAt!).inSeconds;
      final remain = (GameConfig.touchLockRequiredSeconds - held).clamp(0, 99);
      return '接触圏内: あと $remain秒以内に離脱';
    }
    if (_rt.isInfectedNow) {
      return '感染中 (${_secondsUntil(_rt.infectionEndsAt)}秒)';
    }
    return '異常なし';
  }

  String get _localPlayerLabel {
    final fs = _roomSession is FirestoreRoomSession
        ? _roomSession as FirestoreRoomSession
        : null;
    final name = fs?.nickname?.trim();
    return name == null || name.isEmpty ? 'player1' : name;
  }

  Future<void> _loadOniOperatorPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final s = OniOperatorPrefs.fromPrefs(prefs);
    if (!mounted) return;
    setState(() {
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
      } else {
        HapticFeedback.selectionClick();
        SystemSound.play(SystemSoundType.click);
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
    setState(() {
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

  void _toast(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
    _logDebug('toast:$msg');
  }

  String _playAreaSummary() {
    switch (_playArea.type) {
      case PlayAreaType.circle:
        return '円エリア ・ 半径 ${_playArea.radiusMeters.toStringAsFixed(0)} m';
      case PlayAreaType.polygon:
        return '多角形エリア ・ ${_playArea.points.length} 頂点';
    }
  }

  void _toggleAreaEditor() {
    if (_gameState == GameState.running) {
      _toast('ゲーム中はエリアを編集できません');
      return;
    }
    setState(() {
      final opening = !_editingArea;
      _editingArea = opening;
      if (opening) {
        _mapVisibleInLobby = true;
        _prepControlSheetOpen = true;
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
        _polygonDraft.clear();
        _polygonDraftClosed = false;
        _waitingCircleCenterTap = false;
        _statusMessage = '編集を終了しました';
        _returnToPrepAfterAreaEdit();
      }
    });
    _retuneRenderPump();
  }

  Future<void> _applyEditedArea() async {
    await _saveEditedAreaAsSlot();
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
        _toast('プレイエリア内に置いてください');
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
      );
      return;
    }
    if (_rt.waitingCaptureZoneTap) {
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
        _rt.waitingCaptureZoneTap = false;
        _rt.captureZoneCenter = pos;
        _rt.captureZoneBoundIds = rawTargets;
        _rt.captureZoneTargetLeftAt = null;
        _rt.captureZoneEscapeRevealed = false;
        _rt.captureZoneEndsAt = now.add(
          const Duration(seconds: GameConfig.captureZoneDurationSeconds),
        );
        _statusMessage = '捕獲結界を設置しました';
      });
      _emitMatchEvent(
        type: 'capture_zone_start',
        message: '捕獲結界を設置',
        position: pos,
        syncFirestore: !_isOnlineFirestore,
      );
      if (_isOnlineFirestore) {
        unawaited(_publishCaptureZonePlaced(placeId, pos, rawTargets));
        if (_isHost) {
          _scheduleHostCaptureBoundOnce(
            placeId: placeId,
            center: pos,
            targetUids: _captureTargetUidsForFirestore(rawTargets),
          );
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
      final p = LatLng(e.value.lat, e.value.lng);
      final d = Geolocator.distanceBetween(
        p.latitude,
        p.longitude,
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
      '- 役職: ${_localRole.displayName}${_isHunterNow && _localRole != PlayerRole.hunter ? "（一時鬼化中）" : ""}',
      '- スキル: ${_skillLoadout.map(skillLabel).join(" / ")}',
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

  GameMapOverlaySnapshot _overlaySnapshot(WorldProfileTokens tokens) {
    return GameMapOverlaySnapshot(
      now: DateTime.now(),
      playerMarkerPosition: _playerMarkerPosition,
      oniPosition: _oniPosition,
      showOniMarker: _showOniMarker,
      remoteOniKnown: _remoteOniKnown,
      remoteMembers: _remoteMembers,
      showGimmickMarkers: _showGimmickMapMarkers,
      safeZonePositions: _rt.safeZonePositions,
      infoBrokerPositions: _rt.infoBrokerPositions,
      commJammingZonePositions: _rt.commJammingZonePositions,
      cameraPositions: _rt.cameraPositions,
      tracePoints: _tracePoints,
      revealTraces: _recentRevealTraces().toList(growable: false),
      oniIntelTraces: _recentOniIntelTraces().toList(growable: false),
      safeZoneAvailable: _rt.safeZoneAvailable,
      infoBrokerAvailable: _rt.infoBrokerAvailable,
      safeZoneRespawnAt: _rt.safeZoneRespawnAt,
      infoBrokerRespawnAt: _rt.infoBrokerRespawnAt,
      triggeredCameras: _rt.triggeredCameras,
      fakePositionActive: _rt.fakePositionActive,
      fakePositionLatLng: _rt.fakePositionLatLng,
      bodyThrowPosition: _rt.bodyThrowPosition,
      bodyThrowAwaitingMapTap: _rt.bodyThrowAwaitingMapTap,
      afterCatchRule: _afterCatchRule,
      ghostRoughPositions: _afterCatchRule != null
          ? GameMapOverlayBuilder.ghostRoughPositions(
              currentPosition: _currentPosition,
              oniPosition: _oniPosition,
              cameraPositions: _rt.cameraPositions,
            )
          : const [],
      editingArea: _editingArea,
      editCircleMode: _editCircleMode,
      polygonDraft: _polygonDraft,
      polygonDraftClosed: _polygonDraftClosed,
      circleDraftCenter: _circleDraftCenter,
      circleDraftRadiusMeters: _circleDraftRadiusMeters,
      playArea: _playArea,
      captureZoneCenter: _rt.captureZoneCenter,
      tokens: tokens,
      layerToggles: _mapLayerToggles,
      visualPack: _mapVisual.pack,
      markerRegistry: _mapVisual.markerRegistry,
      mapZoom: _mapVisual.mapZoom,
      playerMarkerIcon: _mapVisual.playerAvatarIcon,
      usePhotoPlayerPin: _shouldUsePhotoPlayerPin(),
      cameraPulsePhase: _cameraPulsePhase,
    );
  }

  int _secondsUntil(DateTime? target) => MapGeoFormat.secondsUntil(target);

  void _logDebug(String line) {
    final stamp = DateTime.now().toIso8601String().substring(11, 19);
    _debugLogs.insert(0, '[$stamp] $line');
    if (_debugLogs.length > 120) {
      _debugLogs.removeLast();
    }
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

  int? _buffRemainingSeconds(DateTime? endsAt) {
    if (endsAt == null) return null;
    final remain = endsAt.difference(DateTime.now()).inSeconds;
    return remain < 0 ? 0 : remain;
  }

  /// 暴露ログ一行向けの短い理由（HUD・一覧用）。
  String _shortRevealReason(String type, String message) {
    return switch (type) {
      'camera_spotted' => '監視カメラ',
      'info_broker' => '情報屋',
      'info_broker_hit' => '情報屋',
      'infection_reveal' => '感染',
      'capture_zone_escape' => '捕獲結界離脱',
      'body_throw_miss' => '体投げ（未回収）',
      'body_throw_placement_timeout' => '体投げ（期限）',
      'area_reveal' => 'エリア外',
      'accidental_reveal' => '偽情報',
      'fake_intel_reveal' => '偽情報',
      _ => message.length > 20 ? '${message.substring(0, 20)}…' : message,
    };
  }

  String _pickFakeIntelRevealNarrative(LatLng revealPos) {
    const camNear = 90.0;
    for (final c in _rt.cameraPositions) {
      final d = Geolocator.distanceBetween(
        revealPos.latitude,
        revealPos.longitude,
        c.latitude,
        c.longitude,
      );
      if (d < camNear) {
        return '監視カメラの記録が外部に流れたような座標';
      }
    }
    for (final s in _rt.safeZonePositions) {
      final d = Geolocator.distanceBetween(
        revealPos.latitude,
        revealPos.longitude,
        s.latitude,
        s.longitude,
      );
      if (d < GameConfig.safeZoneRadiusMeters + 30) {
        return '安全地帯付近のノイズに紛れた擬似発信源';
      }
    }
    if (!_playArea.contains(_currentPosition)) {
      return 'エリア外の電波誤差を装った偽の座標ログ';
    }
    return switch (math.Random().nextInt(3)) {
      0 => '傍受されたように見える偽の座標ログ',
      1 => '匿名端末からの誤送信に見せかけた地点',
      _ => '通信経路の混線を偽装した位置情報',
    };
  }

  Future<void> _openMatchResultScreen() async {
    if (!mounted) return;
    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => MatchResultScreen(
          outcome: _gameState,
          detail: _statusMessage,
          roleSummary:
              '$_localPlayerLabel / ${_localRole.displayName} / ${_skillLoadout.map(skillLabel).join("・")}',
          matchDurationLabel: _matchDurationLabel(),
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

  void _recenterMapOnGps() {
    if (_mapController == null) return;
    unawaited(
      _mapController!.animateCamera(
        CameraUpdate.newLatLngZoom(_currentPosition, 16),
      ),
    );
    _toast('現在地へ移動しました');
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
    final prefs0 = await SharedPreferences.getInstance();
    if (!mounted) return;
    final result = await showGameCustomSettingsSheet(
      context: context,
      initial: GameCustomSettingsInitial(
        profile: _activeProfile,
        oniIntelMode: _oniIntelMode,
        trajectoryConsent: _trajectoryConsent,
        eliminationAftermathRule: _eliminationAftermathRule,
        localRole: _localRole,
        customRuleMode: _customRuleMode,
        participantRulesOpen: _participantRulesOpen,
        matchDurationMinutes: _matchDurationSeconds / 60,
        skillLoadout: _skillLoadout,
        useBleScan: prefs0.getBool(GameMapPrefs.useBleScanProximity) ?? false,
        avatarImagePath: _avatarImagePath,
        gimmickDensity: _gimmickDensity,
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
    await WorldProfilePrefs.save(result.profile);
    final prefsPersist = await SharedPreferences.getInstance();
    await prefsPersist.setDouble(
      GameMapPrefs.gimmickDensity,
      result.gimmickDensity.clamp(0.45, 1.55),
    );
    if (!mounted) return;
    setState(() {
      _activeProfile = result.profile;
      _oniIntelMode = result.oniIntelMode;
      _eliminationAftermathRule = result.eliminationAftermathRule;
      _customRuleMode = result.customRuleMode;
      if (_isHost) {
        _participantRulesOpen = result.participantRulesOpen;
      }
      _gimmickDensity = result.gimmickDensity.clamp(0.45, 1.55);
      _matchDurationSeconds = result.matchDurationMinutes.round() * 60;
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
    _avatarImagePath = result.avatarImagePath;
    await _applyWorldProfile(result.profile);
    await _refreshPlayerAvatarIcon();
    await _reloadProximityStackFromPrefs();
    if (_trajectoryConsent != result.trajectoryConsent) {
      await _setTrajectoryConsent(result.trajectoryConsent);
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

  void _showHowToPlaySheet() => showHowToPlaySheet(context);

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
    _renderPump?.cancel();
    _cancelCaptureBoundTimers();
    _dangerPulseController.dispose();
    _revealFlash.dispose();
    _proximityService.stop();
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
    final ended =
        _gameState == GameState.runnerWin ||
        _gameState == GameState.caughtByOni;
    final showHudPanel = running;
    final panelHidden = _controlSheetMode == ControlSheetMode.hidden;
    final showBottomControlSheet =
        (running || _prepControlSheetOpen) && !panelHidden;
    final showControlFab =
        (!running && !_prepControlSheetOpen) || (running && panelHidden);
    final showGameMap =
        _editingArea || _mapVisibleInLobby || _gameState != GameState.waiting;
    final mq = MediaQuery.of(context);
    final narrow = mq.size.width < 400;
    final appTitle = narrow
        ? switch (_gameState) {
            GameState.waiting => '準備',
            GameState.running => 'プレイ中',
            GameState.runnerWin => '逃走成功',
            GameState.caughtByOni => '捕獲',
          }
        : switch (_gameState) {
            GameState.waiting => 'Oni Game ・ 準備',
            GameState.running => 'Oni Game ・ プレイ中',
            GameState.runnerWin => 'Oni Game ・ 逃走成功',
            GameState.caughtByOni => 'Oni Game ・ 捕獲',
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
              Builder(
                builder: (context) {
                  final overlay = _overlaySnapshot(tokens);
                  return GoogleMap(
                    style: _mapVisual.mapStyleJson,
                    initialCameraPosition: CameraPosition(
                      target: _currentPosition,
                      zoom: 16,
                    ),
                    myLocationEnabled: true,
                    myLocationButtonEnabled: !_editingArea,
                    markers: GameMapOverlayBuilder.buildMarkers(overlay),
                    polylines: GameMapOverlayBuilder.buildPolylines(overlay),
                    circles: GameMapOverlayBuilder.buildCircles(overlay),
                    polygons: GameMapOverlayBuilder.buildPolygons(overlay),
                    onTap: _onMapTap,
                    onMapCreated: _onMapCreated,
                    onCameraIdle: _onCameraIdle,
                  );
                },
              )
            else
              PrepLobbyPanel(
                roomLabel: _roomSession.modeLabel,
                playAreaLabel: _playAreaSummary(),
                matchDurationMinutes: _matchDurationSeconds / 60,
                isHost: _isHost,
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
                participantRulesOpen: _participantRulesOpen,
                worldVisualProfile: _mapVisual.pack.profile,
              ),
            if (showGameMap)
              Positioned.fill(
                child: IgnorePointer(
                  child: AnimatedBuilder(
                    animation: _dangerPulseController,
                    builder: (_, child) {
                      final dangerExtra = _gameState == GameState.running
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
            if (ended &&
                _gameState == GameState.caughtByOni &&
                _afterCatchRule != null)
              Positioned(
                left: 16,
                right: 16,
                bottom: showBottomControlSheet ? 200 : 24,
                child: GhostSpectatorBar(
                  rule: _afterCatchRule!,
                  onOpenResult: _openMatchResultScreen,
                ),
              ),
            if (_editingArea && !running && !ended)
              Positioned(
                top: 12,
                left: 12,
                right: 12,
                child: Material(
                  elevation: 2,
                  borderRadius: BorderRadius.circular(10),
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.edit_location_alt_outlined,
                          size: 20,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        const SizedBox(width: 8),
                        const Expanded(
                          child: Text('エリア編集中 — 下部のカードと地図タップで形状を指定'),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
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
                  intelLine: _latestIntelLine(),
                  showIntelLine:
                      _rt.showOniIntelCard &&
                      !_oniIntelLineHidden &&
                      _latestIntelLine().isNotEmpty,
                  onDismissIntel: () =>
                      setState(() => _oniIntelLineHidden = true),
                  onOpenIntelLog: _openCombinedIntelRevealLogSheet,
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
                  werewolfBuffSeconds: _buffRemainingSeconds(
                    _rt.werewolfTransformEndsAt,
                  ),
                  werewolfCooldownSeconds: _cooldownRemainingSeconds(
                    _rt.lastWerewolfTransformAt,
                    GameConfig.werewolfTransformCooldownSeconds,
                  ),
                  fakeCooldownSeconds: _cooldownRemainingSeconds(
                    _rt.lastFakeSkillAt,
                    GameConfig.fakeSkillCooldownSeconds,
                  ),
                  intelLineSuppressed: _oniIntelLineHidden &&
                      _latestIntelLine().isNotEmpty,
                  onRestoreIntelLine: () =>
                      setState(() => _oniIntelLineHidden = false),
                  fakeIntelRevealCooldownSeconds: _cooldownRemainingSeconds(
                    _rt.lastFakeIntelRevealAt,
                    GameConfig.fakeIntelRevealCooldownSeconds,
                  ),
                  mapLayerToggles: _mapLayerToggles,
                  onMapLayersChanged: (t) =>
                      setState(() => _mapLayerToggles = t),
                  onRecenterMap: _recenterMapOnGps,
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
            if (_editingArea)
              Positioned(
                left: 12,
                right: 12,
                bottom: 200,
                child: AreaEditorCard(
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
                  onCancel: () {
                    setState(() {
                      _editingArea = false;
                      _waitingCircleCenterTap = false;
                      _polygonDraft.clear();
                      _polygonDraftClosed = false;
                      _statusMessage = '編集をキャンセルしました';
                    });
                    _returnToPrepAfterAreaEdit();
                  },
                ),
              ),
            if (showBottomControlSheet)
              Positioned(
                bottom: 16,
                left: 16,
                right: 16,
                child: GameControlPanel(
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
                  roleLabel: _isHunterNow ? '鬼' : _localRole.displayName,
                  matchDurationLabel: _matchDurationLabel(),
                  canFakeSkill: _skillLoadout.contains(SkillIds.fakePosition),
                  canFakeIntelReveal:
                      _skillLoadout.contains(SkillIds.fakeIntelReveal) &&
                      _cooldownRemainingSeconds(
                            _rt.lastFakeIntelRevealAt,
                            GameConfig.fakeIntelRevealCooldownSeconds,
                          ) ==
                          0,
                  canWerewolfHunter: _skillLoadout.contains(
                    SkillIds.werewolfTransform,
                  ),
                  canCaptureZone: _skillLoadout.contains(SkillIds.captureZone),
                  canBodyThrow: _skillLoadout.contains(SkillIds.bodyThrow),
                  fakeCooldownSeconds: _cooldownRemainingSeconds(
                    _rt.lastFakeSkillAt,
                    GameConfig.fakeSkillCooldownSeconds,
                  ),
                  captureCooldownSeconds: _cooldownRemainingSeconds(
                    _rt.lastCaptureZoneAt,
                    GameConfig.captureZoneCooldownSeconds,
                  ),
                  bodyThrowCooldownSeconds: _cooldownRemainingSeconds(
                    _rt.lastBodyThrowAt,
                    GameConfig.bodyThrowCooldownSeconds,
                  ),
                  werewolfBuffSeconds: _buffRemainingSeconds(
                    _rt.werewolfTransformEndsAt,
                  ),
                  werewolfCooldownSeconds: _cooldownRemainingSeconds(
                    _rt.lastWerewolfTransformAt,
                    GameConfig.werewolfTransformCooldownSeconds,
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
