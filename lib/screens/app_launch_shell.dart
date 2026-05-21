import 'dart:async';

import 'package:flutter/material.dart';

import '../features/branding/launch_effect_overlay.dart';
import '../features/branding/launch_sound_player.dart';
import '../session/world_profile_prefs.dart';
import '../theme/world_launch_branding.dart';
import '../theme/world_profile.dart';
import '../widgets/themed_geometric_logo.dart';
import 'title_screen.dart';

/// 起動演出 → 図形ロゴが上へ移動 → タイトルへフェード（初回起動も同じ）。
class AppLaunchShell extends StatefulWidget {
  const AppLaunchShell({
    required this.initialProfile,
    required this.onProfileChanged,
    super.key,
  });

  final WorldProfile initialProfile;
  final ValueChanged<WorldProfile> onProfileChanged;

  @override
  State<AppLaunchShell> createState() => _AppLaunchShellState();
}

class _AppLaunchShellState extends State<AppLaunchShell>
    with TickerProviderStateMixin {
  WorldProfile _profile = WorldProfile.horror;

  late final AnimationController _effect;
  late final AnimationController _handoff;
  final LaunchSoundPlayer _sound = LaunchSoundPlayer();

  Timer? _handoffStartTimer;
  bool _soundPlayed = false;

  static const _minLaunchHold = Duration(milliseconds: 1400);
  static const _handoffDuration = Duration(milliseconds: 880);

  @override
  void initState() {
    super.initState();
    _profile = widget.initialProfile;
    _effect = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3200),
    )..repeat();
    _handoff = AnimationController(
      vsync: this,
      duration: _handoffDuration,
    )..addStatusListener((status) {
        if (status == AnimationStatus.completed) {
          _effect.stop();
        }
      });
    Future<void>.microtask(_loadProfile);
    _handoffStartTimer = Timer(_minLaunchHold, _beginHandoff);
  }

  Future<void> _loadProfile() async {
    final p = await WorldProfilePrefs.load();
    if (!mounted) return;
    setState(() => _profile = p);
    _playSoundOnce();
  }

  @override
  void didUpdateWidget(AppLaunchShell oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialProfile != widget.initialProfile) {
      setState(() => _profile = widget.initialProfile);
    }
  }

  void _playSoundOnce() {
    if (_soundPlayed) return;
    _soundPlayed = true;
    unawaited(_sound.playIfEnabled(_profile));
  }

  void _beginHandoff() {
    if (!mounted || _handoff.isAnimating || _handoff.value >= 1) return;
    _handoff.forward();
  }

  @override
  void dispose() {
    _handoffStartTimer?.cancel();
    _effect.dispose();
    _handoff.dispose();
    unawaited(_sound.dispose());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final branding = WorldLaunchBranding.of(_profile);
    final handoff = CurvedAnimation(parent: _handoff, curve: Curves.easeInOutCubic);
    final t = handoff.value;
    final effectFade = (1 - t * 1.15).clamp(0.0, 1.0);
    final titleFade = ((t - 0.28) / 0.72).clamp(0.0, 1.0);
    final logoSize = 96 + (56 - 96) * t;
    final logoAlign = Alignment.lerp(
      const Alignment(0, 0.06),
      const Alignment(0, -0.42),
      t,
    )!;
    final showFloatingLogo = t < 0.97;

    return Stack(
      fit: StackFit.expand,
      children: [
        Opacity(
          opacity: titleFade,
          child: TitleScreen(
            initialProfile: _profile,
            onProfileChanged: widget.onProfileChanged,
            showBrandHeader: titleFade > 0.88,
            reserveBrandHeaderSpace: true,
          ),
        ),
        IgnorePointer(
          ignoring: t > 0.04,
          child: Opacity(
            opacity: effectFade,
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    branding.backgroundTop,
                    branding.backgroundBottom,
                  ],
                ),
              ),
              child: AnimatedBuilder(
                animation: _effect,
                builder: (context, _) => LaunchEffectOverlay(
                  branding: branding,
                  progress: _effect.value,
                ),
              ),
            ),
          ),
        ),
        if (showFloatingLogo)
          Align(
            alignment: logoAlign,
            child: Opacity(
              opacity: (1 - titleFade * 1.2).clamp(0.0, 1.0),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  boxShadow: [
                    BoxShadow(
                      color: branding.glow,
                      blurRadius: 28,
                      spreadRadius: 1,
                    ),
                  ],
                ),
                child: ThemedGeometricLogo(
                  branding: branding,
                  size: logoSize,
                  pulse: _effect.value,
                ),
              ),
            ),
          ),
      ],
    );
  }
}
