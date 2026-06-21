import 'package:flutter/material.dart';

import '../../../presentation/world/world_legibility.dart';

/// 準備画面などで SnackBar の代わりに表示する短い状態バッジ。
class GameInlineStatusBadge extends StatelessWidget {
  const GameInlineStatusBadge({
    required this.message,
    super.key,
  });

  final String message;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final leg = context.mapPanelLegibility();
    return Material(
      elevation: 2,
      borderRadius: BorderRadius.circular(20),
      color: leg.highlightBg,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.info_outline,
              size: 18,
              color: leg.accent,
            ),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                message,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: leg.body,
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
