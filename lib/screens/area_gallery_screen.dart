import 'package:flutter/material.dart';

import '../presentation/world/world_legibility.dart';
import '../presentation/world/world_presentation_context.dart';
import '../presentation/world/world_ui_helpers.dart';
import '../game/play_area.dart';
import '../services/play_area_slot_store.dart';
import '../features/game_map/prep/area_gallery_pick.dart';
import '../features/game_map/play_area/geo_json_actions.dart';
import '../widgets/play_area_shape_preview.dart';

/// 保存済みプレイエリアの一覧（写真フォルダ風）。
class AreaGalleryScreen extends StatefulWidget {
  const AreaGalleryScreen({
    required this.store,
    this.selectedId,
    this.canEdit = true,
    this.previewOnly = false,
    super.key,
  });

  final PlayAreaSlotStore store;
  final String? selectedId;
  final bool canEdit;
  /// 試合中は形の確認のみ（適用不可）。
  final bool previewOnly;

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

  String _summary(PlayArea area) => area.shapeSummary();

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

  Future<void> _showDetail(SavedPlayArea slot) async {
    await showDialog<void>(
      context: context,
      builder: (dCtx) => AlertDialog(
        title: Text(slot.name),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              PlayAreaShapePreview(
                area: slot.area,
                height: 160,
                preserveAspect: true,
              ),
              const SizedBox(height: 10),
              Text(slot.area.coarseLocationLabel()),
              const SizedBox(height: 4),
              Text(_summary(slot.area)),
              const SizedBox(height: 4),
              Text(
                '保存: ${_formatDate(slot.savedAtUtc)}',
                style: Theme.of(dCtx).textTheme.bodySmall,
              ),
            ],
          ),
        ),
        actions: [
          FilledButton(
            onPressed: () => Navigator.pop(dCtx),
            child: const Text('閉じる'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.previewOnly ? 'プレイエリア確認' : '保存エリア一覧'),
        actions: [
          if (widget.canEdit)
            IconButton(
              tooltip: 'ファイルから読み込み',
              onPressed: _importGeoJson,
              icon: const Icon(Icons.upload_file_outlined),
            ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (!widget.previewOnly)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                    child: Text(
                      'この端末に保存したエリアです。試合への反映はホストが行います。',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: context.worldMutedOnScaffold,
                      ),
                    ),
                  ),
                Expanded(
                  child: _areas.isEmpty
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
                          '準備画面のマップ → プレビューから編集・保存するか、'
                          '右上から地図データを読み込めます。',
                          textAlign: TextAlign.center,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: context.worldMutedOnScaffold,
                          ),
                        ),
                        if (widget.canEdit) ...[
                          const SizedBox(height: 16),
                          FilledButton.tonalIcon(
                            onPressed: _importGeoJson,
                            icon: const Icon(Icons.upload_file_outlined),
                            label: const Text('ファイルから読み込み'),
                          ),
                        ],
                      ],
                    ),
                  ),
                )
              : GridView.builder(
                  padding: const EdgeInsets.all(12),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: 10,
                    crossAxisSpacing: 10,
                    childAspectRatio: 0.82,
                  ),
                  itemCount: _areas.length,
                  itemBuilder: (context, index) {
                    final slot = _areas[index];
                    final selected = slot.id == widget.selectedId;
                    final pack = context.worldPresentation;
                    return Card(
                      elevation: selected ? 2 : 0,
                      color: selected
                          ? Color.alphaBlend(
                              pack.accent.withValues(alpha: 0.14),
                              pack.panelSurface,
                            )
                          : null,
                      clipBehavior: Clip.antiAlias,
                      child: InkWell(
                        onTap: widget.previewOnly
                            ? () => _showDetail(slot)
                            : () => Navigator.pop(
                                  context,
                                  AreaGalleryPreviewPick(slot.id),
                                ),
                        onLongPress: () => _showDetail(slot),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Expanded(
                              child: PlayAreaShapePreview(
                                area: slot.area,
                                height: double.infinity,
                                preserveAspect: true,
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.fromLTRB(8, 6, 4, 4),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          slot.name,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: theme.textTheme.titleSmall
                                              ?.copyWith(
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        Text(
                                          slot.area.coarseLocationLabel(),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: theme.textTheme.labelSmall
                                              ?.copyWith(
                                            color: context.worldMutedOnScaffold,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Theme(
                                    data: worldPopupMenuTheme(context),
                                    child: PopupMenuButton<String>(
                                    padding: EdgeInsets.zero,
                                    onSelected: (v) async {
                                      switch (v) {
                                        case 'detail':
                                          await _showDetail(slot);
                                        case 'export':
                                          if (!context.mounted) return;
                                          await GeoJsonActions.exportToClipboard(
                                            context,
                                            slot.area,
                                            onCopied: (m) {
                                              if (!context.mounted) return;
                                              ScaffoldMessenger.of(context)
                                                  .showSnackBar(
                                                SnackBar(content: Text(m)),
                                              );
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
                                        value: 'detail',
                                        child: Text('詳細を見る'),
                                      ),
                                      const PopupMenuItem(
                                        value: 'export',
                                        child: Text('ファイルへ書き出し'),
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
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
                ),
              ],
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
