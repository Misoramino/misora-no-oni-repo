import 'package:flutter/animation.dart';

/// 起動シーケンス: 背景演出を主役に、ロゴ・文言・タイトル UI を重ねる。
abstract final class LaunchIntroTimeline {
  /// ロゴ・演出のフル表示が終わる正規化時刻（この後はタイトルレイアウトへ移行）。
  static const effectEnd = 0.52;

  static const logoHoldEnd = effectEnd;

  static const brandTextStart = 0.02;

  static const brandTextInEnd = 0.09;

  /// 「都市型 GPS…」はロゴ／ONI PIN のレイアウト移動が落ち着いてから表示
  /// （[layoutT] がこの値以上になってから専用スロット内で下から浮かび上がる）
  static const taglineLayoutGate = 0.88;

  /// 操作ボタン（オンライン/オフライン）を早めに表示
  static const bodyFadeStart = 0.08;

  static const bodyFadeEnd = 0.18;

  /// 全体の長さ（[AppLaunchShell] と一致）
  static const totalMs = 3000;

  /// 演出完了後、タイトルへ切り替える前のクロスフェード用ホールド
  static const handoffReleaseMs = 450;

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
      (intro / (effectEnd * 0.9)).clamp(0.0, 1.0),
    );
  }

  /// 背景演出は終盤まで維持（急な暗転を避ける）。
  static double effectOpacity(double intro) {
    if (intro < 0.85) return 1;
    final fade = Curves.easeOut.transform(
      ((intro - 0.85) / 0.15).clamp(0.0, 1.0),
    );
    return (1 - fade * 0.25).clamp(0.75, 1.0);
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

  /// 0 = スロット下端、1 = 定位置（[taglineLayoutGate] 未満は常に 0）
  static double taglineLayoutT(double intro) => _taglinePhase(intro);

  static double taglineOpacity(double intro) {
    final phase = _taglinePhase(intro);
    if (phase <= 0) return 0;
    return Curves.easeIn.transform(phase);
  }

  static double _taglinePhase(double intro) {
    final layout = layoutT(intro);
    if (layout < taglineLayoutGate) return 0;
    return Curves.easeOutCubic.transform(
      ((layout - taglineLayoutGate) / (1.0 - taglineLayoutGate)).clamp(0.0, 1.0),
    );
  }

  static double bodyOpacity(double intro) {
    if (intro < bodyFadeStart) return 0;
    if (intro < bodyFadeEnd) {
      return Curves.easeOut.transform(
        ((intro - bodyFadeStart) / (bodyFadeEnd - bodyFadeStart)).clamp(0.0, 1.0),
      );
    }
    return 1;
  }

  static double scaffoldBlend(double intro) => layoutT(intro);

  static double titleVeil(double intro) => 0;
}

final class LaunchHandoffVisuals {
  LaunchHandoffVisuals._(this.intro)
      : layoutT = LaunchIntroTimeline.layoutT(intro),
        logoReveal = LaunchIntroTimeline.logoReveal(intro),
        effectOpacity = LaunchIntroTimeline.effectOpacity(intro),
        brandTextOpacity = LaunchIntroTimeline.brandTextOpacity(intro),
        taglineLayoutT = LaunchIntroTimeline.taglineLayoutT(intro),
        taglineOpacity = LaunchIntroTimeline.taglineOpacity(intro),
        bodyOpacity = LaunchIntroTimeline.bodyOpacity(intro),
        titleVeil = LaunchIntroTimeline.titleVeil(intro),
        scaffoldBlend = LaunchIntroTimeline.scaffoldBlend(intro);

  final double intro;
  final double layoutT;
  final double logoReveal;
  final double effectOpacity;
  final double brandTextOpacity;
  final double taglineLayoutT;
  final double taglineOpacity;
  final double bodyOpacity;
  final double titleVeil;
  final double scaffoldBlend;
}
