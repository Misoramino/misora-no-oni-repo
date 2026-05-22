import 'package:flutter/animation.dart';

/// 起動シーケンス: 演出 → ロゴ画面 → タイトル（フェード付き遷移）。
abstract final class LaunchIntroTimeline {
  /// 演出のみ（ロゴは小さくフェードイン）
  static const effectEnd = 0.32;

  /// ロゴ画面ホールド（文言は演出中から重なる）
  static const logoHoldEnd = 0.48;

  /// 文言が出始める（演出フェーズ内）
  static const brandTextStart = 0.08;

  /// 文言フェードイン完了
  static const brandTextInEnd = 0.18;

  /// 全体の長さ（[AppLaunchShell] と一致）
  static const totalMs = 5000;

  /// [intro] から UI 用の opacity / レイアウト値を一括算出。
  static LaunchHandoffVisuals visuals(double intro) =>
      LaunchHandoffVisuals._(intro);

  static double layoutT(double intro) {
    if (intro <= logoHoldEnd) return 0;
    return Curves.easeOutCubic.transform(
      ((intro - logoHoldEnd) / (1 - logoHoldEnd)).clamp(0.0, 1.0),
    );
  }

  /// 演出フェーズ中のロゴ出現（0→1）。
  static double logoReveal(double intro) {
    if (intro >= effectEnd) return 1;
    return Curves.easeOutCubic.transform(
      (intro / effectEnd).clamp(0.0, 1.0),
    );
  }

  static double effectOpacity(double intro) {
    if (intro <= effectEnd) return 1;
    if (intro <= logoHoldEnd) {
      final t = (intro - effectEnd) / (logoHoldEnd - effectEnd);
      return 1 - t * 0.22;
    }
    final t = layoutT(intro);
    return (1 - Curves.easeOut.transform(t)) * 0.72;
  }

  /// 演出と重なるタイミングで ONI PIN 文言を表示。
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
    if (intro < logoHoldEnd + 0.03) return 0;
    return Curves.easeIn.transform(
      ((intro - (logoHoldEnd + 0.03)) / (1 - logoHoldEnd - 0.03)).clamp(0.0, 1.0),
    );
  }

  static double scaffoldBlend(double intro) => layoutT(intro);

  static double titleVeil(double intro) {
    if (intro < logoHoldEnd - 0.02) return 0;
    if (intro < logoHoldEnd + 0.12) {
      return Curves.easeInOut.transform(
        ((intro - (logoHoldEnd - 0.02)) / 0.14).clamp(0.0, 1.0),
      );
    }
    return (1 - layoutT(intro)).clamp(0.0, 1.0);
  }
}

/// 起動 handoff 中の opacity・レイアウト（毎フレームの重複計算を避ける）。
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
