import 'package:flutter/material.dart';

import '../../../presentation/world/world_legibility.dart';
import '../../../presentation/world/world_presentation_context.dart';
import '../guide_models.dart';

/// 章一覧（タップで該当章を展開）。
class GuideSectionIndex extends StatelessWidget {
  const GuideSectionIndex({
    required this.sections,
    required this.prompt,
    required this.onSectionTap,
    this.footer,
    super.key,
  });

  final List<GuideSectionData> sections;
  final String prompt;
  final String? footer;
  final ValueChanged<String> onSectionTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          prompt,
          style: theme.textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.w600,
            color: context.worldBodyOnScaffold,
          ),
        ),
        if (footer != null) ...[
          const SizedBox(height: 4),
          Text(
            footer!,
            style: theme.textTheme.bodySmall?.copyWith(
              color: context.worldMutedOnScaffold,
            ),
          ),
        ],
        const SizedBox(height: 8),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: [
            for (final s in sections)
              ActionChip(
                avatar: Icon(s.icon, size: 16, color: context.worldBody),
                label: Text(
                  s.title,
                  style: TextStyle(color: context.worldBody),
                ),
                backgroundColor: context.worldPanelBg,
                side: BorderSide(color: context.worldPresentation.panelBorder),
                visualDensity: VisualDensity.compact,
                onPressed: () => onSectionTap(s.id),
              ),
          ],
        ),
        const SizedBox(height: 12),
      ],
    );
  }
}
