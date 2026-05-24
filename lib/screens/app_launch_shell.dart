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

/// 起動演出 → タイトル（同一 [TitleScreen] でロゴ位置を連続補間）。
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
  bool _handoffReleased = false;

  late final AnimationController _effect;
  late final AnimationController _intro;
  late final Animation<double> _introMotion;
  final LaunchSoundPlayer _sound = LaunchSoundPlayer();

  Timer? _watchdogTimer;
  Timer? _releaseHandoffTimer;
  bool _introStarted = false;

  static const _introDuration = Duration(
    milliseconds: LaunchIntroTimeline.totalMs,
  );
  static const _maxIntroDuration = Duration(seconds: 6);

  @override
  void initState() {
    super.initState();
    _profile = widget.initialProfile;
    _effect = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 4200),
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
    if (!mounted || _introStarted || _handoffReleased) return;
    _introStarted = true;
    unawaited(_intro.forward());
  }

  void _forceFinishIntro() {
    if (!mounted || _handoffReleased) return;
    if (_introMotion.value < 1) {
      _intro.value = 1;
    }
    _scheduleHandoffRelease();
  }

  void _onIntroStatus(AnimationStatus status) {
    if (status != AnimationStatus.completed || !mounted) return;
    _scheduleHandoffRelease();
  }

  void _scheduleHandoffRelease() {
    if (_handoffReleased) return;
    _watchdogTimer?.cancel();
    _releaseHandoffTimer?.cancel();
    _releaseHandoffTimer = Timer(
      const Duration(milliseconds: LaunchIntroTimeline.handoffReleaseMs),
      () {
        if (!mounted || _handoffReleased) return;
        setState(() => _handoffReleased = true);
      },
    );
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
    _releaseHandoffTimer?.cancel();
    _effect.dispose();
    _intro.dispose();
    unawaited(_sound.dispose());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final branding = WorldLaunchBranding.of(_profile);

    return AnimatedBuilder(
      animation: Listenable.merge([_introMotion, _effect]),
      builder: (context, child) {
        return TitleScreen(
          initialProfile: _profile,
          onProfileChanged: widget.onProfileChanged,
          initialAmbientPhase: _handoffReleased ? _effect.value : null,
          handoff: _handoffReleased
              ? null
              : LaunchHandoffView(
                  introProgress: _introMotion.value,
                  effectProgress: _effect.value,
                  branding: branding,
                ),
        );
      },
    );
  }
}
