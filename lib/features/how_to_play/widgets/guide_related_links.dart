import 'package:flutter/material.dart';

import '../guide_sections.dart';

/// 章末の関連リンク。
class GuideRelatedLinks extends StatelessWidget {
  const GuideRelatedLinks({
    required this.relatedSectionIds,
    required this.onSectionTap,
    super.key,
  });

  final List<String> relatedSectionIds;
  final ValueChanged<String> onSectionTap;

  @override
  Widget build(BuildContext context) {
    if (relatedSectionIds.isEmpty) return const SizedBox.shrink();
    final theme = Theme.of(context);
    final hasTarget = relatedSectionIds.any((id) => guideSectionById(id) != null);
    if (!hasTarget) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: 4, bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('関連', style: theme.textTheme.labelMedium),
          const SizedBox(height: 4),
          Wrap(
            spacing: 4,
            runSpacing: 0,
            children: [
              for (var i = 0; i < relatedSectionIds.length; i++)
                TextButton(
                  onPressed: () => onSectionTap(relatedSectionIds[i]),
                  style: TextButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                  ),
                  child: Text(guideSectionById(relatedSectionIds[i])?.title ?? ''),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
