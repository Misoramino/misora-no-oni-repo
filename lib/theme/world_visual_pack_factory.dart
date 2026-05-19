import 'package:flutter/material.dart';

import '../features/game_map/map/game_map_layer_toggles.dart';
import '../features/game_map/map/map_zoom_lod.dart';
import 'world_profile.dart';
import 'world_profile_tokens.dart';
import 'world_visual_pack.dart';

abstract final class WorldVisualPackFactory {
  static WorldVisualPack of(WorldProfile profile) {
    final tokens = WorldProfileTokenFactory.of(profile);
    return switch (profile) {
      WorldProfile.sciFi => WorldVisualPack(
          profile: profile,
          mapStyleAssetPath: 'assets/map_styles/cyber_night.json',
          tokens: tokens,
          layerDefaults: GameMapLayerToggles.allOn,
          lodPolicy: MapZoomLodPolicy.standard,
          vignetteColor: const Color(0x66001028),
          revealFlashColor: const Color(0x8800E5FF),
          revealFlashDurationMs: 380,
          useRevealNoise: true,
          useScanOverlay: true,
        ),
      WorldProfile.sport => WorldVisualPack(
          profile: profile,
          mapStyleAssetPath: 'assets/map_styles/pop_city.json',
          tokens: tokens,
          layerDefaults: GameMapLayerToggles.allOn,
          lodPolicy: MapZoomLodPolicy.rich,
          vignetteColor: null,
          revealFlashColor: const Color(0x66FF6B9D),
          revealFlashDurationMs: 320,
          usePinBounceFlash: true,
          showPhotoPinByDefault: true,
        ),
      WorldProfile.horror => WorldVisualPack(
          profile: profile,
          mapStyleAssetPath: 'assets/map_styles/urban_horror.json',
          tokens: tokens,
          layerDefaults: const GameMapLayerToggles(
            commJamming: false,
            traces: true,
            reveals: true,
            cameras: true,
          ),
          lodPolicy: MapZoomLodPolicy.sparse,
          vignetteColor: const Color(0xAA1A0000),
          revealFlashColor: const Color(0xCCB71C1C),
          revealFlashDurationMs: 480,
          useRevealNoise: true,
          useVhsOverlay: true,
          photoOnlyOnReveal: true,
        ),
      WorldProfile.arg => WorldVisualPack(
          profile: profile,
          mapStyleAssetPath: 'assets/map_styles/stealth_tactical.json',
          tokens: tokens,
          layerDefaults: const GameMapLayerToggles(
            safeZones: true,
            infoBrokers: true,
            commJamming: false,
            traces: false,
            reveals: false,
            oniIntel: true,
            cameras: true,
            skillMarkers: false,
            ghostRough: false,
          ),
          lodPolicy: MapZoomLodPolicy.sparse,
          vignetteColor: const Color(0x55000000),
          revealFlashColor: const Color(0x4437474F),
          revealFlashDurationMs: 280,
        ),
      WorldProfile.magical => WorldVisualPack(
          profile: profile,
          mapStyleAssetPath: 'assets/map_styles/magical_world.json',
          tokens: tokens,
          layerDefaults: GameMapLayerToggles.allOn,
          lodPolicy: MapZoomLodPolicy.standard,
          vignetteColor: const Color(0x554A148C),
          revealFlashColor: const Color(0x88E040FB),
          showPhotoPinByDefault: true,
        ),
      WorldProfile.astronomy => WorldVisualPack(
          profile: profile,
          mapStyleAssetPath: 'assets/map_styles/astronomy.json',
          tokens: tokens,
          layerDefaults: const GameMapLayerToggles(
            commJamming: true,
            cameras: true,
            traces: false,
          ),
          lodPolicy: MapZoomLodPolicy.standard,
          vignetteColor: const Color(0x88000818),
          revealFlashColor: const Color(0x66FFD54F),
          useScanOverlay: true,
        ),
    };
  }
}
