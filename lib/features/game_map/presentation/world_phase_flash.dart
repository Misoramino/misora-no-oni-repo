import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../theme/world_profile.dart';
import '../../../theme/world_launch_branding.dart';
import '../../../widgets/motion_helpers.dart';
import '../../branding/launch_effect_overlay.dart';

enum WorldPhaseFlashKind { start, end }

/// 試合開始・終了などの短い世界観フラッシュ（全画面・操作不可）。
abstract final class WorldPhaseFlash {
  static Future<void> pulse(
    BuildContext context, {
    required WorldProfile profile,
    WorldPhaseFlashKind kind = WorldPhaseFlashKind.start,
    Duration hold = const Duration(milliseconds: 300),
  }) async {
    if (!context.mounted) return;
    if (MotionHelpers.reduceMotionOf(context)) return;

    HapticFeedback.lightImpact();
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black.withValues(alpha: 0.35),
      builder: (ctx) => _PhaseFlashDialog(
        profile: profile,
        kind: kind,
        hold: hold,
      ),
    );
  }
}

class _PhaseFlashDialog extends StatefulWidget {
  const _PhaseFlashDialog({
    required this.profile,
    required this.kind,
    required this.hold,
  });

  final WorldProfile profile;
  final WorldPhaseFlashKind kind;
  final Duration hold;

  @override
  State<_PhaseFlashDialog> createState() => _PhaseFlashDialogState();
}

class _PhaseFlashDialogState extends State<_PhaseFlashDialog>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 360),
  );

  @override
  void initState() {
    super.initState();
    _controller.forward();
    Future<void>.delayed(widget.hold + const Duration(milliseconds: 360), () {
      if (!mounted) return;
      Navigator.of(context).pop();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final branding = WorldLaunchBranding.of(widget.profile);
    final isEnd = widget.kind == WorldPhaseFlashKind.end;
    return Material(
      color: Colors.transparent,
      child: FadeTransition(
        opacity: CurvedAnimation(parent: _controller, curve: Curves.easeOut),
        child: Stack(
          fit: StackFit.expand,
          children: [
            ColoredBox(
              color: branding.backgroundTop.withValues(alpha: isEnd ? 0.85 : 0.78),
            ),
            AnimatedBuilder(
              animation: _controller,
              builder: (_, __) => LaunchEffectOverlay(
                branding: branding,
                progress: _controller.value,
              ),
            ),
            if (isEnd)
              Center(
                child: Text(
                  '試合終了',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        color: Colors.white.withValues(alpha: 0.92),
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.2,
                      ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
