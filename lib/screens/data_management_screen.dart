import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../presentation/world/world_legibility.dart';
import '../presentation/world/world_presentation_context.dart';
import '../presentation/world/world_ui_helpers.dart';
import '../services/match_archive_store.dart';
import '../session/game_map_prefs.dart';
import '../session/world_profile_prefs.dart';
import '../widgets/scene_transitions.dart';
import 'match_gallery_screen.dart';

/// 試合軌跡の保存設定とギャラリーへの導線。
class DataManagementScreen extends StatefulWidget {
  const DataManagementScreen({super.key});

  @override
  State<DataManagementScreen> createState() => _DataManagementScreenState();
}

class _DataManagementScreenState extends State<DataManagementScreen> {
  final MatchArchiveStore _archiveStore = MatchArchiveStore();

  bool _loading = true;
  bool _trajectoryConsent = true;
  int _recordCount = 0;
  int _bytes = 0;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  Future<void> _reload() async {
    setState(() => _loading = true);
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getBool(GameMapPrefs.trajectoryConsent);
    final records = await _archiveStore.listRecent(limit: 100);
    final bytes = await _archiveStore.totalApproxBytes();
    if (!mounted) return;
    setState(() {
      _trajectoryConsent = stored ?? true;
      _recordCount = records.length;
      _bytes = bytes;
      _loading = false;
    });
  }

  Future<void> _setTrajectoryConsent(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(GameMapPrefs.trajectoryConsent, value);
    if (!mounted) return;
    setState(() => _trajectoryConsent = value);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final profile = context.worldProfile;
    return WorldScaffoldThemed(
      profile: profile,
      child: Scaffold(
      appBar: AppBar(
        title: const Text('データ管理'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loading ? null : _reload,
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Text(
                  'この端末に保存される試合データです。オンライン試合の同期とは別で、個人の軌跡・戦績用です。',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: context.worldMutedOnScaffold,
                  ),
                ),
                const SizedBox(height: 16),
                WorldPanelThemed(
                  profile: profile,
                  child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          '試合ギャラリー（軌跡）',
                          style: theme.textTheme.titleMedium,
                        ),
                        const SizedBox(height: 8),
                        SwitchListTile(
                          contentPadding: EdgeInsets.zero,
                          title: const Text('試合後に軌跡を端末保存'),
                          subtitle: const Text(
                            'オフにすると新しい試合の軌跡は記録されません',
                          ),
                          value: _trajectoryConsent,
                          onChanged: _setTrajectoryConsent,
                        ),
                        Text(
                          '保存済み: $_recordCount 試合 / 約 ${_formatBytes(_bytes)}',
                        ),
                        const SizedBox(height: 8),
                        FilledButton.tonalIcon(
                          onPressed: () async {
                            final profile = await WorldProfilePrefs.load();
                            if (!context.mounted) return;
                            await AppNav.push<void>(
                              context,
                              (_) => const MatchGalleryScreen(),
                              worldProfile: profile,
                            );
                            await _reload();
                          },
                          icon: const Icon(Icons.movie_filter_outlined),
                          label: const Text('試合ギャラリーを開く'),
                        ),
                      ],
                    ),
                  ),
                ),
                ),
              ],
            ),
    ),
    );
  }

  static String _formatBytes(int b) {
    if (b < 1024) return '$b B';
    if (b < 1024 * 1024) return '${(b / 1024).toStringAsFixed(1)} KB';
    return '${(b / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
}
