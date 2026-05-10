import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../game/game_config.dart';
import '../game/game_state.dart';
import '../game/location_reveal_event.dart';
import '../game/match_event.dart';
import '../game/oni_intel_mode.dart';
import '../game/play_area.dart';
import '../game/sampling_tier.dart';
import '../map/runner_display_smooth.dart';
import '../services/location_service.dart';
import '../services/match_archive_store.dart';
import '../services/match_recorder.dart';
import '../services/play_area_store.dart';
import '../theme/world_profile.dart';
import '../theme/world_profile_tokens.dart';
import 'match_gallery_screen.dart';

class GameMapScreen extends StatefulWidget {
  const GameMapScreen({required this.profile, super.key});

  final WorldProfile profile;

  @override
  State<GameMapScreen> createState() => _GameMapScreenState();
}

const _kTrajectoryConsentPrefKey = 'trajectory_consent_default';

class _GameMapScreenState extends State<GameMapScreen> {
  final LocationService _locationService = LocationService();
  final PlayAreaStore _areaStore = PlayAreaStore();
  final MatchArchiveStore _matchArchive = MatchArchiveStore();

  GoogleMapController? _mapController;
  StreamSubscription<Position>? _positionSubscription;
  Timer? _matchTimer;
  Timer? _renderPump;

  LocationSamplingTier _gpsTier = LocationSamplingTier.relaxed;
  RunnerDisplaySmoothing? _runnerSmooth;

  LatLng _currentPosition = const LatLng(35.681236, 139.767125);
  LatLng _oniPosition = const LatLng(35.6805, 139.7690);

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

  final LatLng _safeZonePosition = const LatLng(35.6822, 139.7682);
  final LatLng _infoBrokerPosition = const LatLng(35.6804, 139.7657);
  final LatLng _commJammingZonePosition = const LatLng(35.6796, 139.7689);
  int _safeZoneCharges = 0;
  DateTime? _lastSafeChargeAt;
  DateTime? _lastInfoBrokerAt;
  DateTime? _lastPeriodicRevealAt;
  OniIntelMode _oniIntelMode = OniIntelMode.directionOnly;
  bool _safeZoneAvailable = true;
  bool _infoBrokerAvailable = true;
  DateTime? _safeZoneRespawnAt;
  DateTime? _infoBrokerRespawnAt;
  final List<LatLng> _cameraPositions = const [
    LatLng(35.6817, 139.7661),
    LatLng(35.6800, 139.7696),
  ];
  final Set<int> _triggeredCameras = <int>{};
  bool _fakePositionActive = false;
  DateTime? _fakePositionEndsAt;
  DateTime? _lastFakeSkillAt;
  LatLng? _fakePositionLatLng;

  MatchRecorder? _matchRecorder;
  bool _trajectoryConsent = false;

  @override
  void initState() {
    super.initState();
    _setupLocation();
    Future<void>.microtask(_loadTrajectoryConsent);
    _renderPump = Timer.periodic(const Duration(milliseconds: 52), (_) {
      _pulseVisualSmoothing();
    });
  }

  Future<void> _loadTrajectoryConsent() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      _trajectoryConsent = prefs.getBool(_kTrajectoryConsentPrefKey) ?? false;
    });
  }

  Future<void> _setTrajectoryConsent(bool value) async {
    setState(() => _trajectoryConsent = value);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kTrajectoryConsentPrefKey, value);
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
    _positionSubscription = _locationService.watchPosition(_gpsTier).listen(
      (pos) => _acceptPosition(pos, animateCamera: false),
    );
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
    final shouldRepaint = running || (before - after).abs() > 0.25 || !s.isNearlyThere;
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

  LatLng get _playerMarkerPosition => _runnerSmooth?.display ?? _currentPosition;
  LatLng get _positionForReveal =>
      _fakePositionActive && _fakePositionLatLng != null
          ? _fakePositionLatLng!
          : _currentPosition;

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
    }
    _retuneGpsIfNeeded();
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
    if (_gameState == GameState.running) return;
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
    _retuneGpsIfNeeded();
    setState(() {
      _gameState = GameState.running;
      _remainingSeconds = GameConfig.matchDurationSeconds;
      _elapsedSeconds = 0;
      _outsideAreaSince = null;
      _revealedInCurrentOutside = false;
      _revealCount = 0;
      _revealLog.clear();
      _matchEvents.clear();
      _safeZoneCharges = 0;
      _lastSafeChargeAt = null;
      _lastInfoBrokerAt = null;
      _lastPeriodicRevealAt = null;
      _safeZoneAvailable = true;
      _infoBrokerAvailable = true;
      _safeZoneRespawnAt = null;
      _infoBrokerRespawnAt = null;
      _triggeredCameras.clear();
      _fakePositionActive = false;
      _fakePositionEndsAt = null;
      _lastFakeSkillAt = null;
      _fakePositionLatLng = null;
      _statusMessage = 'ゲーム開始。鬼から逃げてください。';
    });

    _matchTimer?.cancel();
    _matchTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted || _gameState != GameState.running) return;
      _matchRecorder?.tryAppendOni(_oniPosition);
      setState(() {
        _remainingSeconds -= 1;
        _elapsedSeconds += 1;
      });
      _evaluateGame();
      _retuneGpsIfNeeded();
    });
  }

  void _resetGame() {
    _matchTimer?.cancel();
    _matchRecorder?.discard();
    _matchRecorder = null;
    _retuneGpsIfNeeded();
    setState(() {
      _gameState = GameState.waiting;
      _remainingSeconds = GameConfig.matchDurationSeconds;
      _elapsedSeconds = 0;
      _outsideAreaSince = null;
      _revealedInCurrentOutside = false;
      _revealCount = 0;
      _revealLog.clear();
      _matchEvents.clear();
      _safeZoneCharges = 0;
      _lastSafeChargeAt = null;
      _lastInfoBrokerAt = null;
      _lastPeriodicRevealAt = null;
      _safeZoneAvailable = true;
      _infoBrokerAvailable = true;
      _safeZoneRespawnAt = null;
      _infoBrokerRespawnAt = null;
      _triggeredCameras.clear();
      _fakePositionActive = false;
      _fakePositionEndsAt = null;
      _fakePositionLatLng = null;
      _statusMessage = 'リセットしました。開始ボタンでゲーム開始。';
    });
  }

  void _endGame(GameState result, String message) {
    _matchTimer?.cancel();
    final outcome = result;
    setState(() {
      _gameState = result;
      _statusMessage = message;
    });
    _retuneGpsIfNeeded();
    Future<void>.microtask(() => _finalizeMatchRecording(outcome));
  }

  void _evaluateGame() {
    if (_gameState != GameState.running) return;

    final distance = _distanceToOni();
    final overflowMeters = _playArea.overflowDistanceMeters(_currentPosition);
    _refreshPointRespawns();
    _evaluateFakeSkillTimer();
    _evaluateCameraTriggers();
    _evaluateSafeZone();
    _evaluateInfoBroker(distance);
    _evaluatePeriodicReveal();

    if (distance <= GameConfig.captureDistanceMeters) {
      _endGame(GameState.caughtByOni, '鬼に捕まりました。');
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
      final outsideSec = DateTime.now().difference(_outsideAreaSince!).inSeconds;
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
  }

  void _triggerLocationReveal(double overflowMeters) {
    _revealedInCurrentOutside = true;
    _revealCount += 1;
    final ev = LocationRevealEvent(
      sequence: _revealCount,
      timestamp: DateTime.now(),
      position: _positionForReveal,
      overflowMeters: overflowMeters,
    );
    setState(() {
      _revealLog.insert(0, ev);
      if (_revealLog.length > 50) {
        _revealLog.removeLast();
      }
      _statusMessage =
          '位置暴露 #$_revealCount: エリア外 ${overflowMeters.toStringAsFixed(0)}m';
    });
    HapticFeedback.heavyImpact();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          '位置暴露: 全員に現在位置が通知されました（$_revealCount回目）',
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

  void _evaluateSafeZone() {
    if (!_safeZoneAvailable) return;
    if (_safeZoneCharges >= GameConfig.safeZoneMaxCharges) return;
    final now = DateTime.now();
    final inside = Geolocator.distanceBetween(
          _currentPosition.latitude,
          _currentPosition.longitude,
          _safeZonePosition.latitude,
          _safeZonePosition.longitude,
        ) <=
        GameConfig.safeZoneRadiusMeters;
    if (!inside) return;
    if (_lastSafeChargeAt != null &&
        now.difference(_lastSafeChargeAt!).inSeconds <
            GameConfig.safeZoneChargeCooldownSeconds) {
      return;
    }
    _lastSafeChargeAt = now;
    _safeZoneCharges += 1;
    _safeZoneAvailable = false;
    _safeZoneRespawnAt = now.add(
      const Duration(seconds: GameConfig.safeZoneRespawnSeconds),
    );
    setState(() {
      _statusMessage = '安全地帯でステルスチャージを獲得（$_safeZoneCharges）';
    });
    _emitMatchEvent(
      type: 'safe_charge',
      message: '安全地帯でチャージ獲得',
      position: _safeZonePosition,
    );
  }

  void _evaluateInfoBroker(double distanceToOni) {
    if (!_infoBrokerAvailable) return;
    final now = DateTime.now();
    final inside = Geolocator.distanceBetween(
          _currentPosition.latitude,
          _currentPosition.longitude,
          _infoBrokerPosition.latitude,
          _infoBrokerPosition.longitude,
        ) <=
        GameConfig.infoBrokerRadiusMeters;
    if (!inside) return;
    if (_lastInfoBrokerAt != null &&
        now.difference(_lastInfoBrokerAt!).inSeconds <
            GameConfig.infoBrokerCooldownSeconds) {
      return;
    }
    _lastInfoBrokerAt = now;
    _infoBrokerAvailable = false;
    _infoBrokerRespawnAt = now.add(
      const Duration(seconds: GameConfig.infoBrokerRespawnSeconds),
    );
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
    final intel = _buildOniIntel(direction: direction, distanceBand: distBand);
    setState(() {
      _statusMessage = '情報屋: $intel';
    });
    _emitMatchEvent(
      type: 'info_broker',
      message: '情報屋を利用: $intel',
      position: _infoBrokerPosition,
    );
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

  void _evaluatePeriodicReveal() {
    if (_elapsedSeconds <= 0 ||
        _elapsedSeconds % GameConfig.periodicRevealIntervalSeconds != 0) {
      return;
    }
    final now = DateTime.now();
    if (_lastPeriodicRevealAt != null &&
        now.difference(_lastPeriodicRevealAt!).inSeconds < 5) {
      return;
    }
    _lastPeriodicRevealAt = now;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('定期暴露: いまの位置が短時間通知されました'),
      ),
    );
    _emitMatchEvent(
      type: 'periodic_reveal',
      message: '定期暴露',
      position: _positionForReveal,
    );
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
        _emitMatchEvent(
          type: 'camera_spotted',
          message: msg,
          position: p,
        );
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
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

  void _activateFakeSkill() {
    if (_gameState != GameState.running) {
      _toast('ゲーム中のみ使えます');
      return;
    }
    final now = DateTime.now();
    if (_lastFakeSkillAt != null &&
        now.difference(_lastFakeSkillAt!).inSeconds <
            GameConfig.fakeSkillCooldownSeconds) {
      final remain =
          GameConfig.fakeSkillCooldownSeconds - now.difference(_lastFakeSkillAt!).inSeconds;
      _toast('偽位置スキル再使用まで $remain 秒');
      return;
    }
    _lastFakeSkillAt = now;
    _fakePositionActive = true;
    _fakePositionEndsAt =
        now.add(const Duration(seconds: GameConfig.fakeSkillDurationSeconds));
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
    final d = Geolocator.distanceBetween(
      _currentPosition.latitude,
      _currentPosition.longitude,
      _commJammingZonePosition.latitude,
      _commJammingZonePosition.longitude,
    );
    return d <= GameConfig.commJammingZoneRadiusMeters;
  }

  bool _isCommJammingOpenNow() {
    if (!_isInsideCommJammingZone()) return true;
    final bucket =
        (_elapsedSeconds ~/ GameConfig.commJammingCycleSeconds) % 2;
    return bucket == 0;
  }

  String _buildOniIntel({
    required String direction,
    required String distanceBand,
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
        final fragmentPick = _elapsedSeconds % 3;
        if (fragmentPick == 0) return '断片: 方角 $direction';
        if (fragmentPick == 1) return '断片: 距離帯 $distanceBand';
        return '断片: 最近10秒は追跡途切れ';
    }
  }

  void _cycleOniIntelMode() {
    if (_gameState == GameState.running) {
      _toast('ゲーム中は情報モードを変更できません');
      return;
    }
    setState(() {
      final nextIndex = (_oniIntelMode.index + 1) % OniIntelMode.values.length;
      _oniIntelMode = OniIntelMode.values[nextIndex];
      _statusMessage = '鬼情報モード: ${_oniIntelMode.label}';
    });
  }

  void _maybeTriggerDangerFeedback(double currentDistance) {
    if (_lastDistance == null) {
      _lastDistance = currentDistance;
      return;
    }
    final wasSafe = _lastDistance! > GameConfig.warningDistanceMeters;
    final isWarning = currentDistance <= GameConfig.warningDistanceMeters;
    final isDanger = currentDistance <= GameConfig.dangerDistanceMeters;

    if (wasSafe && isWarning) {
      HapticFeedback.selectionClick();
    }
    if (_lastDistance! > GameConfig.dangerDistanceMeters && isDanger) {
      HapticFeedback.mediumImpact();
    }
    _lastDistance = currentDistance;
  }

  double _distanceToOni() {
    return Geolocator.distanceBetween(
      _currentPosition.latitude,
      _currentPosition.longitude,
      _oniPosition.latitude,
      _oniPosition.longitude,
    );
  }

  String _formatTime(int seconds) {
    final min = (seconds ~/ 60).toString().padLeft(2, '0');
    final sec = (seconds % 60).toString().padLeft(2, '0');
    return '$min:$sec';
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
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('キャンセル')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('取り込み')),
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

  void _showRevealLog() {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (ctx) => ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text('位置暴露ログ（ローカル・最大50件・将来はクラウド同期）',
              style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          if (_revealLog.isEmpty)
            const Text('まだありません'),
          for (final e in _revealLog)
            ListTile(
              dense: true,
              title: Text('#${e.sequence}  +${e.overflowMeters.toStringAsFixed(0)}m'),
              subtitle: Text(
                  '${e.timestamp.toIso8601String()}\n${e.position.latitude.toStringAsFixed(5)}, ${e.position.longitude.toStringAsFixed(5)}'),
            ),
        ],
      ),
    );
  }

  Set<Marker> _buildMarkers() {
    final markers = <Marker>{
      Marker(
        markerId: const MarkerId('player'),
        position: _playerMarkerPosition,
        infoWindow: const InfoWindow(title: 'あなた', snippet: '現在地'),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
      ),
      Marker(
        markerId: const MarkerId('oni'),
        position: _oniPosition,
        infoWindow: const InfoWindow(title: '鬼', snippet: 'ここに鬼がいる'),
      ),
      Marker(
        markerId: const MarkerId('safe_zone_marker'),
        position: _safeZonePosition,
        infoWindow: InfoWindow(
          title: '安全地帯',
          snippet: _safeZoneAvailable
              ? 'チャージ獲得地点'
              : '再出現まで ${_secondsUntil(_safeZoneRespawnAt)} 秒',
        ),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
      ),
      Marker(
        markerId: const MarkerId('info_broker_marker'),
        position: _infoBrokerPosition,
        infoWindow: InfoWindow(
          title: '情報屋',
          snippet: _infoBrokerAvailable
              ? '鬼の方角ヒント'
              : '再出現まで ${_secondsUntil(_infoBrokerRespawnAt)} 秒',
        ),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueViolet),
      ),
      Marker(
        markerId: const MarkerId('comm_jamming_zone_marker'),
        position: _commJammingZonePosition,
        infoWindow: const InfoWindow(title: '通信障害地帯', snippet: '情報が断片化する'),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueOrange),
      ),
      for (var i = 0; i < _cameraPositions.length; i++)
        Marker(
          markerId: MarkerId('camera_$i'),
          position: _cameraPositions[i],
          infoWindow: InfoWindow(
            title: '監視カメラ ${i + 1}',
            snippet: _triggeredCameras.contains(i) ? '作動済み' : '未作動',
          ),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueYellow),
        ),
    };

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

    if (_editingArea && !_editCircleMode) {
      for (var i = 0; i < _polygonDraft.length; i++) {
        markers.add(
          Marker(
            markerId: MarkerId('draft_v_$i'),
            position: _polygonDraft[i],
            infoWindow: InfoWindow(title: '頂点', snippet: '${i + 1}'),
            icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
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
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueViolet),
        ),
      );
    }

    return markers;
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

  Set<Circle> _buildCircles(WorldProfileTokens tokens) {
    final circles = <Circle>{
      Circle(
        circleId: const CircleId('safe-zone'),
        center: _safeZonePosition,
        radius: GameConfig.safeZoneRadiusMeters,
        strokeWidth: 2,
        fillColor: tokens.safeColor.withValues(
          alpha: _safeZoneAvailable ? 0.12 : 0.04,
        ),
        strokeColor: tokens.safeColor,
      ),
      Circle(
        circleId: const CircleId('info-broker'),
        center: _infoBrokerPosition,
        radius: GameConfig.infoBrokerRadiusMeters,
        strokeWidth: 2,
        fillColor: tokens.infoColor.withValues(
          alpha: _infoBrokerAvailable ? 0.12 : 0.04,
        ),
        strokeColor: tokens.infoColor,
      ),
      Circle(
        circleId: const CircleId('comm-jamming-zone'),
        center: _commJammingZonePosition,
        radius: GameConfig.commJammingZoneRadiusMeters,
        strokeWidth: 2,
        fillColor: Colors.orange.withValues(alpha: 0.12),
        strokeColor: Colors.orange.shade700,
      ),
    };

    if (_editingArea && _editCircleMode) {
      circles.add(
        Circle(
          circleId: const CircleId('draft-circle'),
          center: _circleDraftCenter,
          radius: _circleDraftRadiusMeters,
          strokeWidth: 3,
          fillColor: Colors.purple.withValues(alpha: 0.12),
          strokeColor: Colors.purple.shade600,
        ),
      );
      return circles;
    }

    if (_playArea.type == PlayAreaType.circle && !_editingArea) {
      circles.add(
        Circle(
          circleId: const CircleId('play-area'),
          center: _playArea.center,
          radius: _playArea.radiusMeters,
          strokeWidth: 2,
          fillColor: Colors.blue.withValues(alpha: 0.08),
          strokeColor: Colors.blue.shade400,
        ),
      );
    }
    return circles;
  }

  int _secondsUntil(DateTime? target) {
    if (target == null) return 0;
    final diff = target.difference(DateTime.now()).inSeconds;
    return diff < 0 ? 0 : diff;
  }

  @override
  void dispose() {
    _positionSubscription?.cancel();
    _matchTimer?.cancel();
    _renderPump?.cancel();
    _mapController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tokens = WorldProfileTokenFactory.of(widget.profile);
    final distance = _distanceToOni();
    final overflowMeters = _playArea.overflowDistanceMeters(_currentPosition);
    final bool isOutBeyondGrace = overflowMeters > GameConfig.outsideAreaGraceMeters;
    final bool isDanger = distance <= GameConfig.dangerDistanceMeters;
    final bool isWarning = distance <= GameConfig.warningDistanceMeters;

    final Color alertColor = isDanger
        ? tokens.alertColor
        : isWarning
            ? Colors.orange.shade700
            : Colors.black87;
    final String alertText = isDanger
        ? '${tokens.dangerTextPrefix}: 鬼がすぐ近くにいます'
        : isWarning
            ? '${tokens.warningTextPrefix}: 鬼が近づいています'
            : '${tokens.safeTextPrefix}: 鬼との距離あり';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Oni Game Map'),
        actions: [
          IconButton(
            tooltip: '試合ギャラリー（タイムラプス再生）',
            onPressed: () {
              Navigator.of(context).push<void>(
                MaterialPageRoute<void>(
                  builder: (_) => const MatchGalleryScreen(),
                ),
              );
            },
            icon: const Icon(Icons.movie_filter_outlined),
          ),
          IconButton(
            tooltip: '位置暴露ログ',
            onPressed: _showRevealLog,
            icon: const Icon(Icons.history),
          ),
          IconButton(
            tooltip: 'GeoJSON インポート',
            onPressed: _gameState == GameState.running ? null : _showImportGeoJsonDialog,
            icon: const Icon(Icons.upload_file_outlined),
          ),
          IconButton(
            tooltip: 'GeoJSON エクスポート',
            onPressed: _exportGeoJson,
            icon: const Icon(Icons.copy_outlined),
          ),
        ],
      ),
      body: Stack(
        children: [
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
            polygons: !_editingArea && _playArea.type == PlayAreaType.polygon
                ? {
                    Polygon(
                      polygonId: const PolygonId('play-area-poly'),
                      points: _playArea.points,
                      strokeWidth: 2,
                      strokeColor: Colors.blue.shade400,
                      fillColor: Colors.blue.withValues(alpha: 0.08),
                    ),
                  }
                : _editingArea &&
                        !_editCircleMode &&
                        _polygonDraft.length >= 3
                    ? {
                        Polygon(
                          polygonId: const PolygonId('draft-poly-preview'),
                          points: _polygonDraft,
                          strokeWidth: 2,
                          strokeColor: Colors.deepOrange.shade400,
                          fillColor: Colors.deepOrange.withValues(alpha: 0.1),
                        ),
                      }
                    : {},
            onTap: _onMapTap,
            onMapCreated: (controller) {
              _mapController = controller;
            },
          ),
          Positioned(
            top: 18,
            left: 16,
            right: 16,
            child: _InfoPanel(
              distanceText: '鬼まで ${distance.toStringAsFixed(0)} m',
              timerText: _formatTime(_remainingSeconds),
              gameStateText: _gameState.label,
              statusText: _statusMessage,
              alertText: alertText,
              alertColor: alertColor,
              areaText: isOutBeyondGrace
                  ? '猶予超過: +${overflowMeters.toStringAsFixed(0)}m'
                  : 'エリア内（またはGPS猶予内）',
              areaColor: isOutBeyondGrace ? Colors.red.shade700 : Colors.green.shade700,
              revealCount: _revealCount,
              editing: _editingArea,
              safeZoneCharges: _safeZoneCharges,
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
          Positioned(
            bottom: 16,
            left: 16,
            right: 16,
            child: _ControlPanel(
              onRefresh: () async => _setupLocation(),
              onStart: _startGame,
              onReset: _resetGame,
              onMoveOni: _moveOniForTest,
              onFakeSkill: _activateFakeSkill,
              onToggleAreaEdit: _toggleAreaEditor,
              isRunning: _gameState == GameState.running,
              isEditing: _editingArea,
              fakeSkillActive: _fakePositionActive,
              trajectoryConsent: _trajectoryConsent,
              onTrajectoryConsentChanged: _setTrajectoryConsent,
              oniIntelModeLabel: _oniIntelMode.label,
              onCycleOniIntelMode: _cycleOniIntelMode,
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoPanel extends StatelessWidget {
  const _InfoPanel({
    required this.distanceText,
    required this.timerText,
    required this.gameStateText,
    required this.statusText,
    required this.alertText,
    required this.alertColor,
    required this.areaText,
    required this.areaColor,
    required this.revealCount,
    required this.editing,
    required this.safeZoneCharges,
  });

  final String distanceText;
  final String timerText;
  final String gameStateText;
  final String statusText;
  final String alertText;
  final Color alertColor;
  final String areaText;
  final Color areaColor;
  final int revealCount;
  final bool editing;
  final int safeZoneCharges;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [
          BoxShadow(color: Colors.black26, blurRadius: 6, offset: Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                distanceText,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              ),
              Chip(
                label: Text(editing ? 'エリア編集中' : gameStateText),
                visualDensity: VisualDensity.compact,
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text('残り時間 $timerText / 位置暴露 $revealCount 回 / ステルス $safeZoneCharges'),
          const SizedBox(height: 4),
          Text(statusText),
          const SizedBox(height: 8),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
            decoration: BoxDecoration(
              color: areaColor,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              areaText,
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
            ),
          ),
          const SizedBox(height: 8),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
            decoration: BoxDecoration(
              color: alertColor,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              alertText,
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
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
            Text(
              'プレイエリア編集',
              style: Theme.of(context).textTheme.titleSmall,
            ),
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
    required this.onRefresh,
    required this.onStart,
    required this.onReset,
    required this.onMoveOni,
    required this.onFakeSkill,
    required this.onToggleAreaEdit,
    required this.isRunning,
    required this.isEditing,
    required this.fakeSkillActive,
    required this.trajectoryConsent,
    required this.onTrajectoryConsentChanged,
    required this.oniIntelModeLabel,
    required this.onCycleOniIntelMode,
  });

  final VoidCallback onRefresh;
  final VoidCallback onStart;
  final VoidCallback onReset;
  final VoidCallback onMoveOni;
  final VoidCallback onFakeSkill;
  final VoidCallback onToggleAreaEdit;
  final bool isRunning;
  final bool isEditing;
  final bool fakeSkillActive;
  final bool trajectoryConsent;
  final ValueChanged<bool> onTrajectoryConsentChanged;
  final String oniIntelModeLabel;
  final VoidCallback onCycleOniIntelMode;

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
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Checkbox(
                value: trajectoryConsent,
                onChanged: isRunning
                    ? null
                    : (v) => onTrajectoryConsentChanged(v ?? false),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(top: 10),
                  child: Text(
                    '同意: 試合後に端末内だけで軌跡を保存し、タイムラプスで再生できるようにする（共有・クラウド送信は別途）',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
              ),
            ],
          ),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              FilledButton.icon(
                onPressed: isRunning || isEditing ? null : onStart,
                icon: const Icon(Icons.play_arrow),
                label: const Text('開始'),
              ),
              OutlinedButton.icon(
                onPressed: onReset,
                icon: const Icon(Icons.restart_alt),
                label: const Text('リセット'),
              ),
              OutlinedButton.icon(
                onPressed: isEditing ? null : onRefresh,
                icon: const Icon(Icons.gps_fixed),
                label: const Text('現在地更新'),
              ),
              OutlinedButton.icon(
                onPressed: isEditing ? null : onMoveOni,
                icon: const Icon(Icons.directions_run),
                label: const Text('鬼移動(テスト)'),
              ),
              FilledButton.tonalIcon(
                onPressed: isRunning && !isEditing ? onFakeSkill : null,
                icon: const Icon(Icons.flare),
                label: Text(fakeSkillActive ? '偽位置: 作動中' : '偽位置スキル'),
              ),
              FilledButton.tonalIcon(
                onPressed: isRunning ? null : onToggleAreaEdit,
                icon: Icon(isEditing ? Icons.check_circle : Icons.map_outlined),
                label: Text(isEditing ? '編集閉じる' : 'エリア編集'),
              ),
              FilledButton.tonalIcon(
                onPressed: isRunning ? null : onCycleOniIntelMode,
                icon: const Icon(Icons.tune),
                label: Text('鬼情報: $oniIntelModeLabel'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
