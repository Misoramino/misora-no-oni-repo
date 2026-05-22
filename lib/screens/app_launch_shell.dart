import 'dart:async';

import 'package:flutter/material.dart';

import '../features/branding/launch_intro_timeline.dart';
import '../features/branding/launch_sound_player.dart';
import '../sync/firebase_bootstrap.dart';
import '../session/world_profile_prefs.dart';
import '../theme/world_launch_branding.dart';
import '../theme/world_profile.dart';
import 'launch_handoff.dart';
import 'title_screen.dart';

/// 起動演出 → ロゴ画面 → タイトル（単一ロゴでスムーズに遷移）。
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
  bool _introDone = false;

  late final AnimationController _effect;
  late final AnimationController _intro;
  late final Animation<double> _introMotion;
  final LaunchSoundPlayer _sound = LaunchSoundPlayer();

  Timer? _watchdogTimer;
  bool _introStarted = false;

  static const _introDuration = Duration(
    milliseconds: LaunchIntroTimeline.totalMs,
  );
  static const _maxIntroDuration = Duration(seconds: 5);

  @override
  void initState() {
    super.initState();
    _profile = widget.initialProfile;
    _effect = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3200),
    )..repeat();
    _intro = AnimationController(vsync: this, duration: _introDuration)
      ..addStatusListener(_onIntroStatus);
    _introMotion = CurvedAnimation(
      parent: _intro,
      curve: Curves.easeOutCubic,
    );
    Future<void>.microtask(_bootstrap);
    _watchdogTimer = Timer(_maxIntroDuration, _forceFinishIntro);
  }

  Future<void> _bootstrap() async {
    await Future.wait([
      _loadProfile(),
      FirebaseBootstrap.tryInit(),
    ]);
    if (!mounted) return;
    _startIntroIfReady();
    unawaited(_playSoundOnce());
  }

  void _startIntroIfReady() {
    if (!mounted || _introStarted || _introDone) return;
    _introStarted = true;
    unawaited(_intro.forward());
  }

  void _forceFinishIntro() {
    if (!mounted || _introDone) return;
    if (_introMotion.value < 1) {
      _intro.value = 1;
    }
    _finishIntro();
  }

  void _onIntroStatus(AnimationStatus status) {
    if (status != AnimationStatus.completed || !mounted) return;
    _finishIntro();
  }

  void _finishIntro() {
    if (_introDone) return;
    _watchdogTimer?.cancel();
    _effect.stop();
    setState(() => _introDone = true);
  }

  Future<void> _loadProfile() async {
    final p = await WorldProfilePrefs.load();
    if (!mounted) return;
    setState(() => _profile = p);
  }

  Future<void> _playSoundOnce() => _sound.playIfEnabled(_profile);

  @override
  void didUpdateWidget(AppLaunchShell oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialProfile != widget.initialProfile) {
      setState(() => _profile = widget.initialProfile);
    }
  }

  @override
  void dispose() {
    _watchdogTimer?.cancel();
    _effect.dispose();
    _intro.dispose();
    unawaited(_sound.dispose());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_introDone) {
      return TitleScreen(
        initialProfile: _profile,
        onProfileChanged: widget.onProfileChanged,
      );
    }

    final branding = WorldLaunchBranding.of(_profile);

    return AnimatedBuilder(
      animation: Listenable.merge([_introMotion, _effect]),
      builder: (context, child) {
        return TitleScreen(
          initialProfile: _profile,
          onProfileChanged: widget.onProfileChanged,
          handoff: LaunchHandoffView(
            introProgress: _introMotion.value,
            effectProgress: _effect.value,
            branding: branding,
          ),
        );
      },
    );
  }
}
