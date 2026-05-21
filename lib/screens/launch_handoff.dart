import '../theme/world_launch_branding.dart';

/// 起動 → タイトル遷移中に [TitleScreen] へ渡す状態。
class LaunchHandoffView {
  const LaunchHandoffView({
    required this.progress,
    required this.effectProgress,
    required this.branding,
  });

  /// 0 = 起動中央、1 = タイトル配置。
  final double progress;
  final double effectProgress;
  final WorldLaunchBranding branding;
}
