import 'package:flutter/material.dart';

import 'world_launch_branding.dart';
import 'world_profile.dart';

/// 準備画面（地図オフ）の背景に対して読みやすい前景色セット。
@immutable
class MapHudPrepLegibility {
  const MapHudPrepLegibility({
    required this.background,
    required this.title,
    required this.body,
    required this.muted,
    required this.tileSurface,
    required this.tileTitle,
    required this.tileValue,
    required this.tileIcon,
    required this.tileMutedIcon,
    required this.link,
    required this.decorativeIcon,
  });

  final Color background;
  final Color title;
  final Color body;
  final Color muted;
  final Color tileSurface;
  final Color tileTitle;
  final Color tileValue;
  final Color tileIcon;
  final Color tileMutedIcon;
  final Color link;
  final Color decorativeIcon;

  static MapHudPrepLegibility resolve(
    ColorScheme scheme,
    WorldProfile profile,
  ) {
    final background = MapHudContrast.prepScaffoldBg(scheme, profile);
    final darkBg =
        ThemeData.estimateBrightnessForColor(background) == Brightness.dark;

    /// 背景上で十分なコントラストになるよう前景を選ぶ。
    Color strong() => darkBg
        ? const Color(0xFFF2F2F7)
        : const Color(0xFF1A1C1E);
    Color soft() => darkBg
        ? const Color(0xFFC7C7CC)
        : const Color(0xFF44474E);

    final tileSurface = darkBg
        ? Color.alphaBlend(Colors.white.withValues(alpha: 0.1), background)
        : Color.alphaBlend(Colors.black.withValues(alpha: 0.06), background);

    final tileDark =
        ThemeData.estimateBrightnessForColor(tileSurface) == Brightness.dark;
    final tileStrong = tileDark
        ? const Color(0xFFF2F2F7)
        : const Color(0xFF1A1C1E);
    final tileSoft = tileDark
        ? const Color(0xFFC7C7CC)
        : const Color(0xFF5C5F66);

    final primary = scheme.primary;
    final link = darkBg
        ? Color.alphaBlend(primary.withValues(alpha: 0.85), Colors.white)
        : primary;

    return MapHudPrepLegibility(
      background: background,
      title: strong(),
      body: strong(),
      muted: soft(),
      tileSurface: tileSurface,
      tileTitle: tileSoft,
      tileValue: tileStrong,
      tileIcon: primary,
      tileMutedIcon: tileSoft,
      link: link,
      decorativeIcon: soft().withValues(alpha: darkBg ? 0.55 : 0.65),
    );
  }
}

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
        return scheme.surface.withValues(alpha: 0.93);
      case WorldProfile.sport:
        return Color.alphaBlend(
          const Color(0xFF1A1C1E).withValues(alpha: 0.06),
          scheme.surface.withValues(alpha: 0.94),
        );
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
        return hi.withValues(alpha: 0.93);
      case WorldProfile.sport:
        return Color.alphaBlend(
          const Color(0xFF1A1C1E).withValues(alpha: 0.08),
          hi.withValues(alpha: 0.96),
        );
    }
  }

  /// 準備フェーズ（地図オフ）— 起動画面と同系の暗い世界観色（灰一色の surface は使わない）。
  static Color prepScaffoldBg(ColorScheme scheme, WorldProfile profile) {
    final launch = WorldLaunchBranding.of(profile);
    if (launch.isLightBackground) {
      return Color.alphaBlend(
        launch.accent.withValues(alpha: 0.06),
        launch.backgroundBottom,
      );
    }
    return Color.alphaBlend(
      launch.glow.withValues(alpha: 0.12),
      launch.backgroundBottom,
    );
  }

  /// 準備画面の背景色に合わせた前景色（ライト／ダークの [ColorScheme] および世界観の下地の明度から算出）。
  static MapHudPrepLegibility prepLegibility(
    ColorScheme scheme,
    WorldProfile profile,
  ) =>
      MapHudPrepLegibility.resolve(scheme, profile);
}
