import 'package:flutter/material.dart';

import '../features/game_map/map/game_map_layer_toggles.dart';
import '../features/game_map/map/map_zoom_lod.dart';
import 'world_profile.dart';
import 'world_profile_tokens.dart';

/// 1 世界観ぶんの地図・マーカー・HUD・LOD 設定。
class WorldVisualPack {
  const WorldVisualPack({
    required this.profile,
    required this.mapStyleAssetPath,
    required this.tokens,
    required this.layerDefaults,
    required this.lodPolicy,
    required this.vignetteColor,
    this.revealFlashColor,
    this.revealFlashDurationMs = 420,
    this.useRevealNoise = false,
    this.useScanOverlay = false,
    this.useVhsOverlay = false,
    this.usePinBounceFlash = false,
    this.photoFrameAssetPath,
    this.showPhotoPinByDefault = false,
    this.photoOnlyOnReveal = false,
  });

  final WorldProfile profile;
  final String mapStyleAssetPath;
  final WorldProfileTokens tokens;
  final GameMapLayerToggles layerDefaults;
  final MapZoomLodPolicy lodPolicy;

  /// 試合中の常時ビネット（null ならなし）
  final Color? vignetteColor;

  /// reveal 時のフラッシュ色
  final Color? revealFlashColor;
  final int revealFlashDurationMs;
  final bool useRevealNoise;
  final bool useScanOverlay;
  final bool useVhsOverlay;
  final bool usePinBounceFlash;

  /// 写真ピン枠（将来 PNG。null ならプログラム描画枠）
  final String? photoFrameAssetPath;

  final bool showPhotoPinByDefault;
  final bool photoOnlyOnReveal;
}
