import 'package:flutter/material.dart';

import '../theme/world_profile.dart';

/// 世界観ごとの画面遷移ビルダー。
abstract final class ProfileSceneTransition {
  static Widget build({
    required Animation<double> animation,
    required Animation<double> secondaryAnimation,
    required Widget child,
    required SceneTransitionDirection direction,
    WorldProfile? profile,
  }) {
    final curved = CurvedAnimation(
      parent: animation,
      curve: _curveFor(profile, direction),
      reverseCurve: Curves.easeInCubic,
    );

    return switch (profile) {
      WorldProfile.sciFi => _cyber(curved, child),
      WorldProfile.horror => _horror(curved, child),
      WorldProfile.sport => _pop(curved, child, direction),
      WorldProfile.arg => _tactical(curved, child, direction),
      WorldProfile.magical => _magical(curved, child),
      WorldProfile.astronomy => _astronomy(curved, child),
      _ => _default(curved, child, direction),
    };
  }

  static Curve _curveFor(WorldProfile? profile, SceneTransitionDirection dir) {
    if (profile == WorldProfile.sport) return Curves.elasticOut;
    if (profile == WorldProfile.arg) return Curves.easeOutQuart;
    return Curves.easeOutCubic;
  }

  static Widget _default(
    Animation<double> curved,
    Widget child,
    SceneTransitionDirection direction,
  ) {
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
  }

  static Widget _cyber(Animation<double> curved, Widget child) {
    return FadeTransition(
      opacity: curved,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0.08, 0),
          end: Offset.zero,
        ).animate(curved),
        child: child,
      ),
    );
  }

  static Widget _horror(Animation<double> curved, Widget child) {
    return AnimatedBuilder(
      animation: curved,
      builder: (context, c) {
        final jitter = (1 - curved.value) * 6;
        return Transform.translate(
          offset: Offset(jitter * (curved.value - 0.5), 0),
          child: FadeTransition(
            opacity: curved,
            child: c,
          ),
        );
      },
      child: child,
    );
  }

  static Widget _pop(
    Animation<double> curved,
    Widget child,
    SceneTransitionDirection direction,
  ) {
    return FadeTransition(
      opacity: curved,
      child: ScaleTransition(
        scale: Tween<double>(begin: 0.9, end: 1).animate(curved),
        child: SlideTransition(
          position: Tween<Offset>(
            begin: Offset(0, direction == SceneTransitionDirection.up ? 0.1 : 0.05),
            end: Offset.zero,
          ).animate(curved),
          child: child,
        ),
      ),
    );
  }

  static Widget _tactical(
    Animation<double> curved,
    Widget child,
    SceneTransitionDirection direction,
  ) {
    final dx = direction == SceneTransitionDirection.back ? -0.06 : 0.06;
    return FadeTransition(
      opacity: Tween<double>(begin: 0, end: 1).animate(
        CurvedAnimation(parent: curved, curve: const Interval(0.2, 1)),
      ),
      child: SlideTransition(
        position: Tween<Offset>(
          begin: Offset(dx, 0),
          end: Offset.zero,
        ).animate(curved),
        child: child,
      ),
    );
  }

  static Widget _magical(Animation<double> curved, Widget child) {
    return FadeTransition(
      opacity: curved,
      child: RotationTransition(
        turns: Tween<double>(begin: 0.01, end: 0).animate(curved),
        child: ScaleTransition(
          scale: Tween<double>(begin: 0.96, end: 1).animate(curved),
          child: child,
        ),
      ),
    );
  }

  static Widget _astronomy(Animation<double> curved, Widget child) {
    return FadeTransition(
      opacity: curved,
      child: ScaleTransition(
        scale: Tween<double>(begin: 0.82, end: 1).animate(curved),
        alignment: Alignment.center,
        child: child,
      ),
    );
  }
}

/// 画面遷移の方向（[ScenePageRoute] / [AppNav] 共通）。
enum SceneTransitionDirection { forward, back, up }
