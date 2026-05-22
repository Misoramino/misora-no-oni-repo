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
      pinStroke: const Color(0xFFE0FFFF),
      hornFill: const Color(0xFFB2EBF2),
      titleHeadlineColor: Color(0xFFE0FFFF),
      coreColor: const Color(0xFF00E5FF),
      coreGlow: const Color(0xCCFF1744),
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
      pinStroke: const Color(0xFFF5F5F5),
      hornFill: const Color(0xFFFFCDD2),
      titleHeadlineColor: Color(0xFFFFEBEE),
      coreColor: const Color(0xFFE53935),
      coreGlow: const Color(0xBBE53935),
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
      backgroundTop: const Color(0xFFFFF8FC),
      backgroundBottom: const Color(0xFFE8F7FF),
      accent: const Color(0xFFFF4081),
      secondaryAccent: const Color(0xFF29B6F6),
      glow: const Color(0x55FFB3D9),
      scanLineColor: const Color(0x12000000),
      pulseColor: const Color(0xFFFF80AB),
      particleColor: const Color(0xFFFFD54F),
      subtitleColor: const Color(0xFF5D4037),
      pinStroke: const Color(0xFFFFFFFF),
      hornFill: const Color(0xFFFFF0F5),
      titleHeadlineColor: Color(0xFFC2185B),
      coreColor: const Color(0xFFFF4081),
      coreGlow: const Color(0x99FFEB3B),
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
      pinStroke: const Color(0xFFECEFF1),
      hornFill: const Color(0xFFCFD8DC),
      titleHeadlineColor: Color(0xFFECEFF1),
      coreColor: const Color(0xFFFFB300),
      coreGlow: const Color(0x99FFB300),
      isLightBackground: false,
      showReadyLabel: true,
    );
  }

  static WorldLaunchBranding _magical(WorldProfile profile) {
    return WorldLaunchBranding(
      profile: profile,
      effect: LaunchEffectKind.magical,
      profileLabel: profile.label,
      backgroundTop: const Color(0xFF1A0A2E),
      backgroundBottom: const Color(0xFF0D0618),
      accent: const Color(0xFFD4AF37),
      secondaryAccent: const Color(0xFFCE93D8),
      glow: const Color(0x77D4AF37),
      scanLineColor: const Color(0x33CE93D8),
      pulseColor: const Color(0xFFFFD54F),
      particleColor: const Color(0xFFFFE082),
      subtitleColor: const Color(0xCCF3E5AB),
      pinStroke: const Color(0xFFFFF8E1),
      hornFill: const Color(0xFFFFF9C4),
      titleHeadlineColor: Color(0xFFFFF8E1),
      coreColor: const Color(0xFFFFD54F),
      coreGlow: const Color(0xBBE040FB),
      isLightBackground: false,
      showReadyLabel: false,
    );
  }

  static WorldLaunchBranding _astronomy(WorldProfile profile) {
    return WorldLaunchBranding(
      profile: profile,
      effect: LaunchEffectKind.astronomy,
      profileLabel: profile.label,
      backgroundTop: const Color(0xFF050818),
      backgroundBottom: const Color(0xFF000208),
      accent: const Color(0xFF90CAF9),
      secondaryAccent: const Color(0xFF7986CB),
      glow: const Color(0x5590CAF9),
      scanLineColor: const Color(0x334FC3F7),
      pulseColor: const Color(0xFFFFD54F),
      particleColor: Colors.white,
      subtitleColor: Colors.white.withValues(alpha: 0.62),
      pinStroke: const Color(0xFFE3F2FD),
      hornFill: const Color(0xFFBBDEFB),
      titleHeadlineColor: Color(0xFFE3F2FD),
      coreColor: const Color(0xFFFFD54F),
      coreGlow: const Color(0xBB90CAF9),
      isLightBackground: false,
      showReadyLabel: false,
    );
  }
}
