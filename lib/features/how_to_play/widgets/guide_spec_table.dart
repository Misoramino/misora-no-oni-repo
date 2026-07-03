import 'package:flutter/material.dart';

import '../../../presentation/world/world_legibility.dart';
import '../guide_models.dart';

/// 詳細ルール章向けのラベル／値テーブル。
class GuideSpecTable extends StatelessWidget {
  const GuideSpecTable({
    required this.rows,
    this.groups = const [],
    super.key,
  });

  final List<GuideSpecRow> rows;
  final List<GuideSpecGroup> groups;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final panelAccent = context.worldAccentOn(context.worldPanelBg);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (rows.isNotEmpty) _TableBlock(rows: rows),
        for (final g in groups) ...[
          if (rows.isNotEmpty || g != groups.first) const SizedBox(height: 10),
          Text(
            g.title,
            style: theme.textTheme.labelLarge?.copyWith(
              color: panelAccent,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          _TableBlock(rows: g.rows),
        ],
      ],
    );
  }
}

class _TableBlock extends StatelessWidget {
  const _TableBlock({required this.rows});

  final List<GuideSpecRow> rows;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: context.worldPanelBg.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: scheme.outlineVariant.withValues(alpha: 0.7)),
      ),
      child: Column(
        children: [
          for (var i = 0; i < rows.length; i++) ...[
            if (i > 0)
              Divider(
                height: 1,
                thickness: 1,
                color: scheme.outlineVariant.withValues(alpha: 0.5),
              ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 132,
                    child: Text(
                      rows[i].label,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: context.worldMuted,
                        fontWeight: FontWeight.w600,
                        height: 1.35,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      rows[i].value,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        height: 1.4,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
