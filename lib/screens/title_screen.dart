import 'package:flutter/material.dart';

import '../sync/firebase_bootstrap.dart';
import '../theme/world_profile.dart';
import '../widgets/responsive_page.dart';
import 'game_map_screen.dart';
import 'room_lobby_screen.dart';

/// アプリ入口。オンラインルーム参加か、オフライン練習かを選ぶ。
class TitleScreen extends StatefulWidget {
  const TitleScreen({super.key});

  @override
  State<TitleScreen> createState() => _TitleScreenState();
}

class _TitleScreenState extends State<TitleScreen> {
  bool _booting = true;

  @override
  void initState() {
    super.initState();
    Future<void>.microtask(_warmFirebase);
  }

  Future<void> _warmFirebase() async {
    await FirebaseBootstrap.tryInit();
    if (mounted) setState(() => _booting = false);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: ResponsivePage(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 24),
            Icon(
              Icons.nightlight_round,
              size: 56,
              color: theme.colorScheme.primary,
            ),
            const SizedBox(height: 16),
            Text(
              'Oni Game',
              textAlign: TextAlign.center,
              style: theme.textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '都市型 GPS 鬼ごっこ',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyLarge?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 32),
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
                      builder: (_) => const GameMapScreen(
                        profile: WorldProfile.horror,
                      ),
                    ),
                  );
                },
                icon: const Icon(Icons.map_outlined),
                label: const Padding(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  child: Text('オフラインで練習（マップのみ）'),
                ),
              ),
              const SizedBox(height: 24),
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
          ],
        ),
      ),
    );
  }
}
