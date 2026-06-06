import 'package:flutter/material.dart';

import '../../../theme/map_hud_contrast.dart';
import '../../../theme/world_profile.dart';

/// 直近の重要イベントを1行表示する HUD 帯。
class MatchEventFeedBanner extends StatelessWidget {
  const MatchEventFeedBanner({
    required this.message,
    required this.worldProfile,
    super.key,
  });

  final String message;
  final WorldProfile worldProfile;

  @override
  Widget build(BuildContext context) {
    if (message.isEmpty) return const SizedBox.shrink();
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Material(
      elevation: 1,
      borderRadius: BorderRadius.circular(8),
      color: MapHudContrast.infoPanelSurface(scheme, worldProfile)
          .withValues(alpha: 0.92),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        child: Row(
          children: [
            Icon(Icons.history, size: 16, color: scheme.primary),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                message,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.labelMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
