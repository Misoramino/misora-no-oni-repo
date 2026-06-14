import 'package:flutter/material.dart';

import '../session/world_profile_prefs.dart';
import '../theme/world_profile.dart';
import 'profile_scene_transition.dart';

export 'profile_scene_transition.dart'
    show ProfileSceneTransition, SceneTransitionDirection;

/// 画面遷移の演出（フェードスルー＋世界観別モーション）。
class ScenePageRoute<T> extends PageRouteBuilder<T> {
  ScenePageRoute({
    required this.builder,
    this.direction = SceneTransitionDirection.forward,
    this.worldProfile,
    super.settings,
    Duration? duration,
  }) : super(
          transitionDuration: duration ?? const Duration(milliseconds: 420),
          reverseTransitionDuration: const Duration(milliseconds: 320),
          pageBuilder: (context, animation, secondaryAnimation) =>
              builder(context),
          transitionsBuilder:
              (context, animation, secondaryAnimation, child) {
            return ProfileSceneTransition.build(
              animation: animation,
              secondaryAnimation: secondaryAnimation,
              child: child,
              direction: direction,
              profile: worldProfile,
            );
          },
        );

  final WidgetBuilder builder;
  final SceneTransitionDirection direction;
  final WorldProfile? worldProfile;
}

/// アプリ標準のナビゲーション。演出付きで画面を切り替える。
abstract final class AppNav {
  static Future<T?> push<T>(
    BuildContext context,
    WidgetBuilder builder, {
    SceneTransitionDirection direction = SceneTransitionDirection.forward,
    WorldProfile? worldProfile,
    String? routeName,
  }) async {
    final profile = worldProfile ?? await WorldProfilePrefs.load();
    if (!context.mounted) return null;
    return Navigator.of(context).push<T>(
      ScenePageRoute<T>(
        builder: builder,
        direction: direction,
        worldProfile: profile,
        settings: routeName != null ? RouteSettings(name: routeName) : null,
      ),
    );
  }

  static Future<T?> pushReplacement<T, TO>(
    BuildContext context,
    WidgetBuilder builder, {
    SceneTransitionDirection direction = SceneTransitionDirection.forward,
    WorldProfile? worldProfile,
  }) async {
    final profile = worldProfile ?? await WorldProfilePrefs.load();
    if (!context.mounted) return null;
    return Navigator.of(context).pushReplacement<T, TO>(
      ScenePageRoute<T>(
        builder: builder,
        direction: direction,
        worldProfile: profile,
      ),
    );
  }
}
