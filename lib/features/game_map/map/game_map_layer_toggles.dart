import 'package:flutter/foundation.dart';

/// 地図オーバーレイの表示切替（詳細 HUD から操作。既定はすべてオン）。
@immutable
class GameMapLayerToggles {
  const GameMapLayerToggles({
    this.playArea = true,
    this.remotePlayers = true,
    this.safeZones = true,
    this.infoBrokers = true,
    this.commJamming = true,
    this.cameras = true,
    this.traces = true,
    this.reveals = true,
    this.oniIntel = true,
    this.captureZone = true,
    this.skillMarkers = true,
    this.ghostRough = true,
  });

  final bool playArea;
  final bool remotePlayers;
  final bool safeZones;
  final bool infoBrokers;
  final bool commJamming;
  final bool cameras;
  final bool traces;
  final bool reveals;
  final bool oniIntel;
  final bool captureZone;

  /// 偽位置マーカー・体投げマーカー
  final bool skillMarkers;

  /// 脱落後のざっくり位置候補
  final bool ghostRough;

  static const GameMapLayerToggles allOn = GameMapLayerToggles();

  GameMapLayerToggles copyWith({
    bool? playArea,
    bool? remotePlayers,
    bool? safeZones,
    bool? infoBrokers,
    bool? commJamming,
    bool? cameras,
    bool? traces,
    bool? reveals,
    bool? oniIntel,
    bool? captureZone,
    bool? skillMarkers,
    bool? ghostRough,
  }) {
    return GameMapLayerToggles(
      playArea: playArea ?? this.playArea,
      remotePlayers: remotePlayers ?? this.remotePlayers,
      safeZones: safeZones ?? this.safeZones,
      infoBrokers: infoBrokers ?? this.infoBrokers,
      commJamming: commJamming ?? this.commJamming,
      cameras: cameras ?? this.cameras,
      traces: traces ?? this.traces,
      reveals: reveals ?? this.reveals,
      oniIntel: oniIntel ?? this.oniIntel,
      captureZone: captureZone ?? this.captureZone,
      skillMarkers: skillMarkers ?? this.skillMarkers,
      ghostRough: ghostRough ?? this.ghostRough,
    );
  }
}
