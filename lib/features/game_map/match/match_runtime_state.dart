import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../../game/game_config.dart';
import '../../../game/generated_gimmicks.dart';
import '../../../game/location_reveal_event.dart';
import '../../../game/match_event.dart';
import '../../../game/oni_intel_trace.dart';

/// 1 試合分のランタイム状態（ギミック・スキル・暴露ログ等）。
class MatchRuntimeState {
  int remainingSeconds;
  int elapsedSeconds;
  int revealCount;
  final List<LocationRevealEvent> revealLog;
  final List<MatchEvent> matchEvents;

  DateTime? outsideAreaSince;
  bool revealedInCurrentOutside;

  List<LatLng> safeZonePositions;
  List<LatLng> infoBrokerPositions;
  List<LatLng> commJammingZonePositions;
  int safeZoneCharges;
  DateTime? lastSafeChargeAt;
  DateTime? lastInfoBrokerAt;
  String? lastOniIntelText;
  DateTime? lastOniIntelAt;
  bool showOniIntelCard;
  final List<OniIntelTrace> oniIntelTraces;
  bool safeZoneAvailable;
  bool infoBrokerAvailable;
  DateTime? safeZoneRespawnAt;
  DateTime? infoBrokerRespawnAt;
  List<LatLng> cameraPositions;
  final Set<int> triggeredCameras;

  bool fakePositionActive;
  DateTime? fakePositionEndsAt;
  DateTime? lastFakeSkillAt;
  LatLng? fakePositionLatLng;

  DateTime? werewolfTransformEndsAt;
  DateTime? lastWerewolfTransformAt;
  LatLng? captureZoneCenter;
  DateTime? captureZoneEndsAt;
  DateTime? lastCaptureZoneAt;
  bool waitingCaptureZoneTap;
  Set<String> captureZoneBoundIds;
  DateTime? captureZoneTargetLeftAt;
  bool captureZoneEscapeRevealed;

  DateTime? touchLockStartedAt;
  bool touchLockNoticeShown;

  LatLng? bodyThrowPosition;
  DateTime? bodyThrowEndsAt;
  DateTime? lastBodyThrowAt;
  bool bodyThrowAwaitingMapTap;
  DateTime? bodyThrowTapDeadline;
  /// 体投げ発動時のプレイヤー位置（配置猶予切れの暴露座標）。
  LatLng? bodyThrowSkillOriginLatLng;

  int infectionExposureSeconds;
  DateTime? infectionEndsAt;
  DateTime? lastInfectionRevealAt;

  double? lastDangerDistance;

  MatchRuntimeState({
    int? remainingSeconds,
    this.elapsedSeconds = 0,
    this.revealCount = 0,
    List<LocationRevealEvent>? revealLog,
    List<MatchEvent>? matchEvents,
    this.outsideAreaSince,
    this.revealedInCurrentOutside = false,
    List<LatLng>? safeZonePositions,
    List<LatLng>? infoBrokerPositions,
    List<LatLng>? commJammingZonePositions,
    this.safeZoneCharges = 0,
    this.lastSafeChargeAt,
    this.lastInfoBrokerAt,
    this.lastOniIntelText,
    this.lastOniIntelAt,
    this.showOniIntelCard = true,
    List<OniIntelTrace>? oniIntelTraces,
    this.safeZoneAvailable = true,
    this.infoBrokerAvailable = true,
    this.safeZoneRespawnAt,
    this.infoBrokerRespawnAt,
    List<LatLng>? cameraPositions,
    Set<int>? triggeredCameras,
    this.fakePositionActive = false,
    this.fakePositionEndsAt,
    this.lastFakeSkillAt,
    this.fakePositionLatLng,
    this.werewolfTransformEndsAt,
    this.lastWerewolfTransformAt,
    this.captureZoneCenter,
    this.captureZoneEndsAt,
    this.lastCaptureZoneAt,
    this.waitingCaptureZoneTap = false,
    Set<String>? captureZoneBoundIds,
    this.captureZoneTargetLeftAt,
    this.captureZoneEscapeRevealed = false,
    this.touchLockStartedAt,
    this.touchLockNoticeShown = false,
    this.bodyThrowPosition,
    this.bodyThrowEndsAt,
    this.lastBodyThrowAt,
    this.bodyThrowAwaitingMapTap = false,
    this.bodyThrowTapDeadline,
    this.bodyThrowSkillOriginLatLng,
    this.infectionExposureSeconds = 0,
    this.infectionEndsAt,
    this.lastInfectionRevealAt,
    this.lastDangerDistance,
  })  : remainingSeconds =
            remainingSeconds ?? GameConfig.matchDurationSeconds,
        revealLog = revealLog ?? [],
        matchEvents = matchEvents ?? [],
        safeZonePositions =
            safeZonePositions ?? const [LatLng(35.6822, 139.7682)],
        infoBrokerPositions =
            infoBrokerPositions ?? const [LatLng(35.6804, 139.7657)],
        commJammingZonePositions =
            commJammingZonePositions ?? const [LatLng(35.6796, 139.7689)],
        oniIntelTraces = oniIntelTraces ?? [],
        cameraPositions = cameraPositions ??
            const [
              LatLng(35.6817, 139.7661),
              LatLng(35.6800, 139.7696),
            ],
        triggeredCameras = triggeredCameras ?? <int>{},
        captureZoneBoundIds = captureZoneBoundIds ?? const {};

  bool get isInfectedNow =>
      infectionEndsAt != null && DateTime.now().isBefore(infectionEndsAt!);

  bool get dangerPulseActive =>
      touchLockNoticeShown ||
      captureZoneBoundIds.contains('self') ||
      isInfectedNow;

  void resetToLobby({required int matchDurationSeconds}) {
    remainingSeconds = matchDurationSeconds;
    elapsedSeconds = 0;
    outsideAreaSince = null;
    revealedInCurrentOutside = false;
    revealCount = 0;
    revealLog.clear();
    matchEvents.clear();
    safeZoneCharges = 0;
    lastSafeChargeAt = null;
    lastInfoBrokerAt = null;
    lastOniIntelText = null;
    lastOniIntelAt = null;
    showOniIntelCard = true;
    oniIntelTraces.clear();
    safeZoneAvailable = true;
    infoBrokerAvailable = true;
    safeZoneRespawnAt = null;
    infoBrokerRespawnAt = null;
    triggeredCameras.clear();
    fakePositionActive = false;
    fakePositionEndsAt = null;
    lastFakeSkillAt = null;
    fakePositionLatLng = null;
    werewolfTransformEndsAt = null;
    lastWerewolfTransformAt = null;
    captureZoneCenter = null;
    captureZoneEndsAt = null;
    lastCaptureZoneAt = null;
    waitingCaptureZoneTap = false;
    captureZoneBoundIds = const {};
    captureZoneTargetLeftAt = null;
    captureZoneEscapeRevealed = false;
    touchLockStartedAt = null;
    touchLockNoticeShown = false;
    bodyThrowPosition = null;
    bodyThrowEndsAt = null;
    lastBodyThrowAt = null;
    bodyThrowAwaitingMapTap = false;
    bodyThrowTapDeadline = null;
    bodyThrowSkillOriginLatLng = null;
    infectionExposureSeconds = 0;
    infectionEndsAt = null;
    lastInfectionRevealAt = null;
    lastDangerDistance = null;
  }

  void applyStartGimmicks({
    required GeneratedGimmicks gimmicks,
    required int matchDurationSeconds,
  }) {
    resetToLobby(matchDurationSeconds: matchDurationSeconds);
    safeZonePositions = List<LatLng>.from(gimmicks.safeZones);
    infoBrokerPositions = List<LatLng>.from(gimmicks.infoBrokers);
    commJammingZonePositions = List<LatLng>.from(gimmicks.eventAreas);
    cameraPositions = List<LatLng>.from(gimmicks.cameras);
    lastFakeSkillAt = null;
  }
}
