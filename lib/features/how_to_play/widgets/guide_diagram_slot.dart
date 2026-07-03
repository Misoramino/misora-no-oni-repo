import 'package:flutter/material.dart';

import '../../../presentation/world/world_presentation_context.dart';
import '../../../presentation/world/world_ui_helpers.dart';
import '../guide_text.dart';
import '../../../presentation/world/world_legibility.dart';
import '../guide_models.dart';
import 'guide_diagram_views.dart';

/// 図解の差し込み口。[GuideDiagramType] に応じた簡易図解を表示する。
class GuideDiagramSlot extends StatelessWidget {
  const GuideDiagramSlot({
    required this.data,
    super.key,
  });

  final GuideDiagramData data;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final profile = context.worldProfile;
    final panelBg = context.worldPanelBg;
    return WorldPanelThemed(
      profile: profile,
      child: Card(
        margin: const EdgeInsets.only(bottom: 8),
        color: panelBg,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Icon(Icons.image_outlined,
                      size: 18, color: context.worldAccentReadable),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      GuideText.forDisplay(data.title),
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: context.worldBody,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              buildGuideDiagram(context, data.type),
              if (data.caption != null && data.caption!.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  GuideText.forDisplay(data.caption!),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: context.worldMuted,
                    height: 1.4,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
