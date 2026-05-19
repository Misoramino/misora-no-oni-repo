import 'package:flutter/material.dart';

import '../map/game_map_layer_toggles.dart';
import 'cooldown_chip.dart';
import 'map_layer_toggle_strip.dart';

/// 試合中の上部 HUD（タイマー・エリア・情報）。
class GameInfoPanel extends StatelessWidget {
  const GameInfoPanel({
    required this.expanded,
    required this.onToggleExpanded,
    required this.revealAlert,
    required this.onDismissRevealAlert,
    required this.onOpenRevealLog,
    required this.intelLine,
    required this.showIntelLine,
    required this.onDismissIntel,
    required this.timerText,
    required this.gameStateText,
    required this.statusText,
    required this.areaText,
    required this.areaColor,
    required this.revealCount,
    required this.editing,
    required this.safeZoneCharges,
    required this.conditionText,
    required this.werewolfBuffSeconds,
    required this.werewolfCooldownSeconds,
    required this.fakeCooldownSeconds,
    this.mapLayerToggles,
    this.onMapLayersChanged,
    this.onRecenterMap,
    super.key,
  });

  final bool expanded;
  final VoidCallback onToggleExpanded;
  final String? revealAlert;
  final VoidCallback onDismissRevealAlert;
  final VoidCallback onOpenRevealLog;
  final String intelLine;
  final bool showIntelLine;
  final VoidCallback onDismissIntel;
  final String timerText;
  final String gameStateText;
  final String statusText;
  final String areaText;
  final Color areaColor;
  final int revealCount;
  final bool editing;
  final int safeZoneCharges;
  final String conditionText;
  final int? werewolfBuffSeconds;
  final int werewolfCooldownSeconds;
  final int fakeCooldownSeconds;
  final GameMapLayerToggles? mapLayerToggles;
  final ValueChanged<GameMapLayerToggles>? onMapLayersChanged;
  final VoidCallback? onRecenterMap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    if (revealAlert != null && revealAlert!.isNotEmpty) {
      return Material(
        color: theme.colorScheme.errorContainer.withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(10),
        elevation: 2,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          child: Row(
            children: [
              Icon(Icons.campaign_outlined, color: theme.colorScheme.error),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  revealAlert!,
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              TextButton(
                onPressed: onOpenRevealLog,
                child: const Text('ログ'),
              ),
              IconButton(
                visualDensity: VisualDensity.compact,
                onPressed: onDismissRevealAlert,
                icon: const Icon(Icons.close, size: 18),
              ),
            ],
          ),
        ),
      );
    }

    if (!expanded) {
      return Material(
        color: Colors.white.withValues(alpha: 0.78),
        borderRadius: BorderRadius.circular(10),
        elevation: 1,
        child: InkWell(
          onTap: onToggleExpanded,
          borderRadius: BorderRadius.circular(10),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            child: Row(
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: areaColor,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    timerText,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    areaText,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall,
                  ),
                ),
                if (werewolfBuffSeconds != null && werewolfBuffSeconds! > 0)
                  CooldownChip(label: '鬼化', seconds: werewolfBuffSeconds!),
                if (fakeCooldownSeconds > 0)
                  CooldownChip(label: 'CD', seconds: fakeCooldownSeconds),
                IconButton(
                  visualDensity: VisualDensity.compact,
                  padding: EdgeInsets.zero,
                  constraints:
                      const BoxConstraints(minWidth: 28, minHeight: 28),
                  onPressed: onToggleExpanded,
                  icon: const Icon(Icons.expand_more, size: 20),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.84),
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [
          BoxShadow(color: Colors.black26, blurRadius: 4, offset: Offset(0, 1)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Chip(
                label: Text(editing ? '編集中' : gameStateText),
                visualDensity: VisualDensity.compact,
                padding: EdgeInsets.zero,
              ),
              const SizedBox(width: 6),
              Text(
                timerText,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              Text(
                '暴露$revealCount・ステルス$safeZoneCharges',
                style: theme.textTheme.labelSmall,
              ),
              IconButton(
                visualDensity: VisualDensity.compact,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                onPressed: onToggleExpanded,
                icon: const Icon(Icons.expand_less, size: 20),
              ),
            ],
          ),
          if (werewolfBuffSeconds != null && werewolfBuffSeconds! > 0 ||
              werewolfCooldownSeconds > 0 ||
              fakeCooldownSeconds > 0) ...[
            const SizedBox(height: 4),
            Wrap(
              spacing: 6,
              runSpacing: 4,
              children: [
                if (werewolfBuffSeconds != null && werewolfBuffSeconds! > 0)
                  CooldownChip(label: '鬼化残', seconds: werewolfBuffSeconds!),
                if (werewolfCooldownSeconds > 0)
                  CooldownChip(
                    label: '鬼化CD',
                    seconds: werewolfCooldownSeconds,
                  ),
                if (fakeCooldownSeconds > 0)
                  CooldownChip(label: '偽位置CD', seconds: fakeCooldownSeconds),
              ],
            ),
          ],
          if (showIntelLine) ...[
            const SizedBox(height: 4),
            Row(
              children: [
                Expanded(
                  child: Text(
                    intelLine,
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                IconButton(
                  visualDensity: VisualDensity.compact,
                  padding: EdgeInsets.zero,
                  constraints:
                      const BoxConstraints(minWidth: 28, minHeight: 28),
                  onPressed: onDismissIntel,
                  icon: const Icon(Icons.close, size: 16),
                ),
              ],
            ),
          ],
          Text(
            conditionText,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.bodySmall,
          ),
          const SizedBox(height: 4),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
            decoration: BoxDecoration(
              color: areaColor,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              areaText,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
            ),
          ),
          if (statusText.isNotEmpty) ...[
            const SizedBox(height: 2),
            Text(
              statusText,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.labelSmall,
            ),
          ],
          if (mapLayerToggles != null && onMapLayersChanged != null) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                Text('地図の表示', style: theme.textTheme.labelSmall),
                const Spacer(),
                if (onRecenterMap != null)
                  TextButton.icon(
                    onPressed: onRecenterMap,
                    icon: const Icon(Icons.center_focus_strong, size: 16),
                    label: const Text('現在地へ', style: TextStyle(fontSize: 11)),
                    style: TextButton.styleFrom(
                      visualDensity: VisualDensity.compact,
                      padding: const EdgeInsets.symmetric(horizontal: 6),
                    ),
                  ),
              ],
            ),
            MapLayerToggleStrip(
              dense: true,
              showTitle: false,
              toggles: mapLayerToggles!,
              onChanged: onMapLayersChanged!,
            ),
          ],
        ],
      ),
    );
  }
}
