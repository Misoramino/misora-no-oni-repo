import 'package:flutter/material.dart';

import '../guide_models.dart';
import 'guide_detail_expansion.dart';
import 'guide_diagram_slot.dart';

/// 作戦マニュアルの1テーマ1カード。
class GuideCard extends StatelessWidget {
  const GuideCard({
    required this.data,
    super.key,
  });

  final GuideCardData data;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
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
                Icon(data.icon, size: 20, color: scheme.primary),
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
                        data.oneLine,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: scheme.primary,
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
            const SizedBox(height: 8),
            Text(
              data.body,
              style: theme.textTheme.bodyMedium?.copyWith(height: 1.55),
            ),
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
                          b,
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
                data.footnote!,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: scheme.onSurfaceVariant,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
            if (data.details.isNotEmpty) ...[
              const SizedBox(height: 6),
              GuideDetailExpansion(details: data.details),
            ],
          ],
        ),
      ),
    );
  }
}
