import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

import '../game/match_record.dart';
import '../services/match_archive_store.dart';
import '../sync/offline_sync_queue.dart';

class PrivacyControlScreen extends StatefulWidget {
  const PrivacyControlScreen({super.key});

  @override
  State<PrivacyControlScreen> createState() => _PrivacyControlScreenState();
}

class _PrivacyControlScreenState extends State<PrivacyControlScreen> {
  final MatchArchiveStore _archiveStore = MatchArchiveStore();
  final OfflineSyncQueue _queue = OfflineSyncQueue();

  bool _loading = true;
  List<SavedMatchRecord> _records = const [];
  int _bytes = 0;
  int _queueCount = 0;
  LocationPermission? _permission;
  bool _serviceEnabled = false;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  Future<void> _reload() async {
    setState(() => _loading = true);
    final records = await _archiveStore.listRecent(limit: 100);
    final bytes = await _archiveStore.totalApproxBytes();
    final queue = await _queue.load();
    final permission = await Geolocator.checkPermission();
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!mounted) return;
    setState(() {
      _records = records;
      _bytes = bytes;
      _queueCount = queue.length;
      _permission = permission;
      _serviceEnabled = serviceEnabled;
      _loading = false;
    });
  }

  Future<void> _deleteAllRecords() async {
    await _archiveStore.clearAll();
    await _reload();
  }

  Future<void> _clearOfflineQueue() async {
    await _queue.clear();
    await _reload();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('プライバシー管理'),
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
                _SectionCard(
                  title: '位置情報許可',
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('GPSサービス: ${_serviceEnabled ? 'ON' : 'OFF'}'),
                      Text('権限: ${_permission?.name ?? 'unknown'}'),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        children: [
                          FilledButton.tonal(
                            onPressed: Geolocator.openLocationSettings,
                            child: const Text('位置情報設定を開く'),
                          ),
                          FilledButton.tonal(
                            onPressed: Geolocator.openAppSettings,
                            child: const Text('アプリ設定を開く'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                _SectionCard(
                  title: '軌跡記録',
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('保存試合数: ${_records.length}'),
                      Text('保存容量: ${_formatBytes(_bytes)}'),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        children: [
                          FilledButton.tonal(
                            onPressed: _records.isEmpty ? null : _deleteAllRecords,
                            child: const Text('保存記録を全削除'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                _SectionCard(
                  title: 'オフライン同期キュー',
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('未送信アイテム: $_queueCount'),
                      const SizedBox(height: 8),
                      FilledButton.tonal(
                        onPressed: _queueCount == 0 ? null : _clearOfflineQueue,
                        child: const Text('未送信キューをクリア'),
                      ),
                    ],
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

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            child,
          ],
        ),
      ),
    );
  }
}
