import 'dart:async';

import 'package:flutter/material.dart';

import '../game/game_state.dart';
import '../game/match_record.dart';
import '../services/match_archive_store.dart';
import '../services/match_replay_latest_fetch.dart';
import '../sync/firebase_bootstrap.dart';
import '../sync/firestore_room_session.dart';
import '../theme/world_profile.dart';
import '../presentation/world/world_presentation_catalog.dart';
import '../presentation/world/world_presentation_context.dart';
import '../presentation/world/widgets/world_chip.dart';
import '../presentation/world/widgets/world_scaffold.dart';
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
  WorldProfile _scaffoldProfile = WorldProfile.horror;

  @override
  void initState() {
    super.initState();
    unawaited(_loadScaffoldProfile());
    _reload();
  }

  Future<void> _loadScaffoldProfile() async {
    final profile = await WorldProfilePrefs.load();
    if (mounted) setState(() => _scaffoldProfile = profile);
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

  Future<void> _openReplay(SavedMatchRecord record) async {
    final profile = record.worldProfile != null
        ? WorldProfile.fromStorageName(record.worldProfile)
        : await WorldProfilePrefs.load();
    if (!mounted) return;
    await AppNav.push<void>(
      context,
      (_) => MatchReplayScreen(record: record),
      worldProfile: profile,
    );
  }

  Future<void> _fetchLatestAndReplay(SavedMatchRecord local) async {
    final roomId = local.onlineRoomId;
    final sessionKey = local.onlineSessionKey;
    if (roomId == null || sessionKey == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('オンライン試合の記録情報がありません')),
      );
      await _openReplay(local);
      return;
    }

    if (!mounted) return;
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => const PopScope(
        canPop: false,
        child: AlertDialog(
          content: Row(
            children: [
              CircularProgressIndicator(),
              SizedBox(width: 20),
              Expanded(child: Text('試合記録を更新しています…')),
            ],
          ),
        ),
      ),
    );

    await FirebaseBootstrap.tryInit();
    final fs = FirestoreRoomSession();
    fs.bindRoomForArchiveFetch(roomId);

    final resolved = await MatchReplayLatestFetch.resolveForGallery(
      local: local,
      fetchRemote: () => fs.fetchMergedMatchArchive(
        sessionKey,
        localFallback: local,
      ),
    );

    if (!mounted) return;
    Navigator.of(context, rootNavigator: true).pop();

    final toast = MatchReplayLatestFetch.toastAfterGalleryResolve(resolved);
    if (toast != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(toast)),
      );
    }

    final record = resolved.record ?? local;
    if (resolved.source == MatchReplayFetchSource.remoteMerged) {
      await _store.save(record);
      await _reload();
    }
    await _openReplay(record);
  }

  @override
  Widget build(BuildContext context) {
    final pack = WorldPresentationCatalog.of(_scaffoldProfile);
    return Theme(
      data: Theme.of(context).copyWith(
        extensions: [WorldProfileTheme(_scaffoldProfile)],
      ),
      child: WorldScaffold(
        profile: _scaffoldProfile,
        showProfileMorph: true,
        playEntryReveal: true,
        appBar: AppBar(
          title: const Text('試合ギャラリー'),
          backgroundColor: Colors.transparent,
          foregroundColor: pack.textOnScaffold,
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
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: pack.mutedOnScaffold,
                          ),
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
                                  color: pack.mutedOnScaffold,
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  '保存された試合がありません',
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleMedium
                                      ?.copyWith(color: pack.textOnScaffold),
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
                                        color: pack.mutedOnScaffold,
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
                            final others = m.tracks.keys
                                .where((k) => k.startsWith('player_'))
                                .length;
                            final trackSummary = others > 0
                                ? '軌跡 ${m.tracks.length}人分'
                                : '軌跡 逃:$rn${on > 0 ? ' 鬼:$on' : ''}';
                            final worldProfile = m.worldProfile != null
                                ? WorldProfile.fromStorageName(m.worldProfile)
                                : _scaffoldProfile;
                            final worldLabel = m.worldProfile != null
                                ? worldProfile.label
                                : null;
                            return ListTile(
                              leading: WorldChip(
                                profile: worldProfile,
                                label: m.outcome.galleryEmoji,
                                dense: true,
                              ),
                              title: Text(
                                m.galleryTitle,
                                style: TextStyle(color: pack.textOnScaffold),
                              ),
                              subtitle: Text(
                                '${m.startedAtUtc.toLocal()} 開始'
                                '${worldLabel != null ? ' · $worldLabel' : ''}\n'
                                '$trackSummary'
                                '${m.events.isNotEmpty ? ' · イベント${m.events.length}' : ''}'
                                '${m.gimmickLayout != null ? ' · ギミックあり' : ''}',
                                style: TextStyle(color: pack.mutedOnScaffold),
                              ),
                              isThreeLine: true,
                              onTap: () => _openReplay(m),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  if (m.onlineRoomId != null &&
                                      m.onlineSessionKey != null)
                                    IconButton(
                                      tooltip: '最新の記録を取得',
                                      icon: const Icon(Icons.cloud_download_outlined),
                                      onPressed: () =>
                                          _fetchLatestAndReplay(m),
                                    ),
                                  IconButton(
                                    icon: const Icon(Icons.delete_outline),
                                    onPressed: () async {
                                      final ok = await showConfirmDialog(
                                        context,
                                        title: '軌跡を削除',
                                        message:
                                            '「${m.galleryTitle}」の記録（${m.startedAtUtc.toLocal()}）を削除しますか？',
                                      );
                                      if (!ok) return;
                                      await _store.delete(m.id);
                                      await _reload();
                                    },
                                  ),
                                ],
                              ),
                            );
                          },
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
