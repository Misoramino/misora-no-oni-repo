import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../session/world_profile_prefs.dart';
import '../sync/firebase_bootstrap.dart';
import '../theme/title_profile_chrome.dart';
import '../theme/world_profile.dart';
import '../widgets/responsive_page.dart';
import 'game_map_screen.dart';
import 'room_lobby_screen.dart';

/// アプリ入口。オンラインルーム参加か、オフライン練習かを選ぶ。
class TitleScreen extends StatefulWidget {
  const TitleScreen({
    this.initialProfile = WorldProfile.horror,
    this.onProfileChanged,
    super.key,
  });

  final WorldProfile initialProfile;
  final ValueChanged<WorldProfile>? onProfileChanged;

  @override
  State<TitleScreen> createState() => _TitleScreenState();
}

class _TitleScreenState extends State<TitleScreen> {
  bool _booting = true;
  late WorldProfile _profile;

  @override
  void initState() {
    super.initState();
    _profile = widget.initialProfile;
    Future<void>.microtask(_boot);
  }

  Future<void> _boot() async {
    await FirebaseBootstrap.tryInit();
    final saved = await WorldProfilePrefs.load();
    if (!mounted) return;
    setState(() {
      _profile = saved;
      _booting = false;
    });
    widget.onProfileChanged?.call(saved);
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
      body: ResponsivePage(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final narrow = constraints.maxWidth < 380;
            final titleStyle = theme.textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
              fontSize: narrow ? 22 : null,
            );
            final subStyle = theme.textTheme.bodyLarge?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              fontSize: narrow ? 14 : null,
            );
            return SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: constraints.maxHeight,
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const SizedBox(height: 20),
                      Icon(
                        TitleProfileChrome.iconFor(_profile),
                        size: 56,
                        color: theme.colorScheme.primary,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Oni Game',
                        textAlign: TextAlign.center,
                        style: titleStyle,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '都市型 GPS 鬼ごっこ',
                        textAlign: TextAlign.center,
                        style: subStyle,
                      ),
                      const SizedBox(height: 20),
                      if (!_booting)
                        DropdownButtonFormField<WorldProfile>(
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
                        const Center(child: CircularProgressIndicator())
                      else ...[
                        FilledButton.icon(
                          onPressed: () {
                            Navigator.of(context).push<void>(
                              MaterialPageRoute<void>(
                                builder: (_) => const RoomLobbyScreen(),
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
                        if (FirebaseBootstrap.lastErrorBrief != null) ...[
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
                      SizedBox(height: math.max(24, constraints.maxHeight * 0.08)),
                      Center(
                        child: Icon(
                          Icons.grid_4x4_outlined,
                          size: 40,
                          color: theme.colorScheme.outlineVariant
                              .withValues(alpha: 0.45),
                        ),
                      ),
                      const SizedBox(height: 12),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
