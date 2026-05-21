import 'package:flutter/material.dart';

import '../features/branding/launch_effect_overlay.dart';
import '../session/launch_branding_prefs.dart';
import '../session/world_profile_prefs.dart';
import '../sync/firebase_bootstrap.dart';
import '../theme/world_profile.dart';
import '../theme/world_launch_branding.dart';
import '../widgets/themed_geometric_logo.dart';
import 'game_map_screen.dart';
import 'launch_handoff.dart';
import 'room_lobby_screen.dart';

/// アプリ入口。オンラインルーム参加か、オフライン練習かを選ぶ。
class TitleScreen extends StatefulWidget {
  const TitleScreen({
    this.initialProfile = WorldProfile.horror,
    this.onProfileChanged,
    this.handoff,
    super.key,
  });

  final WorldProfile initialProfile;
  final ValueChanged<WorldProfile>? onProfileChanged;

  /// 非 null のとき起動演出から同一ロゴで遷移中。
  final LaunchHandoffView? handoff;

  @override
  State<TitleScreen> createState() => _TitleScreenState();
}

class _TitleScreenState extends State<TitleScreen> {
  bool _booting = true;
  bool _launchSoundOn = true;
  late WorldProfile _profile;

  static const _titleLogoSize = 56.0;
  static const _launchLogoSize = 96.0;

  @override
  void initState() {
    super.initState();
    _profile = widget.initialProfile;
    if (widget.handoff == null) {
      Future<void>.microtask(_boot);
    }
  }

  Future<void> _boot() async {
    try {
      if (!FirebaseBootstrap.isReady) {
        await FirebaseBootstrap.tryInit();
      }
      final saved = await WorldProfilePrefs.load();
      final soundOn = await LaunchBrandingPrefs.loadSoundEnabled();
      if (!mounted) return;
      setState(() {
        _profile = saved;
        _launchSoundOn = soundOn;
        _booting = false;
      });
      widget.onProfileChanged?.call(saved);
    } catch (e, st) {
      debugPrint('TitleScreen._boot failed: $e\n$st');
      if (!mounted) return;
      setState(() => _booting = false);
    }
  }

  Future<void> _onProfileSelected(WorldProfile? next) async {
    if (next == null || next == _profile) return;
    await WorldProfilePrefs.save(next);
    if (!mounted) return;
    setState(() => _profile = next);
    widget.onProfileChanged?.call(next);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final handoff = widget.handoff;
    final t = handoff?.progress ?? 1.0;
    final launchBranding = handoff?.branding ?? WorldLaunchBranding.of(_profile);
    final uiBranding = WorldLaunchBranding.of(_profile);

    final effectOpacity = handoff == null
        ? 0.0
        : (1 - Curves.easeOut.transform(t)).clamp(0.0, 1.0);
    final brandTextOpacity = handoff == null
        ? 1.0
        : Curves.easeIn.transform(((t - 0.68) / 0.32).clamp(0.0, 1.0));
    final bodyOpacity = handoff == null
        ? 1.0
        : Curves.easeIn.transform(((t - 0.78) / 0.22).clamp(0.0, 1.0));

    final scaffoldBg = handoff == null
        ? null
        : Color.lerp(
            launchBranding.backgroundBottom,
            theme.colorScheme.surface,
            Curves.easeInOut.transform(t),
          );

    return Scaffold(
      backgroundColor: scaffoldBg,
      body: Stack(
        fit: StackFit.expand,
        children: [
          if (handoff != null && effectOpacity > 0.01)
            IgnorePointer(
              child: Opacity(
                opacity: effectOpacity,
                child: ColoredBox(
                  color: launchBranding.backgroundBottom,
                  child: LaunchEffectOverlay(
                    branding: launchBranding,
                    progress: handoff.effectProgress,
                  ),
                ),
              ),
            ),
          SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final narrow = constraints.maxWidth < 380;
                final titleStyle = theme.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  fontSize: narrow ? 22 : null,
                  letterSpacing: 4,
                  color: handoff != null && launchBranding.isLightBackground
                      ? Color.lerp(
                          launchBranding.subtitleColor,
                          theme.colorScheme.onSurface,
                          t,
                        )
                      : null,
                );
                final subBrandStyle = theme.textTheme.labelMedium?.copyWith(
                  color: handoff != null && launchBranding.isLightBackground
                      ? Color.lerp(
                          launchBranding.subtitleColor,
                          theme.colorScheme.onSurfaceVariant,
                          t,
                        )
                      : theme.colorScheme.onSurfaceVariant,
                  letterSpacing: 1.6,
                );

                // 起動時は画面中央付近へ、完了時はタイトル列の定位置へ
                final launchYOffset = constraints.maxHeight * 0.14 * (1 - t);
                final logoScale =
                    _titleLogoSize +
                    (_launchLogoSize - _titleLogoSize) * (1 - t);

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
                                Opacity(
                                  opacity: bodyOpacity,
                                  child: Align(
                                    alignment: Alignment.centerRight,
                                    child: IconButton(
                                      tooltip: _launchSoundOn
                                          ? '起動音: ON（タップでOFF）'
                                          : '起動音: OFF（タップでON）',
                                      onPressed: handoff == null
                                          ? () async {
                                              final next = !_launchSoundOn;
                                              await LaunchBrandingPrefs
                                                  .saveSoundEnabled(next);
                                              if (!mounted) return;
                                              setState(
                                                () => _launchSoundOn = next,
                                              );
                                            }
                                          : null,
                                      icon: Icon(
                                        _launchSoundOn
                                            ? Icons.volume_up_outlined
                                            : Icons.volume_off_outlined,
                                        size: 22,
                                      ),
                                    ),
                                  ),
                                ),
                                Transform.translate(
                                  offset: Offset(0, launchYOffset),
                                  child: _TitleBrandHeader(
                                    branding: uiBranding,
                                    logoSize: logoScale,
                                    textOpacity: brandTextOpacity,
                                    titleStyle: titleStyle,
                                    subBrandStyle: subBrandStyle,
                                    effectProgress: handoff?.effectProgress ?? 0,
                                  ),
                                ),
                                Opacity(
                                  opacity: bodyOpacity,
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.stretch,
                                    children: [
                                      const SizedBox(height: 12),
                                      Text(
                                        '都市型 GPS 鬼ごっこ',
                                        textAlign: TextAlign.center,
                                        style:
                                            theme.textTheme.bodyLarge?.copyWith(
                                          color: theme
                                              .colorScheme.onSurfaceVariant,
                                          fontSize: narrow ? 14 : null,
                                        ),
                                      ),
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
                                            helperText:
                                                '地図・ピン・雰囲気のテーマ（ゲーム中も変更可）',
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
                                        FilledButton.icon(
                                          onPressed: () {
                                            Navigator.of(context).push<void>(
                                              MaterialPageRoute<void>(
                                                builder: (_) =>
                                                    const RoomLobbyScreen(),
                                              ),
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
                                        const SizedBox(height: 12),
                                        OutlinedButton.icon(
                                          onPressed: () {
                                            Navigator.of(context).push<void>(
                                              MaterialPageRoute<void>(
                                                builder: (_) => GameMapScreen(
                                                  profile: _profile,
                                                ),
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
                                        const SizedBox(height: 20),
                                        Text(
                                          FirebaseBootstrap.isReady
                                              ? 'Firebase: 接続準備 OK（匿名ログインはルーム参加時）'
                                              : 'Firebase: 未接続 — ルーム参加時に再試行します',
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
    required this.effectProgress,
  });

  final WorldLaunchBranding branding;
  final double logoSize;
  final double textOpacity;
  final TextStyle? titleStyle;
  final TextStyle? subBrandStyle;
  final double effectProgress;

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
                blurRadius: 24,
                spreadRadius: 0,
              ),
            ],
          ),
          child: ThemedGeometricLogo(
            branding: branding,
            size: logoSize,
            pulse: effectProgress,
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
