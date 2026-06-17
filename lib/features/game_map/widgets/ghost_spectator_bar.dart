import 'package:flutter/material.dart';

import '../../../game/elimination_aftermath_rule.dart';
import '../../../presentation/world/world_presentation_catalog.dart';
import '../../../theme/world_profile.dart';

class GhostSpectatorBar extends StatelessWidget {
  const GhostSpectatorBar({
    required this.rule,
    required this.worldProfile,
    required this.onOpenResult,
    super.key,
  });

  final EliminationAftermathRule rule;
  final WorldProfile worldProfile;
  final VoidCallback onOpenResult;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final pack = WorldPresentationCatalog.of(worldProfile);
    return Material(
      elevation: 4,
      borderRadius: BorderRadius.circular(pack.hudCornerRadius + 2),
      color: pack.panelSurface,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(
          children: [
            Icon(Icons.visibility_outlined, color: pack.accent),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '幽霊・観戦モード',
                    style: theme.textTheme.titleSmall?.copyWith(
                      color: pack.textOnPanel,
                    ),
                  ),
                  Text(
                    rule.infoPanelLine,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: pack.mutedOnPanel,
                    ),
                  ),
                ],
              ),
            ),
            TextButton(
              onPressed: onOpenResult,
              child: Text(
                'リザルト',
                style: TextStyle(color: pack.accent),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
