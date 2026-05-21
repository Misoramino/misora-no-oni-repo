import 'package:flutter/material.dart';

import '../session/launch_branding_prefs.dart';
import '../session/world_profile_prefs.dart';
import '../sync/firebase_bootstrap.dart';
import '../theme/world_profile.dart';
import '../theme/world_launch_branding.dart';
import '../widgets/themed_geometric_logo.dart';
import 'game_map_screen.dart';
import 'room_lobby_screen.dart';

/// アプリ入口。オンラインルーム参加か、オフライン練習かを選ぶ。
class TitleScreen extends StatefulWidget {
  const TitleScreen({
    this.initialProfile = WorldProfile.horror,
    this.onProfileChanged,
    this.showBrandHeader = true,
    this.reserveBrandHeaderSpace = false,
    super.key,
  });

  final WorldProfile initialProfile;
  final ValueChanged<WorldProfile>? onProfileChanged;

  /// false のときロゴ行を隠す（起動→タイトル遷移中のフローティングロゴ用）。
  final bool showBrandHeader;

  /// 起動遷移中にレイアウト高さだけ確保する。
  final bool reserveBrandHeaderSpace;

  @override
  State<TitleScreen> createState() => _TitleScreenState();
}

class _TitleScreenState extends State<TitleScreen> {
  bool _booting = true;
  bool _launchSoundOn = true;
  late WorldProfile _profile;

  @override
  void initState() {
    super.initState();
    _profile = widget.initialProfile;
    Future<void>.microtask(_boot);
  }

  Future<void> _boot() async {
    try {
      await FirebaseBootstrap.tryInit();
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
    return Scaffold(
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final narrow = constraints.maxWidth < 380;
            final branding = WorldLaunchBranding.of(_profile);
            final titleStyle = theme.textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
              fontSize: narrow ? 22 : null,
              letterSpacing: 4,
            );
            final subBrandStyle = theme.textTheme.labelMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              letterSpacing: 1.6,
            );
            // ScrollView 内の Column は maxHeight が無限になり mainAxisAlignment.center が
            // 効かず上に詰まる。SliverFillRemaining でビューポート中央に置く。
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
                            Align(
                              alignment: Alignment.centerRight,
                              child: IconButton(
                                tooltip: _launchSoundOn
                                    ? '起動音: ON（タップでOFF）'
                                    : '起動音: OFF（タップでON）',
                                onPressed: () async {
                                  final next = !_launchSoundOn;
                                  await LaunchBrandingPrefs.saveSoundEnabled(
                                    next,
                                  );
                                  if (!mounted) return;
                                  setState(() => _launchSoundOn = next);
                                },
                                icon: Icon(
                                  _launchSoundOn
                                      ? Icons.volume_up_outlined
                                      : Icons.volume_off_outlined,
                                  size: 22,
                                ),
                              ),
                            ),
                            if (widget.showBrandHeader || widget.reserveBrandHeaderSpace)
                              _TitleBrandHeader(
                                visible: widget.showBrandHeader,
                                branding: branding,
                                titleStyle: titleStyle,
                                subBrandStyle: subBrandStyle,
                              ),
                            const SizedBox(height: 12),
                            Text(
                              '都市型 GPS 鬼ごっこ',
                              textAlign: TextAlign.center,
                              style: theme.textTheme.bodyLarge?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                                fontSize: narrow ? 14 : null,
                              ),
                            ),
                            const SizedBox(height: 20),
                            if (!_booting)
                              DropdownButtonFormField<WorldProfile>(
                                key: ValueKey(_profile),
                                initialValue: _profile,
                                decoration: const InputDecoration(
                                  labelText: '世界観',
                                  border: OutlineInputBorder(),
                                  helperText: '地図・ピン・雰囲気のテーマ（ゲーム中も変更可）',
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
                            if (_booting)
                              const Center(
                                child: CircularProgressIndicator(),
                              )
                            else ...[
                              FilledButton.icon(
                                onPressed: () {
                                  Navigator.of(context).push<void>(
                                    MaterialPageRoute<void>(
                                      builder: (_) =>
                                          const RoomLobbyScreen(),
                                    ),
                                  );
                                },
                                icon: const Icon(Icons.groups_outlined),
                                label: const Padding(
                                  padding: EdgeInsets.symmetric(vertical: 12),
                                  child: Text('オンラインルーム'),
                                ),
                              ),
                              const SizedBox(height: 12),
                              OutlinedButton.icon(
                                onPressed: () {
                                  Navigator.of(context).push<void>(
                                    MaterialPageRoute<void>(
                                      builder: (_) =>
                                          GameMapScreen(profile: _profile),
                                    ),
                                  );
                                },
                                icon: const Icon(Icons.map_outlined),
                                label: const Padding(
                                  padding: EdgeInsets.symmetric(vertical: 12),
                                  child: Text('オフラインで練習（マップのみ）'),
                                ),
                              ),
                              const SizedBox(height: 20),
                              Text(
                                FirebaseBootstrap.isReady
                                    ? 'Firebase: 接続準備 OK（匿名ログインはルーム参加時）'
                                    : 'Firebase: 未接続 — ルーム参加時に再試行します',
                                textAlign: TextAlign.center,
                                style: theme.textTheme.bodySmall?.copyWith(
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
                                  style: theme.textTheme.bodySmall?.copyWith(
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
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _TitleBrandHeader extends StatelessWidget {
  const _TitleBrandHeader({
    required this.visible,
    required this.branding,
    required this.titleStyle,
    required this.subBrandStyle,
  });

  final bool visible;
  final WorldLaunchBranding branding;
  final TextStyle? titleStyle;
  final TextStyle? subBrandStyle;

  @override
  Widget build(BuildContext context) {
    final block = Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        ThemedGeometricLogo(branding: branding, size: 56),
        const SizedBox(height: 12),
        Text('ONI PIN', textAlign: TextAlign.center, style: titleStyle),
        const SizedBox(height: 4),
        Text(
          'GPS × ONI GAME',
          textAlign: TextAlign.center,
          style: subBrandStyle,
        ),
      ],
    );
    if (visible) return block;
    return Opacity(opacity: 0, child: IgnorePointer(child: block));
  }
}
