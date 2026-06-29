import 'package:flutter/material.dart';

import 'world_launch_branding.dart';
import 'world_profile.dart';
import '../presentation/world/world_presentation_catalog.dart';
import '../presentation/world/world_presentation_pack.dart';

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
    final tileStrong = pack.isLightPanel
        ? pack.textOnPanel
        : (tileDark ? const Color(0xFFF2F2F7) : pack.textOnScaffold);
    final tileSoft = pack.isLightPanel
        ? pack.mutedOnPanel
        : (tileDark ? const Color(0xFFC7C7CC) : pack.mutedOnScaffold);

    final link = pack.accentOnScaffold;

    return MapHudPrepLegibility(
      background: background,
      title: title,
      body: body,
      muted: muted,
      tileSurface: tileSurface,
      tileTitle: tileSoft,
      tileValue: tileStrong,
      tileIcon: pack.accentOnScaffold,
      tileMutedIcon: tileSoft,
      link: link,
      decorativeIcon: muted.withValues(alpha: 0.72),
    );
  }
}

/// 試合中 HUD（地図上オーバーレイ）の前景色セット。
@immutable
class MapHudRunningLegibility {
  const MapHudRunningLegibility({
    required this.controlPanelBg,
    required this.infoPanelBg,
    required this.title,
    required this.body,
    required this.muted,
    required this.icon,
    required this.accent,
    required this.border,
    required this.chipBg,
    required this.chipFg,
    required this.skillButtonBg,
    required this.skillButtonFg,
    required this.skillButtonMuted,
    required this.warningBg,
    required this.warningFg,
    required this.cdChipBg,
    required this.cdChipFg,
  });

  final Color controlPanelBg;
  final Color infoPanelBg;
  final Color title;
  final Color body;
  final Color muted;
  final Color icon;
  final Color accent;
  final Color border;
  final Color chipBg;
  final Color chipFg;
  final Color skillButtonBg;
  final Color skillButtonFg;
  final Color skillButtonMuted;
  final Color warningBg;
  final Color warningFg;
  final Color cdChipBg;
  final Color cdChipFg;

  static MapHudRunningLegibility resolve(
    ColorScheme scheme,
    WorldProfile profile,
  ) {
    final pack = WorldPresentationCatalog.of(profile);
    final controlPanelBg =
        MapHudContrast.runningControlPanelBg(scheme, profile);
    final infoPanelBg = MapHudContrast.infoPanelSurface(scheme, profile);
    final titleOnInfo = MapHudContrast._textOnSurface(infoPanelBg, pack);
    final mutedOnInfo = MapHudContrast._mutedOnSurface(infoPanelBg, pack);
    final accent = pack.readableOnScaffold(pack.accentOnScaffold);
    final titleOnControl = MapHudContrast._textOnSurface(controlPanelBg, pack);
    final mutedOnControl =
        MapHudContrast._mutedOnSurface(controlPanelBg, pack);

    return MapHudRunningLegibility(
      controlPanelBg: controlPanelBg,
      infoPanelBg: infoPanelBg,
      title: titleOnInfo,
      body: titleOnInfo,
      muted: mutedOnInfo,
      icon: accent,
      accent: accent,
      border: pack.panelBorder.withValues(alpha: 0.55),
      chipBg: Color.alphaBlend(
        pack.accent.withValues(alpha: 0.22),
        infoPanelBg,
      ),
      chipFg: titleOnInfo,
      skillButtonBg: Color.alphaBlend(
        Colors.white.withValues(alpha: 0.12),
        controlPanelBg,
      ),
      skillButtonFg: titleOnControl,
      skillButtonMuted: mutedOnControl,
      warningBg: pack.dangerColor.withValues(alpha: 0.92),
      warningFg: Colors.white.withValues(alpha: 0.96),
      cdChipBg: Color.alphaBlend(
        Colors.black.withValues(alpha: 0.18),
        infoPanelBg,
      ),
      cdChipFg: titleOnInfo,
    );
  }
}

/// 準備中マップパネル（FAB 展開・ツール列）の色セット。
@immutable
class MapHudMapPanelLegibility {
  const MapHudMapPanelLegibility({
    required this.panelBg,
    required this.title,
    required this.body,
    required this.muted,
    required this.accent,
    required this.tileBg,
    required this.border,
    required this.highlightBg,
  });

  final Color panelBg;
  final Color title;
  final Color body;
  final Color muted;
  final Color accent;
  final Color tileBg;
  final Color border;
  final Color highlightBg;

  static MapHudMapPanelLegibility resolve(
    ColorScheme scheme,
    WorldProfile profile,
  ) {
    final pack = WorldPresentationCatalog.of(profile);
    final prep = MapHudPrepLegibility.resolve(scheme, profile);
    final panelBg = pack.panelSurfaceOpaque;
    return MapHudMapPanelLegibility(
      panelBg: panelBg,
      title: prep.title,
      body: prep.body,
      muted: prep.muted,
      accent: pack.accentOnScaffold,
      tileBg: prep.tileSurface,
      border: pack.panelBorder,
      highlightBg: Color.alphaBlend(
        pack.accent.withValues(alpha: 0.14),
        panelBg,
      ),
    );
  }
}

/// 図解・CustomPaint 向けの線/塗り色。
@immutable
class WorldDiagramLegibility {
  const WorldDiagramLegibility({
    required this.stroke,
    required this.fill,
    required this.mutedStroke,
    required this.label,
    required this.mutedLabel,
    required this.background,
  });

  final Color stroke;
  final Color fill;
  final Color mutedStroke;
  final Color label;
  final Color mutedLabel;
  final Color background;

  static WorldDiagramLegibility resolve(WorldProfile profile) {
    final pack = WorldPresentationCatalog.of(profile);
    final stroke = pack.accentOnScaffold;
    return WorldDiagramLegibility(
      stroke: stroke,
      fill: stroke.withValues(alpha: 0.18),
      mutedStroke: pack.mutedOnPanel,
      label: pack.textOnPanel,
      mutedLabel: pack.mutedOnPanel,
      background: pack.panelSurfaceOpaque.withValues(alpha: 0.55),
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

  static MapHudRunningLegibility runningLegibility(
    ColorScheme scheme,
    WorldProfile profile,
  ) =>
      MapHudRunningLegibility.resolve(scheme, profile);

  static MapHudMapPanelLegibility mapPanelLegibility(
    ColorScheme scheme,
    WorldProfile profile,
  ) =>
      MapHudMapPanelLegibility.resolve(scheme, profile);

  static Color _textOnSurface(Color surface, WorldPresentationPack pack) {
    // HUD パネル面の明度から直接前景を決める。pack.textOnPanel は
    // 「パネル＝明るい」世界観（マジカル/禅京都/ロイヤル）では暗色のため、
    // 暗い HUD 面に載せると暗文字 on 暗背景になってしまう。明度判定で回避。
    if (surface.computeLuminance() > 0.52) {
      return const Color(0xFF1A1A2E);
    }
    return const Color(0xFFF2F2F7);
  }

  static Color _mutedOnSurface(Color surface, WorldPresentationPack pack) {
    final base = _textOnSurface(surface, pack);
    return base.withValues(alpha: 0.78);
  }
}
