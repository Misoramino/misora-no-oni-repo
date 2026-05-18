import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../game/elimination_aftermath_rule.dart';
import '../game/game_config.dart';
import '../game/game_state.dart';
import '../game/location_reveal_event.dart';
import '../game/match_event.dart';
import '../game/oni_intel_mode.dart';
import '../game/play_area.dart';
import '../game/sampling_tier.dart';
import '../map/runner_display_smooth.dart';
import '../proximity/ble_scan_proximity_service.dart';
import '../proximity/hybrid_proximity_service.dart';
import '../proximity/idle_proximity_service.dart';
import '../proximity/proximity_service.dart';
import '../proximity/proximity_signal.dart';
import '../sync/firebase_bootstrap.dart';
import '../sync/firestore_room_session.dart';
import '../sync/remote_member_snapshot.dart';
import '../services/location_service.dart';
import '../services/match_archive_store.dart';
import '../services/match_recorder.dart';
import '../services/play_area_store.dart';
import '../sync/room_session_port.dart';
import '../sync/offline_sync_queue.dart';
import '../theme/world_profile.dart';
import '../theme/world_profile_tokens.dart';
import '../settings/oni_operator_prefs.dart';
import 'match_gallery_screen.dart';
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

enum PlayerRole {
  runner('runner'),
  hunter('hunter'),
  werewolf('werewolf');

  const PlayerRole(this.label);
  final String label;
}

extension PlayerRoleUi on PlayerRole {
  String get displayName => switch (this) {
    PlayerRole.runner => '逃走者',
    PlayerRole.hunter => '鬼',
    PlayerRole.werewolf => '人狼',
  };
}

const _assignableRoles = [
  PlayerRole.runner,
  PlayerRole.hunter,
  PlayerRole.werewolf,
];

abstract final class SkillIds {
  static const fakePosition = 'fake_position';
  static const fakeIntelReveal = 'fake_intel_reveal';
  static const captureZone = 'capture_zone';
  static const bodyThrow = 'body_throw';
  static const werewolfTransform = 'werewolf_transform';
}

String _skillLabel(String id) => switch (id) {
  SkillIds.fakePosition => '偽位置',
  SkillIds.fakeIntelReveal => '偽情報暴露',
  SkillIds.captureZone => '捕獲結界',
  SkillIds.bodyThrow => '体投げ',
  SkillIds.werewolfTransform => '鬼化',
  _ => id,
};

class _OniIntelTrace {
  const _OniIntelTrace({
    required this.timestamp,
    required this.position,
    required this.text,
  });

  final DateTime timestamp;
  final LatLng position;
  final String text;
}

class _GeneratedGimmicks {
  const _GeneratedGimmicks({
    required this.safeZones,
    required this.infoBrokers,
    required this.cameras,
    required this.eventAreas,
  });

  final List<LatLng> safeZones;
  final List<LatLng> infoBrokers;
  final List<LatLng> cameras;
  final List<LatLng> eventAreas;

  factory _GeneratedGimmicks.create(PlayArea area) {
    final center = _centerOf(area);
    final radius = _effectiveRadiusMeters(area, center).clamp(180.0, 2400.0);
    final safeCount = _scaledCount(
      radius,
      GameConfig.safeZoneMinCount,
      GameConfig.safeZoneMaxCount,
    );
    final brokerCount = _scaledCount(
      radius,
      GameConfig.infoBrokerMinCount,
      GameConfig.infoBrokerMaxCount,
    );
    final cameraCount =
        (GameConfig.cameraMinCount + ((radius - 250) / 180).floor())
            .clamp(GameConfig.cameraMinCount, GameConfig.cameraMaxCount)
            .toInt();
    final eventCount = _scaledCount(
      radius,
      GameConfig.commJammingZoneMinCount,
      GameConfig.commJammingZoneMaxCount,
    );
    final minGap = (radius * 0.18).clamp(60.0, 180.0);

    final used = <LatLng>[];
    List<LatLng> group({
      required int count,
      required double angleSeed,
      required double radiusFactor,
      double? minGapOverride,
    }) {
      final out = <LatLng>[];
      final gap = minGapOverride ?? minGap;
      for (var i = 0; i < count; i++) {
        final angle = angleSeed + i * (360 / math.max(1, count));
        final dist = radius * (radiusFactor + 0.08 * (i % 2));
        final p = _pointInArea(
          area: area,
          center: center,
          angleDegrees: angle,
          distanceMeters: dist,
          avoid: used,
          minGapMeters: gap,
        );
        out.add(p);
        used.add(p);
      }
      return out;
    }

    return _GeneratedGimmicks(
      safeZones: group(count: safeCount, angleSeed: 35, radiusFactor: 0.42),
      infoBrokers: group(
        count: brokerCount,
        angleSeed: 150,
        radiusFactor: 0.58,
      ),
      cameras: group(
        count: cameraCount,
        angleSeed: 245,
        radiusFactor: 0.68,
        minGapOverride: (radius * 0.08).clamp(30.0, 90.0),
      ),
      eventAreas: group(count: eventCount, angleSeed: 315, radiusFactor: 0.50),
    );
  }

  static int _scaledCount(double radius, int min, int max) {
    final extra = ((radius - 240) / 320).round();
    return (min + extra).clamp(min, max).toInt();
  }

  static LatLng _centerOf(PlayArea area) {
    switch (area.type) {
      case PlayAreaType.circle:
        return area.center;
      case PlayAreaType.polygon:
        if (area.points.isEmpty) return const LatLng(35.681236, 139.767125);
        final lat =
            area.points.map((p) => p.latitude).reduce((a, b) => a + b) /
            area.points.length;
        final lng =
            area.points.map((p) => p.longitude).reduce((a, b) => a + b) /
            area.points.length;
        final center = LatLng(lat, lng);
        return area.contains(center) ? center : area.points.first;
    }
  }

  static double _effectiveRadiusMeters(PlayArea area, LatLng center) {
    switch (area.type) {
      case PlayAreaType.circle:
        return area.radiusMeters;
      case PlayAreaType.polygon:
        var maxDistance = 240.0;
        for (final p in area.points) {
          maxDistance = math.max(
            maxDistance,
            Geolocator.distanceBetween(
              center.latitude,
              center.longitude,
              p.latitude,
              p.longitude,
            ),
          );
        }
        return maxDistance;
    }
  }

  static LatLng _pointInArea({
    required PlayArea area,
    required LatLng center,
    required double angleDegrees,
    required double distanceMeters,
    required List<LatLng> avoid,
    required double minGapMeters,
  }) {
    for (final scale in const [1.0, 0.75, 0.55, 0.35]) {
      final p = _offset(center, angleDegrees, distanceMeters * scale);
      if (area.contains(p) && _farEnough(p, avoid, minGapMeters)) return p;
    }
    return center;
  }

  static bool _farEnough(LatLng p, List<LatLng> avoid, double minGapMeters) {
    for (final other in avoid) {
      final d = Geolocator.distanceBetween(
        p.latitude,
        p.longitude,
        other.latitude,
        other.longitude,
      );
      if (d < minGapMeters) return false;
    }
    return true;
  }

  static LatLng _offset(LatLng origin, double angleDegrees, double meters) {
    final rad = angleDegrees * math.pi / 180;
    final north = math.cos(rad) * meters;
    final east = math.sin(rad) * meters;
    final lat = origin.latitude + north / 111111;
    final lng =
        origin.longitude +
        east / (111111 * math.cos(origin.latitude * math.pi / 180));
    return LatLng(lat, lng);
  }
}

const _kTrajectoryConsentPrefKey = 'trajectory_consent_default';
const _kEliminationAftermathPrefKey = 'elimination_aftermath_rule_v1';
const _kUseBleScanPrefKey = 'use_ble_scan_proximity_v1';

class _GameMapScreenState extends State<GameMapScreen>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  static const LatLng _defaultOniPosition = LatLng(35.6805, 139.7690);

  final LocationService _locationService = LocationService();
  final PlayAreaStore _areaStore = PlayAreaStore();
  final MatchArchiveStore _matchArchive = MatchArchiveStore();
  final OfflineSyncQueue _offlineQueue = OfflineSyncQueue();
  late HybridProximityService _proximityService = HybridProximityService(
    bleDelegate: IdleProximityService(),
  );
  RoomSessionPort _roomSession = LocalOnlyRoomSession();

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
  LatLng _circleDraftCenter = const LatLng(35.681236, 139.767125);
  double _circleDraftRadiusMeters = GameConfig.playAreaRadiusMeters;
  bool _waitingCircleCenterTap = false;

  /// 待機中は地図を隠してロビー表示。エリア編集・試合中・試合終了後は地図を表示する。
  bool _mapVisibleInLobby = false;

  GameState _gameState = GameState.waiting;
  int _remainingSeconds = GameConfig.matchDurationSeconds;
  String _statusMessage = '現在地を取得中...';
  int _revealCount = 0;
  final List<LocationRevealEvent> _revealLog = [];
  final List<MatchEvent> _matchEvents = [];

  DateTime? _outsideAreaSince;
  bool _revealedInCurrentOutside = false;
  DateTime? _lastAcceptedPositionAt;
  double? _lastDistance;
  int _elapsedSeconds = 0;

  List<LatLng> _safeZonePositions = const [LatLng(35.6822, 139.7682)];
  List<LatLng> _infoBrokerPositions = const [LatLng(35.6804, 139.7657)];
  List<LatLng> _commJammingZonePositions = const [LatLng(35.6796, 139.7689)];
  int _safeZoneCharges = 0;
  DateTime? _lastSafeChargeAt;
  DateTime? _lastInfoBrokerAt;
  String? _lastOniIntelText;
  DateTime? _lastOniIntelAt;
  bool _showOniIntelCard = true;
  final List<_OniIntelTrace> _oniIntelTraces = [];
  OniIntelMode _oniIntelMode = OniIntelMode.directionOnly;
  bool _safeZoneAvailable = true;
  bool _infoBrokerAvailable = true;
  DateTime? _safeZoneRespawnAt;
  DateTime? _infoBrokerRespawnAt;
  List<LatLng> _cameraPositions = const [
    LatLng(35.6817, 139.7661),
    LatLng(35.6800, 139.7696),
  ];
  final Set<int> _triggeredCameras = <int>{};
  bool _fakePositionActive = false;
  DateTime? _fakePositionEndsAt;
  DateTime? _lastFakeSkillAt;
  LatLng? _fakePositionLatLng;
  bool _customRuleMode = false;
  int _matchDurationSeconds = GameConfig.matchDurationSeconds;
  PlayerRole _localRole = PlayerRole.runner;
  Set<String> _skillLoadout = const {SkillIds.fakePosition};
  DateTime? _werewolfTransformEndsAt;
  DateTime? _lastWerewolfTransformAt;
  LatLng? _captureZoneCenter;
  DateTime? _captureZoneEndsAt;
  DateTime? _lastCaptureZoneAt;
  bool _waitingCaptureZoneTap = false;
  Set<String> _captureZoneBoundIds = const {};
  DateTime? _captureZoneTargetLeftAt;
  bool _captureZoneEscapeRevealed = false;
  DateTime? _touchLockStartedAt;
  bool _touchLockNoticeShown = false;
  LatLng? _bodyThrowPosition;
  DateTime? _bodyThrowEndsAt;
  DateTime? _lastBodyThrowAt;
  int _infectionExposureSeconds = 0;
  DateTime? _infectionEndsAt;
  DateTime? _lastInfectionRevealAt;
  final List<LatLng> _tracePoints = [];

  MatchRecorder? _matchRecorder;
  Future<void>? _finalizeRecordingFuture;
  bool _trajectoryConsent = false;
  late WorldProfile _activeProfile;
  bool _menuCollapsed = false;

  /// 準備・試合結果中は操作パネルを隠し、FAB「操作」で開く。
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
  bool _syncInFlight = false;
  Map<String, RemoteMemberSnapshot> _remoteMembers = {};
  StreamSubscription<Map<String, RemoteMemberSnapshot>>? _remoteMembersSub;
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
    _dangerPulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _setupLocation();
    Future<void>.microtask(_loadTrajectoryConsent);
    Future<void>.microtask(_loadEliminationAftermathRule);
    Future<void>.microtask(_initProximityStack);
    Future<void>.microtask(_refreshOfflineQueueCount);
    if (widget.onlineSession != null) {
      Future<void>.microtask(_attachOnlineSession);
    }
    Future<void>.microtask(_loadOniOperatorPrefs);
    _renderPump = Timer.periodic(const Duration(milliseconds: 52), (_) {
      _pulseVisualSmoothing();
    });
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
      _trajectoryConsent = prefs.getBool(_kTrajectoryConsentPrefKey) ?? false;
    });
  }

  Future<void> _loadEliminationAftermathRule() async {
    final prefs = await SharedPreferences.getInstance();
    final parsed = EliminationAftermathRuleX.tryParseName(
      prefs.getString(_kEliminationAftermathPrefKey),
    );
    if (!mounted) return;
    if (parsed != null) {
      setState(() => _eliminationAftermathRule = parsed);
    }
  }

  Future<void> _setTrajectoryConsent(bool value) async {
    setState(() => _trajectoryConsent = value);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kTrajectoryConsentPrefKey, value);
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
    final useBle = prefs.getBool(_kUseBleScanPrefKey) ?? false;
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

  Future<void> _leaveFirestoreRoom() async {
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
      _oniPosition = _defaultOniPosition;
    });
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

  Future<String?> _joinFirestoreRoom({
    required String roomId,
    required String nickname,
    required String role,
  }) async {
    if (!FirebaseBootstrap.isReady) {
      return 'Firebase が初期化されていません。android/app/google-services.json または dart-define（FIREBASE_*）を確認してください。';
    }
    await _leaveFirestoreRoom();
    final fs = FirestoreRoomSession();
    final err = await fs.join(roomId: roomId, nickname: nickname, role: role);
    if (err != null) return err;
    if (!mounted) return '中断されました';
    setState(() {
      _roomSession = fs;
      _ownsRoomSession = true;
    });
    _bindRemoteMembers(fs);
    return null;
  }

  void _bindRemoteMembers(FirestoreRoomSession session) {
    _remoteMembersSub?.cancel();
    _remoteMembersSub = session.remoteMembers.listen((map) {
      if (!mounted) return;
      setState(() {
        _remoteMembers = map;
        _applyRemoteOniPosition(map);
      });
    });
  }

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
      _statusMessage = '前回保存したプレイエリアを読み込みました';
    });
  }

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
      if (_revealedInCurrentOutside) {
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

  void _pulseVisualSmoothing() {
    if (!mounted || _editingArea) return;
    final s = _runnerSmooth;
    if (s == null) return;
    final blend = _visualSmoothBlend(_distanceToOni());
    final before = s.residualMeters;
    s.stepTowardTarget(blend);
    final after = s.residualMeters;
    final running = _gameState == GameState.running;
    final shouldRepaint =
        running || (before - after).abs() > 0.25 || !s.isNearlyThere;
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
    if (_revealedInCurrentOutside) {
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
      _bodyThrowPosition ??
      (_fakePositionActive && _fakePositionLatLng != null
          ? _fakePositionLatLng!
          : _currentPosition);

  bool get _isHunterNow =>
      _localRole == PlayerRole.hunter ||
      (_werewolfTransformEndsAt != null &&
          DateTime.now().isBefore(_werewolfTransformEndsAt!));

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
      reveals: List<LocationRevealEvent>.from(_revealLog),
      events: List<MatchEvent>.from(_matchEvents),
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

  void _startGame() {
    if (_gameState != GameState.waiting) {
      if (_gameState == GameState.running) return;
      _toast('新しい試合を始めるには「リセット」で結果を閉じてからにしてください');
      return;
    }
    if (_editingArea) {
      _toast('エリア編集中は開始できません');
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
    final gimmicks = _GeneratedGimmicks.create(_playArea);
    _assignDefaultSetupIfNeeded();
    _retuneGpsIfNeeded();
    setState(() {
      _safeZonePositions = gimmicks.safeZones;
      _infoBrokerPositions = gimmicks.infoBrokers;
      _commJammingZonePositions = gimmicks.eventAreas;
      _cameraPositions = gimmicks.cameras;
      _gameState = GameState.running;
      _afterCatchRule = null;
      _remainingSeconds = _matchDurationSeconds;
      _elapsedSeconds = 0;
      _outsideAreaSince = null;
      _revealedInCurrentOutside = false;
      _revealCount = 0;
      _revealLog.clear();
      _matchEvents.clear();
      _safeZoneCharges = 0;
      _lastSafeChargeAt = null;
      _lastInfoBrokerAt = null;
      _lastOniIntelText = null;
      _lastOniIntelAt = null;
      _showOniIntelCard = true;
      _oniIntelTraces.clear();
      _safeZoneAvailable = true;
      _infoBrokerAvailable = true;
      _safeZoneRespawnAt = null;
      _infoBrokerRespawnAt = null;
      _triggeredCameras.clear();
      _fakePositionActive = false;
      _fakePositionEndsAt = null;
      _lastFakeSkillAt = null;
      _fakePositionLatLng = null;
      _werewolfTransformEndsAt = null;
      _lastWerewolfTransformAt = null;
      _captureZoneCenter = null;
      _captureZoneEndsAt = null;
      _waitingCaptureZoneTap = false;
      _captureZoneBoundIds = const {};
      _captureZoneTargetLeftAt = null;
      _captureZoneEscapeRevealed = false;
      _touchLockStartedAt = null;
      _touchLockNoticeShown = false;
      _bodyThrowPosition = null;
      _bodyThrowEndsAt = null;
      _infectionExposureSeconds = 0;
      _infectionEndsAt = null;
      _lastInfectionRevealAt = null;
      _statusMessage = 'ゲーム開始。鬼から逃げてください。';
    });
    _emitMatchEvent(
      type: 'gimmicks_generated',
      message:
          'ギミック生成: 安全地帯${_safeZonePositions.length} / 情報屋${_infoBrokerPositions.length} / 監視カメラ${_cameraPositions.length} / イベントエリア${_commJammingZonePositions.length}',
      position: _playAreaAnchor,
    );
    _showRoleSkillDialog();
    _logDebug('match_start scale=${_timeScale}x');
    HapticFeedback.selectionClick();
    SystemSound.play(SystemSoundType.click);

    _matchTimer?.cancel();
    _matchTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted || _gameState != GameState.running) return;
      _matchRecorder?.tryAppendOni(_oniPosition);
      setState(() {
        _remainingSeconds -= _timeScale;
        _elapsedSeconds += _timeScale;
        _estimatedBatteryScore += _batteryCostPerSecond() * _timeScale;
      });
      _evaluateGame();
      _retuneGpsIfNeeded();
    });
  }

  void _resetGame() {
    _matchTimer?.cancel();
    _matchRecorder?.discard();
    _matchRecorder = null;
    _finalizeRecordingFuture = null;
    _retuneGpsIfNeeded();
    setState(() {
      _gameState = GameState.waiting;
      _mapVisibleInLobby = false;
      _afterCatchRule = null;
      _remainingSeconds = _matchDurationSeconds;
      _elapsedSeconds = 0;
      _outsideAreaSince = null;
      _revealedInCurrentOutside = false;
      _revealCount = 0;
      _revealLog.clear();
      _matchEvents.clear();
      _safeZoneCharges = 0;
      _lastSafeChargeAt = null;
      _lastInfoBrokerAt = null;
      _lastOniIntelText = null;
      _lastOniIntelAt = null;
      _showOniIntelCard = true;
      _oniIntelTraces.clear();
      _safeZoneAvailable = true;
      _infoBrokerAvailable = true;
      _safeZoneRespawnAt = null;
      _infoBrokerRespawnAt = null;
      _triggeredCameras.clear();
      _fakePositionActive = false;
      _fakePositionEndsAt = null;
      _fakePositionLatLng = null;
      _werewolfTransformEndsAt = null;
      _lastWerewolfTransformAt = null;
      _captureZoneCenter = null;
      _captureZoneEndsAt = null;
      _waitingCaptureZoneTap = false;
      _captureZoneBoundIds = const {};
      _captureZoneTargetLeftAt = null;
      _captureZoneEscapeRevealed = false;
      _touchLockStartedAt = null;
      _touchLockNoticeShown = false;
      _bodyThrowPosition = null;
      _bodyThrowEndsAt = null;
      _infectionExposureSeconds = 0;
      _infectionEndsAt = null;
      _lastInfectionRevealAt = null;
      _statusMessage = 'リセットしました。開始ボタンでゲーム開始。';
      _prepControlSheetOpen = false;
    });
    _logDebug('match_reset');
  }

  void _showRoleSkillDialog() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _gameState != GameState.running) return;
      showDialog<void>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('あなたの役職 / スキル'),
          content: Text(
            '役職: ${_localRole.displayName}\n'
            'スキル: ${_skillLoadout.map(_skillLabel).join(" / ")}',
          ),
          actions: [
            FilledButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('OK'),
            ),
          ],
        ),
      );
    });
  }

  void _assignDefaultSetupIfNeeded() {
    if (_customRuleMode) return;
    final seed = DateTime.now().millisecondsSinceEpoch;
    final rnd = math.Random(seed);
    const roles = _assignableRoles;
    _localRole = roles[rnd.nextInt(roles.length)];
    _skillLoadout = _randomSkillsFor(_localRole, rnd);
    _oniIntelMode =
        OniIntelMode.values[rnd.nextInt(OniIntelMode.values.length)];
    _eliminationAftermathRule = EliminationAftermathRule
        .values[rnd.nextInt(EliminationAftermathRule.values.length)];
  }

  Set<String> _randomSkillsFor(PlayerRole role, math.Random rnd) {
    final list = _skillCandidates(role).toList()..shuffle(rnd);
    return list.take(role == PlayerRole.hunter ? 2 : 1).toSet();
  }

  List<String> _skillCandidates(PlayerRole role) => switch (role) {
    PlayerRole.runner => const [
      SkillIds.fakePosition,
      SkillIds.bodyThrow,
      SkillIds.captureZone,
    ],
    PlayerRole.hunter => const [
      SkillIds.fakeIntelReveal,
      SkillIds.captureZone,
      SkillIds.bodyThrow,
    ],
    PlayerRole.werewolf => const [SkillIds.werewolfTransform],
  };

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

  void _endGame(GameState result, String message) {
    _matchTimer?.cancel();
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
  }

  void _evaluateGame() {
    if (_gameState != GameState.running) return;

    final distance = _distanceToOni();
    _proximityService.ingestGpsDistanceMeters(distance);
    final overflowMeters = _playArea.overflowDistanceMeters(_currentPosition);
    _refreshPointRespawns();
    _evaluateFakeSkillTimer();
    _evaluateSkillTimers();
    _evaluateInfection(_effectiveInfectionDistance(distance));
    _evaluateCameraTriggers();
    _evaluateSafeZone();
    _evaluateInfoBroker(distance);
    _evaluateScaledTouchLock(distance);

    if (_isCaptureTriggered()) {
      _endGame(GameState.caughtByOni, 'BLE接近で接触判定。鬼に捕まりました。');
      HapticFeedback.heavyImpact();
      return;
    }

    if (_remainingSeconds <= 0) {
      _endGame(GameState.runnerWin, '逃走成功。時間切れです。');
      HapticFeedback.mediumImpact();
      return;
    }

    final isOutBeyondGrace = overflowMeters > GameConfig.outsideAreaGraceMeters;
    if (isOutBeyondGrace) {
      _outsideAreaSince ??= DateTime.now();
      final outsideSec = DateTime.now()
          .difference(_outsideAreaSince!)
          .inSeconds;
      if (!_revealedInCurrentOutside &&
          outsideSec >= GameConfig.outsideAreaGraceSeconds) {
        if (_safeZoneCharges > 0) {
          _safeZoneCharges -= 1;
          _outsideAreaSince = null;
          _revealedInCurrentOutside = false;
          setState(() {
            _statusMessage = '安全地帯チャージを消費して位置暴露を回避しました';
          });
        } else {
          _triggerLocationReveal(overflowMeters);
        }
      }
    } else {
      _outsideAreaSince = null;
      _revealedInCurrentOutside = false;
    }

    _maybeTriggerDangerFeedback(distance);
    _updateDangerPulse();
  }

  void _updateDangerPulse() {
    final shouldPulse =
        _touchLockNoticeShown ||
        _captureZoneBoundIds.contains('self') ||
        _isInfectedNow;
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
    _revealedInCurrentOutside = true;
    _revealCount += 1;
    final playerLabel = _localPlayerLabel;
    final ev = LocationRevealEvent(
      sequence: _revealCount,
      timestamp: DateTime.now(),
      position: _positionForReveal,
      overflowMeters: overflowMeters,
      playerLabel: playerLabel,
    );
    setState(() {
      _revealLog.insert(0, ev);
      if (_revealLog.length > 50) {
        _revealLog.removeLast();
      }
      _statusMessage =
          '$playerLabel の位置暴露 #$_revealCount: ${_formatLatLng(_positionForReveal)}';
    });
    HapticFeedback.heavyImpact();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          '位置暴露: $playerLabel / ${_formatLatLng(_positionForReveal)}（数分だけ地図表示）',
        ),
      ),
    );
    _emitMatchEvent(
      type: 'area_reveal',
      message: 'エリア外猶予超過で位置暴露',
      position: _positionForReveal,
    );
    _retuneGpsIfNeeded();
  }

  void _emitLocationReveal({required String type, required String message}) {
    _revealCount += 1;
    final playerLabel = _localPlayerLabel;
    final ev = LocationRevealEvent(
      sequence: _revealCount,
      timestamp: DateTime.now(),
      position: _positionForReveal,
      overflowMeters: 0,
      playerLabel: playerLabel,
    );
    setState(() {
      _revealLog.insert(0, ev);
      if (_revealLog.length > 50) _revealLog.removeLast();
      _statusMessage = message;
    });
    _emitMatchEvent(type: type, message: message, position: _positionForReveal);
  }

  void _evaluateSafeZone() {
    if (!_safeZoneAvailable) return;
    if (_safeZoneCharges >= GameConfig.safeZoneMaxCharges) return;
    final now = DateTime.now();
    final hitIndex = _firstPointWithinIndex(
      _safeZonePositions,
      GameConfig.safeZoneRadiusMeters,
    );
    if (hitIndex == null) return;
    final hit = _safeZonePositions[hitIndex];
    if (_lastSafeChargeAt != null &&
        now.difference(_lastSafeChargeAt!).inSeconds <
            GameConfig.safeZoneChargeCooldownSeconds) {
      return;
    }
    final nextSafeZone = _relocatedGimmickPoint(
      avoid: [
        ..._safeZonePositions,
        ..._infoBrokerPositions,
        ..._cameraPositions,
        ..._commJammingZonePositions,
      ],
      angleSeed: 35 + _elapsedSeconds * 7 + hitIndex * 53,
      radiusFactor: 0.44,
    );
    setState(() {
      _lastSafeChargeAt = now;
      _safeZoneCharges += 1;
      _refreshSkillCooldownsFromSafeZone();
      _safeZonePositions[hitIndex] = nextSafeZone;
      _safeZoneAvailable = false;
      _safeZoneRespawnAt = now.add(
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
    if (!_infoBrokerAvailable) return;
    final now = DateTime.now();
    final hitIndex = _firstPointWithinIndex(
      _infoBrokerPositions,
      GameConfig.infoBrokerRadiusMeters,
    );
    if (hitIndex == null) return;
    final hit = _infoBrokerPositions[hitIndex];
    if (_lastInfoBrokerAt != null &&
        now.difference(_lastInfoBrokerAt!).inSeconds <
            GameConfig.infoBrokerCooldownSeconds) {
      return;
    }
    final bearing = Geolocator.bearingBetween(
      _currentPosition.latitude,
      _currentPosition.longitude,
      _oniPosition.latitude,
      _oniPosition.longitude,
    );
    final direction = _bearingToDirection(bearing);
    final distBand = distanceToOni <= GameConfig.dangerDistanceMeters
        ? '至近'
        : distanceToOni <= GameConfig.warningDistanceMeters
        ? '中距離'
        : '遠距離';
    final intel = _buildOniIntel(
      direction: direction,
      distanceBand: distBand,
      bearingDegrees: bearing,
    );
    final nextInfoBroker = _relocatedGimmickPoint(
      avoid: [
        ..._safeZonePositions,
        ..._infoBrokerPositions,
        ..._cameraPositions,
        ..._commJammingZonePositions,
      ],
      angleSeed: 150 + _elapsedSeconds * 11 + hitIndex * 71,
      radiusFactor: 0.58,
    );
    setState(() {
      _lastInfoBrokerAt = now;
      _infoBrokerAvailable = false;
      _infoBrokerRespawnAt = now.add(
        const Duration(seconds: GameConfig.infoBrokerRespawnSeconds),
      );
      _lastOniIntelText = intel;
      _lastOniIntelAt = now;
      _showOniIntelCard = true;
      _oniIntelTraces.insert(
        0,
        _OniIntelTrace(timestamp: now, position: _oniPosition, text: intel),
      );
      if (_oniIntelTraces.length > 20) {
        _oniIntelTraces.removeLast();
      }
      _infoBrokerPositions[hitIndex] = nextInfoBroker;
      _statusMessage = '情報屋: $intel';
    });
    _emitMatchEvent(
      type: 'info_broker',
      message: '情報屋を利用: $intel',
      position: hit,
    );
  }

  LatLng? _firstPointWithin(List<LatLng> points, double radiusMeters) {
    final index = _firstPointWithinIndex(points, radiusMeters);
    return index == null ? null : points[index];
  }

  int? _firstPointWithinIndex(List<LatLng> points, double radiusMeters) {
    for (var i = 0; i < points.length; i++) {
      final p = points[i];
      final d = Geolocator.distanceBetween(
        _currentPosition.latitude,
        _currentPosition.longitude,
        p.latitude,
        p.longitude,
      );
      if (d <= radiusMeters) return i;
    }
    return null;
  }

  LatLng _relocatedGimmickPoint({
    required List<LatLng> avoid,
    required double angleSeed,
    required double radiusFactor,
  }) {
    final center = _GeneratedGimmicks._centerOf(_playArea);
    final radius = _GeneratedGimmicks._effectiveRadiusMeters(
      _playArea,
      center,
    ).clamp(180.0, 2400.0);
    final minGap = (radius * 0.16).clamp(45.0, 160.0);
    return _GeneratedGimmicks._pointInArea(
      area: _playArea,
      center: center,
      angleDegrees: angleSeed % 360,
      distanceMeters: radius * radiusFactor,
      avoid: avoid,
      minGapMeters: minGap,
    );
  }

  void _refreshSkillCooldownsFromSafeZone() {
    if (_skillLoadout.contains(SkillIds.fakePosition)) {
      _lastFakeSkillAt = null;
    }
    if (_skillLoadout.contains(SkillIds.werewolfTransform)) {
      _lastWerewolfTransformAt = null;
    }
    if (_skillLoadout.contains(SkillIds.captureZone)) {
      _lastCaptureZoneAt = null;
    }
    if (_skillLoadout.contains(SkillIds.bodyThrow)) {
      _lastBodyThrowAt = null;
    }
  }

  void _refreshPointRespawns() {
    final now = DateTime.now();
    if (!_safeZoneAvailable &&
        _safeZoneRespawnAt != null &&
        !now.isBefore(_safeZoneRespawnAt!)) {
      _safeZoneAvailable = true;
      _safeZoneRespawnAt = null;
      setState(() {
        _statusMessage = '安全地帯が再出現しました';
      });
    }
    if (!_infoBrokerAvailable &&
        _infoBrokerRespawnAt != null &&
        !now.isBefore(_infoBrokerRespawnAt!)) {
      _infoBrokerAvailable = true;
      _infoBrokerRespawnAt = null;
      setState(() {
        _statusMessage = '情報屋が再出現しました';
      });
    }
  }

  void _evaluateCameraTriggers() {
    for (var i = 0; i < _cameraPositions.length; i++) {
      if (_triggeredCameras.contains(i)) continue;
      final p = _cameraPositions[i];
      final d = Geolocator.distanceBetween(
        _currentPosition.latitude,
        _currentPosition.longitude,
        p.latitude,
        p.longitude,
      );
      if (d <= GameConfig.cameraTriggerRadiusMeters) {
        _triggeredCameras.add(i);
        final msg = '監視カメラ: プレイヤーが監視地点${i + 1}に現れた';
        _emitMatchEvent(type: 'camera_spotted', message: msg, position: p);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(msg)));
      }
    }
  }

  void _evaluateFakeSkillTimer() {
    if (!_fakePositionActive || _fakePositionEndsAt == null) return;
    if (DateTime.now().isAfter(_fakePositionEndsAt!)) {
      _fakePositionActive = false;
      _fakePositionEndsAt = null;
      _fakePositionLatLng = null;
      _emitMatchEvent(
        type: 'fake_end',
        message: '偽位置スキルが終了',
        position: _currentPosition,
      );
      setState(() {
        _statusMessage = '偽位置スキル終了';
      });
    }
  }

  void _evaluateSkillTimers() {
    final now = DateTime.now();
    if (_werewolfTransformEndsAt != null &&
        now.isAfter(_werewolfTransformEndsAt!)) {
      _werewolfTransformEndsAt = null;
      _emitMatchEvent(
        type: 'werewolf_transform_end',
        message: '人狼の一時鬼化が終了',
        position: _currentPosition,
      );
    }
    if (_captureZoneEndsAt != null && now.isAfter(_captureZoneEndsAt!)) {
      _captureZoneCenter = null;
      _captureZoneEndsAt = null;
      _captureZoneBoundIds = const {};
      _captureZoneTargetLeftAt = null;
      _captureZoneEscapeRevealed = false;
      _emitMatchEvent(
        type: 'capture_zone_end',
        message: '捕獲結界が終了',
        position: _currentPosition,
      );
    }
    if (_captureZoneCenter != null && _captureZoneBoundIds.contains('self')) {
      final d = Geolocator.distanceBetween(
        _currentPosition.latitude,
        _currentPosition.longitude,
        _captureZoneCenter!.latitude,
        _captureZoneCenter!.longitude,
      );
      if (d > GameConfig.captureZoneRadiusMeters) {
        _captureZoneTargetLeftAt ??= now;
        if (now.difference(_captureZoneTargetLeftAt!).inSeconds >= 8) {
          _endGame(GameState.caughtByOni, '捕獲結界から長時間離脱しました。');
        } else if (!_captureZoneEscapeRevealed) {
          _captureZoneEscapeRevealed = true;
          _emitLocationReveal(
            type: 'capture_zone_escape',
            message: '捕獲結界から離脱して位置暴露',
          );
        }
      } else {
        _captureZoneTargetLeftAt = null;
        _captureZoneEscapeRevealed = false;
      }
    }
    if (_bodyThrowEndsAt != null && now.isAfter(_bodyThrowEndsAt!)) {
      _emitLocationReveal(type: 'body_throw_miss', message: '体投げ未回収で位置暴露');
      _bodyThrowPosition = null;
      _bodyThrowEndsAt = null;
    }
  }

  bool get _isInfectedNow =>
      _infectionEndsAt != null && DateTime.now().isBefore(_infectionEndsAt!);

  void _evaluateScaledTouchLock(double gpsDistance) {
    if (_gameState != GameState.running) return;
    if (!_testMode && !_remoteOniKnown && !_isHunterNow) return;
    if (_captureZoneBoundIds.contains('self')) return;

    final radius = _scaledTouchRadiusMeters();
    final now = DateTime.now();
    if (gpsDistance > radius) {
      _touchLockStartedAt = null;
      _touchLockNoticeShown = false;
      return;
    }

    _touchLockStartedAt ??= now;
    final heldSeconds = now.difference(_touchLockStartedAt!).inSeconds;
    if (!_touchLockNoticeShown &&
        heldSeconds >= GameConfig.touchLockRunnerNoticeSeconds) {
      _touchLockNoticeShown = true;
      setState(() {
        _statusMessage = '鬼の接触圏に入りました。離脱してください。';
      });
    }

    if (heldSeconds < GameConfig.touchLockRequiredSeconds) return;

    setState(() {
      _captureZoneCenter = _currentPosition;
      _captureZoneBoundIds = const {'self'};
      _captureZoneTargetLeftAt = null;
      _captureZoneEscapeRevealed = false;
      _captureZoneEndsAt = now.add(
        const Duration(seconds: GameConfig.touchLockDurationSeconds),
      );
      _touchLockStartedAt = null;
      _touchLockNoticeShown = false;
      _statusMessage = '鬼に捕捉され、移動範囲が制限されました。BLE接触で捕獲。';
    });
    _emitMatchEvent(
      type: 'touch_lock_start',
      message: 'エリア連動タッチ範囲 ${radius.toStringAsFixed(0)}m 内に一定時間入り、捕獲結界状態',
      position: _currentPosition,
    );
    HapticFeedback.mediumImpact();
  }

  bool _isCaptureTriggered() {
    if (_gameState != GameState.running) return false;
    if (!_testMode && !_remoteOniKnown && !_isHunterNow) return false;
    final isLocked = _captureZoneBoundIds.contains('self');
    if (isLocked && _latestProximityBand == ProximityBand.contact) {
      return true;
    }
    return false;
  }

  double _scaledTouchRadiusMeters() {
    final areaRadius = _effectivePlayAreaRadiusMeters();
    final scaled = areaRadius * GameConfig.scaledTouchRadiusAreaRatio;
    return scaled.clamp(
      GameConfig.scaledTouchRadiusMinMeters,
      GameConfig.scaledTouchRadiusMaxMeters,
    );
  }

  double _effectivePlayAreaRadiusMeters() {
    switch (_playArea.type) {
      case PlayAreaType.circle:
        return _playArea.radiusMeters;
      case PlayAreaType.polygon:
        if (_playArea.points.isEmpty) return GameConfig.playAreaRadiusMeters;
        final center = _polygonCenter(_playArea.points);
        var maxDistance = GameConfig.playAreaRadiusMeters;
        for (final p in _playArea.points) {
          maxDistance = math.max(
            maxDistance,
            Geolocator.distanceBetween(
              center.latitude,
              center.longitude,
              p.latitude,
              p.longitude,
            ),
          );
        }
        return maxDistance;
    }
  }

  LatLng _polygonCenter(List<LatLng> points) {
    final lat =
        points.map((p) => p.latitude).reduce((a, b) => a + b) / points.length;
    final lng =
        points.map((p) => p.longitude).reduce((a, b) => a + b) / points.length;
    return LatLng(lat, lng);
  }

  double _distanceToOni() {
    if (!_testMode && !_remoteOniKnown) {
      return double.infinity;
    }
    return Geolocator.distanceBetween(
      _currentPosition.latitude,
      _currentPosition.longitude,
      _oniPosition.latitude,
      _oniPosition.longitude,
    );
  }

  bool get _showGimmickMapMarkers =>
      _testMode || _gameState == GameState.running;

  bool get _showOniMarker => _testMode || _remoteOniKnown;

  double _effectiveInfectionDistance(double gpsDistance) {
    if (_latestProximityBand == ProximityBand.contact) {
      return 0;
    }
    if (_latestProximityBand == ProximityBand.near) {
      return gpsDistance - 10;
    }
    return gpsDistance;
  }

  void _evaluateInfection(double distanceToOni) {
    if (_isInfectedNow) {
      final now = DateTime.now();
      if (_lastInfectionRevealAt == null ||
          now.difference(_lastInfectionRevealAt!).inSeconds >=
              GameConfig.infectionRevealIntervalSeconds) {
        _lastInfectionRevealAt = now;
        final ev = LocationRevealEvent(
          sequence: _revealCount + 1,
          timestamp: now,
          position: _positionForReveal,
          overflowMeters: 0,
        );
        _revealCount += 1;
        _revealLog.insert(0, ev);
        if (_revealLog.length > 50) _revealLog.removeLast();
        _emitMatchEvent(
          type: 'infection_reveal',
          message: '感染露出パルス',
          position: _positionForReveal,
        );
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('感染反応: 位置が断続的に露出しています')));
      }
      return;
    }

    if (distanceToOni <= GameConfig.infectionTriggerDistanceMeters) {
      _infectionExposureSeconds += 1;
      if (_infectionExposureSeconds >= GameConfig.infectionExposureSeconds) {
        _infectionEndsAt = DateTime.now().add(
          const Duration(seconds: GameConfig.infectionDurationSeconds),
        );
        _infectionExposureSeconds = 0;
        _lastInfectionRevealAt = null;
        _emitMatchEvent(
          type: 'infection_start',
          message: '感染状態に入った',
          position: _currentPosition,
        );
        setState(() {
          _statusMessage = '感染状態: 一時的に位置露出が増加';
        });
      }
    } else {
      _infectionExposureSeconds = 0;
    }
  }

  void _activateFakeSkill() {
    if (_gameState != GameState.running) {
      _toast('ゲーム中のみ使えます');
      return;
    }
    if (!_skillLoadout.contains(SkillIds.fakePosition)) return;
    final now = DateTime.now();
    if (_lastFakeSkillAt != null &&
        now.difference(_lastFakeSkillAt!).inSeconds <
            GameConfig.fakeSkillCooldownSeconds) {
      final remain =
          GameConfig.fakeSkillCooldownSeconds -
          now.difference(_lastFakeSkillAt!).inSeconds;
      _toast('偽位置スキル再使用まで $remain 秒');
      return;
    }
    _lastFakeSkillAt = now;
    _fakePositionActive = true;
    _fakePositionEndsAt = now.add(
      const Duration(seconds: GameConfig.fakeSkillDurationSeconds),
    );
    _fakePositionLatLng = LatLng(
      _currentPosition.latitude + 0.0012,
      _currentPosition.longitude - 0.0011,
    );
    _emitMatchEvent(
      type: 'fake_start',
      message: '偽位置スキル発動',
      position: _fakePositionLatLng!,
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
    if (_lastWerewolfTransformAt != null &&
        now.difference(_lastWerewolfTransformAt!).inSeconds <
            GameConfig.werewolfTransformCooldownSeconds) {
      return;
    }
    _lastWerewolfTransformAt = now;
    _werewolfTransformEndsAt = now.add(
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
    if (_gameState != GameState.running) return;
    if (!_skillLoadout.contains(SkillIds.fakeIntelReveal)) return;
    final self = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('偽情報暴露'),
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
      ),
    );
    if (self == null) return;
    final p = self
        ? LatLng(
            _currentPosition.latitude + 0.0007,
            _currentPosition.longitude - 0.0005,
          )
        : _randomOtherRevealPoint();
    _emitMatchEvent(
      type: 'accidental_reveal',
      message: self ? '事故風の位置暴露（自分）' : '事故風の位置暴露（他人）',
      position: p,
    );
    setState(() => _statusMessage = '自然な事故イベント風に位置暴露を偽装しました');
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
    if (_lastCaptureZoneAt != null &&
        now.difference(_lastCaptureZoneAt!).inSeconds <
            GameConfig.captureZoneCooldownSeconds) {
      return;
    }
    _lastCaptureZoneAt = now;
    setState(() {
      _waitingCaptureZoneTap = true;
      _statusMessage = '地図タップ地点に捕獲結界を設置';
    });
  }

  void _activateBodyThrow() {
    if (_gameState != GameState.running) return;
    if (!_skillLoadout.contains(SkillIds.bodyThrow)) return;
    final now = DateTime.now();
    if (_lastBodyThrowAt != null &&
        now.difference(_lastBodyThrowAt!).inSeconds <
            GameConfig.bodyThrowCooldownSeconds) {
      return;
    }
    _lastBodyThrowAt = now;
    _bodyThrowPosition = LatLng(
      _currentPosition.latitude,
      _currentPosition.longitude +
          GameConfig.bodyThrowDistanceMeters /
              (111111 * math.cos(_currentPosition.latitude * math.pi / 180)),
    );
    _bodyThrowEndsAt = now.add(
      const Duration(seconds: GameConfig.bodyThrowDurationSeconds),
    );
    _emitMatchEvent(
      type: 'body_throw_start',
      message: '体投げ発動',
      position: _bodyThrowPosition!,
    );
    setState(() => _statusMessage = '体投げ発動中');
  }

  void _emitMatchEvent({
    required String type,
    required String message,
    required LatLng position,
  }) {
    final event = MatchEvent(
      type: type,
      atUtc: DateTime.now().toUtc(),
      message: message,
      position: position,
    );
    _matchEvents.insert(0, event);
    if (_matchEvents.length > 120) {
      _matchEvents.removeLast();
    }
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

  void _clearTracePoints() {
    if (_tracePoints.isEmpty && _revealLog.isEmpty && _oniIntelTraces.isEmpty) {
      _toast('痕跡はありません');
      return;
    }
    setState(() {
      _tracePoints.clear();
      _revealLog.clear();
      _oniIntelTraces.clear();
      _statusMessage = '痕跡をクリアしました';
    });
  }

  Iterable<LocationRevealEvent> _recentRevealTraces() {
    final cutoff = DateTime.now().subtract(const Duration(minutes: 3));
    return _revealLog.where((e) => e.timestamp.isAfter(cutoff)).take(12);
  }

  Iterable<_OniIntelTrace> _recentOniIntelTraces() {
    final cutoff = DateTime.now().subtract(const Duration(minutes: 10));
    return _oniIntelTraces.where((e) => e.timestamp.isAfter(cutoff)).take(12);
  }

  String _latestIntelLine() {
    final text = _lastOniIntelText;
    final at = _lastOniIntelAt;
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
    if (_captureZoneBoundIds.contains('self') && _captureZoneEndsAt != null) {
      return '捕捉ロック中: 残り ${_secondsUntil(_captureZoneEndsAt)}秒 / BLE接触で捕獲';
    }
    if (_touchLockNoticeShown && _touchLockStartedAt != null) {
      final held = DateTime.now().difference(_touchLockStartedAt!).inSeconds;
      final remain = (GameConfig.touchLockRequiredSeconds - held).clamp(0, 99);
      return '接触圏内: あと $remain秒以内に離脱';
    }
    if (_isInfectedNow) {
      return '感染中 (${_secondsUntil(_infectionEndsAt)}秒)';
    }
    return '異常なし';
  }

  String _formatTraceAge(DateTime timestamp) {
    final ageSeconds = DateTime.now().difference(timestamp).inSeconds;
    if (ageSeconds < 60) return '$ageSeconds秒前の暴露地点';
    return '${ageSeconds ~/ 60}分前の暴露地点';
  }

  String _formatIntelTraceAge(DateTime timestamp) {
    final ageSeconds = DateTime.now().difference(timestamp).inSeconds;
    if (ageSeconds < 60) return '$ageSeconds秒前の鬼情報';
    return '${ageSeconds ~/ 60}分前の鬼情報';
  }

  String _formatLatLng(LatLng p) {
    return '${p.latitude.toStringAsFixed(5)}, ${p.longitude.toStringAsFixed(5)}';
  }

  String get _localPlayerLabel {
    final fs = _roomSession is FirestoreRoomSession
        ? _roomSession as FirestoreRoomSession
        : null;
    final name = fs?.nickname?.trim();
    return name == null || name.isEmpty ? 'player1' : name;
  }

  String _bearingToDirection(double bearing) {
    final b = (bearing + 360) % 360;
    if (b >= 337.5 || b < 22.5) return '北';
    if (b < 67.5) return '北東';
    if (b < 112.5) return '東';
    if (b < 157.5) return '南東';
    if (b < 202.5) return '南';
    if (b < 247.5) return '南西';
    if (b < 292.5) return '西';
    return '北西';
  }

  bool _isInsideCommJammingZone() {
    return _firstPointWithin(
          _commJammingZonePositions,
          GameConfig.commJammingZoneRadiusMeters,
        ) !=
        null;
  }

  bool _isCommJammingOpenNow() {
    if (!_isInsideCommJammingZone()) return true;
    final bucket = (_elapsedSeconds ~/ GameConfig.commJammingCycleSeconds) % 2;
    return bucket == 0;
  }

  /// 断片モード用。16 方位ではなく大まかな寄りだけに落とす。
  String _fragmentedCoarseCardinal(double bearingDegrees) {
    final b = (bearingDegrees + 360) % 360;
    if (b >= 315 || b < 45) return '北寄り';
    if (b < 135) return '東寄り';
    if (b < 225) return '南寄り';
    return '西寄り';
  }

  String _buildOniIntel({
    required String direction,
    required String distanceBand,
    required double bearingDegrees,
  }) {
    if (!_isCommJammingOpenNow()) {
      return '通信障害: ノイズ混入（情報欠落）';
    }

    switch (_oniIntelMode) {
      case OniIntelMode.directionOnly:
        return '鬼は $direction 方向';
      case OniIntelMode.distanceBandOnly:
        return '鬼の距離帯: $distanceBand';
      case OniIntelMode.fragmented:
        final phase =
            (_elapsedSeconds ~/ GameConfig.fragmentedPhaseSeconds) % 5;
        final coarse = _fragmentedCoarseCardinal(bearingDegrees);
        switch (phase) {
          case 0:
            return '断片: 信号途切れ — 方角・距離とも取得不能';
          case 1:
            return '断片: 粗い方角のみ — $coarse（精密方位は非表示）';
          case 2:
            return '断片: ノイズ帯 — このウィンドウは情報ロック';
          case 3:
            return '断片: 距離帯のみ — $distanceBand（方角は伏せられています）';
          case 4:
          default:
            return '断片: 同期ズレ — 次のウィンドウまで欠落';
        }
    }
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

  void _maybeTriggerDangerFeedback(double currentDistance) {
    if (!_touchLockNoticeShown && !_captureZoneBoundIds.contains('self')) {
      _lastDistance = currentDistance;
      return;
    }
    if (_lastDistance == null) {
      _lastDistance = currentDistance;
      return;
    }
    final warningDistance = _scaledTouchRadiusMeters();
    final dangerDistance = GameConfig.captureDistanceMeters;
    final wasSafe = _lastDistance! > warningDistance;
    final isWarning = currentDistance <= warningDistance;
    final isDanger = currentDistance <= dangerDistance;

    if (wasSafe && isWarning) {
      _emitOniCue(level: 'warning');
      _logDebug('danger_warning_enter');
    }
    if (_lastDistance! > dangerDistance && isDanger) {
      _emitOniCue(level: 'danger');
      _logDebug('danger_close_enter');
    }
    _lastDistance = currentDistance;
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

  String _formatTime(int seconds) {
    final min = (seconds ~/ 60).toString().padLeft(2, '0');
    final sec = (seconds % 60).toString().padLeft(2, '0');
    return '$min:$sec';
  }

  Offset _clampControlFabOffset(Offset? raw, Size screenSize) {
    const fabWidth = 132.0;
    const fabHeight = 64.0;
    final fallback = Offset(16, math.max(96, screenSize.height - 190));
    final next = raw ?? fallback;
    return Offset(
      next.dx.clamp(8.0, math.max(8, screenSize.width - fabWidth)),
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
        return '円エリア · 半径 ${_playArea.radiusMeters.toStringAsFixed(0)} m';
      case PlayAreaType.polygon:
        return '多角形エリア · ${_playArea.points.length} 頂点';
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
        _waitingCircleCenterTap = false;
        _statusMessage = '編集を終了しました';
      }
    });
  }

  Future<void> _applyEditedArea() async {
    try {
      late final PlayArea next;
      if (_editCircleMode) {
        next = PlayArea.circle(
          center: _circleDraftCenter,
          radiusMeters: _circleDraftRadiusMeters,
        );
      } else {
        if (_polygonDraft.length < 3) {
          _toast('多角形は3点以上必要です');
          return;
        }
        next = PlayArea.polygon(points: List.from(_polygonDraft));
      }
      await _areaStore.save(next);
      if (!mounted) return;
      setState(() {
        _playArea = next;
        _editingArea = false;
        _waitingCircleCenterTap = false;
        _statusMessage = 'プレイエリアを保存しました';
      });
    } catch (e) {
      _toast('保存に失敗しました: $e');
    }
  }

  void _onMapTap(LatLng pos) {
    if (_waitingCaptureZoneTap) {
      final now = DateTime.now();
      final d = Geolocator.distanceBetween(
        _currentPosition.latitude,
        _currentPosition.longitude,
        pos.latitude,
        pos.longitude,
      );
      setState(() {
        _waitingCaptureZoneTap = false;
        _captureZoneCenter = pos;
        _captureZoneBoundIds = _captureZoneTargetsAt(pos, d);
        _captureZoneTargetLeftAt = null;
        _captureZoneEscapeRevealed = false;
        _captureZoneEndsAt = now.add(
          const Duration(seconds: GameConfig.captureZoneDurationSeconds),
        );
        _statusMessage = '捕獲結界を設置しました';
      });
      _emitMatchEvent(
        type: 'capture_zone_start',
        message: '捕獲結界を設置',
        position: pos,
      );
      return;
    }
    if (!_editingArea) return;
    setState(() {
      if (_editCircleMode && _waitingCircleCenterTap) {
        _circleDraftCenter = pos;
        _waitingCircleCenterTap = false;
        _statusMessage = '円の中心を設定しました';
      } else if (!_editCircleMode) {
        _polygonDraft.add(pos);
        _statusMessage = '頂点 ${_polygonDraft.length} 点目';
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
      _statusMessage = '頂点を1つ戻しました（${_polygonDraft.length}点）';
    });
  }

  void _clearPolygonDraft() {
    setState(() {
      _polygonDraft.clear();
      _statusMessage = '頂点をクリアしました';
    });
  }

  Future<void> _showImportGeoJsonDialog() async {
    final controller = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('GeoJSON を取り込み'),
        content: SingleChildScrollView(
          child: TextField(
            controller: controller,
            maxLines: 12,
            decoration: const InputDecoration(
              hintText: 'Feature / FeatureCollection / Polygon を貼り付け',
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('キャンセル'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('取り込み'),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    try {
      final area = PlayArea.fromGeoJsonString(controller.text.trim());
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
    } finally {
      controller.dispose();
    }
  }

  Future<void> _exportGeoJson() async {
    final raw = _playArea.toGeoJsonFeatureString();
    await Clipboard.setData(ClipboardData(text: raw));
    if (!mounted) return;
    _toast('GeoJSON をクリップボードにコピーしました');
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(16),
        child: SelectableText(raw, style: const TextStyle(fontSize: 12)),
      ),
    );
  }

  Future<void> _copyDiscordStatusSummary() async {
    final lines = [
      '**Oni Game 状況共有**',
      '- 状態: ${_gameState.label}',
      '- ルーム: ${_roomSession.modeLabel}',
      '- エリア: ${_playAreaSummary()}',
      '- 役職: ${_localRole.displayName}${_isHunterNow && _localRole != PlayerRole.hunter ? "（一時鬼化中）" : ""}',
      '- スキル: ${_skillLoadout.map(_skillLabel).join(" / ")}',
      '- 残り時間: ${_formatTime(_remainingSeconds)}',
      '- 位置暴露: $_revealCount 回',
      '- 情報屋: ${_lastOniIntelText == null ? "未取得" : _latestIntelLine()}',
      '- ギミック: 安全地帯 ${_safeZonePositions.length} / 情報屋 ${_infoBrokerPositions.length} / カメラ ${_cameraPositions.length} / イベント ${_commJammingZonePositions.length}',
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
          if (_revealLog.isEmpty) const Text('まだありません'),
          for (final e in _revealLog)
            ListTile(
              dense: true,
              title: Text(
                '${e.playerLabel} #${e.sequence}  +${e.overflowMeters.toStringAsFixed(0)}m',
              ),
              subtitle: Text(
                '${e.timestamp.toIso8601String()}\n${_formatLatLng(e.position)}',
              ),
            ),
        ],
      ),
    );
  }

  Set<Marker> _buildMarkers() {
    final revealTraces = _recentRevealTraces().toList(growable: false);
    final oniIntelTraces = _recentOniIntelTraces().toList(growable: false);
    final markers = <Marker>{
      Marker(
        markerId: const MarkerId('player'),
        position: _playerMarkerPosition,
        infoWindow: const InfoWindow(title: 'あなた', snippet: '現在地'),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
      ),
      if (_showOniMarker)
        Marker(
          markerId: const MarkerId('oni'),
          position: _oniPosition,
          infoWindow: InfoWindow(
            title: '鬼',
            snippet: _remoteOniKnown ? 'オンライン同期' : 'テスト／デモ',
          ),
        ),
      for (final e in _remoteMembers.entries)
        Marker(
          markerId: MarkerId('remote_${e.key}'),
          position: LatLng(e.value.lat, e.value.lng),
          infoWindow: InfoWindow(
            title: e.value.nickname.isEmpty ? '参加者' : e.value.nickname,
            snippet: '${e.value.role} (online)',
          ),
          icon: BitmapDescriptor.defaultMarkerWithHue(switch (e.value.role) {
            'oni' => BitmapDescriptor.hueRose,
            'spectator' => BitmapDescriptor.hueAzure,
            _ => BitmapDescriptor.hueMagenta,
          }),
        ),
    };

    if (_showGimmickMapMarkers) {
      markers.addAll({
        for (var i = 0; i < _safeZonePositions.length; i++)
          Marker(
            markerId: MarkerId('safe_zone_marker_$i'),
            position: _safeZonePositions[i],
            infoWindow: InfoWindow(
              title: '安全地帯 ${i + 1}',
              snippet: _safeZoneAvailable
                  ? 'チャージ獲得地点'
                  : '再出現まで ${_secondsUntil(_safeZoneRespawnAt)} 秒',
            ),
            icon: BitmapDescriptor.defaultMarkerWithHue(
              BitmapDescriptor.hueGreen,
            ),
          ),
        for (var i = 0; i < _infoBrokerPositions.length; i++)
          Marker(
            markerId: MarkerId('info_broker_marker_$i'),
            position: _infoBrokerPositions[i],
            infoWindow: InfoWindow(
              title: '情報屋 ${i + 1}',
              snippet: _infoBrokerAvailable
                  ? '鬼の方角ヒント'
                  : '再出現まで ${_secondsUntil(_infoBrokerRespawnAt)} 秒',
            ),
            icon: BitmapDescriptor.defaultMarkerWithHue(
              BitmapDescriptor.hueViolet,
            ),
          ),
        for (var i = 0; i < _commJammingZonePositions.length; i++)
          Marker(
            markerId: MarkerId('comm_jamming_zone_marker_$i'),
            position: _commJammingZonePositions[i],
            infoWindow: InfoWindow(
              title: '通信障害地帯 ${i + 1}',
              snippet: '情報が断片化する',
            ),
            icon: BitmapDescriptor.defaultMarkerWithHue(
              BitmapDescriptor.hueOrange,
            ),
          ),
        for (var i = 0; i < _tracePoints.length; i++)
          Marker(
            markerId: MarkerId('trace_$i'),
            position: _tracePoints[i],
            infoWindow: const InfoWindow(title: '痕跡', snippet: '脱落地点の痕跡'),
            icon: BitmapDescriptor.defaultMarkerWithHue(
              BitmapDescriptor.hueCyan,
            ),
          ),
        for (var i = 0; i < revealTraces.length; i++)
          Marker(
            markerId: MarkerId('reveal_trace_$i'),
            position: revealTraces[i].position,
            infoWindow: InfoWindow(
              title:
                  '${revealTraces[i].playerLabel} の位置暴露 #${revealTraces[i].sequence}',
              snippet:
                  '${_formatTraceAge(revealTraces[i].timestamp)} / ${_formatLatLng(revealTraces[i].position)}',
            ),
            icon: BitmapDescriptor.defaultMarkerWithHue(
              BitmapDescriptor.hueViolet,
            ),
          ),
        for (var i = 0; i < oniIntelTraces.length; i++)
          Marker(
            markerId: MarkerId('oni_intel_trace_$i'),
            position: oniIntelTraces[i].position,
            infoWindow: InfoWindow(
              title: '情報屋の鬼情報',
              snippet:
                  '${_formatIntelTraceAge(oniIntelTraces[i].timestamp)} / ${oniIntelTraces[i].text}',
            ),
            icon: BitmapDescriptor.defaultMarkerWithHue(
              BitmapDescriptor.hueRed,
            ),
          ),
        for (var i = 0; i < _cameraPositions.length; i++)
          Marker(
            markerId: MarkerId('camera_$i'),
            position: _cameraPositions[i],
            infoWindow: InfoWindow(
              title: '監視カメラ ${i + 1}',
              snippet: _triggeredCameras.contains(i) ? '作動済み' : '未作動',
            ),
            icon: BitmapDescriptor.defaultMarkerWithHue(
              BitmapDescriptor.hueYellow,
            ),
          ),
      });
    }

    if (_fakePositionActive && _fakePositionLatLng != null) {
      markers.add(
        Marker(
          markerId: const MarkerId('fake_position'),
          position: _fakePositionLatLng!,
          infoWindow: const InfoWindow(title: '偽位置', snippet: 'デコイ発信中'),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRose),
        ),
      );
    }
    if (_bodyThrowPosition != null) {
      markers.add(
        Marker(
          markerId: const MarkerId('body_throw_position'),
          position: _bodyThrowPosition!,
          infoWindow: const InfoWindow(title: '体投げ', snippet: '判定位置'),
          icon: BitmapDescriptor.defaultMarkerWithHue(
            BitmapDescriptor.hueOrange,
          ),
        ),
      );
    }

    if (_afterCatchRule != null) {
      final rough = _buildGhostRoughPositions();
      final rule = _afterCatchRule!;
      final hue = rule == EliminationAftermathRule.joinOni
          ? BitmapDescriptor.hueRed
          : BitmapDescriptor.hueAzure;
      final title = rule == EliminationAftermathRule.joinOni ? '鬼側索敵' : '幽霊視点';
      final snippet = rule == EliminationAftermathRule.joinOni
          ? 'ざっくり位置（鬼合流）'
          : 'ざっくり位置（中立）';
      for (var i = 0; i < rough.length; i++) {
        markers.add(
          Marker(
            markerId: MarkerId('spectator_rough_$i'),
            position: rough[i],
            infoWindow: InfoWindow(title: title, snippet: snippet),
            icon: BitmapDescriptor.defaultMarkerWithHue(hue),
          ),
        );
      }
    }

    if (_editingArea && !_editCircleMode) {
      for (var i = 0; i < _polygonDraft.length; i++) {
        markers.add(
          Marker(
            markerId: MarkerId('draft_v_$i'),
            position: _polygonDraft[i],
            infoWindow: InfoWindow(title: '頂点', snippet: '${i + 1}'),
            icon: BitmapDescriptor.defaultMarkerWithHue(
              BitmapDescriptor.hueGreen,
            ),
          ),
        );
      }
    }

    if (_editingArea && _editCircleMode) {
      markers.add(
        Marker(
          markerId: const MarkerId('circle_center'),
          position: _circleDraftCenter,
          infoWindow: const InfoWindow(title: '円の中心', snippet: '編集中'),
          icon: BitmapDescriptor.defaultMarkerWithHue(
            BitmapDescriptor.hueViolet,
          ),
        ),
      );
    }

    return markers;
  }

  List<LatLng> _buildGhostRoughPositions() {
    final base = [
      _currentPosition,
      _oniPosition,
      for (final p in _cameraPositions) p,
    ];
    return base.asMap().entries.map((e) {
      final p = e.value;
      final shift = (e.key + 1) * 0.0006;
      return LatLng(p.latitude + shift, p.longitude - shift);
    }).toList();
  }

  Set<Polyline> _buildPolylines() {
    if (!_editingArea || _editCircleMode || _polygonDraft.length < 2) {
      return {};
    }
    return {
      Polyline(
        polylineId: const PolylineId('draft_polyline'),
        points: _polygonDraft,
        width: 3,
        color: Colors.deepOrange,
      ),
    };
  }

  List<LatLng> _closedPolygonPoints(List<LatLng> points) {
    if (points.length < 3) return points;
    final first = points.first;
    final last = points.last;
    if (first.latitude == last.latitude && first.longitude == last.longitude) {
      return points;
    }
    return [...points, first];
  }

  Set<Circle> _buildCircles(WorldProfileTokens tokens) {
    final revealTraces = _recentRevealTraces().toList(growable: false);
    final oniIntelTraces = _recentOniIntelTraces().toList(growable: false);
    final circles = <Circle>{
      for (var i = 0; i < _safeZonePositions.length; i++)
        Circle(
          circleId: CircleId('safe-zone-$i'),
          center: _safeZonePositions[i],
          radius: GameConfig.safeZoneRadiusMeters,
          strokeWidth: 2,
          fillColor: tokens.safeColor.withValues(
            alpha: _safeZoneAvailable ? 0.12 : 0.04,
          ),
          strokeColor: tokens.safeColor,
          zIndex: 1,
        ),
      for (var i = 0; i < _infoBrokerPositions.length; i++)
        Circle(
          circleId: CircleId('info-broker-$i'),
          center: _infoBrokerPositions[i],
          radius: GameConfig.infoBrokerRadiusMeters,
          strokeWidth: 2,
          fillColor: tokens.infoColor.withValues(
            alpha: _infoBrokerAvailable ? 0.12 : 0.04,
          ),
          strokeColor: tokens.infoColor,
          zIndex: 1,
        ),
      for (var i = 0; i < _commJammingZonePositions.length; i++)
        Circle(
          circleId: CircleId('comm-jamming-zone-$i'),
          center: _commJammingZonePositions[i],
          radius: GameConfig.commJammingZoneRadiusMeters,
          strokeWidth: 2,
          fillColor: Colors.orange.withValues(alpha: 0.12),
          strokeColor: Colors.orange.shade700,
          zIndex: 1,
        ),
      for (var i = 0; i < _tracePoints.length; i++)
        Circle(
          circleId: CircleId('trace_circle_$i'),
          center: _tracePoints[i],
          radius: 18,
          strokeWidth: 1,
          fillColor: Colors.cyan.withValues(alpha: 0.2),
          strokeColor: Colors.cyan.shade700,
          zIndex: 2,
        ),
      for (var i = 0; i < revealTraces.length; i++)
        Circle(
          circleId: CircleId('reveal_trace_circle_$i'),
          center: revealTraces[i].position,
          radius: 24,
          strokeWidth: 1,
          fillColor: Colors.deepPurple.withValues(alpha: 0.16),
          strokeColor: Colors.deepPurple.shade700,
          zIndex: 2,
        ),
      for (var i = 0; i < oniIntelTraces.length; i++)
        Circle(
          circleId: CircleId('oni_intel_trace_circle_$i'),
          center: oniIntelTraces[i].position,
          radius: 30,
          strokeWidth: 2,
          fillColor: Colors.red.withValues(alpha: 0.12),
          strokeColor: Colors.red.shade700,
          zIndex: 3,
        ),
      if (_captureZoneCenter != null)
        Circle(
          circleId: const CircleId('capture-zone'),
          center: _captureZoneCenter!,
          radius: GameConfig.captureZoneRadiusMeters,
          strokeWidth: 3,
          fillColor: Colors.red.withValues(alpha: 0.16),
          strokeColor: Colors.red.shade700,
          zIndex: 12,
        ),
    };

    if (_playArea.type == PlayAreaType.circle && !_editingArea) {
      circles.add(
        Circle(
          circleId: const CircleId('play-area'),
          center: _playArea.center,
          radius: _playArea.radiusMeters,
          strokeWidth: 4,
          fillColor: Colors.blue.withValues(alpha: 0.16),
          strokeColor: Colors.blue.shade600,
          zIndex: 10,
        ),
      );
    }

    if (_editingArea && _editCircleMode) {
      circles.add(
        Circle(
          circleId: const CircleId('draft-circle'),
          center: _circleDraftCenter,
          radius: _circleDraftRadiusMeters,
          strokeWidth: 4,
          fillColor: Colors.purple.withValues(alpha: 0.22),
          strokeColor: Colors.purple.shade700,
          zIndex: 20,
        ),
      );
    }
    return circles;
  }

  Set<Polygon> _buildPolygons() {
    if (!_editingArea && _playArea.type == PlayAreaType.polygon) {
      return {
        Polygon(
          polygonId: const PolygonId('play-area-poly'),
          points: _closedPolygonPoints(_playArea.points),
          strokeWidth: 4,
          strokeColor: Colors.blue.shade600,
          fillColor: Colors.blue.withValues(alpha: 0.16),
          zIndex: 10,
        ),
      };
    }
    if (_editingArea && !_editCircleMode && _polygonDraft.length >= 3) {
      return {
        Polygon(
          polygonId: const PolygonId('draft-poly-preview'),
          points: _closedPolygonPoints(_polygonDraft),
          strokeWidth: 4,
          strokeColor: Colors.deepOrange.shade600,
          fillColor: Colors.deepOrange.withValues(alpha: 0.22),
          zIndex: 20,
        ),
      };
    }
    return {};
  }

  int _secondsUntil(DateTime? target) {
    if (target == null) return 0;
    final diff = target.difference(DateTime.now()).inSeconds;
    return diff < 0 ? 0 : diff;
  }

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

  void _toggleMenuCollapsed() {
    setState(() {
      _menuCollapsed = !_menuCollapsed;
    });
  }

  Future<void> _openCustomMenu() async {
    if (_gameState == GameState.running) {
      _toast('ゲーム中はカスタム設定を変更できません');
      return;
    }
    WorldProfile selectedProfile = _activeProfile;
    OniIntelMode selectedIntel = _oniIntelMode;
    bool selectedConsent = _trajectoryConsent;
    EliminationAftermathRule selectedElimination = _eliminationAftermathRule;
    PlayerRole selectedRole = _localRole;
    bool selectedCustomRuleMode = _customRuleMode;
    double selectedDurationMinutes = _matchDurationSeconds / 60;
    final selectedSkills = Set<String>.from(_skillLoadout);
    final prefs0 = await SharedPreferences.getInstance();
    if (!mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    var selectedUseBle = prefs0.getBool(_kUseBleScanPrefKey) ?? false;
    final roomController = TextEditingController();
    final nickController = TextEditingController(text: 'player1');
    var firebaseWarmScheduled = false;

    bool? ok;
    try {
      ok = await showModalBottomSheet<bool>(
        context: context,
        showDragHandle: true,
        isScrollControlled: true,
        builder: (ctx) {
          return StatefulBuilder(
            builder: (ctx, setModalState) {
              final screenH = MediaQuery.sizeOf(ctx).height;
              final kb = MediaQuery.viewInsetsOf(ctx).bottom;
              final sheetH = (screenH * 0.86 - kb).clamp(280.0, screenH * 0.92);
              if (!firebaseWarmScheduled) {
                firebaseWarmScheduled = true;
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  unawaited(
                    FirebaseBootstrap.tryInit().then((_) {
                      if (ctx.mounted) setModalState(() {});
                    }),
                  );
                });
              }
              return Padding(
                padding: EdgeInsets.only(
                  left: 16,
                  right: 16,
                  top: 8,
                  bottom: 16 + kb,
                ),
                child: SizedBox(
                  height: sheetH,
                  child: SingleChildScrollView(
                    physics: const ClampingScrollPhysics(),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'カスタム設定',
                          style: Theme.of(ctx).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 10),

                        DropdownButtonFormField<WorldProfile>(
                          initialValue: selectedProfile,
                          decoration: const InputDecoration(labelText: '世界観'),
                          items: WorldProfile.values
                              .map(
                                (p) => DropdownMenuItem(
                                  value: p,
                                  child: Text(p.label),
                                ),
                              )
                              .toList(),
                          onChanged: (v) {
                            if (v == null) return;
                            setModalState(() => selectedProfile = v);
                          },
                        ),

                        const SizedBox(height: 10),

                        DropdownButtonFormField<OniIntelMode>(
                          initialValue: selectedIntel,
                          decoration: InputDecoration(
                            labelText: '鬼情報モード',
                            helperText:
                                '「断片」は約${GameConfig.fragmentedPhaseSeconds}秒ごとにフェーズが変わり、方位・距離が周期欠落します。',
                            helperMaxLines: 3,
                          ),
                          items: OniIntelMode.values
                              .map(
                                (m) => DropdownMenuItem(
                                  value: m,
                                  child: Text(m.label),
                                ),
                              )
                              .toList(),
                          onChanged: (v) {
                            if (v == null) return;
                            setModalState(() => selectedIntel = v);
                          },
                        ),

                        const SizedBox(height: 10),

                        DropdownButtonFormField<PlayerRole>(
                          initialValue: selectedRole,
                          decoration: const InputDecoration(
                            labelText: 'ローカル役職',
                            helperText: 'カスタム公開ルールON時だけ固定されます',
                          ),
                          items: _assignableRoles
                              .map(
                                (r) => DropdownMenuItem(
                                  value: r,
                                  child: Text(r.displayName),
                                ),
                              )
                              .toList(),
                          onChanged: selectedCustomRuleMode
                              ? (v) {
                                  if (v == null) return;
                                  setModalState(() {
                                    selectedRole = v;
                                    selectedSkills
                                      ..clear()
                                      ..addAll(
                                        _skillCandidates(
                                          v,
                                        ).take(v == PlayerRole.hunter ? 2 : 1),
                                      );
                                  });
                                }
                              : null,
                        ),

                        Wrap(
                          spacing: 8,
                          children: [
                            for (final s in _skillCandidates(selectedRole))
                              FilterChip(
                                label: Text(_skillLabel(s)),
                                selected: selectedSkills.contains(s),
                                onSelected: selectedCustomRuleMode
                                    ? (v) {
                                        setModalState(() {
                                          if (v) {
                                            if (selectedRole !=
                                                PlayerRole.hunter) {
                                              selectedSkills.clear();
                                            }
                                            if (selectedRole ==
                                                    PlayerRole.hunter &&
                                                selectedSkills.length >= 2) {
                                              selectedSkills.remove(
                                                selectedSkills.first,
                                              );
                                            }
                                            selectedSkills.add(s);
                                          } else {
                                            selectedSkills.remove(s);
                                          }
                                        });
                                      }
                                    : null,
                              ),
                          ],
                        ),

                        const SizedBox(height: 10),

                        SwitchListTile(
                          contentPadding: EdgeInsets.zero,
                          title: const Text('カスタム公開ルール'),
                          subtitle: const Text('オフ時は開始時に役職/スキル/ルールを秘密ランダム割当'),
                          value: selectedCustomRuleMode,
                          onChanged: (v) =>
                              setModalState(() => selectedCustomRuleMode = v),
                        ),
                        Text('制限時間: ${selectedDurationMinutes.round()} 分'),
                        Slider(
                          min: 1,
                          max: 20,
                          divisions: 19,
                          value: selectedDurationMinutes.clamp(1, 20),
                          onChanged: (v) =>
                              setModalState(() => selectedDurationMinutes = v),
                        ),

                        const SizedBox(height: 10),

                        DropdownButtonFormField<EliminationAftermathRule>(
                          initialValue: selectedElimination,
                          decoration: const InputDecoration(
                            labelText: '脱落後ルール（ルーム設定）',
                          ),
                          items: EliminationAftermathRule.values
                              .map(
                                (r) => DropdownMenuItem(
                                  value: r,
                                  child: Text(r.label),
                                ),
                              )
                              .toList(),
                          onChanged: (v) {
                            if (v == null) return;
                            setModalState(() => selectedElimination = v);
                          },
                        ),

                        const SizedBox(height: 10),

                        SwitchListTile(
                          contentPadding: EdgeInsets.zero,
                          title: const Text('実機 BLE スキャン（近接推定）'),
                          subtitle: const Text(
                            'オフ時はモック BLE。Android では Bluetooth 権限が必要です。',
                          ),
                          value: selectedUseBle,
                          onChanged: (v) =>
                              setModalState(() => selectedUseBle = v),
                        ),

                        ExpansionTile(
                          initiallyExpanded: true,
                          tilePadding: EdgeInsets.zero,
                          title: const Text('オンラインルーム（Firestore）'),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                FirebaseBootstrap.isReady
                                    ? '接続済み · 下のボタンでルームに参加できます'
                                    : '未接続 · 「参加」で Firebase を再初期化します',
                                style: Theme.of(ctx).textTheme.bodySmall,
                              ),
                              Text(
                                'まだ誰も使っていないルームIDで参加すると、Firestore に rooms と members が作成されます。',
                                style: Theme.of(ctx).textTheme.bodySmall
                                    ?.copyWith(
                                      fontSize: 11,
                                      color: Theme.of(
                                        ctx,
                                      ).colorScheme.onSurfaceVariant,
                                    ),
                              ),
                            ],
                          ),
                          children: [
                            if (!FirebaseBootstrap.isReady &&
                                FirebaseBootstrap.lastErrorBrief != null)
                              Padding(
                                padding: const EdgeInsets.only(bottom: 8),
                                child: SelectableText(
                                  FirebaseBootstrap.lastErrorBrief!,
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Theme.of(ctx).colorScheme.error,
                                  ),
                                ),
                              ),
                            TextField(
                              controller: roomController,
                              textInputAction: TextInputAction.next,
                              decoration: const InputDecoration(
                                labelText: 'ルームID',
                                hintText: '例: demo-room-1',
                                border: OutlineInputBorder(),
                                isDense: true,
                              ),
                            ),
                            const SizedBox(height: 8),
                            TextField(
                              controller: nickController,
                              textInputAction: TextInputAction.done,
                              decoration: const InputDecoration(
                                labelText: '表示名',
                                border: OutlineInputBorder(),
                                isDense: true,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Expanded(
                                  child: FilledButton(
                                    style: FilledButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 14,
                                      ),
                                    ),
                                    onPressed: () async {
                                      FocusScope.of(ctx).unfocus();
                                      await FirebaseBootstrap.tryInit();
                                      if (!ctx.mounted) return;
                                      setModalState(() {});
                                      if (!FirebaseBootstrap.isReady) {
                                        messenger.showSnackBar(
                                          SnackBar(
                                            content: Text(
                                              'Firebase に接続できません。\n\n'
                                              '1) android/app/google-services.json を配置してフル再ビルド\n'
                                              '2) または dart-define で FIREBASE_* を指定\n\n'
                                              '${FirebaseBootstrap.lastErrorBrief ?? ""}',
                                            ),
                                            behavior: SnackBarBehavior.floating,
                                            margin: const EdgeInsets.fromLTRB(
                                              16,
                                              0,
                                              16,
                                              220,
                                            ),
                                            duration: const Duration(
                                              seconds: 10,
                                            ),
                                          ),
                                        );
                                        return;
                                      }
                                      final rid = roomController.text.trim();
                                      final nick = nickController.text.trim();
                                      if (rid.isEmpty || nick.isEmpty) {
                                        messenger.showSnackBar(
                                          const SnackBar(
                                            behavior: SnackBarBehavior.floating,
                                            margin: EdgeInsets.fromLTRB(
                                              16,
                                              0,
                                              16,
                                              220,
                                            ),
                                            content: Text('ルームIDと表示名を入力してください'),
                                          ),
                                        );
                                        return;
                                      }
                                      showDialog<void>(
                                        context: ctx,
                                        barrierDismissible: false,
                                        useRootNavigator: true,
                                        builder: (dCtx) => const AlertDialog(
                                          content: Row(
                                            children: [
                                              CircularProgressIndicator(),
                                              SizedBox(width: 16),
                                              Expanded(
                                                child: Text('ルームに参加しています…'),
                                              ),
                                            ],
                                          ),
                                        ),
                                      );
                                      String? err;
                                      try {
                                        err = await _joinFirestoreRoom(
                                          roomId: rid,
                                          nickname: nick,
                                          role: 'runner',
                                        );
                                      } finally {
                                        if (ctx.mounted) {
                                          Navigator.of(
                                            ctx,
                                            rootNavigator: true,
                                          ).pop();
                                        }
                                      }
                                      if (!ctx.mounted) return;
                                      if (err != null) {
                                        messenger.showSnackBar(
                                          SnackBar(
                                            content: Text(err),
                                            behavior: SnackBarBehavior.floating,
                                            margin: const EdgeInsets.fromLTRB(
                                              16,
                                              0,
                                              16,
                                              220,
                                            ),
                                            duration: const Duration(
                                              seconds: 10,
                                            ),
                                          ),
                                        );
                                      } else {
                                        await showDialog<void>(
                                          context: ctx,
                                          builder: (dCtx) => AlertDialog(
                                            icon: Icon(
                                              Icons.check_circle,
                                              color: Theme.of(
                                                dCtx,
                                              ).colorScheme.primary,
                                              size: 40,
                                            ),
                                            title: const Text('ルームに接続しました'),
                                            content: SingleChildScrollView(
                                              child: Text(
                                                'ルームID「$rid」への参加が完了しました。\n\n'
                                                'Firestore では次のパスにメンバーが作成されています。\n'
                                                'rooms / $rid / members / （あなたの UID）\n\n'
                                                'このシートの「適用」で閉じたあと、地図画面で「開始」から鬼ごっこを始められます。',
                                              ),
                                            ),
                                            actions: [
                                              FilledButton(
                                                onPressed: () =>
                                                    Navigator.pop(dCtx),
                                                child: const Text('OK'),
                                              ),
                                            ],
                                          ),
                                        );
                                      }
                                      if (ctx.mounted) setModalState(() {});
                                    },
                                    child: const Text('ルームに参加'),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: OutlinedButton(
                                    style: OutlinedButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 14,
                                      ),
                                    ),
                                    onPressed: () async {
                                      FocusScope.of(ctx).unfocus();
                                      await _leaveFirestoreRoom();
                                      if (!ctx.mounted) return;
                                      setModalState(() {});
                                      messenger.showSnackBar(
                                        const SnackBar(
                                          behavior: SnackBarBehavior.floating,
                                          margin: EdgeInsets.fromLTRB(
                                            16,
                                            0,
                                            16,
                                            220,
                                          ),
                                          content: Text('オフラインに戻しました'),
                                        ),
                                      );
                                    },
                                    child: const Text('退出'),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),

                        const SizedBox(height: 10),

                        SwitchListTile(
                          contentPadding: EdgeInsets.zero,
                          title: const Text('軌跡を端末保存（同意）'),
                          value: selectedConsent,
                          onChanged: (v) =>
                              setModalState(() => selectedConsent = v),
                        ),

                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: Icon(
                            Icons.nightlight_round,
                            color: Theme.of(ctx).colorScheme.primary,
                          ),
                          title: const Text('鬼ロール・鬼向け通知'),
                          subtitle: const Text(
                            'AppBar の「鬼コンソール」アイコンから設定します（バイブ・サウンド等）。',
                          ),
                        ),

                        const SizedBox(height: 10),

                        Wrap(
                          spacing: 8,
                          children: [
                            OutlinedButton.icon(
                              onPressed: () {
                                Navigator.pop(ctx, false);
                                _setupLocation();
                              },
                              icon: const Icon(Icons.gps_fixed),
                              label: const Text('現在地更新'),
                            ),

                            OutlinedButton.icon(
                              onPressed: () {
                                Navigator.pop(ctx, false);
                                _moveOniForTest();
                              },
                              icon: const Icon(Icons.directions_run),
                              label: const Text('鬼移動(テスト)'),
                            ),

                            OutlinedButton.icon(
                              onPressed: () {
                                Navigator.pop(ctx, false);
                                _clearTracePoints();
                              },
                              icon: const Icon(Icons.cleaning_services),
                              label: const Text('痕跡クリア'),
                            ),
                          ],
                        ),

                        const SizedBox(height: 10),

                        Align(
                          alignment: Alignment.centerRight,
                          child: FilledButton(
                            onPressed: () => Navigator.pop(ctx, true),
                            child: const Text('適用'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      );
    } finally {
      roomController.dispose();
      nickController.dispose();
    }

    if (ok != true) return;
    setState(() {
      _activeProfile = selectedProfile;
      _oniIntelMode = selectedIntel;
      _eliminationAftermathRule = selectedElimination;
      _customRuleMode = selectedCustomRuleMode;
      _matchDurationSeconds = selectedDurationMinutes.round() * 60;
      if (_customRuleMode) {
        _localRole = selectedRole;
        _skillLoadout = selectedSkills.isEmpty
            ? _skillCandidates(_localRole).take(1).toSet()
            : selectedSkills;
      }
    });
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _kEliminationAftermathPrefKey,
      selectedElimination.name,
    );
    await prefs.setBool(_kUseBleScanPrefKey, selectedUseBle);
    await _reloadProximityStackFromPrefs();
    if (_trajectoryConsent != selectedConsent) {
      await _setTrajectoryConsent(selectedConsent);
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
    final pulse = _isInfectedNow ? 0.25 : 0.0;
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
    if (!await _confirmLeaveActiveMatch('ルームロビーへ移動しますか？')) return;
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

  void _hideMapToPrep() {
    if (_gameState != GameState.waiting || _editingArea) {
      _toast('地図を隠せるのは準備中のみです');
      return;
    }
    setState(() {
      _mapVisibleInLobby = false;
      _prepControlSheetOpen = true;
      _statusMessage = '準備画面に切り替えました';
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

  void _showHowToPlaySheet() {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (ctx) => ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text('遊び方', style: Theme.of(ctx).textTheme.titleLarge),
          const SizedBox(height: 12),
          const ListTile(
            leading: Icon(Icons.flag_outlined),
            title: Text('流れ'),
            subtitle: Text(
              'タイトル → ルーム/エリア/ルール設定 → 開始 → 役職/スキル確認 → 試合 → 結果 → 軌跡再生',
            ),
          ),
          const ListTile(
            leading: Icon(Icons.visibility_off_outlined),
            title: Text('基本ルール'),
            subtitle: Text('通常はライブ位置を見せません。位置暴露・情報屋・イベント・スキルで情報が出ます。'),
          ),
          const ListTile(
            leading: Icon(Icons.shield_outlined),
            title: Text('安全地帯'),
            subtitle: Text('ステルスチャージを得て、装備中スキルの再使用待ちを回復します。使用後は移動します。'),
          ),
          const ListTile(
            leading: Icon(Icons.storefront_outlined),
            title: Text('情報屋'),
            subtitle: Text('鬼情報を一時的に取得します。手に入れた情報はマップ上に10分ほど痕跡として残ります。'),
          ),
          const ListTile(
            leading: Icon(Icons.videocam_outlined),
            title: Text('監視カメラ'),
            subtitle: Text('小さい罠です。踏むとイベントログに残り、逃走中のルート選びに影響します。'),
          ),
          const ListTile(
            leading: Icon(Icons.front_hand_outlined),
            title: Text('捕獲'),
            subtitle: Text('鬼の接触圏に一定時間入るとロックされ、ロック中にBLE接触すると捕獲です。'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    SchedulerBinding.instance.removeTimingsCallback(_onFrameTimings);
    WidgetsBinding.instance.removeObserver(this);
    _positionSubscription?.cancel();
    _proximitySubscription?.cancel();
    _remoteMembersSub?.cancel();
    _matchTimer?.cancel();
    _renderPump?.cancel();
    _dangerPulseController.dispose();
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
    final showBottomControlSheet = running || _prepControlSheetOpen;
    final showGameMap =
        _editingArea || _mapVisibleInLobby || _gameState != GameState.waiting;
    final appTitle = switch (_gameState) {
      GameState.waiting => 'Oni Game · 準備',
      GameState.running => 'Oni Game · プレイ中',
      GameState.runnerWin => 'Oni Game · 逃走成功',
      GameState.caughtByOni => 'Oni Game · 捕獲',
    };

    return Scaffold(
      appBar: AppBar(
        title: Text(appTitle),
        actions: [
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
          if (_gameState == GameState.waiting &&
              !_editingArea &&
              _mapVisibleInLobby)
            TextButton.icon(
              onPressed: _hideMapToPrep,
              icon: const Icon(Icons.dashboard_outlined, size: 18),
              label: const Text('Map off'),
            ),
          PopupMenuButton<String>(
            tooltip: 'More',
            onSelected: (value) async {
              switch (value) {
                case 'discord':
                  await _copyDiscordStatusSummary();
                  break;
                case 'help':
                  _showHowToPlaySheet();
                  break;
                case 'oni':
                  await Navigator.of(context).push<void>(
                    MaterialPageRoute<void>(
                      builder: (_) => const OniOperatorScreen(),
                    ),
                  );
                  await _loadOniOperatorPrefs();
                  break;
                case 'hide_map':
                  _hideMapToPrep();
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
                    MaterialPageRoute<void>(
                      builder: (_) => const PrivacyControlScreen(),
                    ),
                  );
                  break;
                case 'test':
                  _toggleTestMode();
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
              }
            },
            itemBuilder: (ctx) => [
              const PopupMenuItem(
                value: 'help',
                child: ListTile(
                  leading: Icon(Icons.help_outline),
                  title: Text('How to play'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              const PopupMenuItem(
                value: 'oni',
                child: ListTile(
                  leading: Icon(Icons.nightlight_round),
                  title: Text('Oni settings'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              const PopupMenuItem(
                value: 'discord',
                child: ListTile(
                  leading: Icon(Icons.chat_bubble_outline),
                  title: Text('Discord用メモをコピー'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              PopupMenuItem(
                value: 'hide_map',
                enabled:
                    _gameState == GameState.waiting &&
                    !_editingArea &&
                    _mapVisibleInLobby,
                child: const ListTile(
                  leading: Icon(Icons.dashboard_outlined),
                  title: Text('Map off / Setup'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              const PopupMenuItem(
                value: 'gallery',
                child: ListTile(
                  leading: Icon(Icons.movie_filter_outlined),
                  title: Text('試合ギャラリー'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              const PopupMenuItem(
                value: 'history',
                child: ListTile(
                  leading: Icon(Icons.history),
                  title: Text('位置暴露ログ'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              const PopupMenuItem(
                value: 'privacy',
                child: ListTile(
                  leading: Icon(Icons.privacy_tip_outlined),
                  title: Text('プライバシー管理'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              PopupMenuItem(
                value: 'test',
                child: ListTile(
                  leading: Icon(
                    _testMode ? Icons.bug_report : Icons.bug_report_outlined,
                  ),
                  title: Text(_testMode ? 'テストモードをOFF' : 'テストモードをON'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              const PopupMenuDivider(),
              PopupMenuItem(
                value: 'import',
                enabled: _gameState != GameState.running,
                child: const ListTile(
                  leading: Icon(Icons.upload_file_outlined),
                  title: Text('GeoJSON インポート'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              const PopupMenuItem(
                value: 'export',
                child: ListTile(
                  leading: Icon(Icons.copy_outlined),
                  title: Text('GeoJSON エクスポート'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ],
          ),
        ],
      ),
      body: Stack(
        children: [
          if (showGameMap)
            GoogleMap(
              initialCameraPosition: CameraPosition(
                target: _currentPosition,
                zoom: 16,
              ),
              myLocationEnabled: true,
              myLocationButtonEnabled: !_editingArea,
              markers: _buildMarkers(),
              polylines: _buildPolylines(),
              circles: _buildCircles(tokens),
              polygons: _buildPolygons(),
              onTap: _onMapTap,
              onMapCreated: (controller) {
                _mapController = controller;
              },
            )
          else
            _PrepLobbyPanel(
              roomLabel: _roomSession.modeLabel,
              playAreaLabel: _playAreaSummary(),
              onShowMap: () => setState(() {
                _mapVisibleInLobby = true;
                _statusMessage = '地図を表示しました。エリア編集や開始ができます。';
              }),
              onOpenLobby: _openRoomLobby,
            ),
          if (showGameMap && _gameState == GameState.running)
            Positioned.fill(
              child: IgnorePointer(
                child: AnimatedBuilder(
                  animation: _dangerPulseController,
                  builder: (_, child) {
                    final level =
                        (_dangerPulseController.value * 0.35) +
                        (_isInfectedNow ? 0.20 : 0.0);
                    return Container(
                      decoration: BoxDecoration(
                        gradient: RadialGradient(
                          center: const Alignment(0, -0.2),
                          radius: 1.0,
                          colors: [
                            Colors.red.withValues(alpha: level),
                            Colors.transparent,
                          ],
                        ),
                      ),
                      child: child,
                    );
                  },
                ),
              ),
            ),
          if (_testMode)
            Positioned(
              top: 120,
              right: 12,
              child: _DiagnosticsCard(
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
              child: _MatchOutcomeBanner(
                outcome: _gameState,
                detail: _statusMessage,
                roleSummary:
                    '$_localPlayerLabel / ${_localRole.displayName} / ${_skillLoadout.map(_skillLabel).join("・")}',
                onPrepareNext: _resetGame,
                onOpenGallery: _openMatchGallery,
                onOpenLobby: _openRoomLobby,
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
              child: _InfoPanel(
                intelLine: _latestIntelLine(),
                showIntelLine: _showOniIntelCard,
                onDismissIntel: () => setState(() {
                  _showOniIntelCard = false;
                }),
                timerText: _formatTime(_remainingSeconds),
                gameStateText: _gameState.label,
                statusText: _statusMessage,
                areaText: isOutBeyondGrace
                    ? '猶予超過: +${overflowMeters.toStringAsFixed(0)}m'
                    : 'エリア内（またはGPS猶予内）',
                areaColor: isOutBeyondGrace
                    ? Colors.red.shade700
                    : Colors.green.shade700,
                revealCount: _revealCount,
                editing: _editingArea,
                safeZoneCharges: _safeZoneCharges,
                conditionText: _conditionLine(),
                spectatorLine: _afterCatchRule?.infoPanelLine,
              ),
            ),
          if (running && _remainingSeconds <= 10)
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
                      _remainingSeconds.clamp(0, 10).toString(),
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
          if (_editingArea)
            Positioned(
              left: 12,
              right: 12,
              bottom: 200,
              child: _AreaEditorCard(
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
                vertexCount: _polygonDraft.length,
                onApply: _applyEditedArea,
                onCancel: () => setState(() {
                  _editingArea = false;
                  _waitingCircleCenterTap = false;
                  _polygonDraft.clear();
                  _statusMessage = '編集をキャンセルしました';
                }),
              ),
            ),
          if (showBottomControlSheet)
            Positioned(
              bottom: 16,
              left: 16,
              right: 16,
              child: GestureDetector(
                onVerticalDragEnd: (details) {
                  if (details.primaryVelocity == null) return;
                  if (details.primaryVelocity! > 180) {
                    if (!_menuCollapsed) _toggleMenuCollapsed();
                  } else if (details.primaryVelocity! < -180) {
                    if (_menuCollapsed) _toggleMenuCollapsed();
                  }
                },
                child: AnimatedSlide(
                  duration: const Duration(milliseconds: 220),
                  offset: _menuCollapsed ? const Offset(0, 0.74) : Offset.zero,
                  child: _ControlPanel(
                    onStart: _startGame,
                    onReset: _resetGame,
                    onFakeSkill: _activateFakeSkill,
                    onFakeIntelReveal: _activateFakeIntelReveal,
                    onWerewolfHunter: _activateWerewolfHunter,
                    onCaptureZone: _activateCaptureZone,
                    onBodyThrow: _activateBodyThrow,
                    onAbortVote: _requestAbortByVote,
                    onToggleAreaEdit: _toggleAreaEditor,
                    onToggleCollapsed: _toggleMenuCollapsed,
                    onOpenCustomMenu: _openCustomMenu,
                    onOpenHelp: _showHowToPlaySheet,
                    onDismissPrepSheet: () => setState(() {
                      _prepControlSheetOpen = false;
                    }),
                    isRunning: running,
                    canStartMatch: _gameState == GameState.waiting,
                    isEditing: _editingArea,
                    fakeSkillActive: _fakePositionActive,
                    roleLabel: _isHunterNow ? '鬼' : _localRole.displayName,
                    canFakeSkill: _skillLoadout.contains(SkillIds.fakePosition),
                    canFakeIntelReveal: _skillLoadout.contains(
                      SkillIds.fakeIntelReveal,
                    ),
                    canWerewolfHunter: _skillLoadout.contains(
                      SkillIds.werewolfTransform,
                    ),
                    canCaptureZone: _skillLoadout.contains(
                      SkillIds.captureZone,
                    ),
                    canBodyThrow: _skillLoadout.contains(SkillIds.bodyThrow),
                    menuCollapsed: _menuCollapsed,
                    prepLobbyMapHidden:
                        _gameState == GameState.waiting && !showGameMap,
                  ),
                ),
              ),
            )
          else
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
                    onPressed: () =>
                        setState(() => _prepControlSheetOpen = true),
                    icon: const Icon(Icons.tune),
                    label: const Text('操作'),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _MatchOutcomeBanner extends StatelessWidget {
  const _MatchOutcomeBanner({
    required this.outcome,
    required this.detail,
    required this.roleSummary,
    required this.onPrepareNext,
    required this.onOpenGallery,
    required this.onOpenLobby,
  });

  final GameState outcome;
  final String detail;
  final String roleSummary;
  final VoidCallback onPrepareNext;
  final VoidCallback onOpenGallery;
  final VoidCallback onOpenLobby;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final (IconData icon, String title) = switch (outcome) {
      GameState.runnerWin => (Icons.emoji_events_outlined, '逃走成功'),
      GameState.caughtByOni => (Icons.front_hand_outlined, '捕獲'),
      _ => (Icons.flag_outlined, '試合終了'),
    };

    return Material(
      elevation: 4,
      borderRadius: BorderRadius.circular(12),
      color: theme.colorScheme.surfaceContainerHigh,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 32, color: theme.colorScheme.primary),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(detail, style: theme.textTheme.bodySmall),
                  const SizedBox(height: 4),
                  Text(
                    '開示: $roleSummary',
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '次はリザルト確認、軌跡再生、またはルームロビーへ戻れます。',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              direction: Axis.vertical,
              children: [
                FilledButton(
                  onPressed: onPrepareNext,
                  child: const Text('Next setup'),
                ),
                OutlinedButton(
                  onPressed: onOpenGallery,
                  child: const Text('Replay'),
                ),
                OutlinedButton(
                  onPressed: onOpenLobby,
                  child: const Text('Lobby'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _PrepLobbyPanel extends StatelessWidget {
  const _PrepLobbyPanel({
    required this.roomLabel,
    required this.playAreaLabel,
    required this.onShowMap,
    required this.onOpenLobby,
  });

  final String roomLabel;
  final String playAreaLabel;
  final VoidCallback onShowMap;
  final VoidCallback onOpenLobby;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: theme.colorScheme.surfaceContainerHighest,
      child: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.map_outlined,
                    size: 52,
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    '準備（地図は非表示）',
                    style: theme.textTheme.headlineSmall,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'ルーム参加やカスタム設定はこのまま下部パネルから行えます。鬼ごっこを始めると地図が表示されます。',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Wrap(
                    alignment: WrapAlignment.center,
                    spacing: 6,
                    runSpacing: 6,
                    children: const [
                      Chip(label: Text('1 Setup')),
                      Chip(label: Text('2 Start')),
                      Chip(label: Text('3 Role')),
                      Chip(label: Text('4 Play')),
                      Chip(label: Text('5 Result')),
                      Chip(label: Text('6 Replay/Lobby')),
                    ],
                  ),
                  const SizedBox(height: 28),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Icon(
                      Icons.groups_outlined,
                      color: theme.colorScheme.primary,
                    ),
                    title: const Text('オンライン'),
                    subtitle: Text(roomLabel),
                  ),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Icon(
                      Icons.crop_free,
                      color: theme.colorScheme.primary,
                    ),
                    title: const Text('プレイエリア'),
                    subtitle: Text(playAreaLabel),
                  ),
                  const SizedBox(height: 20),
                  FilledButton.icon(
                    onPressed: onOpenLobby,
                    icon: const Icon(Icons.groups_outlined),
                    label: const Text('ルームロビーを開く'),
                  ),
                  const SizedBox(height: 10),
                  OutlinedButton.icon(
                    onPressed: onShowMap,
                    icon: const Icon(Icons.map),
                    label: const Text('地図を表示する'),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    '位置確認・エリア編集・GeoJSON インポートには地図が必要です。下部の「エリア編集」を押しても地図が開きます。',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _InfoPanel extends StatelessWidget {
  const _InfoPanel({
    required this.intelLine,
    required this.showIntelLine,
    required this.onDismissIntel,
    required this.timerText,
    required this.gameStateText,
    required this.statusText,
    required this.areaText,
    required this.areaColor,
    required this.revealCount,
    required this.editing,
    required this.safeZoneCharges,
    required this.conditionText,
    required this.spectatorLine,
  });

  final String intelLine;
  final bool showIntelLine;
  final VoidCallback onDismissIntel;
  final String timerText;
  final String gameStateText;
  final String statusText;
  final String areaText;
  final Color areaColor;
  final int revealCount;
  final bool editing;
  final int safeZoneCharges;
  final String conditionText;
  final String? spectatorLine;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.84),
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [
          BoxShadow(color: Colors.black26, blurRadius: 6, offset: Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 4,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Chip(
                label: Text(editing ? 'エリア編集中' : gameStateText),
                visualDensity: VisualDensity.compact,
              ),
              Text(
                timerText,
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              Text('暴露 $revealCount / ステルス $safeZoneCharges'),
            ],
          ),
          if (showIntelLine) ...[
            const SizedBox(height: 6),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    intelLine,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                IconButton(
                  tooltip: '鬼情報をしまう',
                  visualDensity: VisualDensity.compact,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(
                    minWidth: 32,
                    minHeight: 32,
                  ),
                  onPressed: onDismissIntel,
                  icon: const Icon(Icons.close, size: 18),
                ),
              ],
            ),
          ],
          const SizedBox(height: 2),
          Text(conditionText, style: Theme.of(context).textTheme.bodySmall),
          if (spectatorLine != null) ...[
            const SizedBox(height: 4),
            Text(spectatorLine!, style: Theme.of(context).textTheme.bodySmall),
          ],
          const SizedBox(height: 4),
          Text(
            statusText,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 6),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 10),
            decoration: BoxDecoration(
              color: areaColor,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              areaText,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AreaEditorCard extends StatelessWidget {
  const _AreaEditorCard({
    required this.editCircleMode,
    required this.onModeChanged,
    required this.circleRadiusMeters,
    required this.onRadiusChanged,
    required this.waitingCenterTap,
    required this.onRequestCenterTap,
    required this.onCenterGps,
    required this.onUndo,
    required this.onClear,
    required this.vertexCount,
    required this.onApply,
    required this.onCancel,
  });

  final bool editCircleMode;
  final ValueChanged<bool> onModeChanged;
  final double circleRadiusMeters;
  final ValueChanged<double> onRadiusChanged;
  final bool waitingCenterTap;
  final VoidCallback onRequestCenterTap;
  final VoidCallback onCenterGps;
  final VoidCallback onUndo;
  final VoidCallback onClear;
  final int vertexCount;
  final VoidCallback onApply;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    return Material(
      elevation: 6,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('プレイエリア編集', style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 8),
            SegmentedButton<bool>(
              segments: const [
                ButtonSegment(value: true, label: Text('円')),
                ButtonSegment(value: false, label: Text('多角形')),
              ],
              emptySelectionAllowed: false,
              selected: {editCircleMode},
              onSelectionChanged: (s) {
                if (s.isNotEmpty) onModeChanged(s.first);
              },
            ),
            const SizedBox(height: 12),
            if (editCircleMode) ...[
              Text('半径: ${circleRadiusMeters.toStringAsFixed(0)} m'),
              Slider(
                min: 50,
                max: 2000,
                divisions: 79,
                value: circleRadiusMeters.clamp(50, 2000),
                onChanged: onRadiusChanged,
              ),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  OutlinedButton.icon(
                    onPressed: onCenterGps,
                    icon: const Icon(Icons.my_location),
                    label: const Text('中心=現在地'),
                  ),
                  FilledButton.tonalIcon(
                    onPressed: onRequestCenterTap,
                    icon: const Icon(Icons.touch_app),
                    label: Text(waitingCenterTap ? 'タップ待ち…' : '中心を地図タップ'),
                  ),
                ],
              ),
            ] else ...[
              Text('頂点数: $vertexCount（地図をタップで追加）'),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  OutlinedButton.icon(
                    onPressed: onUndo,
                    icon: const Icon(Icons.undo),
                    label: const Text('戻す'),
                  ),
                  OutlinedButton.icon(
                    onPressed: onClear,
                    icon: const Icon(Icons.clear_all),
                    label: const Text('クリア'),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: FilledButton(
                    onPressed: onApply,
                    child: const Text('保存して適用'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton(
                    onPressed: onCancel,
                    child: const Text('キャンセル'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ControlPanel extends StatelessWidget {
  const _ControlPanel({
    required this.onStart,
    required this.onReset,
    required this.onFakeSkill,
    required this.onFakeIntelReveal,
    required this.onWerewolfHunter,
    required this.onCaptureZone,
    required this.onBodyThrow,
    required this.onAbortVote,
    required this.onToggleAreaEdit,
    required this.onToggleCollapsed,
    required this.onOpenCustomMenu,
    required this.onOpenHelp,
    required this.onDismissPrepSheet,
    required this.isRunning,
    required this.canStartMatch,
    required this.isEditing,
    required this.fakeSkillActive,
    required this.roleLabel,
    required this.canFakeSkill,
    required this.canFakeIntelReveal,
    required this.canWerewolfHunter,
    required this.canCaptureZone,
    required this.canBodyThrow,
    required this.menuCollapsed,
    required this.prepLobbyMapHidden,
  });

  final VoidCallback onStart;
  final VoidCallback onReset;
  final VoidCallback onFakeSkill;
  final VoidCallback onFakeIntelReveal;
  final VoidCallback onWerewolfHunter;
  final VoidCallback onCaptureZone;
  final VoidCallback onBodyThrow;
  final VoidCallback onAbortVote;
  final VoidCallback onToggleAreaEdit;
  final VoidCallback onToggleCollapsed;
  final VoidCallback onOpenCustomMenu;
  final VoidCallback onOpenHelp;
  final VoidCallback onDismissPrepSheet;
  final bool isRunning;
  final bool canStartMatch;
  final bool isEditing;
  final bool fakeSkillActive;
  final String roleLabel;
  final bool canFakeSkill;
  final bool canFakeIntelReveal;
  final bool canWerewolfHunter;
  final bool canCaptureZone;
  final bool canBodyThrow;
  final bool menuCollapsed;
  final bool prepLobbyMapHidden;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [
          BoxShadow(color: Colors.black26, blurRadius: 8, offset: Offset(0, 3)),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (!isRunning)
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: onDismissPrepSheet,
                icon: const Icon(Icons.expand_more, size: 20),
                label: const Text('操作パネルを閉じる'),
              ),
            ),
          Center(
            child: IconButton(
              onPressed: onToggleCollapsed,
              icon: Icon(
                menuCollapsed
                    ? Icons.keyboard_arrow_up
                    : Icons.keyboard_arrow_down,
              ),
              visualDensity: VisualDensity.compact,
            ),
          ),
          if (prepLobbyMapHidden) ...[
            Text(
              '準備フェーズ（地図はオフ）',
              textAlign: TextAlign.center,
              style: Theme.of(
                context,
              ).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 6),
          ],
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 220),
            switchInCurve: Curves.easeOutCubic,
            switchOutCurve: Curves.easeInCubic,
            child: isRunning
                ? Wrap(
                    key: const ValueKey('in_game_controls'),
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      if (canFakeSkill)
                        FilledButton.tonalIcon(
                          onPressed: !isEditing ? onFakeSkill : null,
                          icon: const Icon(Icons.flare),
                          label: Text(fakeSkillActive ? '偽位置: 作動中' : '偽位置'),
                        ),
                      if (canFakeIntelReveal)
                        OutlinedButton.icon(
                          onPressed: !isEditing ? onFakeIntelReveal : null,
                          icon: const Icon(Icons.report),
                          label: const Text('偽情報暴露'),
                        ),
                      if (canWerewolfHunter)
                        OutlinedButton.icon(
                          onPressed: !isEditing ? onWerewolfHunter : null,
                          icon: const Icon(Icons.nightlight),
                          label: const Text('鬼化'),
                        ),
                      if (canCaptureZone)
                        OutlinedButton.icon(
                          onPressed: !isEditing ? onCaptureZone : null,
                          icon: const Icon(Icons.trip_origin),
                          label: const Text('捕獲結界'),
                        ),
                      if (canBodyThrow)
                        OutlinedButton.icon(
                          onPressed: !isEditing ? onBodyThrow : null,
                          icon: const Icon(Icons.near_me),
                          label: const Text('体投げ'),
                        ),
                      Chip(label: Text('役職: $roleLabel')),
                      OutlinedButton.icon(
                        onPressed: onOpenHelp,
                        icon: const Icon(Icons.help_outline),
                        label: const Text('遊び方'),
                      ),
                      OutlinedButton.icon(
                        onPressed: onAbortVote,
                        icon: const Icon(Icons.how_to_vote_outlined),
                        label: const Text('中止提案'),
                      ),
                      OutlinedButton.icon(
                        onPressed: onReset,
                        icon: const Icon(Icons.stop_circle_outlined),
                        label: const Text('強制リセット'),
                      ),
                    ],
                  )
                : Wrap(
                    key: const ValueKey('pre_game_controls'),
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      FilledButton.icon(
                        onPressed: (isEditing || !canStartMatch)
                            ? null
                            : onStart,
                        icon: const Icon(Icons.play_arrow),
                        label: const Text('開始'),
                      ),
                      OutlinedButton.icon(
                        onPressed: onReset,
                        icon: const Icon(Icons.restart_alt),
                        label: const Text('リセット'),
                      ),
                      FilledButton.tonalIcon(
                        onPressed: onToggleAreaEdit,
                        icon: Icon(
                          isEditing ? Icons.check_circle : Icons.map_outlined,
                        ),
                        label: Text(isEditing ? '編集閉じる' : 'エリア編集'),
                      ),
                      FilledButton.tonalIcon(
                        onPressed: onOpenCustomMenu,
                        icon: const Icon(Icons.settings),
                        label: const Text('カスタム設定'),
                      ),
                      OutlinedButton.icon(
                        onPressed: onOpenHelp,
                        icon: const Icon(Icons.help_outline),
                        label: const Text('遊び方'),
                      ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}

class _DiagnosticsCard extends StatelessWidget {
  const _DiagnosticsCard({
    required this.fps,
    required this.gpsTier,
    required this.gpsAccuracyLast,
    required this.gpsAccuracyAvg,
    required this.batteryScore,
    required this.timeScale,
    required this.onCycleTimeScale,
    required this.onFlushSync,
    required this.debugLogs,
    required this.queueCount,
    required this.proximityText,
    required this.roomSessionText,
    required this.syncInFlight,
  });

  final double fps;
  final String gpsTier;
  final double? gpsAccuracyLast;
  final double gpsAccuracyAvg;
  final double batteryScore;
  final int timeScale;
  final VoidCallback onCycleTimeScale;
  final VoidCallback onFlushSync;
  final List<String> debugLogs;
  final int queueCount;
  final String proximityText;
  final String roomSessionText;
  final bool syncInFlight;

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 280),
      child: Material(
        color: Colors.black.withValues(alpha: 0.72),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  const Icon(Icons.speed, color: Colors.white, size: 16),
                  const SizedBox(width: 6),
                  const Text(
                    'Test Mode',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  TextButton(
                    onPressed: onCycleTimeScale,
                    child: Text('${timeScale}x'),
                  ),
                  const SizedBox(width: 4),
                  TextButton(
                    onPressed: syncInFlight ? null : onFlushSync,
                    child: Text(syncInFlight ? 'Sync...' : 'Sync'),
                  ),
                ],
              ),
              Text(
                'FPS: ${fps.toStringAsFixed(1)}',
                style: const TextStyle(color: Colors.white),
              ),
              Text(
                'GPS tier: $gpsTier',
                style: const TextStyle(color: Colors.white),
              ),
              Text(
                'GPS精度: last=${gpsAccuracyLast?.toStringAsFixed(1) ?? '-'}m / avg=${gpsAccuracyAvg.toStringAsFixed(1)}m',
                style: const TextStyle(color: Colors.white),
              ),
              Text(
                'Battery score(est): ${batteryScore.toStringAsFixed(1)}',
                style: const TextStyle(color: Colors.white),
              ),
              Text(
                'Offline queue: $queueCount',
                style: const TextStyle(color: Colors.white),
              ),
              Text(proximityText, style: const TextStyle(color: Colors.white)),
              Text(
                'Room: $roomSessionText',
                style: const TextStyle(color: Colors.white70, fontSize: 12),
              ),
              const SizedBox(height: 6),
              const Text(
                'Logs',
                style: TextStyle(color: Colors.white70, fontSize: 12),
              ),
              ...debugLogs
                  .take(4)
                  .map(
                    (e) => Text(
                      e,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white60,
                        fontSize: 11,
                      ),
                    ),
                  ),
            ],
          ),
        ),
      ),
    );
  }
}
