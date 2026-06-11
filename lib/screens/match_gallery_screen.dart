import 'package:flutter/material.dart';

import '../game/game_state.dart';
import '../game/match_record.dart';
import '../services/match_archive_store.dart';
import '../widgets/confirm_dialog.dart';
import '../session/world_profile_prefs.dart';
import '../widgets/scene_transitions.dart';
import 'match_replay_screen.dart';

/// 端末に保存した試合一覧。同期前はローカルのみ。
class MatchGalleryScreen extends StatefulWidget {
  const MatchGalleryScreen({super.key});

  @override
  State<MatchGalleryScreen> createState() => _MatchGalleryScreenState();
}

class _MatchGalleryScreenState extends State<MatchGalleryScreen> {
  final MatchArchiveStore _store = MatchArchiveStore();
  List<SavedMatchRecord> _items = [];
  bool _loading = true;
  int? _approxBytes;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  Future<void> _deleteAll() async {
    final ok = await showConfirmDialog(
      context,
      title: 'すべての軌跡を削除',
      message: '保存済みの試合記録 ${_items.length} 件をすべて削除しますか？\nこの操作は取り消せません。',
      confirmLabel: 'すべて削除',
      isDestructive: true,
    );
    if (!ok) return;
    await _store.clearAll();
    await _reload();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('すべての軌跡を削除しました')),
    );
  }

  Future<void> _reload() async {
    setState(() => _loading = true);
    final items = await _store.listRecent(limit: 50);
    final bytes = await _store.totalApproxBytes();
    if (!mounted) return;
    setState(() {
      _items = items;
      _approxBytes = bytes;
      _loading = false;
    });
  }

  String _outcomeJa(GameState s) => s.label;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('試合ギャラリー'),
        actions: [
          if (_items.isNotEmpty)
            IconButton(
              tooltip: 'すべて削除',
              onPressed: _loading ? null : _deleteAll,
              icon: const Icon(Icons.delete_sweep_outlined),
            ),
          IconButton(
            tooltip: '再読込',
            onPressed: _loading ? null : _reload,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (_approxBytes != null)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                    child: Text(
                      '保存済みおおよその容量: ${_formatBytes(_approxBytes!)} （この端末内のみ・同意済みログのみ）',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ),
                Expanded(
                  child: _items.isEmpty
                      ? Center(
                          child: Padding(
                            padding: const EdgeInsets.all(28),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.movie_filter_outlined,
                                  size: 56,
                                  color: Theme.of(context)
                                      .colorScheme
                                      .outline,
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  '保存された試合がありません',
                                  style:
                                      Theme.of(context).textTheme.titleMedium,
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  '設定 → データ管理で「試合後に軌跡を端末保存」をオンにすると、'
                                  '終了後にここからリプレイできます。',
                                  textAlign: TextAlign.center,
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodySmall
                                      ?.copyWith(
                                        color: Theme.of(context)
                                            .colorScheme
                                            .onSurfaceVariant,
                                      ),
                                ),
                              ],
                            ),
                          ),
                        )
                      : ListView.separated(
                          itemCount: _items.length,
                          separatorBuilder: (_, _) => const Divider(height: 1),
                          itemBuilder: (ctx, i) {
                            final m = _items[i];
                            final rn = (m.tracks['runner_local']?.length ?? 0);
                            final on = (m.tracks['oni_local']?.length ?? 0);
                            return ListTile(
                              leading: CircleAvatar(
                                child: Text(m.outcome.galleryEmoji),
                              ),
                              title: Text(_outcomeJa(m.outcome)),
                              subtitle: Text(
                                '${m.startedAtUtc.toLocal()} 開始\n点数 逃:$rn 鬼:$on',
                              ),
                              isThreeLine: true,
                              onTap: () async {
                                final profile = await WorldProfilePrefs.load();
                                if (!context.mounted) return;
                                await AppNav.push<void>(
                                  context,
                                  (_) => MatchReplayScreen(record: m),
                                  worldProfile: profile,
                                );
                              },
                              trailing: IconButton(
                                icon: const Icon(Icons.delete_outline),
                                onPressed: () async {
                                  final ok = await showConfirmDialog(
                                    context,
                                    title: '軌跡を削除',
                                    message:
                                        '「${_outcomeJa(m.outcome)}」の記録（${m.startedAtUtc.toLocal()}）を削除しますか？',
                                  );
                                  if (!ok) return;
                                  await _store.delete(m.id);
                                  await _reload();
                                },
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
    );
  }

  static String _formatBytes(int b) {
    if (b < 1024) return '$b B';
    if (b < 1024 * 1024) return '${(b / 1024).toStringAsFixed(1)} KB';
    return '${(b / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
}

extension GameStateGalleryDecor on GameState {
  String get galleryEmoji {
    switch (this) {
      case GameState.runnerWin:
        return '🎉';
      case GameState.caughtByOni:
        return '👻';
      case GameState.waiting:
      case GameState.running:
        return '📍';
    }
  }
}
