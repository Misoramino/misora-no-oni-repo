import 'package:flutter/material.dart';

import '../../../services/play_area_slot_store.dart';

/// プレビューモードの地図下パネル。
class PrepMapPreviewPanel extends StatelessWidget {
  const PrepMapPreviewPanel({
    required this.savedAreas,
    required this.focusSlotId,
    required this.activePlayAreaLabel,
    required this.isHost,
    required this.onFocusSlot,
    required this.onApplyFocused,
    this.onProposeFocused,
    required this.onOpenGallery,
    required this.onRecenterGps,
    required this.onDismiss,
    this.onCreateNew,
    super.key,
  });

  final List<SavedPlayArea> savedAreas;
  final String? focusSlotId;
  final String activePlayAreaLabel;
  final bool isHost;
  final ValueChanged<String?> onFocusSlot;
  final VoidCallback? onApplyFocused;
  final VoidCallback? onProposeFocused;
  final VoidCallback onOpenGallery;
  final VoidCallback onRecenterGps;
  final VoidCallback onDismiss;
  final VoidCallback? onCreateNew;

  SavedPlayArea? get _focused {
    if (focusSlotId == null) return null;
    for (final s in savedAreas) {
      if (s.id == focusSlotId) return s;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final focused = _focused;

    return Material(
      color: scheme.surfaceContainerHigh.withValues(alpha: 0.97),
      borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
      elevation: 8,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 14),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Text(
                  'エリアプレビュー',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const Spacer(),
                IconButton(
                  tooltip: 'パネルを閉じる',
                  onPressed: onDismiss,
                  icon: const Icon(Icons.expand_more),
                ),
              ],
            ),
            Text(
              focused == null
                  ? '適用中: $activePlayAreaLabel'
                  : '${focused.name} — ${focused.area.coarseLocationLabel()}',
              style: theme.textTheme.bodySmall?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              height: 36,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  _SlotChip(
                    label: '適用中',
                    selected: focusSlotId == null,
                    onTap: () => onFocusSlot(null),
                  ),
                  for (final slot in savedAreas) ...[
                    const SizedBox(width: 6),
                    _SlotChip(
                      label: slot.name,
                      selected: focusSlotId == slot.id,
                      onTap: () => onFocusSlot(slot.id),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: onRecenterGps,
                    icon: const Icon(Icons.center_focus_strong, size: 18),
                    label: const Text('現在地へ'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: onOpenGallery,
                    icon: const Icon(Icons.photo_library_outlined, size: 18),
                    label: const Text('ギャラリー'),
                  ),
                ),
              ],
            ),
            if (isHost && onCreateNew != null) ...[
              const SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed: onCreateNew,
                icon: const Icon(Icons.add_location_alt_outlined, size: 20),
                label: const Text('新規エリアを作成'),
              ),
            ],
            if (isHost && focused != null) ...[
              const SizedBox(height: 8),
              FilledButton.icon(
                onPressed: onApplyFocused,
                icon: const Icon(Icons.check_circle_outline, size: 20),
                label: Text('「${focused.name}」を試合に適用'),
              ),
            ],
            if (!isHost && focused != null && onProposeFocused != null) ...[
              const SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed: onProposeFocused,
                icon: const Icon(Icons.send_outlined, size: 20),
                label: Text('「${focused.name}」をホストに提案'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _SlotChip extends StatelessWidget {
  const _SlotChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return FilterChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => onTap(),
      visualDensity: VisualDensity.compact,
      selectedColor: scheme.primaryContainer,
      checkmarkColor: scheme.onPrimaryContainer,
    );
  }
}
