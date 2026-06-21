import 'package:flutter/material.dart';

import '../../../presentation/world/world_legibility.dart';
import '../../../theme/map_hud_contrast.dart';
import '../../../services/play_area_slot_store.dart';
import '../../../theme/world_profile.dart';

/// プレビューモードの地図下パネル。
class PrepMapPreviewPanel extends StatelessWidget {
  const PrepMapPreviewPanel({
    required this.savedAreas,
    required this.focusSlotId,
    required this.activePlayAreaLabel,
    required this.isHost,
    required this.onFocusSlot,
    required this.onApplyFocused,
    required this.worldProfile,
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
  final WorldProfile worldProfile;

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
    final leg = context.mapPanelLegibility(worldProfile);
    final focused = _focused;

    return Material(
      color: leg.panelBg,
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
                    color: leg.title,
                  ),
                ),
                const Spacer(),
                IconButton(
                  tooltip: 'パネルを閉じる',
                  onPressed: onDismiss,
                  icon: Icon(Icons.expand_more, color: leg.muted),
                ),
              ],
            ),
            Text(
              focused == null
                  ? '適用中: $activePlayAreaLabel'
                  : '${focused.name} — ${focused.area.coarseLocationLabel()}',
              style: theme.textTheme.bodySmall?.copyWith(
                color: leg.muted,
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
                    leg: leg,
                    onTap: () => onFocusSlot(null),
                  ),
                  for (final slot in savedAreas) ...[
                    const SizedBox(width: 6),
                    _SlotChip(
                      label: slot.name,
                      selected: focusSlotId == slot.id,
                      leg: leg,
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
    required this.leg,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final MapHudMapPanelLegibility leg;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final fg = selected ? leg.accent : leg.muted;
    return Material(
      color: selected ? leg.highlightBg : leg.tileBg,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
              color: fg,
            ),
          ),
        ),
      ),
    );
  }
}
