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
          lodPolicy: MapZoomLodPolicy.cyberNight,
          vignetteColor: const Color(0x77001030),
          revealFlashColor: const Color(0x9900F5FF),
          revealFlashDurationMs: 380,
          useRevealNoise: true,
          useScanOverlay: true,
        ),
      WorldProfile.sport => WorldVisualPack(
          profile: profile,
          mapStyleAssetPath: 'assets/map_styles/pop_city.json',
          tokens: tokens,
          layerDefaults: GameMapLayerToggles.allOn,
          lodPolicy: MapZoomLodPolicy.popCity,
          vignetteColor: null,
          revealFlashColor: const Color(0x77FF8FB3),
          revealFlashDurationMs: 340,
          usePinBounceFlash: true,
          showPhotoPinByDefault: true,
        ),
      WorldProfile.horror => WorldVisualPack(
          profile: profile,
          mapStyleAssetPath: 'assets/map_styles/urban_horror.json',
          tokens: tokens,
          layerDefaults: const GameMapLayerToggles(
            commJamming: true,
            ghostRough: false,
            traces: true,
            reveals: true,
            cameras: true,
          ),
          lodPolicy: MapZoomLodPolicy.urbanHorror,
          vignetteColor: const Color(0xBB240008),
          revealFlashColor: const Color(0xDDB71C1C),
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
            commJamming: true,
            traces: false,
            reveals: false,
            oniIntel: true,
            cameras: true,
            skillMarkers: false,
            ghostRough: false,
          ),
          lodPolicy: MapZoomLodPolicy.stealthTactical,
          vignetteColor: const Color(0x60080A10),
          revealFlashColor: const Color(0x5548505A),
          revealFlashDurationMs: 280,
        ),
      WorldProfile.magical => WorldVisualPack(
          profile: profile,
          mapStyleAssetPath: 'assets/map_styles/magical_world.json',
          tokens: tokens,
          layerDefaults: GameMapLayerToggles.allOn,
          lodPolicy: MapZoomLodPolicy.standard,
          vignetteColor: const Color(0x454A148C),
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
          vignetteColor: const Color(0x70000818),
          revealFlashColor: const Color(0x66FFD54F),
        ),
      WorldProfile.japaneseLuxury => WorldVisualPack(
          profile: profile,
          mapStyleAssetPath: 'assets/map_styles/japanese_luxury.json',
          tokens: tokens,
          layerDefaults: GameMapLayerToggles.allOn,
          lodPolicy: MapZoomLodPolicy.standard,
          vignetteColor: const Color(0x88080A06),
          revealFlashColor: const Color(0x99C9A227),
          revealFlashDurationMs: 460,
        ),
      WorldProfile.westernLuxury => WorldVisualPack(
          profile: profile,
          mapStyleAssetPath: 'assets/map_styles/western_luxury.json',
          tokens: tokens,
          layerDefaults: GameMapLayerToggles.allOn,
          lodPolicy: MapZoomLodPolicy.standard,
          vignetteColor: const Color(0x66101828),
          revealFlashColor: const Color(0x99D4AF37),
          revealFlashDurationMs: 440,
          useRevealNoise: true,
        ),
    };
  }
}
