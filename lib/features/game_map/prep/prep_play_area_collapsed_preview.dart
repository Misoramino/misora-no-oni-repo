import 'package:flutter/material.dart';

import '../../../game/play_area.dart';
import '../../../presentation/world/world_legibility.dart';
import '../../../theme/map_hud_contrast.dart';
import '../../../widgets/play_area_shape_preview.dart';

/// プレイエリアタブ折りたたみ時のコンパクトプレビュー。
class PrepPlayAreaCollapsedPreview extends StatelessWidget {
  const PrepPlayAreaCollapsedPreview({
    required this.area,
    required this.summary,
    this.prepLegibility,
    super.key,
  });

  final PlayArea area;
  final String summary;
  final MapHudPrepLegibility? prepLegibility;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final leg = prepLegibility;
    final location = area.coarseLocationLabel();

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        PlayAreaShapePreview(
          area: area,
          width: 64,
          height: 64,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                location,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.labelMedium?.copyWith(
                  color: leg?.tileValue ??
                      context.worldTextOn(
                        leg?.tileSurface ?? theme.colorScheme.surface,
                      ),
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                summary,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: leg?.muted ?? context.worldMutedOnScaffold,
                  height: 1.25,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
