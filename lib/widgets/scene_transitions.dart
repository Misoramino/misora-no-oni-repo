import 'dart:async';

import 'package:flutter/material.dart';

import '../audio/game_audio.dart';
import '../session/world_profile_prefs.dart';
import '../theme/world_profile.dart';
import '../presentation/world/world_studio_identity_catalog.dart';
import 'motion_helpers.dart';
import 'profile_scene_transition.dart';
import 'world_transition_fx.dart';

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
    Duration? reverseDuration,
  }) : super(
          transitionDuration:
              duration ?? _durationFor(worldProfile, reverse: false),
          reverseTransitionDuration:
              reverseDuration ?? _durationFor(worldProfile, reverse: true),
          pageBuilder: (context, animation, secondaryAnimation) =>
              builder(context),
          transitionsBuilder:
              (context, animation, secondaryAnimation, child) {
            final reduce = MotionHelpers.reduceMotionOf(context);
            return Stack(
              fit: StackFit.expand,
              children: [
                ProfileSceneTransition.build(
                  context: context,
                  animation: animation,
                  secondaryAnimation: secondaryAnimation,
                  child: child,
                  direction: direction,
                  profile: worldProfile,
                  reduceMotion: reduce,
                ),
                if (!reduce)
                  AnimatedBuilder(
                    animation: animation,
                    builder: (context, child) => WorldTransitionFxOverlay(
                      profile: worldProfile,
                      progress: animation.value,
                    ),
                  ),
              ],
            );
          },
        );

  final WidgetBuilder builder;
  final SceneTransitionDirection direction;
  final WorldProfile? worldProfile;

  static Duration _durationFor(WorldProfile? profile, {required bool reverse}) {
    if (profile == null) {
      return Duration(milliseconds: reverse ? 320 : 420);
    }
    final m = WorldStudioIdentityCatalog.of(profile).motion;
    return Duration(
      milliseconds: reverse ? m.reverseTransitionMs : m.transitionMs,
    );
  }
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
    final studio = WorldStudioIdentityCatalog.of(profile);
    final breath = studio.silence.transitionBreathMs;
    if (breath > 0) {
      await Future<void>.delayed(Duration(milliseconds: breath));
    }
    if (!context.mounted) return null;
    unawaited(GameAudio.instance.playTransitionSfx(profile));
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
    final studio = WorldStudioIdentityCatalog.of(profile);
    final breath = studio.silence.transitionBreathMs;
    if (breath > 0) {
      await Future<void>.delayed(Duration(milliseconds: breath));
    }
    if (!context.mounted) return null;
    unawaited(GameAudio.instance.playTransitionSfx(profile));
    return Navigator.of(context).pushReplacement<T, TO>(
      ScenePageRoute<T>(
        builder: builder,
        direction: direction,
        worldProfile: profile,
      ),
    );
  }
}
