import 'package:flutter/material.dart';

import '../game/play_area.dart';
import '../services/play_area_slot_store.dart';
import '../features/game_map/play_area/geo_json_actions.dart';

/// 保存済みプレイエリアの一覧（写真フォルダ風）。
class AreaGalleryScreen extends StatefulWidget {
  const AreaGalleryScreen({
    required this.store,
    this.selectedId,
    this.canEdit = true,
    super.key,
  });

  final PlayAreaSlotStore store;
  final String? selectedId;
  final bool canEdit;

  @override
  State<AreaGalleryScreen> createState() => _AreaGalleryScreenState();
}

class _AreaGalleryScreenState extends State<AreaGalleryScreen> {
  List<SavedPlayArea> _areas = const [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  Future<void> _reload() async {
    final list = await widget.store.loadAll();
    if (!mounted) return;
    setState(() {
      _areas = list;
      _loading = false;
    });
  }

  String _summary(PlayArea area) => switch (area.type) {
        PlayAreaType.circle =>
          '円 · 半径 ${area.radiusMeters.toStringAsFixed(0)} m',
        PlayAreaType.polygon => '多角形 · ${area.points.length} 頂点',
      };

  Future<void> _rename(SavedPlayArea slot) async {
    final controller = TextEditingController(text: slot.name);
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('エリア名を変更'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(hintText: '名前'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('キャンセル'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('保存'),
          ),
        ],
      ),
    );
    final name = controller.text.trim();
    controller.dispose();
    if (ok != true || name.isEmpty) return;
    await widget.store.upsert(
      SavedPlayArea(
        id: slot.id,
        name: name,
        area: slot.area,
        savedAtUtc: slot.savedAtUtc,
      ),
    );
    await _reload();
  }

  Future<void> _delete(SavedPlayArea slot) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('エリアを削除'),
        content: Text('「${slot.name}」を削除しますか？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('キャンセル'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('削除'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    await widget.store.remove(slot.id);
    await _reload();
  }

  Future<void> _importGeoJson() async {
    if (!widget.canEdit) return;
    final area = await GeoJsonActions.showImportDialog(context);
    if (area == null || !mounted) return;
    final name = await _promptName(
      defaultName: 'インポート ${DateTime.now().month}/${DateTime.now().day}',
    );
    if (name == null || name.isEmpty) return;
    final id = 'area_${DateTime.now().millisecondsSinceEpoch}';
    await widget.store.upsert(
      SavedPlayArea(
        id: id,
        name: name,
        area: area,
        savedAtUtc: DateTime.now().toUtc(),
      ),
    );
    await _reload();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('「$name」をギャラリーに追加しました')),
    );
  }

  Future<String?> _promptName({required String defaultName}) async {
    final controller = TextEditingController(text: defaultName);
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('エリア名'),
        content: TextField(
          controller: controller,
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('キャンセル'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('保存'),
          ),
        ],
      ),
    );
    final name = controller.text.trim();
    controller.dispose();
    return ok == true ? name : null;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('エリアギャラリー'),
        actions: [
          if (widget.canEdit)
            IconButton(
              tooltip: 'GeoJSON インポート',
              onPressed: _importGeoJson,
              icon: const Icon(Icons.upload_file_outlined),
            ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _areas.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.map_outlined,
                            size: 56, color: theme.colorScheme.outline),
                        const SizedBox(height: 12),
                        Text(
                          '保存したエリアがありません',
                          style: theme.textTheme.titleMedium,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'マップパネルでエリアを編集して保存するか、右上から GeoJSON を取り込めます。',
                          textAlign: TextAlign.center,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                        if (widget.canEdit) ...[
                          const SizedBox(height: 16),
                          FilledButton.tonalIcon(
                            onPressed: _importGeoJson,
                            icon: const Icon(Icons.upload_file_outlined),
                            label: const Text('GeoJSON をインポート'),
                          ),
                        ],
                      ],
                    ),
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.all(12),
                  itemCount: _areas.length,
                  separatorBuilder: (context, index) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final slot = _areas[index];
                    final selected = slot.id == widget.selectedId;
                    return Card(
                      elevation: selected ? 2 : 0,
                      color: selected
                          ? theme.colorScheme.primaryContainer
                              .withValues(alpha: 0.35)
                          : null,
                      child: ListTile(
                        leading: CircleAvatar(
                          child: Icon(
                            slot.area.type == PlayAreaType.circle
                                ? Icons.radio_button_unchecked
                                : Icons.pentagon_outlined,
                          ),
                        ),
                        title: Text(
                          slot.name,
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        subtitle: Text(
                          '${_summary(slot.area)}\n保存: ${_formatDate(slot.savedAtUtc)}',
                        ),
                        isThreeLine: true,
                        trailing: PopupMenuButton<String>(
                          onSelected: (v) async {
                            switch (v) {
                              case 'use':
                                if (context.mounted) {
                                  Navigator.pop(context, slot.id);
                                }
                              case 'export':
                                if (!context.mounted) return;
                                await GeoJsonActions.exportToClipboard(
                                  context,
                                  slot.area,
                                  onCopied: (m) {
                                    if (!context.mounted) return;
                                    ScaffoldMessenger.of(context)
                                        .showSnackBar(SnackBar(content: Text(m)));
                                  },
                                );
                              case 'rename':
                                if (widget.canEdit) await _rename(slot);
                              case 'delete':
                                if (widget.canEdit) await _delete(slot);
                            }
                          },
                          itemBuilder: (ctx) => [
                            const PopupMenuItem(
                              value: 'use',
                              child: Text('このエリアを使う'),
                            ),
                            const PopupMenuItem(
                              value: 'export',
                              child: Text('GeoJSON エクスポート'),
                            ),
                            if (widget.canEdit) ...[
                              const PopupMenuItem(
                                value: 'rename',
                                child: Text('名前を変更'),
                              ),
                              const PopupMenuItem(
                                value: 'delete',
                                child: Text('削除'),
                              ),
                            ],
                          ],
                        ),
                        onTap: () => Navigator.pop(context, slot.id),
                      ),
                    );
                  },
                ),
    );
  }

  String _formatDate(DateTime utc) {
    final local = utc.toLocal();
    return '${local.year}/${local.month}/${local.day} '
        '${local.hour.toString().padLeft(2, '0')}:'
        '${local.minute.toString().padLeft(2, '0')}';
  }
}
