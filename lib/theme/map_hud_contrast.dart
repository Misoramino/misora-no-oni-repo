import 'package:flutter/material.dart';

import 'world_launch_branding.dart';
import 'world_profile.dart';
import '../presentation/world/world_presentation_catalog.dart';

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
    final pack = WorldPresentationCatalog.of(profile);
    final background = MapHudContrast.prepScaffoldBg(scheme, profile);

    final title = pack.textOnScaffold;
    final body = pack.textOnScaffold;
    final muted = pack.mutedOnScaffold;

    final tileSurface = pack.isLightScaffold
        ? Color.alphaBlend(Colors.black.withValues(alpha: 0.05), pack.panelSurface)
        : Color.alphaBlend(Colors.white.withValues(alpha: 0.08), pack.panelSurface);

    final tileDark =
        ThemeData.estimateBrightnessForColor(tileSurface) == Brightness.dark;
    final tileStrong = tileDark ? const Color(0xFFF2F2F7) : pack.textOnScaffold;
    final tileSoft = tileDark
        ? const Color(0xFFC7C7CC)
        : pack.mutedOnScaffold;

    final primary = scheme.primary;
    final link = pack.isLightScaffold
        ? Color.alphaBlend(primary.withValues(alpha: 0.88), Colors.black)
        : Color.alphaBlend(primary.withValues(alpha: 0.85), Colors.white);

    return MapHudPrepLegibility(
      background: background,
      title: title,
      body: body,
      muted: muted,
      tileSurface: tileSurface,
      tileTitle: tileSoft,
      tileValue: tileStrong,
      tileIcon: primary,
      tileMutedIcon: tileSoft,
      link: link,
      decorativeIcon: muted.withValues(alpha: 0.72),
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
      case WorldProfile.japaneseLuxury:
      case WorldProfile.westernLuxury:
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
          const Color(0xFF1A1C1E).withValues(alpha: 0.22),
          scheme.surface.withValues(alpha: 0.97),
        );
    }
  }

  /// 上部情報パネル（折りたたみ／展開）
  static Color infoPanelSurface(ColorScheme scheme, WorldProfile profile) {
    final hi = scheme.surfaceContainerHigh;
    switch (profile) {
      case WorldProfile.horror:
      case WorldProfile.astronomy:
      case WorldProfile.japaneseLuxury:
      case WorldProfile.westernLuxury:
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
