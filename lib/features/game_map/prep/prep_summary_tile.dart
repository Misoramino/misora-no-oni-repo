import 'package:flutter/material.dart';

import '../../../theme/map_hud_contrast.dart';

class PrepSummaryTile extends StatelessWidget {
  const PrepSummaryTile({
    required this.icon,
    required this.title,
    required this.value,
    this.subtitle,
    required this.expanded,
    required this.canEdit,
    this.onTap,
    this.preview,
    this.child,
    this.prepLegibility,
    super.key,
  });

  final IconData icon;
  final String title;
  final String value;
  final String? subtitle;
  final bool expanded;
  final bool canEdit;
  final VoidCallback? onTap;
  final Widget? preview;
  final Widget? child;

  /// 準備画面の下地に合わせたコントラスト（未指定なら通常の [Theme]）。
  final MapHudPrepLegibility? prepLegibility;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final pl = prepLegibility;
    final surfaceColor = pl?.tileSurface ?? theme.colorScheme.surface;
    final titleStyle = theme.textTheme.labelMedium?.copyWith(
      color: pl?.tileTitle,
    );
    final valueStyle = theme.textTheme.titleMedium?.copyWith(
      fontWeight: FontWeight.w600,
      color: pl?.tileValue,
    );
    final iconColor = pl?.tileIcon ?? theme.colorScheme.primary;
    final chevronColor =
        pl?.tileMutedIcon ?? theme.colorScheme.onSurfaceVariant;

    return Material(
      color: surfaceColor,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 10, 8, 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Icon(icon, size: 22, color: iconColor),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(title, style: titleStyle),
                        Text(
                          value,
                          style: valueStyle,
                        ),
                        if (subtitle != null && subtitle!.isNotEmpty) ...[
                          const SizedBox(height: 2),
                          Text(
                            subtitle!,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: pl?.muted ?? theme.colorScheme.onSurfaceVariant,
                              height: 1.3,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  if (canEdit)
                    Icon(
                      expanded ? Icons.expand_less : Icons.expand_more,
                      color: chevronColor,
                    ),
                ],
              ),
              if (preview != null && !expanded) ...[
                const SizedBox(height: 8),
                preview!,
              ],
              if (child != null && expanded) ...[
                const SizedBox(height: 8),
                child!,
              ],
            ],
          ),
        ),
      ),
    );
  }
}
