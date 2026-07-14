import 'dart:math' as math;

import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../../game/game_config.dart';
import '../../../game/play_area.dart';
import '../../../proximity/proximity_signal.dart';

/// 試合中の距離・エリアスケール計算（副作用なし）。
abstract final class MatchGeoHelpers {
  static double distanceToOni({
    required LatLng player,
    required LatLng oni,
    required bool oniKnown,
    required bool testMode,
  }) {
    if (!testMode && !oniKnown) return double.infinity;
    return Geolocator.distanceBetween(
      player.latitude,
      player.longitude,
      oni.latitude,
      oni.longitude,
    );
  }

  static double effectiveInfectionDistance({
    required double gpsDistance,
    required ProximityBand proximityBand,
  }) {
    return switch (proximityBand) {
      ProximityBand.contact => 0,
      ProximityBand.near => gpsDistance - 10,
      _ => gpsDistance,
    };
  }

  static double scaledTouchRadiusMeters(PlayArea playArea) {
    final areaRadius = effectivePlayAreaRadiusMeters(playArea);
    final scaled = areaRadius * GameConfig.scaledTouchRadiusAreaRatio;
    return scaled.clamp(
      GameConfig.scaledTouchRadiusMinMeters,
      GameConfig.scaledTouchRadiusMaxMeters,
    );
  }

  /// 接触拘束中に逃げてはいけない円（スキル結界より広め・エリア連動）。
  static double scaledRestraintRadiusMeters(PlayArea playArea) {
    final areaRadius = effectivePlayAreaRadiusMeters(playArea);
    final scaled = areaRadius * GameConfig.scaledRestraintRadiusAreaRatio;
    return scaled.clamp(
      GameConfig.scaledRestraintRadiusMinMeters,
      GameConfig.scaledRestraintRadiusMaxMeters,
    );
  }

  /// 感染が始まる距離（接触圏より外側になりやすい環）。
  static double scaledInfectionTriggerMeters(PlayArea playArea) {
    final areaRadius = effectivePlayAreaRadiusMeters(playArea);
    final scaled = areaRadius * GameConfig.scaledInfectionRadiusAreaRatio;
    return scaled.clamp(
      GameConfig.infectionTriggerMinMeters,
      GameConfig.infectionTriggerMaxMeters,
    );
  }

  /// 拘束の持続: 中心から半径分を走って脱出する想定 + バッファ。
  static int touchLockDurationSeconds(PlayArea playArea) {
    final r = scaledRestraintRadiusMeters(playArea);
    final runToEdgeSec = r / GameConfig.restraintEscapeRunMps;
    return (runToEdgeSec + GameConfig.touchLockDurationBufferSeconds)
        .round()
        .clamp(
          GameConfig.touchLockDurationMinSeconds,
          GameConfig.touchLockDurationMaxSeconds,
        );
  }

  static double lockZoneEscapeRadiusMeters({
    required bool placedBySkill,
    required PlayArea playArea,
  }) =>
      placedBySkill
          ? GameConfig.captureZoneSkillRadiusMeters
          : scaledRestraintRadiusMeters(playArea);

  @Deprecated('Use lockZoneEscapeRadiusMeters')
  static double captureZoneEscapeRadiusMeters({
    required bool placedBySkill,
    required PlayArea playArea,
  }) =>
      lockZoneEscapeRadiusMeters(placedBySkill: placedBySkill, playArea: playArea);

  static double effectivePlayAreaRadiusMeters(PlayArea playArea) {
    switch (playArea.type) {
      case PlayAreaType.circle:
        return playArea.radiusMeters;
      case PlayAreaType.polygon:
        if (playArea.points.isEmpty) return GameConfig.playAreaRadiusMeters;
        final center = polygonCenter(playArea.points);
        var maxDistance = GameConfig.playAreaRadiusMeters;
        for (final p in playArea.points) {
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

  static LatLng polygonCenter(List<LatLng> points) {
    final lat =
        points.map((p) => p.latitude).reduce((a, b) => a + b) / points.length;
    final lng =
        points.map((p) => p.longitude).reduce((a, b) => a + b) / points.length;
    return LatLng(lat, lng);
  }

  static bool isCaptureTriggered({
    required bool running,
    required bool testMode,
    required bool oniKnown,
    required bool isHunterNow,
    required Set<String> lockZoneBoundIds,
    required ProximityBand proximityBand,
    required double gpsDistanceToOniMeters,
    required bool proximityCapturePermitted,
    required bool lockZoneCapturePermitted,
  }) {
    if (!running) return false;
    if (!testMode && !oniKnown && !isHunterNow) return false;
    if (!lockZoneBoundIds.contains('self')) return false;
    if (!lockZoneCapturePermitted) return false;
    return isBoundProximityCapture(
      proximityBand: proximityBand,
      gpsDistanceToOniMeters: gpsDistanceToOniMeters,
      proximityCapturePermitted: proximityCapturePermitted,
    );
  }

  /// 拘束中の至近捕獲（逃走者ローカル / 鬼側ホストライト共通）。
  static bool isBoundProximityCapture({
    required ProximityBand proximityBand,
    required double gpsDistanceToOniMeters,
    required bool proximityCapturePermitted,
  }) {
    if (proximityBand == ProximityBand.contact) {
      return proximityCapturePermitted;
    }
    return gpsDistanceToOniMeters <= GameConfig.captureDistanceMeters;
  }

  /// 捕獲結界の中心から、半径内の自分 (`self`) とリモート UID を集める。
  static Set<String> captureZoneTargetIds({
    required LatLng center,
    required double selfDistanceMeters,
    required double radiusMeters,
    required Map<String, LatLng> remotePositions,
  }) {
    final ids = <String>{};
    if (selfDistanceMeters <= radiusMeters) ids.add('self');
    for (final e in remotePositions.entries) {
      final d = Geolocator.distanceBetween(
        e.value.latitude,
        e.value.longitude,
        center.latitude,
        center.longitude,
      );
      if (d <= radiusMeters) ids.add(e.key);
    }
    return ids;
  }
}
