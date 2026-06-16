import 'package:flutter/material.dart';

/// 世界観に依存しない共通 UI レイアウト（位置・余白・当たり判定）。
///
/// フォント・色・装飾・背景・エフェクトのみ世界観で差し替える。
abstract final class WorldUILayout {
  static const double screenPaddingH = 20;
  static const double screenPaddingV = 16;
  static const double sectionGap = 16;
  static const double cardGap = 10;
  static const double dialogPaddingH = 20;
  static const bool symmetric = true;
  static const Alignment contentAlign = Alignment.center;
  static const double cardFloat = 4;
  static const double galleryHeroHeight = 0.32;
  static const double dialogBorderRadius = 22;

  static EdgeInsets screenPadding(BuildContext context) =>
      const EdgeInsets.symmetric(
        horizontal: screenPaddingH,
        vertical: screenPaddingV,
      );

  static EdgeInsets dialogInsets(BuildContext context) => EdgeInsets.symmetric(
        horizontal: dialogPaddingH,
        vertical: screenPaddingV + 8,
      );
}
