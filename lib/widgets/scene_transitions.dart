import 'package:flutter/material.dart';

/// 画面遷移の演出（フェードスルー＋わずかなスケール/スライド）。
///
/// 素の [MaterialPageRoute] より上質な切り替え感を与えるための共通ルート。
class ScenePageRoute<T> extends PageRouteBuilder<T> {
  ScenePageRoute({
    required this.builder,
    this.direction = SceneTransitionDirection.forward,
    super.settings,
    Duration? duration,
  }) : super(
          transitionDuration: duration ?? const Duration(milliseconds: 420),
          reverseTransitionDuration: const Duration(milliseconds: 320),
          pageBuilder: (context, animation, secondaryAnimation) =>
              builder(context),
          transitionsBuilder:
              (context, animation, secondaryAnimation, child) {
            final curved = CurvedAnimation(
              parent: animation,
              curve: Curves.easeOutCubic,
              reverseCurve: Curves.easeInCubic,
            );
            final slideDy = switch (direction) {
              SceneTransitionDirection.forward => 0.045,
              SceneTransitionDirection.back => -0.03,
              SceneTransitionDirection.up => 0.12,
            };
            return FadeTransition(
              opacity: curved,
              child: SlideTransition(
                position: Tween<Offset>(
                  begin: Offset(0, slideDy),
                  end: Offset.zero,
                ).animate(curved),
                child: ScaleTransition(
                  scale: Tween<double>(begin: 0.985, end: 1).animate(curved),
                  child: child,
                ),
              ),
            );
          },
        );

  final WidgetBuilder builder;
  final SceneTransitionDirection direction;
}

enum SceneTransitionDirection { forward, back, up }

/// アプリ標準のナビゲーション。演出付きで画面を切り替える。
abstract final class AppNav {
  static Future<T?> push<T>(
    BuildContext context,
    WidgetBuilder builder, {
    SceneTransitionDirection direction = SceneTransitionDirection.forward,
  }) {
    return Navigator.of(context).push<T>(
      ScenePageRoute<T>(builder: builder, direction: direction),
    );
  }

  static Future<T?> pushReplacement<T, TO>(
    BuildContext context,
    WidgetBuilder builder, {
    SceneTransitionDirection direction = SceneTransitionDirection.forward,
  }) {
    return Navigator.of(context).pushReplacement<T, TO>(
      ScenePageRoute<T>(builder: builder, direction: direction),
    );
  }
}
