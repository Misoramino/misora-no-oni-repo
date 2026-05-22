import 'package:flutter/animation.dart';

/// 起動シーケンス: 演出 → ロゴ＋文言 → タイトル（フェード付き遷移）。
abstract final class LaunchIntroTimeline {
  /// 演出フル（背景エフェクト＋ロゴ出現）
  static const effectEnd = 0.38;

  /// ロゴ＋文言ホールド（短め — すぐタイトルレイアウトへ）
  static const logoHoldEnd = 0.41;

  /// 文言が出始める（演出と重なる）
  static const brandTextStart = 0.06;

  /// 文言フェードイン完了
  static const brandTextInEnd = 0.14;

  /// 全体の長さ（[AppLaunchShell] と一致）
  static const totalMs = 3800;

  static LaunchHandoffVisuals visuals(double intro) =>
      LaunchHandoffVisuals._(intro);

  static double layoutT(double intro) {
    if (intro <= logoHoldEnd) return 0;
    return Curves.easeOut.transform(
      ((intro - logoHoldEnd) / (1 - logoHoldEnd)).clamp(0.0, 1.0),
    );
  }

  static double logoReveal(double intro) {
    if (intro >= effectEnd) return 1;
    return Curves.easeOut.transform(
      (intro / effectEnd).clamp(0.0, 1.0),
    );
  }

  static double effectOpacity(double intro) {
    if (intro <= effectEnd) return 1;
    if (intro <= logoHoldEnd) {
      final t = (intro - effectEnd) / (logoHoldEnd - effectEnd);
      return 1 - t * 0.3;
    }
    final t = layoutT(intro);
    return (1 - Curves.easeOut.transform(t)) * 0.68;
  }

  static double brandTextOpacity(double intro) {
    if (intro < brandTextStart) return 0;
    if (intro < brandTextInEnd) {
      return Curves.easeIn.transform(
        ((intro - brandTextStart) / (brandTextInEnd - brandTextStart))
            .clamp(0.0, 1.0),
      );
    }
    return 1;
  }

  static double bodyOpacity(double intro) {
    if (intro < logoHoldEnd + 0.02) return 0;
    return Curves.easeIn.transform(
      ((intro - (logoHoldEnd + 0.02)) / (1 - logoHoldEnd - 0.02)).clamp(0.0, 1.0),
    );
  }

  static double scaffoldBlend(double intro) => layoutT(intro);

  static double titleVeil(double intro) {
    if (intro < logoHoldEnd - 0.01) return 0;
    if (intro < logoHoldEnd + 0.08) {
      return Curves.easeInOut.transform(
        ((intro - (logoHoldEnd - 0.01)) / 0.09).clamp(0.0, 1.0),
      );
    }
    return (1 - layoutT(intro)).clamp(0.0, 1.0);
  }
}

final class LaunchHandoffVisuals {
  LaunchHandoffVisuals._(this.intro)
      : layoutT = LaunchIntroTimeline.layoutT(intro),
        logoReveal = LaunchIntroTimeline.logoReveal(intro),
        effectOpacity = LaunchIntroTimeline.effectOpacity(intro),
        brandTextOpacity = LaunchIntroTimeline.brandTextOpacity(intro),
        bodyOpacity = LaunchIntroTimeline.bodyOpacity(intro),
        titleVeil = LaunchIntroTimeline.titleVeil(intro),
        scaffoldBlend = LaunchIntroTimeline.scaffoldBlend(intro);

  final double intro;
  final double layoutT;
  final double logoReveal;
  final double effectOpacity;
  final double brandTextOpacity;
  final double bodyOpacity;
  final double titleVeil;
  final double scaffoldBlend;
}
