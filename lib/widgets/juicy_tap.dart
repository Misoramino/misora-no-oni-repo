import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../audio/game_audio.dart';
import '../audio/sfx_id.dart';

/// 押すと縮む・SE が鳴る「気持ちよさ」を任意の子に付与するラッパ。
///
/// 既存のボタン/カードを置き換えずに包むだけで、押下フィードバックを足せる。
class JuicyTap extends StatefulWidget {
  const JuicyTap({
    super.key,
    required this.child,
    required this.onTap,
    this.sfx = SfxId.uiTap,
    this.haptic = true,
    this.pressedScale = 0.94,
    this.enabled = true,
  });

  final Widget child;
  final VoidCallback? onTap;
  final SfxId sfx;
  final bool haptic;
  final double pressedScale;
  final bool enabled;

  @override
  State<JuicyTap> createState() => _JuicyTapState();
}

class _JuicyTapState extends State<JuicyTap>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 90),
    reverseDuration: const Duration(milliseconds: 160),
    lowerBound: 0,
    upperBound: 1,
  );

  bool get _active => widget.enabled && widget.onTap != null;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _down(_) {
    if (!_active) return;
    _controller.forward();
  }

  void _up(_) {
    _controller.reverse();
  }

  void _cancel() {
    _controller.reverse();
  }

  void _tap() {
    if (!_active) return;
    if (widget.haptic) HapticFeedback.selectionClick();
    GameAudio.instance.playSfx(widget.sfx);
    widget.onTap!();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: _down,
      onTapUp: _up,
      onTapCancel: _cancel,
      onTap: _tap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          final scale = 1 - (1 - widget.pressedScale) * _controller.value;
          return Transform.scale(scale: scale, child: child);
        },
        child: widget.child,
      ),
    );
  }
}

/// SE/ハプティクスを単発で鳴らすための軽量ヘルパー。
abstract final class Feedback {
  static void sfx(SfxId id) => GameAudio.instance.playSfx(id);

  static void tap() {
    HapticFeedback.selectionClick();
    GameAudio.instance.playSfx(SfxId.uiTap);
  }

  static void confirm() {
    HapticFeedback.mediumImpact();
    GameAudio.instance.playSfx(SfxId.uiConfirm);
  }

  static void error() {
    HapticFeedback.heavyImpact();
    GameAudio.instance.playSfx(SfxId.uiError);
  }
}
