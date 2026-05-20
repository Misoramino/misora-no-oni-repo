import 'package:flutter/material.dart';

import 'world_profile.dart';

/// 暗い地図スタイルでも HUD / パネルが読みやすいよう、世界観に応じた背景の微調整。
abstract final class MapHudContrast {
  /// 試合中・下部コントロールパネル
  static Color runningControlPanelBg(
    ColorScheme scheme,
    WorldProfile profile,
  ) {
    switch (profile) {
      case WorldProfile.horror:
      case WorldProfile.astronomy:
        return Color.alphaBlend(
          const Color(0xFFFFF8F5).withValues(alpha: 0.11),
          scheme.surface.withValues(alpha: 0.96),
        );
      case WorldProfile.sciFi:
        return Color.alphaBlend(
          const Color(0xFF00E5FF).withValues(alpha: 0.065),
          scheme.surface.withValues(alpha: 0.95),
        );
      case WorldProfile.arg:
        return Color.alphaBlend(
          Colors.white.withValues(alpha: 0.075),
          scheme.surface.withValues(alpha: 0.96),
        );
      case WorldProfile.magical:
      case WorldProfile.sport:
        return scheme.surface.withValues(alpha: 0.93);
    }
  }

  /// 上部情報パネル（折りたたみ／展開）
  static Color infoPanelSurface(ColorScheme scheme, WorldProfile profile) {
    final hi = scheme.surfaceContainerHigh;
    switch (profile) {
      case WorldProfile.horror:
      case WorldProfile.astronomy:
        return Color.alphaBlend(
          Colors.white.withValues(alpha: 0.12),
          hi.withValues(alpha: 0.97),
        );
      case WorldProfile.sciFi:
        return Color.alphaBlend(
          const Color(0xFF64FFDA).withValues(alpha: 0.075),
          hi.withValues(alpha: 0.96),
        );
      case WorldProfile.arg:
        return Color.alphaBlend(
          Colors.white.withValues(alpha: 0.095),
          hi.withValues(alpha: 0.97),
        );
      case WorldProfile.magical:
      case WorldProfile.sport:
        return hi.withValues(alpha: 0.93);
    }
  }

  /// 準備フェーズ（地図オフ）のメイン背景
  static Color prepScaffoldBg(ColorScheme scheme, WorldProfile profile) {
    final hi = scheme.surfaceContainerHighest;
    switch (profile) {
      case WorldProfile.horror:
      case WorldProfile.astronomy:
        return Color.alphaBlend(
          Colors.white.withValues(alpha: 0.065),
          hi,
        );
      case WorldProfile.arg:
        return Color.alphaBlend(
          Colors.white.withValues(alpha: 0.055),
          hi,
        );
      case WorldProfile.sciFi:
        return Color.alphaBlend(
          const Color(0xFFB2EBF2).withValues(alpha: 0.055),
          hi,
        );
      case WorldProfile.magical:
      case WorldProfile.sport:
        return hi;
    }
  }
}
