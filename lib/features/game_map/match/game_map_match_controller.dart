import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../../game/game_config.dart';
import '../../../game/game_state.dart';
import '../../../game/match_hud_copy.dart';
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
    required bool applyOutsideAreaRules,
    required bool oniOutsideEndsMatch,
    required ProximityBand proximityBand,
    required bool proximityCapturePermitted,
    required DateTime now,
  }) {
    final effects = <MatchTickEffect>[];

    _applyRespawns(effects, now);

    for (final outcome in MatchSkillTickEvaluator.evaluateTimers(
      runtime: runtime,
      playerPosition: playerPosition,
      playArea: playArea,
      now: now,
    )) {
      effects.addAll(_effectsForSkillOutcome(outcome, playerPosition));
    }

    if (applyOutsideAreaRules) {
      final overflowMeters = playArea.overflowDistanceMeters(playerPosition);
      if (overflowMeters > GameConfig.outsideAreaGraceMeters) {
        runtime.outsideAreaSince ??= now;
      }
      final outsideSec = runtime.outsideAreaSince == null
          ? 0
          : now.difference(runtime.outsideAreaSince!).inSeconds;
      final sinceReveal = runtime.lastOutsideRevealAt == null
          ? outsideSec
          : now.difference(runtime.lastOutsideRevealAt!).inSeconds;
      final outsideAction = MatchTickEvaluator.evaluateOutsideArea(
        OutsideAreaTickInput(
          overflowMeters: overflowMeters,
          outsideSeconds: outsideSec,
          revealedInCurrentOutside: runtime.revealedInCurrentOutside,
          safeZoneCharges: runtime.safeZoneCharges,
          secondsSinceLastOutsideReveal: sinceReveal,
        ),
      );
      switch (outsideAction) {
        case null:
          break;
        case MatchTickAction.consumeSafeChargeAvoidReveal:
          if (!oniOutsideEndsMatch) {
            runtime.safeZoneCharges -= 1;
            runtime.outsideAreaSince = null;
            runtime.revealedInCurrentOutside = false;
            runtime.lastOutsideRevealAt = null;
            effects.add(const MatchConsumeSafeChargeEffect());
            effects.add(
              const MatchStatusMessageEffect(
                '${MatchHudCopy.safeChargeConsumed} — '
                '${MatchHudCopy.safeChargeConsumedDetail}',
              ),
            );
          }
        case MatchTickAction.triggerLocationReveal:
        case MatchTickAction.triggerOutsidePeriodicReveal:
          runtime.revealedInCurrentOutside = true;
          runtime.lastOutsideRevealAt = now;
          effects.add(MatchAreaRevealEffect(overflowMeters));
        case MatchTickAction.outsideElimination:
          effects.add(
            MatchEndEffect(
              state: GameState.caughtByOni,
              message: MatchTickEvaluator.endMessageFor(
                MatchTickAction.outsideElimination,
              ),
              heavyHaptic: true,
            ),
          );
          return effects;
        case MatchTickAction.resetOutsideTracking:
          runtime.outsideAreaSince = null;
          runtime.revealedInCurrentOutside = false;
          runtime.lastOutsideRevealAt = null;
          effects.add(const MatchResetOutsideTrackingEffect());
        case MatchTickAction.none:
        case MatchTickAction.endRunnerWin:
        case MatchTickAction.endCaughtByOni:
          break;
      }
    }

    if (!runnerProximityActive) {
      return effects;
    }

    final gpsToOniForInfection = MatchGeoHelpers.distanceToOni(
      player: playerPosition,
      oni: oniPosition,
      oniKnown: oniKnown,
      testMode: testMode,
    );
    final infectionDistance = switch (proximityBand) {
      ProximityBand.contact => 0.0,
      ProximityBand.near => MatchGeoHelpers.effectiveInfectionDistance(
          gpsDistance: gpsToOniForInfection,
          proximityBand: proximityBand,
        ),
      _ => gpsToOniForInfection,
    };
    final infectionTrigger = MatchGeoHelpers.scaledInfectionTriggerMeters(
      playArea,
    );
    for (final infectionOutcome in MatchSkillTickEvaluator.evaluateInfection(
      runtime: runtime,
      gpsDistanceToOni: infectionDistance,
      infectionTriggerMeters: infectionTrigger,
      now: now,
    )) {
      effects.addAll(_effectsForSkillOutcome(infectionOutcome, playerPosition));
    }

    final cameraIndices = CameraTriggerEvaluator.newlyTriggeredIndices(
      cameraPositions: runtime.cameraPositions,
      lastTriggeredAt: runtime.cameraLastTriggeredAt,
      playerPosition: playerPosition,
      triggerRadiusMeters: GameConfig.cameraTriggerRadiusMeters,
      cooldownSeconds: GameConfig.cameraRetriggerCooldownSeconds,
      now: now,
    );
    for (final i in cameraIndices) {
      if (runtime.disabledCameraIndices.contains(i)) continue;
      runtime.cameraLastTriggeredAt[i] = now;
      final p = runtime.cameraPositions[i];
      effects.add(
        MatchCameraSpottedEffect(
          index: i,
          position: p,
          message: MatchHudCopy.cameraSpottedMessage(i),
        ),
      );
    }

    final touchRadius = MatchGeoHelpers.scaledTouchRadiusMeters(playArea);
    final touchEnabled = testMode || oniKnown || isHunterNow;
    final touchOutcome = MatchSkillTickEvaluator.evaluateTouchLock(
      runtime: runtime,
      playArea: playArea,
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
      runtime.lockZoneCenter = playerPosition;
      runtime.lockZoneFromSkill = false;
      runtime.lockZoneCapturePermitted = true;
      effects.add(
        MatchTouchLockStartEffect(
          radiusMeters: touchOutcome.radiusMeters,
          endsAt: touchOutcome.endsAt,
        ),
      );
      effects.add(
        MatchEmitEventEffect(
          type: 'touch_lock_start',
          message: MatchHudCopy.touchLockEvent(
            touchRadiusMeters: touchOutcome.radiusMeters,
            restraintRadiusMeters: touchOutcome.restraintRadiusMeters,
            bindDurationSeconds: touchOutcome.bindDurationSeconds,
          ),
          position: playerPosition,
        ),
      );
      effects.add(
        const MatchStatusMessageEffect(
          '${MatchHudCopy.restraintStarted} — ${MatchHudCopy.restraintStartedDetail}',
        ),
      );
    } else if (touchOutcome is SkillTickTouchLockNotice) {
      effects.add(
        const MatchStatusMessageEffect(
          '${MatchHudCopy.contactRingEntered} — ${MatchHudCopy.contactRingEnteredDetail}',
        ),
      );
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
      lockZoneBoundIds: runtime.lockZoneBoundIds,
      proximityBand: proximityBand,
      gpsDistanceToOniMeters: gpsToOni,
      proximityCapturePermitted: proximityCapturePermitted,
      lockZoneCapturePermitted: runtime.lockZoneCapturePermitted,
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

    final distance = MatchGeoHelpers.distanceToOni(
      player: playerPosition,
      oni: oniPosition,
      oniKnown: oniKnown,
      testMode: testMode,
    );
    if (runnerProximityActive) {
      final cue = MatchSkillTickEvaluator.evaluateDangerCue(
        runtime: runtime,
        currentDistance: distance,
        warningDistance: touchRadius,
        dangerDistance: GameConfig.captureDistanceMeters,
      );
      if (cue != null) {
        effects.add(MatchOniCueEffect(cue));
      }
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
      effects.add(const MatchStatusMessageEffect(MatchHudCopy.safeZoneRespawned));
    }
    if (GimmickPickupEvaluator.shouldRespawn(
      available: runtime.infoBrokerAvailable,
      respawnAt: runtime.infoBrokerRespawnAt,
      now: now,
    )) {
      runtime.infoBrokerAvailable = true;
      runtime.infoBrokerRespawnAt = null;
      effects.add(const MatchStatusMessageEffect(MatchHudCopy.infoBrokerRespawned));
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
          message: MatchHudCopy.fakePositionEndedEvent,
          position: playerPosition,
        ),
        const MatchStatusMessageEffect(MatchHudCopy.fakePositionEnded),
      ],
      SkillTickWerewolfEnded() => const [],
      SkillTickCaptureZoneEnded(:final placedBySkill) => [
        MatchEmitEventEffect(
          type: 'capture_zone_end',
          message:
              placedBySkill
                  ? MatchHudCopy.captureZoneEnded
                  : MatchHudCopy.touchRestraintReleased,
          position: playerPosition,
        ),
      ],
      SkillTickCaptureZoneEscapeReveal(:final placedBySkill) => [
        MatchLocationRevealEmitEffect(
          type: 'capture_zone_escape',
          message: placedBySkill
              ? MatchHudCopy.captureZoneEscapeReveal
              : MatchHudCopy.touchRestraintEscapeReveal,
        ),
      ],
      SkillTickCaptureZoneGameOver(:final placedBySkill) => [
        MatchEndEffect(
          state: GameState.caughtByOni,
          message: placedBySkill
              ? MatchHudCopy.captureZoneLongEscape
              : MatchHudCopy.touchRestraintLongEscape,
          heavyHaptic: false,
        ),
      ],
      SkillTickBodyThrowMiss(:final puppetPosition) => [
        MatchLocationRevealEmitEffect(
          type: 'body_throw_miss',
          message: MatchHudCopy.bodyThrowMissReveal,
          position: puppetPosition,
        ),
      ],
      SkillTickBodyThrowPlacementTimeout(:final playerPositionAtCast) => [
        MatchLocationRevealEmitEffect(
          type: 'body_throw_placement_timeout',
          message: MatchHudCopy.bodyThrowTimeoutReveal,
          position: playerPositionAtCast,
        ),
      ],
      SkillTickFakeIntelPlacementCancelled() => const [
        MatchStatusMessageEffect('偽情報暴露の配置をキャンセルしました'),
      ],
      SkillTickTouchLockNotice() => const [],
      SkillTickTouchLockStart() => const [],
      SkillTickInfectionPulse() => [const MatchInfectionPulseRevealEffect()],
      SkillTickInfectionExposureWarn(:final level) => [
        MatchInfectionExposureWarnEffect(level: level),
      ],
      SkillTickInfectionStarted() => [
        MatchEmitEventEffect(
          type: 'panic_start',
          message: MatchHudCopy.panicStartedEvent,
          position: playerPosition,
        ),
        const MatchStatusMessageEffect(MatchHudCopy.panicStartedStatus),
      ],
    };
  }
}
