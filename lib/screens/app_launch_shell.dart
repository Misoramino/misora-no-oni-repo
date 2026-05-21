import 'dart:async';

import 'package:flutter/material.dart';

import '../features/branding/launch_sound_player.dart';
import '../sync/firebase_bootstrap.dart';
import '../session/world_profile_prefs.dart';
import '../theme/world_launch_branding.dart';
import '../theme/world_profile.dart';
import 'launch_handoff.dart';
import 'title_screen.dart';

/// 起動演出 → タイトル（単一ロゴでスムーズに遷移）。
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
  late final AnimationController _handoff;
  late final Animation<double> _handoffAnim;
  final LaunchSoundPlayer _sound = LaunchSoundPlayer();

  Timer? _handoffStartTimer;
  Timer? _watchdogTimer;
  bool _soundPlayed = false;

  static const _minLaunchHold = Duration(milliseconds: 1400);
  static const _handoffDuration = Duration(milliseconds: 1000);
  static const _maxIntroDuration = Duration(seconds: 5);

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
    );
    _handoffAnim = CurvedAnimation(
      parent: _handoff,
      curve: Curves.easeInOutCubic,
    );
    _handoff.addStatusListener(_onHandoffStatus);
    Future<void>.microtask(_bootstrap);
    _handoffStartTimer = Timer(_minLaunchHold, _beginHandoff);
    _watchdogTimer = Timer(_maxIntroDuration, _forceFinishIntro);
  }

  Future<void> _bootstrap() async {
    await Future.wait([
      _loadProfile(),
      FirebaseBootstrap.tryInit(),
    ]);
  }

  void _forceFinishIntro() {
    if (!mounted || _introDone) return;
    if (_handoff.value < 1 && !_handoff.isAnimating) {
      unawaited(_handoff.forward());
    }
    setState(() => _introDone = true);
  }

  void _onHandoffStatus(AnimationStatus status) {
    if (status != AnimationStatus.completed || !mounted) return;
    _watchdogTimer?.cancel();
    _effect.stop();
    setState(() => _introDone = true);
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
    if (!mounted || _introDone) return;
    if (_handoff.isAnimating) return;
    if (_handoff.value >= 1) {
      setState(() => _introDone = true);
      return;
    }
    unawaited(_handoff.forward());
  }

  @override
  void dispose() {
    _handoffStartTimer?.cancel();
    _watchdogTimer?.cancel();
    _effect.dispose();
    _handoff.dispose();
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

    return AnimatedBuilder(
      animation: Listenable.merge([_handoffAnim, _effect]),
      builder: (context, _) {
        return TitleScreen(
          initialProfile: _profile,
          onProfileChanged: widget.onProfileChanged,
          handoff: LaunchHandoffView(
            progress: _handoffAnim.value,
            effectProgress: _effect.value,
            branding: WorldLaunchBranding.of(_profile),
          ),
        );
      },
    );
  }
}
