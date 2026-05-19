import 'package:flutter/material.dart';

import '../../../game/elimination_aftermath_rule.dart';

class GhostSpectatorBar extends StatelessWidget {
  const GhostSpectatorBar({
    required this.rule,
    required this.onOpenResult,
    super.key,
  });

  final EliminationAftermathRule rule;
  final VoidCallback onOpenResult;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      elevation: 4,
      borderRadius: BorderRadius.circular(12),
      color: theme.colorScheme.primaryContainer.withValues(alpha: 0.92),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(
          children: [
            Icon(Icons.visibility_outlined, color: theme.colorScheme.primary),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('幽霊・観戦モード', style: theme.textTheme.titleSmall),
                  Text(
                    rule.infoPanelLine,
                    style: theme.textTheme.bodySmall,
                  ),
                ],
              ),
            ),
            TextButton(onPressed: onOpenResult, child: const Text('リザルト')),
          ],
        ),
      ),
    );
  }
}
