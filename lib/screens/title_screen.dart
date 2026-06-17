import 'dart:async';

import 'package:flutter/material.dart';

import '../app_version.dart';
import '../audio/game_audio.dart';
import '../audio/world_audio_director.dart';
import '../audio/world_audio_state.dart';
import '../audio/sfx_id.dart';
import '../features/onboarding/offline_practice_intro.dart';
import '../features/settings/guide_hub_sheet.dart';
import '../features/settings/settings_hub_sheet.dart';
import '../features/onboarding/welcome_flow.dart';
import '../features/tutorial/tutorial_entry.dart';
import '../features/branding/launch_effect_overlay.dart';
import '../features/branding/title_ambient_overlay.dart';
import '../features/branding/launch_intro_timeline.dart';
import '../session/onboarding_prefs.dart';
import '../session/world_profile_prefs.dart';
import '../sync/firebase_bootstrap.dart';
import '../features/world_selection/world_selection_sheet.dart';
import '../presentation/world/world_presentation_catalog.dart';
import '../presentation/world/world_ui_layout.dart';
import '../presentation/world/widgets/world_button.dart';
import '../presentation/world/widgets/world_profile_morph_overlay.dart';
import '../presentation/world/widgets/world_loading.dart';
import '../theme/world_profile.dart';
import '../theme/world_launch_branding.dart';
import '../widgets/scene_transitions.dart';
import '../widgets/themed_geometric_logo.dart';
import 'game_map_screen.dart';
import 'launch_handoff.dart';
import 'progress_screen.dart';
import 'room_lobby_screen.dart';

/// アプリ入口。オンラインルーム参加か、オフライン練習かを選ぶ。
class TitleScreen extends StatefulWidget {
  const TitleScreen({
    this.initialProfile = WorldProfile.horror,
    this.onProfileChanged,
    this.handoff,
    this.initialAmbientPhase,
    super.key,
  });

  final WorldProfile initialProfile;
  final ValueChanged<WorldProfile>? onProfileChanged;

  /// 非 null のとき起動演出から同一ロゴで遷移中。
  final LaunchHandoffView? handoff;

  /// 起動演出の背景アニメ位相を引き継ぐ（ぷつ切れ防止）。
  final double? initialAmbientPhase;

  @override
  State<TitleScreen> createState() => _TitleScreenState();
}

class _TitleScreenState extends State<TitleScreen> with TickerProviderStateMixin {
  bool _booting = true;
  bool _titleBgmScheduled = false;
  late WorldProfile _profile;
  AnimationController? _logoPulse;
  AnimationController? _ambientEffect;
  static const _titleLogoSize = 56.0;
  static const _launchLogoSize = 96.0;

  @override
  void initState() {
    super.initState();
    _profile = widget.initialProfile;
    if (widget.handoff == null) {
      _logoPulse = AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 2800),
      )..repeat();
      _ambientEffect = AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 4200),
      );
      final phase = widget.initialAmbientPhase;
      if (phase != null) {
        _ambientEffect!.value = phase % 1.0;
      }
      _ambientEffect!.repeat();
    }
    // 起動演出中もバックグラウンドで初期化（handoff 解除後にスピナーが残らない）
    Future<void>.microtask(_boot);
  }

  @override
  void didUpdateWidget(TitleScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.handoff != null && widget.handoff == null) {
      _ensureTitleAmbientControllers();
    }
  }

  void _ensureTitleAmbientControllers() {
    if (_logoPulse != null) return;
    _logoPulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2800),
    )..repeat();
    _ambientEffect = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 4200),
    );
    final phase = widget.initialAmbientPhase;
    if (phase != null) {
      _ambientEffect!.value = phase % 1.0;
    }
    _ambientEffect!.repeat();
  }

  @override
  void dispose() {
    _logoPulse?.dispose();
    _ambientEffect?.dispose();
    super.dispose();
  }

  Future<void> _boot() async {
    try {
      if (!FirebaseBootstrap.isReady) {
        await FirebaseBootstrap.tryInit();
      }
      final saved = await WorldProfilePrefs.load();
      if (!mounted) return;
      setState(() {
        _profile = saved;
        _booting = false;
      });
      widget.onProfileChanged?.call(saved);
      unawaited(_scheduleTitleBgm(saved));
      _maybeShowWelcomeOnFirstLaunch();
    } catch (e, st) {
      debugPrint('TitleScreen._boot failed: $e\n$st');
      if (!mounted) return;
      setState(() => _booting = false);
    }
  }

  /// 起動音の余韻のあと、ゆっくりタイトル BGM を入れる。
  Future<void> _scheduleTitleBgm(WorldProfile profile) async {
    if (_titleBgmScheduled) return;
    _titleBgmScheduled = true;
    while (mounted && widget.handoff != null) {
      await Future<void>.delayed(const Duration(milliseconds: 80));
    }
    if (!mounted) return;
    await Future<void>.delayed(const Duration(milliseconds: 2600));
    if (!mounted) return;
    unawaited(
      WorldAudioDirector.instance.enter(
        WorldAudioState.title,
        profile: profile,
      ),
    );
  }

  Future<void> _maybeShowWelcomeOnFirstLaunch() async {
    if (widget.handoff != null) return;
    if (await OnboardingPrefs.welcomeSeen()) return;
    if (!mounted || widget.handoff != null) return;
    final result = await showWelcomeFlow(context, offerTutorial: true);
    await OnboardingPrefs.markWelcomeSeen();
    if (!mounted) return;
    if (result == WelcomeResult.tutorial) await openTutorialPicker(context);
  }

  Future<void> _reloadProfileFromPrefs() async {
    final next = await WorldProfilePrefs.load();
    if (!mounted) return;
    setState(() => _profile = next);
    widget.onProfileChanged?.call(next);
  }

  Future<void> _onProfileSelected(WorldProfile? next) async {
    if (next == null || next == _profile) return;
    await WorldProfilePrefs.save(next);
    if (!mounted) return;
    setState(() => _profile = next);
    widget.onProfileChanged?.call(next);
    unawaited(WorldAudioDirector.instance.onProfileChanged(next));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final handoff = widget.handoff;
    final v = handoff == null
        ? null
        : LaunchIntroTimeline.visuals(handoff.introProgress);
    final layoutT = v?.layoutT ?? 1.0;
    final branding = handoff?.branding ?? WorldLaunchBranding.of(_profile);
    final logoPulse = handoff?.effectProgress ?? _logoPulse?.value ?? 0;
    final logoReveal = v?.logoReveal ?? 1.0;

    final effectOpacity = v?.effectOpacity ?? 0.0;
    final brandTextOpacity = v?.brandTextOpacity ?? 1.0;
    final bodyOpacity = v?.bodyOpacity ?? 1.0;
    final taglineLayoutT = v?.taglineLayoutT ?? 1.0;
    final taglineOpacity = v?.taglineOpacity ?? 1.0;
    final titleVeil = v?.titleVeil ?? 0.0;

    final scaffoldBg = handoff == null
        ? Color.lerp(
            theme.colorScheme.surface,
            branding.backgroundBottom,
            branding.isLightBackground ? 0.42 : 0.38,
          )
        : Color.lerp(
            branding.backgroundBottom,
            theme.colorScheme.surface,
            v!.scaffoldBlend,
          );

    return Scaffold(
      backgroundColor: scaffoldBg,
      body: Stack(
        fit: StackFit.expand,
        children: [
          if (handoff == null && _ambientEffect != null)
            Positioned.fill(
              child: RepaintBoundary(
                child: AnimatedBuilder(
                  animation: _ambientEffect!,
                  builder: (context, _) => TitleAmbientOverlay(
                    branding: branding,
                    progress: _ambientEffect!.value,
                    strength: branding.isLightBackground
                        ? 0.72
                        : (branding.effect == LaunchEffectKind.horror
                            ? 1.05
                            : 0.92),
                  ),
                ),
              ),
            ),
          if (handoff == null)
            Positioned.fill(
              child: WorldProfileMorphOverlay(profile: _profile),
            ),
          if (handoff != null && effectOpacity > 0.01)
            RepaintBoundary(
              child: IgnorePointer(
                child: Opacity(
                  opacity: effectOpacity,
                  child: LaunchEffectOverlay(
                    branding: branding,
                    progress: handoff.effectProgress,
                  ),
                ),
              ),
            ),
          if (handoff != null && titleVeil > 0.01)
            IgnorePointer(
              child: Opacity(
                opacity: titleVeil,
                child: ColoredBox(color: theme.colorScheme.surface),
              ),
            ),
          SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final narrow = constraints.maxWidth < 380;
                final headlineColor = handoff == null
                    ? branding.titleHeadlineColor
                    : Color.lerp(
                        branding.titleHeadlineColor,
                        theme.colorScheme.onSurface,
                        layoutT,
                      )!;
                final subtitleColor = handoff == null
                    ? branding.subtitleColor
                    : Color.lerp(
                        branding.subtitleColor,
                        theme.colorScheme.onSurfaceVariant,
                        layoutT,
                      )!;
                final titleStyle = theme.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  fontSize: narrow ? 22 : null,
                  letterSpacing: 4,
                  color: headlineColor,
                );
                final subBrandStyle = theme.textTheme.labelMedium?.copyWith(
                  color: subtitleColor,
                  letterSpacing: 1.6,
                );

                // 起動・ロゴ画面は視覚中心へ、タイトルへはフェードしながら移動
                final launchYOffset = constraints.maxHeight * 0.06 * (1 - layoutT);
                final logoScale =
                    (_titleLogoSize +
                            (_launchLogoSize - _titleLogoSize) *
                                (1 - layoutT)) *
                        (0.82 + 0.18 * logoReveal);

                return CustomScrollView(
                  slivers: [
                    SliverFillRemaining(
                      hasScrollBody: true,
                      child: Padding(
                        padding: WorldUILayout.screenPadding(context),
                        child: Align(
                          alignment: WorldUILayout.contentAlign,
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 520),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                if (handoff == null && bodyOpacity > 0.95)
                                  Opacity(
                                  opacity: bodyOpacity,
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.end,
                                    children: [
                                      IconButton(
                                        tooltip: '設定',
                                        onPressed: handoff == null
                                            ? () {
                                                GameAudio.instance
                                                    .playSfx(SfxId.uiTap);
                                                showSettingsHubSheet(
                                                  context,
                                                  onPersonalSettingsApplied:
                                                      (_) =>
                                                          _reloadProfileFromPrefs(),
                                                );
                                              }
                                            : null,
                                        icon: const Icon(
                                          Icons.settings_outlined,
                                          size: 22,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Transform.translate(
                                  offset: Offset(0, launchYOffset),
                                  child: RepaintBoundary(
                                    child: _logoPulse == null
                                        ? _TitleBrandHeader(
                                            branding: branding,
                                            logoSize: logoScale,
                                            textOpacity: brandTextOpacity,
                                            titleStyle: titleStyle,
                                            subBrandStyle: subBrandStyle,
                                            logoPulse: logoPulse,
                                          )
                                        : AnimatedBuilder(
                                            animation: _logoPulse!,
                                            builder: (context, _) =>
                                                _TitleBrandHeader(
                                              branding: branding,
                                              logoSize: logoScale,
                                              textOpacity: brandTextOpacity,
                                              titleStyle: titleStyle,
                                              subBrandStyle: subBrandStyle,
                                              logoPulse: _logoPulse!.value,
                                            ),
                                          ),
                                  ),
                                ),
                                SizedBox(
                                  height: 40,
                                  child: taglineOpacity > 0.01
                                      ? ClipRect(
                                          child: Align(
                                            alignment: Alignment(
                                              0,
                                              1.0 - taglineLayoutT,
                                            ),
                                            child: Opacity(
                                              opacity: taglineOpacity,
                                              child: Text(
                                                '都市型 GPS 鬼ごっこ',
                                                textAlign: TextAlign.center,
                                                style: theme
                                                    .textTheme.bodyLarge
                                                    ?.copyWith(
                                                  color: theme.colorScheme
                                                      .onSurfaceVariant,
                                                  fontSize: narrow ? 14 : null,
                                                ),
                                              ),
                                            ),
                                          ),
                                        )
                                      : null,
                                ),
                                Opacity(
                                  opacity: bodyOpacity,
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.stretch,
                                    children: [
                                      const SizedBox(height: 20),
                                      if (handoff == null && _booting)
                                        Center(
                                          child: WorldLoading(
                                            profile: _profile,
                                            label: '準備中…',
                                          ),
                                        )
                                      else if (handoff == null) ...[
                                        _WorldProfilePickerCard(
                                          profile: _profile,
                                          onTap: () async {
                                            final next =
                                                await showWorldSelectionSheet(
                                              context,
                                              current: _profile,
                                            );
                                            if (next != null) {
                                              await _onProfileSelected(next);
                                            }
                                          },
                                        ),
                                        const SizedBox(height: 20),
                                        WorldButtonIcon(
                                          profile: _profile,
                                          icon: Icons.groups_outlined,
                                          label: 'オンラインルーム',
                                          onPressed: () {
                                            AppNav.push<void>(
                                              context,
                                              (_) => const RoomLobbyScreen(),
                                              worldProfile: _profile,
                                            );
                                          },
                                        ),
                                        const SizedBox(height: 12),
                                        WorldButtonIcon(
                                          profile: _profile,
                                          icon: Icons.map_outlined,
                                          label: 'オフラインで練習（マップのみ）',
                                          outlined: true,
                                          onPressed: () async {
                                            final ok =
                                                await confirmOfflinePracticeIntro(
                                              context,
                                            );
                                            if (!context.mounted || !ok) {
                                              return;
                                            }
                                            await AppNav.push<void>(
                                              context,
                                              (_) => GameMapScreen(
                                                profile: _profile,
                                                onProfileChanged:
                                                    widget.onProfileChanged,
                                              ),
                                              worldProfile: _profile,
                                              routeName: GameMapScreen.routeName,
                                            );
                                            if (mounted) {
                                              await _reloadProfileFromPrefs();
                                            }
                                          },
                                        ),
                                        const SizedBox(height: 12),
                                        Row(
                                          children: [
                                            Expanded(
                                              child: TextButton.icon(
                                                onPressed: () {
                                                  GameAudio.instance
                                                      .playSfx(SfxId.uiTap);
                                                  showGuideHubSheet(context);
                                                },
                                                icon: const Icon(
                                                  Icons.menu_book_outlined,
                                                ),
                                                label: const Text('ガイド・遊び方'),
                                              ),
                                            ),
                                            Expanded(
                                              child: TextButton.icon(
                                                onPressed: () {
                                                  AppNav.push<void>(
                                                    context,
                                                    (_) =>
                                                        const ProgressScreen(),
                                                    direction:
                                                        SceneTransitionDirection
                                                            .up,
                                                    worldProfile: _profile,
                                                  );
                                                },
                                                icon: const Icon(
                                                  Icons
                                                      .workspace_premium_outlined,
                                                ),
                                                label: const Text('戦績・称号'),
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 20),
                                        Text(
                                          FirebaseBootstrap.isReady
                                              ? 'オンラインプレイ: 準備OK'
                                              : 'オンラインプレイ: 未接続（参加時に再試行）',
                                          textAlign: TextAlign.center,
                                          style: theme.textTheme.bodySmall
                                              ?.copyWith(
                                            color: FirebaseBootstrap.isReady
                                                ? theme.colorScheme.primary
                                                : theme.colorScheme.error,
                                          ),
                                        ),
                                        if (FirebaseBootstrap.lastErrorBrief !=
                                            null) ...[
                                          const SizedBox(height: 8),
                                          Text(
                                            FirebaseBootstrap.lastErrorBrief!,
                                            textAlign: TextAlign.center,
                                            style: theme.textTheme.bodySmall
                                                ?.copyWith(
                                              color: theme.colorScheme.error,
                                              fontSize: 11,
                                            ),
                                          ),
                                        ],
                                        const SizedBox(height: 12),
                                        Text(
                                          AppVersion.display,
                                          textAlign: TextAlign.center,
                                          style: theme.textTheme.bodySmall
                                              ?.copyWith(
                                            color: theme.colorScheme.outline,
                                            fontSize: 11,
                                          ),
                                        ),
                                      ],
                                      const SizedBox(height: 28),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _WorldProfilePickerCard extends StatelessWidget {
  const _WorldProfilePickerCard({
    required this.profile,
    required this.onTap,
  });

  final WorldProfile profile;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final pack = WorldPresentationCatalog.of(profile);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(pack.hudCornerRadius + 6),
        child: Ink(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                pack.scaffoldTop.withValues(alpha: 0.85),
                pack.scaffoldBottom.withValues(alpha: 0.92),
              ],
            ),
            borderRadius: BorderRadius.circular(pack.hudCornerRadius + 6),
            border: Border.all(color: pack.accent.withValues(alpha: 0.55), width: 1.4),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            child: Row(
              children: [
                Icon(pack.profileIcon, color: pack.accent, size: 28),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '世界観',
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              color: pack.mutedOnScaffold,
                            ),
                      ),
                      Text(
                        profile.label,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              color: pack.textOnScaffold,
                              fontWeight: FontWeight.w700,
                            ),
                      ),
                      Text(
                        pack.tagline,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: pack.mutedOnScaffold,
                            ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                Icon(Icons.chevron_right, color: pack.accent),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _TitleBrandHeader extends StatelessWidget {
  const _TitleBrandHeader({
    required this.branding,
    required this.logoSize,
    required this.textOpacity,
    required this.titleStyle,
    required this.subBrandStyle,
    required this.logoPulse,
  });

  final WorldLaunchBranding branding;
  final double logoSize;
  final double textOpacity;
  final TextStyle? titleStyle;
  final TextStyle? subBrandStyle;
  final double logoPulse;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        DecoratedBox(
          decoration: BoxDecoration(
            boxShadow: [
              BoxShadow(
                color: branding.glow,
                blurRadius: 20 + logoPulse * 10,
                spreadRadius: logoPulse * 2,
              ),
              BoxShadow(
                color: branding.accent.withValues(alpha: 0.15 + logoPulse * 0.12),
                blurRadius: 12,
              ),
            ],
          ),
          child: ThemedGeometricLogo(
            branding: branding,
            size: logoSize,
            pulse: logoPulse,
          ),
        ),
        SizedBox(height: 12 * textOpacity.clamp(0.0, 1.0)),
        Opacity(
          opacity: textOpacity,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'ONI PIN',
                textAlign: TextAlign.center,
                style: titleStyle,
              ),
              const SizedBox(height: 4),
              Text(
                'GPS × ONI GAME',
                textAlign: TextAlign.center,
                style: subBrandStyle,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
