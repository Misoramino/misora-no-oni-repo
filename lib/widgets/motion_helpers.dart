import 'package:flutter/material.dart';

/// アクセシビリティ設定に沿った演出の可否。
abstract final class MotionHelpers {
  static bool reduceMotionOf(BuildContext context) =>
      MediaQuery.disableAnimationsOf(context);

  static Duration durationOf(
    BuildContext context,
    Duration normal, {
    Duration? reduced,
  }) {
    if (reduceMotionOf(context)) {
      return reduced ?? Duration.zero;
    }
    return normal;
  }
}
