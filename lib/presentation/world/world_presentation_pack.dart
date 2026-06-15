import 'package:flutter/material.dart';

import '../../theme/world_profile.dart';

/// マップピンのシルエット言語。
enum WorldPinSilhouette {
  classic,
  rounded,
  angular,
  hex,
  sigil,
  orbit,
  inkDrop,
  crest,
}

/// ローディング演出の種類。
enum WorldLoadingKind {
  horrorTape,
  popBounce,
  cyberPulse,
  tacticalGrid,
  magicalSigil,
  astronomyOrbit,
  zenBrush,
  royalSeal,
}

/// モーメント用パーティクル。
enum WorldParticleKind {
  smokeRain,
  neonPop,
  dataBits,
  dust,
  sparks,
  stardust,
  goldInk,
  lightRays,
}

/// フラッシュ演出の種類。
enum WorldFlashKind {
  vhsFlicker,
  popBurst,
  cyberGlitch,
  tacticalScan,
  sigilPulse,
  cosmicWave,
  inkWash,
  gildedCurtain,
}

/// ボタン形状・質感。
class WorldButtonShape {
  const WorldButtonShape({
    required this.borderRadius,
    this.borderWidth = 0,
    this.elevation = 2,
    this.pressScale = 0.97,
    this.useGradient = false,
    this.outlined = false,
  });

  final double borderRadius;
  final double borderWidth;
  final double elevation;
  final double pressScale;
  final bool useGradient;
  final bool outlined;
}

/// 1 世界観ぶんの UI / 演出パラメータ（ゲームロジック非依存）。
class WorldPresentationPack {
  const WorldPresentationPack({
    required this.profile,
    required this.tagline,
    required this.shortIntro,
    required this.headlineFont,
    required this.bodyFont,
    required this.headlineLetterSpacing,
    required this.bodyLetterSpacing,
    required this.headlineWeight,
    required this.bodyLineHeight,
    required this.scaffoldTop,
    required this.scaffoldBottom,
    required this.panelSurface,
    required this.panelBorder,
    required this.accent,
    required this.accentMuted,
    required this.onAccent,
    required this.successColor,
    required this.dangerColor,
    required this.warningColor,
    required this.profileIcon,
    required this.decorSymbol,
    required this.buttonShape,
    required this.loadingKind,
    required this.pinSilhouette,
    required this.momentParticle,
    required this.flashKind,
    required this.winAccent,
    required this.loseAccent,
    required this.resultHeadlineWin,
    required this.resultHeadlineLose,
    required this.chipBorderRadius,
    required this.hudCornerRadius,
  });

  final WorldProfile profile;
  final String tagline;
  final String shortIntro;

  /// Google Fonts family names.
  final String headlineFont;
  final String bodyFont;
  final double headlineLetterSpacing;
  final double bodyLetterSpacing;
  final FontWeight headlineWeight;
  final double bodyLineHeight;

  final Color scaffoldTop;
  final Color scaffoldBottom;
  final Color panelSurface;
  final Color panelBorder;
  final Color accent;
  final Color accentMuted;
  final Color onAccent;
  final Color successColor;
  final Color dangerColor;
  final Color warningColor;

  final IconData profileIcon;
  final String decorSymbol;

  final WorldButtonShape buttonShape;
  final WorldLoadingKind loadingKind;
  final WorldPinSilhouette pinSilhouette;
  final WorldParticleKind momentParticle;
  final WorldFlashKind flashKind;

  final Color winAccent;
  final Color loseAccent;
  final String resultHeadlineWin;
  final String resultHeadlineLose;

  final double chipBorderRadius;
  final double hudCornerRadius;

  LinearGradient get scaffoldGradient => LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [scaffoldTop, scaffoldBottom],
      );

  LinearGradient get accentGradient => LinearGradient(
        colors: [accent, accentMuted],
      );
}
