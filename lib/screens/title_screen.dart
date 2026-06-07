import 'package:flutter/material.dart';

import '../app_version.dart';
import '../audio/game_audio.dart';
import '../audio/sfx_id.dart';
import '../features/onboarding/offline_practice_intro.dart';
import '../features/settings/settings_hub_sheet.dart';
import '../features/onboarding/welcome_flow.dart';
import '../features/tutorial/tutorial_entry.dart';
import '../features/branding/launch_effect_overlay.dart';
import '../features/branding/title_ambient_overlay.dart';
import '../features/branding/launch_intro_timeline.dart';
import '../session/onboarding_prefs.dart';
import '../session/world_profile_prefs.dart';
import '../sync/firebase_bootstrap.dart';
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
      GameAudio.instance.playMenuBgm(saved);
      _maybeShowWelcomeOnFirstLaunch();
    } catch (e, st) {
      debugPrint('TitleScreen._boot failed: $e\n$st');
      if (!mounted) return;
      setState(() => _booting = false);
    }
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

  Future<void> _openWelcome() async {
    GameAudio.instance.playSfx(SfxId.uiTap);
    final result = await showWelcomeFlow(context, offerTutorial: true);
    if (!mounted) return;
    if (result == WelcomeResult.tutorial) await openTutorialPicker(context);
  }

  Future<void> _onProfileSelected(WorldProfile? next) async {
    if (next == null || next == _profile) return;
    await WorldProfilePrefs.save(next);
    if (!mounted) return;
    setState(() => _profile = next);
    widget.onProfileChanged?.call(next);
    GameAudio.instance.playMenuBgm(next);
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
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 16,
                        ),
                        child: Align(
                          alignment: Alignment.center,
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
                                                showSettingsHubSheet(context);
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
                                        const Center(
                                          child: CircularProgressIndicator(),
                                        )
                                      else if (handoff == null) ...[
                                        DropdownButtonFormField<WorldProfile>(
                                          key: ValueKey(_profile),
                                          initialValue: _profile,
                                          decoration: const InputDecoration(
                                            labelText: '世界観',
                                            border: OutlineInputBorder(),
                                            helperText: '地図・ピン・演出のテーマ',
                                          ),
                                          items: WorldProfile.values
                                              .map(
                                                (p) => DropdownMenuItem(
                                                  value: p,
                                                  child: Text(p.label),
                                                ),
                                              )
                                              .toList(),
                                          onChanged: _onProfileSelected,
                                        ),
                                        const SizedBox(height: 20),
                                        Semantics(
                                          button: true,
                                          label: 'オンラインルーム。友達とマルチプレイ',
                                          child: FilledButton.icon(
                                          onPressed: () {
                                            GameAudio.instance
                                                .playSfx(SfxId.uiConfirm);
                                            AppNav.push<void>(
                                              context,
                                              (_) => const RoomLobbyScreen(),
                                            );
                                          },
                                          icon: const Icon(
                                            Icons.groups_outlined,
                                          ),
                                          label: const Padding(
                                            padding: EdgeInsets.symmetric(
                                              vertical: 12,
                                            ),
                                            child: Text('オンラインルーム'),
                                          ),
                                        ),
                                        ),
                                        const SizedBox(height: 12),
                                        OutlinedButton.icon(
                                          onPressed: () async {
                                            GameAudio.instance
                                                .playSfx(SfxId.uiTap);
                                            final ok =
                                                await confirmOfflinePracticeIntro(
                                              context,
                                            );
                                            if (!context.mounted || !ok) {
                                              return;
                                            }
                                            AppNav.push<void>(
                                              context,
                                              (_) => GameMapScreen(
                                                profile: _profile,
                                              ),
                                            );
                                          },
                                          icon: const Icon(Icons.map_outlined),
                                          label: const Padding(
                                            padding: EdgeInsets.symmetric(
                                              vertical: 12,
                                            ),
                                            child: Text('オフラインで練習（マップのみ）'),
                                          ),
                                        ),
                                        const SizedBox(height: 12),
                                        Row(
                                          children: [
                                            Expanded(
                                              child: TextButton.icon(
                                                onPressed: _openWelcome,
                                                icon: const Icon(
                                                  Icons.help_outline_rounded,
                                                ),
                                                label: const Text('遊び方'),
                                              ),
                                            ),
                                            Expanded(
                                              child: TextButton.icon(
                                                onPressed: () {
                                                  GameAudio.instance
                                                      .playSfx(SfxId.uiTap);
                                                  AppNav.push<void>(
                                                    context,
                                                    (_) =>
                                                        const ProgressScreen(),
                                                    direction:
                                                        SceneTransitionDirection
                                                            .up,
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
                                              ? 'オンライン: 利用可能'
                                              : 'オンライン: 未接続（参加時に再試行）',
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
