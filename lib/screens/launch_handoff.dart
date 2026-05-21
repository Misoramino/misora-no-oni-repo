import '../theme/world_launch_branding.dart';

/// 起動 → タイトル遷移中に [TitleScreen] へ渡す状態。
class LaunchHandoffView {
  const LaunchHandoffView({
    required this.introProgress,
    required this.effectProgress,
    required this.branding,
  });

  /// 0..1 全体タイムライン（演出 → ロゴ画面 → タイトル）。
  final double introProgress;
  final double effectProgress;
  final WorldLaunchBranding branding;
}
