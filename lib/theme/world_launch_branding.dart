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

/// 起動画面用の色・オーバーレイ・ロゴ配色。
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
    required this.pinStroke,
    required this.hornFill,
    required this.titleHeadlineColor,
    required this.coreColor,
    required this.coreGlow,
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
  final Color pinStroke;
  /// 角の塗り（[pinStroke] にアクセントを少し混ぜた色）。
  final Color hornFill;
  /// タイトル「ONI PIN」見出し色（ロゴと同系統）。
  final Color titleHeadlineColor;
  final Color coreColor;
  final Color coreGlow;
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
    final t = WorldVisualPackFactory.of(profile).tokens;
    return WorldLaunchBranding(
      profile: profile,
      effect: LaunchEffectKind.cyber,
      profileLabel: profile.label,
      backgroundTop: const Color(0xFF0B1020),
      backgroundBottom: const Color(0xFF12082A),
      accent: t.markerAccent,
      secondaryAccent: t.revealRingColor,
      glow: const Color(0x3800E5FF),
      scanLineColor: const Color(0x264DD0E1),
      pulseColor: t.playerRingColor,
      particleColor: const Color(0xFF4DD0E1),
      subtitleColor: const Color(0x994DD0E1),
      pinStroke: const Color(0xFFE0F7FA),
      hornFill: const Color(0xFF1A2A4A),
      titleHeadlineColor: Color(0xFF80DEEA),
      coreColor: t.markerAccent,
      coreGlow: const Color(0x667C4DFF),
      isLightBackground: false,
      showReadyLabel: false,
    );
  }

  static WorldLaunchBranding _horror(WorldProfile profile) {
    final t = WorldVisualPackFactory.of(profile).tokens;
    return WorldLaunchBranding(
      profile: profile,
      effect: LaunchEffectKind.horror,
      profileLabel: profile.label,
      backgroundTop: const Color(0xFF1A0808),
      backgroundBottom: const Color(0xFF080808),
      accent: const Color(0xFFC62828),
      secondaryAccent: const Color(0xFF2C1010),
      glow: const Color(0x48B71C1C),
      scanLineColor: const Color(0x18FFFFFF),
      pulseColor: t.alertColor,
      particleColor: const Color(0xFF5D4037),
      subtitleColor: Colors.white.withValues(alpha: 0.48),
      pinStroke: const Color(0xFFD7CCC8),
      hornFill: const Color(0xFF3E1818),
      titleHeadlineColor: const Color(0xFFBCAAA4),
      coreColor: const Color(0xFFB71C1C),
      coreGlow: const Color(0x99C62828),
      isLightBackground: false,
      showReadyLabel: false,
    );
  }

  /// 明るくポップ（暗いグローは使わない）。
  static WorldLaunchBranding _pop(WorldProfile profile) {
    return WorldLaunchBranding(
      profile: profile,
      effect: LaunchEffectKind.pop,
      profileLabel: profile.label,
      backgroundTop: const Color(0xFFFFFBFE),
      backgroundBottom: const Color(0xFFF3EEFF),
      accent: const Color(0xFFF8BBD0),
      secondaryAccent: const Color(0xFFB2DFDB),
      glow: const Color(0x33F8BBD0),
      scanLineColor: const Color(0x0A000000),
      pulseColor: const Color(0xFFFFCCBC),
      particleColor: const Color(0xFFE1BEE7),
      subtitleColor: const Color(0xFF8D6E99),
      pinStroke: const Color(0xFFFFFFFF),
      hornFill: const Color(0xFFFFF5F8),
      titleHeadlineColor: Color(0xFFBC8FA8),
      coreColor: const Color(0xFFFFB3C6),
      coreGlow: const Color(0xAAFFF9C4),
      isLightBackground: true,
      showReadyLabel: false,
    );
  }

  static WorldLaunchBranding _tactical(WorldProfile profile) {
    final t = WorldVisualPackFactory.of(profile).tokens;
    return WorldLaunchBranding(
      profile: profile,
      effect: LaunchEffectKind.tactical,
      profileLabel: profile.label,
      backgroundTop: const Color(0xFF12151A),
      backgroundBottom: const Color(0xFF080A0D),
      accent: t.markerAccent,
      secondaryAccent: t.playAreaColor,
      glow: const Color(0x2878909C),
      scanLineColor: const Color(0xFF546E7A),
      pulseColor: t.playerRingColor,
      particleColor: t.traceColor,
      subtitleColor: Colors.white.withValues(alpha: 0.48),
      pinStroke: const Color(0xFF90A4AE),
      hornFill: const Color(0xFF455A64),
      titleHeadlineColor: Color(0xFFB0BEC5),
      coreColor: const Color(0xFF78909C),
      coreGlow: const Color(0x44646F7B),
      isLightBackground: false,
      showReadyLabel: true,
    );
  }

  static WorldLaunchBranding _magical(WorldProfile profile) {
    return WorldLaunchBranding(
      profile: profile,
      effect: LaunchEffectKind.magical,
      profileLabel: profile.label,
      backgroundTop: const Color(0xFF1C1208),
      backgroundBottom: const Color(0xFF0E0804),
      accent: const Color(0xFFC9A227),
      secondaryAccent: const Color(0xFF5D4037),
      glow: const Color(0x66C9A227),
      scanLineColor: const Color(0x338D6E63),
      pulseColor: const Color(0xFFE8D5A3),
      particleColor: const Color(0xFFFFE082),
      subtitleColor: const Color(0xCCD7CCC8),
      pinStroke: const Color(0xFFFFF8E1),
      hornFill: const Color(0xFFEFEBE9),
      titleHeadlineColor: Color(0xFFE8D5A3),
      coreColor: const Color(0xFFFFD54F),
      coreGlow: const Color(0xBB7E57C2),
      isLightBackground: false,
      showReadyLabel: false,
    );
  }

  static WorldLaunchBranding _astronomy(WorldProfile profile) {
    return WorldLaunchBranding(
      profile: profile,
      effect: LaunchEffectKind.astronomy,
      profileLabel: profile.label,
      backgroundTop: const Color(0xFF020510),
      backgroundBottom: const Color(0xFF00020A),
      accent: const Color(0xFF90CAF9),
      secondaryAccent: const Color(0xFF283593),
      glow: const Color(0x4490CAF9),
      scanLineColor: const Color(0x334FC3F7),
      pulseColor: const Color(0xFFFFF8E1),
      particleColor: const Color(0xFFE3F2FD),
      subtitleColor: Colors.white.withValues(alpha: 0.62),
      pinStroke: const Color(0xFFE3F2FD),
      hornFill: const Color(0xFF90CAF9),
      titleHeadlineColor: Color(0xFFE3F2FD),
      coreColor: const Color(0xFFFFFFFF),
      coreGlow: const Color(0xBB64B5F6),
      isLightBackground: false,
      showReadyLabel: false,
    );
  }
}
