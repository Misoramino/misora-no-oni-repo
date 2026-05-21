import 'package:flutter/material.dart';

import 'world_profile.dart';
import 'world_visual_pack_factory.dart';

/// 起動画面の演出カテゴリ（全 WorldProfile 専用）。
enum LaunchEffectKind {
  cyber,
  horror,
  pop,
  tactical,
  magical,
  astronomy,
}

extension LaunchEffectKindLabel on LaunchEffectKind {
  String get profileTag => switch (this) {
        LaunchEffectKind.cyber => 'Cyber Night',
        LaunchEffectKind.horror => 'Urban Horror',
        LaunchEffectKind.pop => 'Pop City',
        LaunchEffectKind.tactical => 'Stealth Tactical',
        LaunchEffectKind.magical => 'Magical World',
        LaunchEffectKind.astronomy => 'Astronomy',
      };
}

/// 起動画面用の色・オーバーレイ・サウンド方針。
class WorldLaunchBranding {
  const WorldLaunchBranding({
    required this.profile,
    required this.effect,
    required this.profileLabel,
    required this.backgroundTop,
    required this.backgroundBottom,
    required this.accent,
    required this.secondaryAccent,
    required this.glow,
    required this.scanLineColor,
    required this.pulseColor,
    required this.particleColor,
    required this.subtitleColor,
    required this.isLightBackground,
    required this.showReadyLabel,
  });

  final WorldProfile profile;
  final LaunchEffectKind effect;
  final String profileLabel;
  final Color backgroundTop;
  final Color backgroundBottom;
  final Color accent;
  final Color secondaryAccent;
  final Color glow;
  final Color scanLineColor;
  final Color pulseColor;
  final Color particleColor;
  final Color subtitleColor;
  final bool isLightBackground;
  final bool showReadyLabel;

  factory WorldLaunchBranding.of(WorldProfile profile) {
    return switch (_effectFor(profile)) {
      LaunchEffectKind.cyber => _cyber(profile),
      LaunchEffectKind.horror => _horror(profile),
      LaunchEffectKind.pop => _pop(profile),
      LaunchEffectKind.tactical => _tactical(profile),
      LaunchEffectKind.magical => _magical(profile),
      LaunchEffectKind.astronomy => _astronomy(profile),
    };
  }

  static LaunchEffectKind _effectFor(WorldProfile profile) {
    return switch (profile) {
      WorldProfile.sciFi => LaunchEffectKind.cyber,
      WorldProfile.horror => LaunchEffectKind.horror,
      WorldProfile.sport => LaunchEffectKind.pop,
      WorldProfile.arg => LaunchEffectKind.tactical,
      WorldProfile.magical => LaunchEffectKind.magical,
      WorldProfile.astronomy => LaunchEffectKind.astronomy,
    };
  }

  static WorldLaunchBranding _cyber(WorldProfile profile) {
    return WorldLaunchBranding(
      profile: profile,
      effect: LaunchEffectKind.cyber,
      profileLabel: profile.label,
      backgroundTop: const Color(0xFF02040C),
      backgroundBottom: const Color(0xFF060E18),
      accent: const Color(0xFF00E5FF),
      secondaryAccent: const Color(0xFF7C4DFF),
      glow: const Color(0x5500E5FF),
      scanLineColor: const Color(0x4400B8D4),
      pulseColor: const Color(0xFF18FFFF),
      particleColor: const Color(0xFF40C4FF),
      subtitleColor: Colors.white.withValues(alpha: 0.68),
      isLightBackground: false,
      showReadyLabel: false,
    );
  }

  static WorldLaunchBranding _horror(WorldProfile profile) {
    final pack = WorldVisualPackFactory.of(profile);
    return WorldLaunchBranding(
      profile: profile,
      effect: LaunchEffectKind.horror,
      profileLabel: profile.label,
      backgroundTop: const Color(0xFF240008),
      backgroundBottom: const Color(0xFF060102),
      accent: const Color(0xFFE53935),
      secondaryAccent: const Color(0xFF4A0000),
      glow: const Color(0x66E53935),
      scanLineColor: const Color(0x18FFFFFF),
      pulseColor: pack.tokens.alertColor,
      particleColor: const Color(0xFFFF5252),
      subtitleColor: Colors.white.withValues(alpha: 0.52),
      isLightBackground: false,
      showReadyLabel: false,
    );
  }

  static WorldLaunchBranding _pop(WorldProfile profile) {
    return WorldLaunchBranding(
      profile: profile,
      effect: LaunchEffectKind.pop,
      profileLabel: profile.label,
      backgroundTop: const Color(0xFFFFF5FA),
      backgroundBottom: const Color(0xFFE3F5FF),
      accent: const Color(0xFFFF4081),
      secondaryAccent: const Color(0xFF40C4FF),
      glow: const Color(0x44FF4081),
      scanLineColor: const Color(0x18000000),
      pulseColor: const Color(0xFFFF6D9E),
      particleColor: const Color(0xFFFFD54F),
      subtitleColor: const Color(0x99000000),
      isLightBackground: true,
      showReadyLabel: false,
    );
  }

  static WorldLaunchBranding _tactical(WorldProfile profile) {
    return WorldLaunchBranding(
      profile: profile,
      effect: LaunchEffectKind.tactical,
      profileLabel: profile.label,
      backgroundTop: const Color(0xFF161A20),
      backgroundBottom: const Color(0xFF080A0E),
      accent: const Color(0xFF90A4AE),
      secondaryAccent: const Color(0xFF546E7A),
      glow: const Color(0x4490A4AE),
      scanLineColor: const Color(0x4489A4AE),
      pulseColor: const Color(0xFFB0BEC5),
      particleColor: const Color(0xFF78909C),
      subtitleColor: Colors.white.withValues(alpha: 0.58),
      isLightBackground: false,
      showReadyLabel: true,
    );
  }

  /// 魔法・不思議・キャンドルライト風（ハリーポッター的ムード、固有 IP は使わない）。
  static WorldLaunchBranding _magical(WorldProfile profile) {
    return WorldLaunchBranding(
      profile: profile,
      effect: LaunchEffectKind.magical,
      profileLabel: profile.label,
      backgroundTop: const Color(0xFF1A0A2E),
      backgroundBottom: const Color(0xFF0D0618),
      accent: const Color(0xFFD4AF37),
      secondaryAccent: const Color(0xFF9C27B0),
      glow: const Color(0x66D4AF37),
      scanLineColor: const Color(0x33CE93D8),
      pulseColor: const Color(0xFFFFD54F),
      particleColor: const Color(0xFFFFE082),
      subtitleColor: const Color(0xCCF3E5AB),
      isLightBackground: false,
      showReadyLabel: false,
    );
  }

  /// 星・宇宙・広大な空間。
  static WorldLaunchBranding _astronomy(WorldProfile profile) {
    return WorldLaunchBranding(
      profile: profile,
      effect: LaunchEffectKind.astronomy,
      profileLabel: profile.label,
      backgroundTop: const Color(0xFF050818),
      backgroundBottom: const Color(0xFF000208),
      accent: const Color(0xFF90CAF9),
      secondaryAccent: const Color(0xFF5C6BC0),
      glow: const Color(0x5590CAF9),
      scanLineColor: const Color(0x334FC3F7),
      pulseColor: const Color(0xFFFFD54F),
      particleColor: Colors.white,
      subtitleColor: Colors.white.withValues(alpha: 0.62),
      isLightBackground: false,
      showReadyLabel: false,
    );
  }
}
