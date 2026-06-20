import 'package:flutter/material.dart';

import '../../../presentation/world/world_legibility.dart';
import '../guide_text.dart';
import '../guide_models.dart';
import 'guide_detail_expansion.dart';
import 'guide_diagram_slot.dart';
import 'guide_spec_table.dart';

/// 遊び方の1テーマ1カード。
class GuideCard extends StatelessWidget {
  const GuideCard({
    required this.data,
    this.onOpenSpecCard,
    super.key,
  });

  final GuideCardData data;
  final ValueChanged<String>? onOpenSpecCard;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(data.icon, size: 20, color: context.worldAccentReadable),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        data.title,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        GuideText.forDisplay(data.oneLine),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: context.worldAccentReadable,
                          fontWeight: FontWeight.w600,
                          height: 1.35,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (data.diagram != null) ...[
              const SizedBox(height: 10),
              GuideDiagramSlot(data: data.diagram!),
            ],
            if (data.specRows.isNotEmpty || data.specGroups.isNotEmpty) ...[
              const SizedBox(height: 8),
              GuideSpecTable(rows: data.specRows, groups: data.specGroups),
            ] else ...[
              const SizedBox(height: 8),
              Text(
                GuideText.forDisplay(data.body),
                style: theme.textTheme.bodyMedium?.copyWith(height: 1.55),
              ),
            ],
            if (data.bullets.isNotEmpty) ...[
              const SizedBox(height: 8),
              for (final b in data.bullets)
                Padding(
                  padding: const EdgeInsets.only(left: 4, bottom: 4),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('・', style: theme.textTheme.bodyMedium),
                      Expanded(
                        child: Text(
                          GuideText.forDisplay(b),
                          style: theme.textTheme.bodyMedium?.copyWith(
                            height: 1.45,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
            if (data.footnote != null) ...[
              const SizedBox(height: 6),
              Text(
                GuideText.forDisplay(data.footnote!),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: context.worldMuted,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
            if (data.details.isNotEmpty) ...[
              const SizedBox(height: 6),
              GuideDetailExpansion(
                details: data.details,
                onOpenSpecCard: onOpenSpecCard,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
