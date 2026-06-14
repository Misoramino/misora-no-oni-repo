import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../../game/game_config.dart';
import '../../../game/play_area.dart';
import 'match_geo_helpers.dart';
import 'match_runtime_state.dart';

/// スキル・感染・タッチロックの純粋判定結果。
sealed class SkillTickOutcome {
  const SkillTickOutcome();
}

final class SkillTickNone extends SkillTickOutcome {
  const SkillTickNone();
}

final class SkillTickFakeEnded extends SkillTickOutcome {
  const SkillTickFakeEnded();
}

final class SkillTickWerewolfEnded extends SkillTickOutcome {
  const SkillTickWerewolfEnded();
}

final class SkillTickCaptureZoneEnded extends SkillTickOutcome {
  const SkillTickCaptureZoneEnded({required this.placedBySkill});

  final bool placedBySkill;
}

final class SkillTickCaptureZoneEscapeReveal extends SkillTickOutcome {
  const SkillTickCaptureZoneEscapeReveal({required this.placedBySkill});

  final bool placedBySkill;
}

final class SkillTickCaptureZoneGameOver extends SkillTickOutcome {
  const SkillTickCaptureZoneGameOver({required this.placedBySkill});

  final bool placedBySkill;
}

/// 偽情報暴露の配置時間切れ — キャンセル（CD 消費なし）。
final class SkillTickFakeIntelPlacementCancelled extends SkillTickOutcome {
  const SkillTickFakeIntelPlacementCancelled();
}

final class SkillTickBodyThrowMiss extends SkillTickOutcome {
  const SkillTickBodyThrowMiss(this.puppetPosition);

  final LatLng puppetPosition;
}

/// 人形を置くまでの時間切れ — 発動時点のプレイヤー位置を暴露。
final class SkillTickBodyThrowPlacementTimeout extends SkillTickOutcome {
  const SkillTickBodyThrowPlacementTimeout(this.playerPositionAtCast);

  final LatLng playerPositionAtCast;
}

final class SkillTickTouchLockNotice extends SkillTickOutcome {
  const SkillTickTouchLockNotice();
}

final class SkillTickTouchLockStart extends SkillTickOutcome {
  const SkillTickTouchLockStart({
    required this.radiusMeters,
    required this.restraintRadiusMeters,
    required this.bindDurationSeconds,
    required this.endsAt,
  });

  final double radiusMeters;
  final double restraintRadiusMeters;
  final int bindDurationSeconds;
  final DateTime endsAt;
}

final class SkillTickInfectionPulse extends SkillTickOutcome {
  const SkillTickInfectionPulse();
}

final class SkillTickInfectionStarted extends SkillTickOutcome {
  const SkillTickInfectionStarted();
}

/// 感染確定前の至近警告（逃走者向け）。
final class SkillTickInfectionExposureWarn extends SkillTickOutcome {
  const SkillTickInfectionExposureWarn({required this.level});

  /// `start` = 至近に入った直後 / `imminent` = 感染直前
  final String level;
}

/// スキルタイマー・感染・捕獲結界・タッチロック（状態は [runtime] を更新）。
abstract final class MatchSkillTickEvaluator {
  static List<SkillTickOutcome> evaluateTimers({
    required MatchRuntimeState runtime,
    required LatLng playerPosition,
    required PlayArea playArea,
    required DateTime now,
  }) {
    final out = <SkillTickOutcome>[];

    if (runtime.fakePositionActive &&
        runtime.fakePositionEndsAt != null &&
        now.isAfter(runtime.fakePositionEndsAt!)) {
      runtime.fakePositionActive = false;
      runtime.fakePositionEndsAt = null;
      runtime.fakePositionLatLng = null;
      runtime.fakePositionBearingDegrees = null;
      out.add(const SkillTickFakeEnded());
    }

    if (runtime.lockZoneEndsAt != null &&
        now.isAfter(runtime.lockZoneEndsAt!)) {
      final wasSkill = runtime.lockZoneFromSkill;
      runtime.lockZoneCenter = null;
      runtime.lockZoneEndsAt = null;
      runtime.lockZoneFromSkill = false;
      runtime.lockZoneCapturePermitted = true;
      runtime.lockZoneBoundIds = const {};
      runtime.lockZoneTargetLeftAt = null;
      runtime.lockZoneEscapeRevealed = false;
      out.add(SkillTickCaptureZoneEnded(placedBySkill: wasSkill));
    }

    if (runtime.lockZoneCenter != null &&
        runtime.lockZoneBoundIds.contains('self')) {
      final center = runtime.lockZoneCenter!;
      final placedBySkill = runtime.lockZoneFromSkill;
      final escapeRadius = MatchGeoHelpers.lockZoneEscapeRadiusMeters(
        placedBySkill: placedBySkill,
        playArea: playArea,
      );
      final d = Geolocator.distanceBetween(
        playerPosition.latitude,
        playerPosition.longitude,
        center.latitude,
        center.longitude,
      );
      if (d > escapeRadius) {
        runtime.lockZoneTargetLeftAt ??= now;
        if (now.difference(runtime.lockZoneTargetLeftAt!).inSeconds >=
            GameConfig.bindZoneEscapeGraceSeconds) {
          if (runtime.lockZoneCapturePermitted) {
            out.add(SkillTickCaptureZoneGameOver(placedBySkill: placedBySkill));
          }
        } else if (!runtime.lockZoneEscapeRevealed) {
          runtime.lockZoneEscapeRevealed = true;
          out.add(
            SkillTickCaptureZoneEscapeReveal(placedBySkill: placedBySkill),
          );
        }
      } else {
        runtime.lockZoneTargetLeftAt = null;
        runtime.lockZoneEscapeRevealed = false;
      }
    }

    if (runtime.bodyThrowEndsAt != null &&
        now.isAfter(runtime.bodyThrowEndsAt!)) {
      final puppet = runtime.bodyThrowPosition;
      runtime.bodyThrowPosition = null;
      runtime.bodyThrowEndsAt = null;
      runtime.bodyThrowSkillOriginLatLng = null;
      if (puppet != null) {
        out.add(SkillTickBodyThrowMiss(puppet));
      }
    }

    if (runtime.fakeIntelAwaitingMapTap &&
        runtime.fakeIntelTapDeadline != null &&
        now.isAfter(runtime.fakeIntelTapDeadline!)) {
      runtime.fakeIntelAwaitingMapTap = false;
      runtime.fakeIntelTapDeadline = null;
      runtime.fakeIntelTargetLabel = '';
      runtime.fakeIntelTargetUid = null;
      out.add(const SkillTickFakeIntelPlacementCancelled());
    }

    if (runtime.bodyThrowAwaitingMapTap &&
        runtime.bodyThrowTapDeadline != null &&
        now.isAfter(runtime.bodyThrowTapDeadline!)) {
      final anchor = runtime.bodyThrowSkillOriginLatLng;
      runtime.bodyThrowAwaitingMapTap = false;
      runtime.bodyThrowTapDeadline = null;
      runtime.bodyThrowSkillOriginLatLng = null;
      if (anchor != null) {
        out.add(SkillTickBodyThrowPlacementTimeout(anchor));
      }
    }

    return out;
  }

  static SkillTickOutcome evaluateTouchLock({
    required MatchRuntimeState runtime,
    required PlayArea playArea,
    required double gpsDistance,
    required double touchRadiusMeters,
    required DateTime now,
    required bool enabled,
  }) {
    if (!enabled) {
      runtime.touchLockStartedAt = null;
      runtime.touchLockNoticeShown = false;
      return const SkillTickNone();
    }
    if (runtime.lockZoneBoundIds.contains('self')) {
      return const SkillTickNone();
    }

    if (gpsDistance > touchRadiusMeters) {
      runtime.touchLockStartedAt = null;
      runtime.touchLockNoticeShown = false;
      return const SkillTickNone();
    }

    runtime.touchLockStartedAt ??= now;
    final heldSeconds = now.difference(runtime.touchLockStartedAt!).inSeconds;
    if (!runtime.touchLockNoticeShown &&
        heldSeconds >= GameConfig.touchLockRunnerNoticeSeconds) {
      runtime.touchLockNoticeShown = true;
      return const SkillTickTouchLockNotice();
    }

    if (heldSeconds < GameConfig.touchLockRequiredSeconds) {
      return const SkillTickNone();
    }

    runtime.lockZoneBoundIds = const {'self'};
    runtime.lockZoneFromSkill = false;
    runtime.lockZoneCapturePermitted = true;
    runtime.lockZoneTargetLeftAt = null;
    runtime.lockZoneEscapeRevealed = false;
    final bindSec = MatchGeoHelpers.touchLockDurationSeconds(playArea);
    runtime.lockZoneEndsAt = now.add(Duration(seconds: bindSec));
    runtime.touchLockStartedAt = null;
    runtime.touchLockNoticeShown = false;

    return SkillTickTouchLockStart(
      radiusMeters: touchRadiusMeters,
      restraintRadiusMeters: MatchGeoHelpers.scaledRestraintRadiusMeters(playArea),
      bindDurationSeconds: bindSec,
      endsAt: runtime.lockZoneEndsAt!,
    );
  }

  static List<SkillTickOutcome> evaluateInfection({
    required MatchRuntimeState runtime,
    required double gpsDistanceToOni,
    required double infectionTriggerMeters,
    required DateTime now,
  }) {
    if (runtime.isInfectedNow) {
      if (runtime.lastInfectionRevealAt == null ||
          now.difference(runtime.lastInfectionRevealAt!).inSeconds >=
              GameConfig.infectionRevealIntervalSeconds) {
        runtime.lastInfectionRevealAt = now;
        return const [SkillTickInfectionPulse()];
      }
      return const [];
    }

    if (gpsDistanceToOni <= infectionTriggerMeters) {
      runtime.infectionExposureSeconds += 1;
      final exp = runtime.infectionExposureSeconds;
      final need = GameConfig.infectionExposureSeconds;
      final out = <SkillTickOutcome>[];
      if (exp == 1) {
        out.add(const SkillTickInfectionExposureWarn(level: 'start'));
      } else if (exp == need - 1) {
        out.add(const SkillTickInfectionExposureWarn(level: 'imminent'));
      }
      if (exp >= need) {
        runtime.infectionEndsAt = now.add(
          const Duration(seconds: GameConfig.infectionDurationSeconds),
        );
        runtime.infectionExposureSeconds = 0;
        runtime.lastInfectionRevealAt = null;
        out.add(const SkillTickInfectionStarted());
      }
      return out;
    }
    runtime.infectionExposureSeconds = 0;
    return const [];
  }

  static String? evaluateDangerCue({
    required MatchRuntimeState runtime,
    required double currentDistance,
    required double warningDistance,
    required double dangerDistance,
  }) {
    if (!runtime.touchLockNoticeShown &&
        !runtime.lockZoneBoundIds.contains('self')) {
      runtime.lastDangerDistance = currentDistance;
      return null;
    }
    final last = runtime.lastDangerDistance;
    if (last == null) {
      runtime.lastDangerDistance = currentDistance;
      return null;
    }
    String? cue;
    final wasSafe = last > warningDistance;
    final isWarning = currentDistance <= warningDistance;
    final isDanger = currentDistance <= dangerDistance;
    if (wasSafe && isWarning) cue = 'warning';
    if (last > dangerDistance && isDanger) cue = 'danger';
    runtime.lastDangerDistance = currentDistance;
    return cue;
  }
}
