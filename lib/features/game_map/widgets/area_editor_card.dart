import 'package:flutter/material.dart';

class AreaEditorCard extends StatelessWidget {
  const AreaEditorCard({
    required this.editCircleMode,
    required this.onModeChanged,
    required this.circleRadiusMeters,
    required this.onRadiusChanged,
    required this.waitingCenterTap,
    required this.onRequestCenterTap,
    required this.onCenterGps,
    required this.onUndo,
    required this.onClear,
    required this.polygonClosed,
    required this.onClosePolygon,
    required this.onReopenPolygon,
    required this.vertexCount,
    required this.onApply,
    required this.onCancel,
    super.key,
  });

  final bool editCircleMode;
  final ValueChanged<bool> onModeChanged;
  final double circleRadiusMeters;
  final ValueChanged<double> onRadiusChanged;
  final bool waitingCenterTap;
  final VoidCallback onRequestCenterTap;
  final VoidCallback onCenterGps;
  final VoidCallback onUndo;
  final VoidCallback onClear;
  final bool polygonClosed;
  final VoidCallback onClosePolygon;
  final VoidCallback onReopenPolygon;
  final int vertexCount;
  final VoidCallback onApply;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    return Material(
      elevation: 6,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('プレイエリア編集', style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 8),
            SegmentedButton<bool>(
              segments: const [
                ButtonSegment(value: true, label: Text('円')),
                ButtonSegment(value: false, label: Text('多角形')),
              ],
              emptySelectionAllowed: false,
              selected: {editCircleMode},
              onSelectionChanged: (s) {
                if (s.isNotEmpty) onModeChanged(s.first);
              },
            ),
            const SizedBox(height: 12),
            if (editCircleMode) ...[
              Text('半径: ${circleRadiusMeters.toStringAsFixed(0)} m'),
              Slider(
                min: 50,
                max: 2000,
                divisions: 79,
                value: circleRadiusMeters.clamp(50, 2000),
                onChanged: onRadiusChanged,
              ),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  OutlinedButton.icon(
                    onPressed: onCenterGps,
                    icon: const Icon(Icons.my_location),
                    label: const Text('中心=現在地'),
                  ),
                  FilledButton.tonalIcon(
                    onPressed: onRequestCenterTap,
                    icon: const Icon(Icons.touch_app),
                    label: Text(waitingCenterTap ? 'タップ待ち…' : '中心を地図タップ'),
                  ),
                ],
              ),
            ] else ...[
              Text(
                polygonClosed
                    ? '閉じ済み（$vertexCount 頂点）・ 保存で名前を付けられます'
                    : '頂点 $vertexCount ・ 地図タップで追加、「閉じる」で確定',
              ),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  if (!polygonClosed)
                    FilledButton.tonalIcon(
                      onPressed: vertexCount >= 3 ? onClosePolygon : null,
                      icon: const Icon(Icons.polyline),
                      label: const Text('閉じる'),
                    ),
                  if (polygonClosed)
                    OutlinedButton.icon(
                      onPressed: onReopenPolygon,
                      icon: const Icon(Icons.edit_outlined),
                      label: const Text('頂点を再編集'),
                    ),
                  OutlinedButton.icon(
                    onPressed: onUndo,
                    icon: const Icon(Icons.undo),
                    label: const Text('戻す'),
                  ),
                  OutlinedButton.icon(
                    onPressed: onClear,
                    icon: const Icon(Icons.clear_all),
                    label: const Text('クリア'),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: FilledButton(
                    onPressed: onApply,
                    child: const Text('エリアを保存'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton(
                    onPressed: onCancel,
                    child: const Text('キャンセル'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
