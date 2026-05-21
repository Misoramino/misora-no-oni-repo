import 'package:flutter/material.dart';

/// ONI PIN ブランドロゴ（PNG）。
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

/// 起動画面用シンボル（文字なし）。
class SplashLogo extends StatelessWidget {
  const SplashLogo({
    this.size = 112,
    super.key,
  });

  final double size;

  static const assetPath = 'assets/branding/splash_logo.png';

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      assetPath,
      width: size,
      height: size,
      fit: BoxFit.contain,
      filterQuality: FilterQuality.high,
      semanticLabel: 'ONI PIN',
    );
  }
}
