import 'package:google_maps_flutter/google_maps_flutter.dart';

import 'game_config.dart';
import 'play_area.dart';

/// 世界観共通の簡易プリセット（試合時間・エリア・ギミック密度）。
enum MatchQuickPreset {
  casual,
  standard,
  intense;

  static MatchQuickPreset? fromName(String? raw) {
    if (raw == null) return null;
    for (final v in MatchQuickPreset.values) {
      if (v.name == raw) return v;
    }
    return null;
  }

  String get label => switch (this) {
        MatchQuickPreset.casual => 'お手軽',
        MatchQuickPreset.standard => '標準',
        MatchQuickPreset.intense => 'じっくり',
      };

  String get subtitle => switch (this) {
        MatchQuickPreset.casual => '30分 · 狭め · ギミック少なめ',
        MatchQuickPreset.standard => '45分 · 標準 · バランス',
        MatchQuickPreset.intense => '60分 · 広め · ギミック多め',
      };

  double get durationMinutes => switch (this) {
        MatchQuickPreset.casual => 30,
        MatchQuickPreset.standard => 45,
        MatchQuickPreset.intense => 60,
      };

  double get gimmickDensity => switch (this) {
        MatchQuickPreset.casual => 0.72,
        MatchQuickPreset.standard => 1.0,
        MatchQuickPreset.intense => 1.28,
      };

  double get areaRadiusMeters => switch (this) {
        MatchQuickPreset.casual => GameConfig.playAreaRadiusMeters * 0.72,
        MatchQuickPreset.standard => GameConfig.playAreaRadiusMeters,
        MatchQuickPreset.intense => GameConfig.playAreaRadiusMeters * 1.35,
      };

  /// 現在の中心を保ったまま円形エリアをプリセット値へ。
  PlayArea playAreaFromCenter(LatLng center) => PlayArea.circle(
        center: center,
        radiusMeters: areaRadiusMeters,
      );
}
