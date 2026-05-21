import 'package:flutter/material.dart';

/// ONI PIN ブランドロゴ（PNG）。README・共有画像用。
///
/// アプリ内 UI は [ThemedGeometricLogo]（世界観別の図形マーク）を使用。
class BrandLogo extends StatelessWidget {
  const BrandLogo({
    this.width = 280,
    this.fit = BoxFit.contain,
    super.key,
  });

  final double width;
  final BoxFit fit;

  static const assetPath = 'assets/branding/brand_logo.png';

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      assetPath,
      width: width,
      fit: fit,
      filterQuality: FilterQuality.high,
      semanticLabel: 'ONI PIN — GPS × ONI GAME',
    );
  }
}
