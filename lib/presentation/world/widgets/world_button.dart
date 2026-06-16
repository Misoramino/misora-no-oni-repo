import 'package:flutter/material.dart';

import '../../../theme/world_profile.dart';
import '../world_studio_identity.dart';
import '../world_studio_identity_catalog.dart';
import '../world_presentation_catalog.dart';

/// 世界観別ボタン（形状・影・押下アニメーション）。
class WorldButton extends StatefulWidget {
  const WorldButton({
    required this.profile,
    required this.label,
    required this.onPressed,
    this.icon,
    this.variant = WorldButtonVariant.filled,
    super.key,
  });

  final WorldProfile profile;
  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final WorldButtonVariant variant;

  @override
  State<WorldButton> createState() => _WorldButtonState();
}

enum WorldButtonVariant { filled, outlined, text }

class _WorldButtonState extends State<WorldButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final pack = WorldPresentationCatalog.of(widget.profile);
    final studio = WorldStudioIdentityCatalog.of(widget.profile);
    final shape = pack.buttonShape;
    final radius = BorderRadius.circular(shape.borderRadius);
    final scale = _pressed ? shape.pressScale : 1.0;

    final child = AnimatedScale(
      scale: scale,
      duration: studio.motion.button,
      curve: studio.motion.emphasisCurve,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (widget.icon != null) ...[
              Icon(widget.icon, size: 20),
              const SizedBox(width: 8),
            ],
            Flexible(
              child: Text(
                widget.label,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );

    switch (widget.variant) {
      case WorldButtonVariant.filled:
        return _wrapGesture(
          Material(
            elevation: shape.elevation,
            shadowColor: pack.accent.withValues(alpha: 0.35),
            borderRadius: radius,
            child: Ink(
              decoration: BoxDecoration(
                borderRadius: radius,
                gradient: shape.useGradient
                    ? pack.accentGradient
                    : null,
                color: shape.useGradient ? null : pack.accent,
                border: shape.borderWidth > 0
                    ? Border.all(
                        color: pack.panelBorder,
                        width: shape.borderWidth,
                      )
                    : null,
              ),
              child: DefaultTextStyle(
                style: TextStyle(
                  color: pack.buttonLabelOnAccent,
                  fontWeight: FontWeight.w600,
                ),
                child: child,
              ),
            ),
          ),
        );
      case WorldButtonVariant.outlined:
        return _wrapGesture(
          DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: radius,
              border: Border.all(
                color: pack.accent,
                width: shape.borderWidth > 0 ? shape.borderWidth : 1.5,
              ),
              color: pack.panelSurface.withValues(alpha: 0.5),
            ),
            child: DefaultTextStyle(
              style: TextStyle(color: pack.accent, fontWeight: FontWeight.w600),
              child: child,
            ),
          ),
        );
      case WorldButtonVariant.text:
        return _wrapGesture(
          DefaultTextStyle(
            style: TextStyle(color: pack.accent, fontWeight: FontWeight.w600),
            child: child,
          ),
        );
    }
  }

  Widget _wrapGesture(Widget child) {
    return GestureDetector(
      onTapDown: widget.onPressed == null ? null : (_) => setState(() => _pressed = true),
      onTapUp: widget.onPressed == null
          ? null
          : (_) {
              setState(() => _pressed = false);
              WorldHaptics.confirm(widget.profile);
              widget.onPressed?.call();
            },
      onTapCancel: widget.onPressed == null
          ? null
          : () => setState(() => _pressed = false),
      child: Opacity(
        opacity: widget.onPressed == null ? 0.45 : 1,
        child: child,
      ),
    );
  }
}

/// アイコン付き世界観ボタン（Filled 相当）。
class WorldButtonIcon extends StatelessWidget {
  const WorldButtonIcon({
    required this.profile,
    required this.label,
    required this.icon,
    required this.onPressed,
    this.outlined = false,
    super.key,
  });

  final WorldProfile profile;
  final String label;
  final IconData icon;
  final VoidCallback? onPressed;
  final bool outlined;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: WorldButton(
        profile: profile,
        label: label,
        icon: icon,
        onPressed: onPressed,
        variant: outlined ? WorldButtonVariant.outlined : WorldButtonVariant.filled,
      ),
    );
  }
}
