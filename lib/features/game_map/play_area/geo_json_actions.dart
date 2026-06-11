import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../game/play_area.dart';

/// GeoJSON のインポート・エクスポート UI。
abstract final class GeoJsonActions {
  static Future<PlayArea?> showImportDialog(BuildContext context) async {
    final controller = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('ファイルから読み込み'),
        content: SingleChildScrollView(
          child: TextField(
            controller: controller,
            maxLines: 12,
            decoration: const InputDecoration(
              hintText: '地図データ（Polygon など）を貼り付け',
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('キャンセル'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('読み込む'),
          ),
        ],
      ),
    );
    try {
      if (ok != true) return null;
      return PlayArea.fromGeoJsonString(controller.text.trim());
    } finally {
      controller.dispose();
    }
  }

  static Future<void> exportToClipboard(
    BuildContext context,
    PlayArea area, {
    void Function(String message)? onCopied,
  }) async {
    final raw = area.toGeoJsonFeatureString();
    await Clipboard.setData(ClipboardData(text: raw));
    onCopied?.call('地図データをクリップボードにコピーしました');
    if (!context.mounted) return;
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(16),
        child: SelectableText(raw, style: const TextStyle(fontSize: 12)),
      ),
    );
  }
}
