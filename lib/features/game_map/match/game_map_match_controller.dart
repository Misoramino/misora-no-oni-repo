import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../../game/game_config.dart';
import '../../../game/game_state.dart';
import '../../../game/play_area.dart';
import '../../../proximity/proximity_signal.dart';
import 'camera_trigger_evaluator.dart';
import 'gimmick_pickup_evaluator.dart';
import 'match_geo_helpers.dart';
import 'match_runtime_state.dart';
import 'match_skill_tick_evaluator.dart';
import 'match_tick_effects.dart';
import 'match_tick_evaluator.dart';

/// 試合ランタイムと 1 ティック分の判定。
class GameMapMatchController {
  GameMapMatchController({MatchRuntimeState? runtime})
    : runtime = runtime ?? MatchRuntimeState();

  final MatchRuntimeState runtime;

  List<MatchTickEffect> evaluateRunningTick({
    required PlayArea playArea,
    required LatLng playerPosition,
    required LatLng oniPosition,
    required bool testMode,
    required bool oniKnown,
    required bool isHunterNow,
    required bool runnerProximityActive,
    required ProximityBand proximityBand,
    required DateTime now,
  }) {
    final effects = <MatchTickEffect>[];

    _applyRespawns(effects, now);

    for (final outcome in MatchSkillTickEvaluator.evaluateTimers(
      runtime: runtime,
      playerPosition: playerPosition,
      now: now,
    )) {
      effects.addAll(_effectsForSkillOutcome(outcome, playerPosition));
    }

    if (!runnerProximityActive) {
      return effects;
    }

    final infectionDistance = MatchGeoHelpers.effectiveInfectionDistance(
      gpsDistance: MatchGeoHelpers.distanceToOni(
        player: playerPosition,
        oni: oniPosition,
        oniKnown: oniKnown,
        testMode: testMode,
      ),
      proximityBand: proximityBand,
    );
    for (final infectionOutcome in MatchSkillTickEvaluator.evaluateInfection(
      runtime: runtime,
      distanceToOni: infectionDistance,
      now: now,
    )) {
      effects.addAll(_effectsForSkillOutcome(infectionOutcome, playerPosition));
    }

    final cameraIndices = CameraTriggerEvaluator.newlyTriggeredIndices(
      cameraPositions: runtime.cameraPositions,
      alreadyTriggered: runtime.triggeredCameras,
      playerPosition: playerPosition,
      triggerRadiusMeters: GameConfig.cameraTriggerRadiusMeters,
    );
    for (final i in cameraIndices) {
      runtime.triggeredCameras.add(i);
      final p = runtime.cameraPositions[i];
      effects.add(
        MatchCameraSpottedEffect(
          index: i,
          position: p,
          message: '監視カメラ: プレイヤーが監視地点${i + 1}に現れた',
        ),
      );
    }

    final touchRadius = MatchGeoHelpers.scaledTouchRadiusMeters(playArea);
    final touchEnabled = testMode || oniKnown || isHunterNow;
    final touchOutcome = MatchSkillTickEvaluator.evaluateTouchLock(
      runtime: runtime,
      gpsDistance: MatchGeoHelpers.distanceToOni(
        player: playerPosition,
        oni: oniPosition,
        oniKnown: oniKnown,
        testMode: testMode,
      ),
      touchRadiusMeters: touchRadius,
      now: now,
      enabled: touchEnabled,
    );
    if (touchOutcome is SkillTickTouchLockStart) {
      runtime.captureZoneCenter = playerPosition;
      effects.add(
        MatchTouchLockStartEffect(
          radiusMeters: touchOutcome.radiusMeters,
          endsAt: touchOutcome.endsAt,
        ),
      );
      effects.add(
        MatchEmitEventEffect(
          type: 'touch_lock_start',
          message:
              'エリア連動タッチ範囲 ${touchOutcome.radiusMeters.toStringAsFixed(0)}m 内に一定時間入り、捕獲結界状態',
          position: playerPosition,
        ),
      );
      effects.add(
        const MatchStatusMessageEffect(
          '鬼に捕捉され、移動範囲が制限されました。至近距離または BLE 接触で捕獲。',
        ),
      );
    } else if (touchOutcome is SkillTickTouchLockNotice) {
      effects.add(const MatchStatusMessageEffect('鬼の接触圏に入りました。離脱してください。'));
    }

    final gpsToOni = MatchGeoHelpers.distanceToOni(
      player: playerPosition,
      oni: oniPosition,
      oniKnown: oniKnown,
      testMode: testMode,
    );
    final captureTriggered = MatchGeoHelpers.isCaptureTriggered(
      running: true,
      testMode: testMode,
      oniKnown: oniKnown,
      isHunterNow: isHunterNow,
      captureZoneBoundIds: runtime.captureZoneBoundIds,
      proximityBand: proximityBand,
      gpsDistanceToOniMeters: gpsToOni,
    );
    final terminal = MatchTickEvaluator.evaluateTerminal(
      remainingSeconds: runtime.remainingSeconds,
      captureTriggered: captureTriggered,
    );
    if (terminal != null) {
      effects.add(
        MatchEndEffect(
          state: MatchTickEvaluator.endStateFor(terminal),
          message: MatchTickEvaluator.endMessageFor(terminal),
          heavyHaptic: terminal == MatchTickAction.endCaughtByOni,
        ),
      );
      return effects;
    }

    final overflowMeters = playArea.overflowDistanceMeters(playerPosition);
    if (overflowMeters > GameConfig.outsideAreaGraceMeters) {
      runtime.outsideAreaSince ??= now;
    }
    final outsideSec = runtime.outsideAreaSince == null
        ? 0
        : now.difference(runtime.outsideAreaSince!).inSeconds;
    final outsideAction = MatchTickEvaluator.evaluateOutsideArea(
      OutsideAreaTickInput(
        overflowMeters: overflowMeters,
        outsideSeconds: outsideSec,
        revealedInCurrentOutside: runtime.revealedInCurrentOutside,
        safeZoneCharges: runtime.safeZoneCharges,
      ),
    );
    switch (outsideAction) {
      case null:
        break;
      case MatchTickAction.consumeSafeChargeAvoidReveal:
        runtime.safeZoneCharges -= 1;
        runtime.outsideAreaSince = null;
        runtime.revealedInCurrentOutside = false;
        effects.add(const MatchConsumeSafeChargeEffect());
        effects.add(const MatchStatusMessageEffect('安全地帯チャージを消費して位置暴露を回避しました'));
      case MatchTickAction.triggerLocationReveal:
        effects.add(MatchAreaRevealEffect(overflowMeters));
      case MatchTickAction.resetOutsideTracking:
        runtime.outsideAreaSince = null;
        runtime.revealedInCurrentOutside = false;
        effects.add(const MatchResetOutsideTrackingEffect());
      case MatchTickAction.none:
      case MatchTickAction.endRunnerWin:
      case MatchTickAction.endCaughtByOni:
        break;
    }

    final distance = MatchGeoHelpers.distanceToOni(
      player: playerPosition,
      oni: oniPosition,
      oniKnown: oniKnown,
      testMode: testMode,
    );
    final cue = MatchSkillTickEvaluator.evaluateDangerCue(
      runtime: runtime,
      currentDistance: distance,
      warningDistance: touchRadius,
      dangerDistance: GameConfig.captureDistanceMeters,
    );
    if (cue != null) {
      effects.add(MatchOniCueEffect(cue));
    }

    return effects;
  }

  void _applyRespawns(List<MatchTickEffect> effects, DateTime now) {
    if (GimmickPickupEvaluator.shouldRespawn(
      available: runtime.safeZoneAvailable,
      respawnAt: runtime.safeZoneRespawnAt,
      now: now,
    )) {
      runtime.safeZoneAvailable = true;
      runtime.safeZoneRespawnAt = null;
      effects.add(const MatchStatusMessageEffect('安全地帯が再出現しました'));
    }
    if (GimmickPickupEvaluator.shouldRespawn(
      available: runtime.infoBrokerAvailable,
      respawnAt: runtime.infoBrokerRespawnAt,
      now: now,
    )) {
      runtime.infoBrokerAvailable = true;
      runtime.infoBrokerRespawnAt = null;
      effects.add(const MatchStatusMessageEffect('情報屋が再出現しました'));
    }
  }

  List<MatchTickEffect> _effectsForSkillOutcome(
    SkillTickOutcome outcome,
    LatLng playerPosition,
  ) {
    return switch (outcome) {
      SkillTickNone() => const [],
      SkillTickFakeEnded() => [
        MatchEmitEventEffect(
          type: 'fake_end',
          message: '偽位置スキルが終了',
          position: playerPosition,
        ),
        const MatchStatusMessageEffect('偽位置スキル終了'),
      ],
      SkillTickWerewolfEnded() => [
        MatchEmitEventEffect(
          type: 'werewolf_transform_end',
          message: '人狼の一時鬼化が終了',
          position: playerPosition,
        ),
      ],
      SkillTickCaptureZoneEnded() => [
        MatchEmitEventEffect(
          type: 'capture_zone_end',
          message: '捕獲結界が終了',
          position: playerPosition,
        ),
      ],
      SkillTickCaptureZoneEscapeReveal() => [
        const MatchLocationRevealEmitEffect(
          type: 'capture_zone_escape',
          message: '捕獲結界から離脱して位置暴露',
        ),
      ],
      SkillTickCaptureZoneGameOver() => [
        MatchEndEffect(
          state: GameState.caughtByOni,
          message: '捕獲結界から長時間離脱しました。',
          heavyHaptic: false,
        ),
      ],
      SkillTickBodyThrowMiss(:final puppetPosition) => [
        MatchLocationRevealEmitEffect(
          type: 'body_throw_miss',
          message: '体投げ未回収で位置暴露（人形側）',
          position: puppetPosition,
        ),
      ],
      SkillTickBodyThrowPlacementTimeout(:final playerPositionAtCast) => [
        MatchLocationRevealEmitEffect(
          type: 'body_throw_placement_timeout',
          message: '体投げ: 配置の時間切れで位置が露見（発動地点）',
          position: playerPositionAtCast,
        ),
      ],
      SkillTickTouchLockNotice() => const [],
      SkillTickTouchLockStart() => const [],
      SkillTickInfectionPulse() => [const MatchInfectionPulseRevealEffect()],
      SkillTickInfectionExposureWarn(:final level) => [
        MatchInfectionExposureWarnEffect(level: level),
      ],
      SkillTickInfectionStarted() => [
        MatchEmitEventEffect(
          type: 'infection_start',
          message: '感染状態に入った',
          position: playerPosition,
        ),
        const MatchStatusMessageEffect('感染状態: 一時的に位置露出が増加'),
      ],
    };
  }
}
