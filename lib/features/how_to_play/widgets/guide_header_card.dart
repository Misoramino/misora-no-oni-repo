import 'package:flutter/material.dart';

import '../../../presentation/world/world_legibility.dart';
import '../../../presentation/world/world_presentation_context.dart';
import '../../../presentation/world/world_ui_helpers.dart';
import '../guide_models.dart';

class GuideHeaderCard extends StatelessWidget {
  const GuideHeaderCard({
    required this.data,
    super.key,
  });

  final GuideHeaderData data;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final profile = context.worldProfile;
    return WorldPanelThemed(
      profile: profile,
      child: Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: context.worldPanelBg,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              data.title,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: context.worldBody,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              data.subtitle,
              style: theme.textTheme.titleSmall?.copyWith(
                color: context.worldAccentReadable,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              data.body,
              style: theme.textTheme.bodyMedium?.copyWith(
                height: 1.55,
                color: context.worldBody,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              data.hint,
              style: theme.textTheme.bodySmall?.copyWith(
                color: context.worldMuted,
                height: 1.45,
              ),
            ),
          ],
        ),
      ),
    ),
    );
  }
}
