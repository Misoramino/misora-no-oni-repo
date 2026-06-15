import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../audio/game_audio.dart';
import '../../../audio/sfx_id.dart';
import '../../../theme/world_profile.dart';
import '../../../theme/world_launch_branding.dart';
import '../../../theme/world_visual_pack.dart';
import '../../../widgets/motion_helpers.dart';
import '../../branding/launch_effect_overlay.dart';

/// 試合開始前の 3-2-1 カウント＋世界観フラッシュ。
Future<void> showMatchStartCountdown({
  required BuildContext context,
  required WorldProfile profile,
  required WorldVisualPack pack,
}) async {
  if (!context.mounted) return;
  final reduce = MotionHelpers.reduceMotionOf(context);
  if (reduce) {
    GameAudio.instance.playSfx(SfxId.matchStart, profile: profile);
    HapticFeedback.mediumImpact();
    return;
  }

  await showGeneralDialog<void>(
    context: context,
    barrierDismissible: false,
    barrierColor: Colors.black.withValues(alpha: 0.62),
    transitionDuration: const Duration(milliseconds: 240),
    pageBuilder: (_, __, ___) => _MatchStartCountdownOverlay(
      profile: profile,
      pack: pack,
    ),
  );
}

class _MatchStartCountdownOverlay extends StatefulWidget {
  const _MatchStartCountdownOverlay({
    required this.profile,
    required this.pack,
  });

  final WorldProfile profile;
  final WorldVisualPack pack;

  @override
  State<_MatchStartCountdownOverlay> createState() =>
      _MatchStartCountdownOverlayState();
}

class _MatchStartCountdownOverlayState extends State<_MatchStartCountdownOverlay>
    with SingleTickerProviderStateMixin {
  static const _steps = <String?>['3', '2', '1', '開始!'];
  int _index = 0;
  late final AnimationController _pulse = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 520),
  )..forward();
  Timer? _timer;

  WorldLaunchBranding get _branding => WorldLaunchBranding.of(widget.profile);

  @override
  void initState() {
    super.initState();
    _playStepFeedback();
    _timer = Timer.periodic(const Duration(milliseconds: 780), (_) => _advance());
  }

  void _playStepFeedback() {
    if (_index < 3) {
      GameAudio.instance.playSfx(SfxId.uiConfirm, profile: widget.profile);
      HapticFeedback.selectionClick();
    } else {
      GameAudio.instance.playSfx(SfxId.matchStart, profile: widget.profile);
      HapticFeedback.heavyImpact();
    }
    _pulse.forward(from: 0);
  }

  void _advance() {
    if (!mounted) return;
    if (_index >= _steps.length - 1) {
      _timer?.cancel();
      Future<void>.delayed(const Duration(milliseconds: 420), () {
        if (mounted) Navigator.of(context).pop();
      });
      return;
    }
    setState(() => _index += 1);
    _playStepFeedback();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final label = _steps[_index]!;
    final theme = Theme.of(context);
    final accent = _branding.accent;
    final isGo = _index == 3;

    return Material(
      color: Colors.transparent,
      child: Stack(
        fit: StackFit.expand,
        children: [
          AnimatedBuilder(
            animation: _pulse,
            builder: (_, __) => LaunchEffectOverlay(
              branding: _branding,
              progress: _pulse.value,
            ),
          ),
          if (widget.pack.useScanOverlay && !isGo)
            IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      accent.withValues(alpha: 0.08),
                      Colors.transparent,
                      accent.withValues(alpha: 0.05),
                    ],
                  ),
                ),
              ),
            ),
          Center(
            child: ScaleTransition(
              scale: Tween<double>(begin: 0.55, end: 1).animate(
                CurvedAnimation(parent: _pulse, curve: Curves.elasticOut),
              ),
              child: FadeTransition(
                opacity: CurvedAnimation(parent: _pulse, curve: Curves.easeOut),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _branding.profileLabel,
                      style: theme.textTheme.labelLarge?.copyWith(
                        color: accent.withValues(alpha: 0.9),
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      label,
                      style: theme.textTheme.displayLarge?.copyWith(
                        fontWeight: FontWeight.w900,
                        color: isGo ? accent : Colors.white,
                        shadows: [
                          Shadow(
                            color: accent.withValues(alpha: 0.65),
                            blurRadius: 24,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
