import 'package:flutter/material.dart';

import '../../../presentation/world/world_presentation_catalog.dart';
import '../../../presentation/world/world_presentation_pack.dart';
import '../../../theme/map_hud_contrast.dart';
import '../../../theme/world_profile.dart';
import '../prep/prep_map_mode.dart';

/// 準備中地図のモード切替 FAB。
class PrepMapModeFab extends StatelessWidget {
  const PrepMapModeFab({
    required this.mode,
    required this.onModeSelected,
    required this.worldProfile,
    super.key,
  });

  final PrepMapMode mode;
  final ValueChanged<PrepMapMode> onModeSelected;
  final WorldProfile worldProfile;

  @override
  Widget build(BuildContext context) {
    final leg = MapHudMapPanelLegibility.resolve(
      Theme.of(context).colorScheme,
      worldProfile,
    );
    final pack = WorldPresentationCatalog.of(worldProfile);
    return Material(
      elevation: 4,
      borderRadius: BorderRadius.circular(16),
      color: leg.panelBg,
      child: Padding(
        padding: const EdgeInsets.all(4),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _chip(context, PrepMapMode.browse, Icons.map_outlined, '閲覧', leg, pack),
            _chip(context, PrepMapMode.preview, Icons.layers_outlined, 'プレビュー', leg, pack),
            _chip(
              context,
              PrepMapMode.edit,
              Icons.edit_location_alt_outlined,
              '編集',
              leg,
              pack,
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
    MapHudMapPanelLegibility leg,
    WorldPresentationPack pack,
  ) {
    final selected = mode == target;
    final bg = selected ? leg.highlightBg : Colors.transparent;
    final fg = selected ? leg.accent : leg.muted;
    return InkWell(
      onTap: () => onModeSelected(target),
      borderRadius: BorderRadius.circular(12),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(12),
          border: selected
              ? Border.all(color: pack.panelBorder.withValues(alpha: 0.65))
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 18, color: fg),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                color: fg,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
