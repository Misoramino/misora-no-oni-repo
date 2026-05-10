import 'package:flutter/material.dart';

import '../game/game_state.dart';
import '../game/match_record.dart';
import '../services/match_archive_store.dart';
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
                      ? const Center(child: Text('まだ保存された試合がありません。\n開始前に「軌跡を保存」をオンにしてください。'))
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
                              onTap: () {
                                Navigator.push<void>(
                                  context,
                                  MaterialPageRoute<void>(
                                    builder: (_) =>
                                        MatchReplayScreen(record: m),
                                  ),
                                );
                              },
                              trailing: IconButton(
                                icon: const Icon(Icons.delete_outline),
                                onPressed: () async {
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
