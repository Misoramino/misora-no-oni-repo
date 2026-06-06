import 'package:flutter/material.dart';

import '../progression/player_progress.dart';
import '../progression/player_title.dart';
import '../progression/progress_store.dart';
import '../widgets/responsive_page.dart';

/// 累積戦績と称号コレクションを表示する画面。
class ProgressScreen extends StatefulWidget {
  const ProgressScreen({super.key});

  @override
  State<ProgressScreen> createState() => _ProgressScreenState();
}

class _ProgressScreenState extends State<ProgressScreen> {
  PlayerProgress _progress = const PlayerProgress();
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final p = await ProgressStore.load();
    if (!mounted) return;
    setState(() {
      _progress = p;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final unlocked = _progress.unlockedTitleIds;
    final earned = PlayerTitles.all.where((t) => unlocked.contains(t.id)).length;

    return Scaffold(
      appBar: AppBar(title: const Text('戦績・称号')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ResponsivePage(
              child: ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              _Metric(value: '${_progress.matches}', label: '試合'),
                              _Metric(value: '${_progress.wins}', label: '勝利'),
                              _Metric(
                                value:
                                    '${(_progress.winRate * 100).round()}%',
                                label: '勝率',
                              ),
                              _Metric(
                                value: '${_progress.bestStreak}',
                                label: '最高連勝',
                              ),
                            ],
                          ),
                          const Divider(height: 24),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              _Metric(
                                value: '${_progress.winsHuman}',
                                label: '人間勝利',
                              ),
                              _Metric(
                                value: '${_progress.winsOni}',
                                label: '鬼勝利',
                              ),
                              _Metric(
                                value: '${_progress.currentStreak}',
                                label: '現在連勝',
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Text('称号', style: theme.textTheme.titleMedium),
                      const SizedBox(width: 8),
                      Text(
                        '$earned / ${PlayerTitles.all.length}',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ...PlayerTitles.all.map((t) {
                    final got = unlocked.contains(t.id);
                    return Card(
                      child: ListTile(
                        leading: Icon(
                          got
                              ? IconData(t.icon, fontFamily: 'MaterialIcons')
                              : Icons.lock_outline_rounded,
                          color: got
                              ? theme.colorScheme.primary
                              : theme.colorScheme.outline,
                        ),
                        title: Text(
                          got ? t.label : '???',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: got
                                ? null
                                : theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                        subtitle: Text(t.description),
                        trailing: got
                            ? Icon(Icons.check_circle,
                                color: Colors.green.shade600)
                            : null,
                      ),
                    );
                  }),
                ],
              ),
            ),
    );
  }
}

class _Metric extends StatelessWidget {
  const _Metric({required this.value, required this.label});

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      children: [
        Text(
          value,
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.primary,
          ),
        ),
        const SizedBox(height: 2),
        Text(label, style: theme.textTheme.labelSmall),
      ],
    );
  }
}
