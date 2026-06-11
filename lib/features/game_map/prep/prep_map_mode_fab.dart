import 'package:flutter/material.dart';

import 'prep_map_mode.dart';

/// 準備中地図のモード切替 FAB。
class PrepMapModeFab extends StatelessWidget {
  const PrepMapModeFab({
    required this.mode,
    required this.onModeSelected,
    super.key,
  });

  final PrepMapMode mode;
  final ValueChanged<PrepMapMode> onModeSelected;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Material(
      elevation: 4,
      borderRadius: BorderRadius.circular(16),
      color: scheme.surfaceContainerHigh.withValues(alpha: 0.96),
      child: Padding(
        padding: const EdgeInsets.all(4),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _chip(
              context,
              PrepMapMode.browse,
              Icons.map_outlined,
              '閲覧',
            ),
            _chip(
              context,
              PrepMapMode.preview,
              Icons.layers_outlined,
              'プレビュー',
            ),
            _chip(
              context,
              PrepMapMode.edit,
              Icons.edit_location_alt_outlined,
              '編集',
            ),
          ],
        ),
      ),
    );
  }

  Widget _chip(
    BuildContext context,
    PrepMapMode target,
    IconData icon,
    String label,
  ) {
    final scheme = Theme.of(context).colorScheme;
    final selected = mode == target;
    return InkWell(
      onTap: () => onModeSelected(target),
      borderRadius: BorderRadius.circular(12),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? scheme.primaryContainer : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 18,
              color: selected ? scheme.onPrimaryContainer : scheme.onSurfaceVariant,
            ),
            const SizedBox(width: 4),
            Text(
              label,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: selected
                        ? scheme.onPrimaryContainer
                        : scheme.onSurfaceVariant,
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}
