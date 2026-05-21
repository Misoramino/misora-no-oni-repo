import 'dart:async';

import 'package:flutter/material.dart';

import '../features/branding/launch_effect_overlay.dart';
import '../features/branding/launch_sound_player.dart';
import '../theme/world_launch_branding.dart';
import '../theme/world_profile.dart';
import '../widgets/brand_logo.dart';

/// ネイティブスプラッシュ後の branded 起動（世界観別の軽量演出 + 短い効果音）。
class BrandedLaunchScreen extends StatefulWidget {
  const BrandedLaunchScreen({
    required this.profile,
    required this.onFinished,
    this.minVisible = const Duration(milliseconds: 1200),
    super.key,
  });

  final WorldProfile profile;
  final VoidCallback onFinished;
  final Duration minVisible;

  @override
  State<BrandedLaunchScreen> createState() => _BrandedLaunchScreenState();
}

class _BrandedLaunchScreenState extends State<BrandedLaunchScreen>
    with TickerProviderStateMixin {
  late final AnimationController _fadeIn;
  late final AnimationController _effect;
  final LaunchSoundPlayer _sound = LaunchSoundPlayer();
  Timer? _finishTimer;
  bool _finished = false;
  bool _soundStarted = false;

  @override
  void initState() {
    super.initState();
    _fadeIn = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 480),
    )..forward();
    _effect = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3200),
    )..repeat();
    _finishTimer = Timer(widget.minVisible, _complete);
    _maybePlaySound();
  }

  @override
  void didUpdateWidget(BrandedLaunchScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.profile != widget.profile) {
      setState(() {});
      _maybePlaySound();
    }
  }

  void _maybePlaySound() {
    if (_soundStarted) return;
    _soundStarted = true;
    unawaited(_sound.playIfEnabled(widget.profile));
  }

  void _complete() {
    if (_finished || !mounted) return;
    _finished = true;
    widget.onFinished();
  }

  @override
  void dispose() {
    _finishTimer?.cancel();
    _fadeIn.dispose();
    _effect.dispose();
    unawaited(_sound.dispose());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final b = WorldLaunchBranding.of(widget.profile);
    final onDark = !b.isLightBackground;

    return FadeTransition(
      opacity: CurvedAnimation(parent: _fadeIn, curve: Curves.easeOut),
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [b.backgroundTop, b.backgroundBottom],
          ),
        ),
        child: Stack(
          fit: StackFit.expand,
          children: [
            AnimatedBuilder(
              animation: _effect,
              builder: (context, _) {
                return LaunchEffectOverlay(
                  branding: b,
                  progress: _effect.value,
                );
              },
            ),
            SafeArea(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 36),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      DecoratedBox(
                        decoration: BoxDecoration(
                          boxShadow: [
                            BoxShadow(
                              color: b.glow,
                              blurRadius: _logoGlowBlur(b.effect),
                              spreadRadius: 2,
                            ),
                            if (b.effect == LaunchEffectKind.magical ||
                                b.effect == LaunchEffectKind.astronomy)
                              BoxShadow(
                                color: b.secondaryAccent.withValues(alpha: 0.35),
                                blurRadius: 48,
                                spreadRadius: 0,
                              ),
                          ],
                        ),
                        child: const SplashLogo(size: 120),
                      ),
                      const SizedBox(height: 28),
                      Text(
                        'ONI PIN',
                        style: TextStyle(
                          color: onDark
                              ? Colors.white.withValues(alpha: 0.96)
                              : const Color(0xFF1A1A1E),
                          fontSize: 26,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 8,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'GPS × ONI GAME',
                        style: TextStyle(
                          color: b.subtitleColor,
                          fontSize: 12,
                          letterSpacing: 2.4,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                      const SizedBox(height: 14),
                      Text(
                        b.profileLabel,
                        style: TextStyle(
                          color: b.subtitleColor.withValues(alpha: 0.85),
                          fontSize: 11,
                          letterSpacing: 1,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  double _logoGlowBlur(LaunchEffectKind effect) {
    return switch (effect) {
      LaunchEffectKind.magical => 40,
      LaunchEffectKind.astronomy => 38,
      LaunchEffectKind.horror => 36,
      LaunchEffectKind.cyber => 34,
      _ => 32,
    };
  }
}
