import 'package:flutter/material.dart';

import '../../../theme/world_profile.dart';
import '../world_presentation_catalog.dart';

/// HUD / 設定用の世界観チップ。
class WorldChip extends StatelessWidget {
  const WorldChip({
    required this.profile,
    required this.label,
    this.icon,
    this.backgroundColor,
    this.foregroundColor,
    this.dense = false,
    super.key,
  });

  final WorldProfile profile;
  final String label;
  final IconData? icon;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final bool dense;

  @override
  Widget build(BuildContext context) {
    final pack = WorldPresentationCatalog.of(profile);
    final bg = backgroundColor ?? pack.panelOnScaffold;
    final fg = foregroundColor ?? pack.textOnPanelOverScaffold;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(pack.chipBorderRadius),
        border: Border.all(color: pack.panelBorder, width: 0.8),
      ),
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: dense ? 6 : 8,
          vertical: dense ? 2 : 4,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon ?? pack.profileIcon,
              size: dense ? 12 : 14,
              color: fg,
            ),
            SizedBox(width: dense ? 4 : 6),
            Text(
              label,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: fg,
                    fontWeight: FontWeight.w600,
                    fontSize: dense ? 10 : null,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

/// タイマー用チップ（エリア状態色を世界観トークンに寄せる）。
class WorldTimerChip extends StatelessWidget {
  const WorldTimerChip({
    required this.profile,
    required this.text,
    required this.isAlert,
    super.key,
  });

  final WorldProfile profile;
  final String text;
  final bool isAlert;

  @override
  Widget build(BuildContext context) {
    final pack = WorldPresentationCatalog.of(profile);
    final bg = isAlert ? pack.dangerColor : pack.successColor;
    final fg = bg.computeLuminance() > 0.55
        ? const Color(0xFF1A1A2E)
        : Colors.white.withValues(alpha: 0.95);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(pack.chipBorderRadius),
        border: Border.all(
          color: pack.accent.withValues(alpha: 0.35),
          width: 0.6,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Text(
          text,
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: fg,
                fontWeight: FontWeight.w700,
                fontFeatures: profile == WorldProfile.sciFi
                    ? const [FontFeature.tabularFigures()]
                    : null,
              ),
        ),
      ),
    );
  }
}
