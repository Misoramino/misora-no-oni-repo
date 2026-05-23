import 'package:flutter/animation.dart';

/// 起動シーケンス: 背景演出を主役に、ロゴ・文言・タイトル UI を重ねる。
abstract final class LaunchIntroTimeline {
  /// ロゴ・演出のフル表示が終わる正規化時刻（この後はタイトルレイアウトへ移行）。
  static const effectEnd = 0.60;

  static const logoHoldEnd = effectEnd;

  /// 文言は演出開始直後からフェードイン（静止ロゴ専用時間なし）。
  static const brandTextStart = 0.03;

  static const brandTextInEnd = 0.11;

  /// 全体の長さ（[AppLaunchShell] と一致）
  static const totalMs = 5600;

  static LaunchHandoffVisuals visuals(double intro) =>
      LaunchHandoffVisuals._(intro);

  static double layoutT(double intro) {
    if (intro <= effectEnd) return 0;
    return Curves.easeInOut.transform(
      ((intro - effectEnd) / (1 - effectEnd)).clamp(0.0, 1.0),
    );
  }

  static double logoReveal(double intro) {
    if (intro >= effectEnd) return 1;
    return Curves.easeOut.transform(
      (intro / (effectEnd * 0.85)).clamp(0.0, 1.0),
    );
  }

  /// 背景演出は序盤〜中盤まで常にフル表示。終盤だけわずかに落とす。
  static double effectOpacity(double intro) {
    if (intro < 0.72) return 1;
    final fade = Curves.easeOut.transform(
      ((intro - 0.72) / 0.28).clamp(0.0, 1.0),
    );
    return (1 - fade * 0.32).clamp(0.68, 1.0);
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

  /// タイトル操作 UI は演出の上に早めに載せる（暗転なし）。
  static double bodyOpacity(double intro) {
    if (intro < 0.16) return 0;
    if (intro < 0.30) {
      return Curves.easeOut.transform(
        ((intro - 0.16) / 0.14).clamp(0.0, 1.0),
      );
    }
    return 1;
  }

  static double scaffoldBlend(double intro) => layoutT(intro);

  /// 暗いベールは使わない（演出が見えなくなるため）。
  static double titleVeil(double intro) => 0;
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
