import 'package:flutter/material.dart';

import '../guide_models.dart';

/// 章一覧（タップで該当章を展開）。
class GuideSectionIndex extends StatelessWidget {
  const GuideSectionIndex({
    required this.sections,
    required this.prompt,
    required this.onSectionTap,
    super.key,
  });

  final List<GuideSectionData> sections;
  final String prompt;
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
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: [
            for (final s in sections)
              ActionChip(
                avatar: Icon(s.icon, size: 16),
                label: Text(s.title),
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
