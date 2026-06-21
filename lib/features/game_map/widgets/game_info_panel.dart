import 'package:flutter/material.dart';

import '../../../presentation/world/widgets/world_chip.dart';
import '../../../presentation/world/world_studio_identity_catalog.dart';
import '../../../theme/map_hud_contrast.dart';
import '../../../theme/world_profile.dart';
import '../../../theme/world_profile_tokens.dart';
import 'cooldown_chip.dart';
import 'hud_marquee_text.dart';

/// 試合中の上部 HUD（タイマー・エリア・情報）。
class GameInfoPanel extends StatelessWidget {
  const GameInfoPanel({
    required this.expanded,
    required this.onToggleExpanded,
    required this.revealAlert,
    required this.onDismissRevealAlert,
    required this.onOpenRevealLog,
    required this.compactLineText,
    required this.intelLine,
    required this.showIntelLine,
    required this.onOpenIntelLog,
    required this.onOpenDisplaySettings,
    this.displaySettingsKey,
    required this.timerText,
    required this.gameStateText,
    required this.statusText,
    required this.showStatusLine,
    required this.areaText,
    required this.areaColor,
    required this.revealCount,
    required this.editing,
    required this.safeZoneCharges,
    required this.conditionText,
    required this.showConditionLine,
    this.werewolfOniActive = false,
    this.werewolfHudSummary,
    required this.werewolfCooldownSeconds,
    this.werewolfForcedSeconds = 0,
    required this.fakeCooldownSeconds,
    required this.fakeIntelRevealCooldownSeconds,
    required this.mapWorldProfile,
    this.phaseLabel,
    this.eventFeedLine,
    this.connectionChipLabel,
    super.key,
  });

  final bool expanded;
  final VoidCallback onToggleExpanded;
  final String? revealAlert;
  final VoidCallback onDismissRevealAlert;
  final VoidCallback onOpenRevealLog;
  final String compactLineText;
  final String intelLine;
  final bool showIntelLine;
  final VoidCallback onOpenIntelLog;
  final VoidCallback onOpenDisplaySettings;
  final GlobalKey? displaySettingsKey;
  final String timerText;
  final String gameStateText;
  final String statusText;
  final bool showStatusLine;
  final String areaText;
  final Color areaColor;
  final int revealCount;
  final bool editing;
  final int safeZoneCharges;
  final String conditionText;
  final bool showConditionLine;
  final bool werewolfOniActive;
  final String? werewolfHudSummary;
  final int werewolfCooldownSeconds;
  final int werewolfForcedSeconds;
  final int fakeCooldownSeconds;
  final int fakeIntelRevealCooldownSeconds;
  final WorldProfile mapWorldProfile;
  final String? phaseLabel;
  final String? eventFeedLine;
  final String? connectionChipLabel;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final hudInset = WorldStudioIdentityCatalog.of(mapWorldProfile)
        .layout
        .hudEdgeInset;
    if (revealAlert != null && revealAlert!.isNotEmpty) {
      return Padding(
        padding: EdgeInsets.all(hudInset),
        child: Material(
        color: scheme.errorContainer.withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(10),
        elevation: 2,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          child: Row(
            children: [
              Icon(Icons.campaign_outlined, color: scheme.error),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  revealAlert!,
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: scheme.onErrorContainer,
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
      ),
      );
    }

    final tokens = WorldProfileTokenFactory.of(mapWorldProfile);
    final inArea = areaColor == tokens.safeColor;
    final hud = MapHudRunningLegibility.resolve(scheme, mapWorldProfile);

    if (!expanded) {
      final werewolfChips = _werewolfChipRow();
      return Padding(
        padding: EdgeInsets.all(hudInset),
        child: Material(
        color: hud.infoPanelBg,
        borderRadius: BorderRadius.circular(10),
        elevation: 1,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
            children: [
              WorldTimerChip(
                profile: mapWorldProfile,
                text: timerText,
                isAlert: !inArea,
              ),
              const SizedBox(width: 6),
              if (phaseLabel != null && phaseLabel!.isNotEmpty)
                Flexible(
                  child: WorldChip(
                    profile: mapWorldProfile,
                    label: phaseLabel!,
                    dense: true,
                    backgroundColor: hud.chipBg,
                    foregroundColor: hud.chipFg,
                  ),
                ),
              if (phaseLabel != null && phaseLabel!.isNotEmpty)
                const SizedBox(width: 6),
              if (connectionChipLabel != null &&
                  connectionChipLabel!.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: Chip(
                    label: Text(connectionChipLabel!),
                    visualDensity: VisualDensity.compact,
                    padding: EdgeInsets.zero,
                    backgroundColor: hud.warningBg,
                    labelStyle: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: hud.warningFg,
                    ),
                  ),
                ),
              Expanded(
                child: InkWell(
                  onTap: onToggleExpanded,
                  borderRadius: BorderRadius.circular(6),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: HudMarqueeText(
                      text: compactLineText,
                      style: theme.textTheme.bodySmall?.copyWith(color: hud.body),
                    ),
                  ),
                ),
              ),
              IconButton(
                key: displaySettingsKey,
                tooltip: '表示の切替（手がかり・地図レイヤー等）',
                visualDensity: VisualDensity.compact,
                padding: EdgeInsets.zero,
                constraints:
                    const BoxConstraints(minWidth: 32, minHeight: 32),
                onPressed: onOpenDisplaySettings,
                icon: Icon(Icons.tune, size: 20, color: hud.icon),
              ),
              IconButton(
                tooltip: '位置情報・鬼の手がかりログ',
                visualDensity: VisualDensity.compact,
                padding: EdgeInsets.zero,
                constraints:
                    const BoxConstraints(minWidth: 32, minHeight: 32),
                onPressed: onOpenIntelLog,
                icon: Icon(Icons.radar, size: 20, color: hud.icon),
              ),
              IconButton(
                tooltip: 'HUDを展開',
                visualDensity: VisualDensity.compact,
                padding: EdgeInsets.zero,
                constraints:
                    const BoxConstraints(minWidth: 28, minHeight: 28),
                onPressed: onToggleExpanded,
                icon: Icon(Icons.expand_more, size: 20, color: hud.muted),
              ),
            ],
              ),
              if (werewolfChips != null) ...[
                const SizedBox(height: 4),
                werewolfChips,
              ],
            ],
          ),
        ),
      ),
      );
    }

    return Padding(
      padding: EdgeInsets.all(hudInset),
      child: Container(
      padding: const EdgeInsets.fromLTRB(8, 6, 6, 6),
      decoration: BoxDecoration(
        color: hud.infoPanelBg,
        borderRadius: BorderRadius.circular(10),
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
              if (phaseLabel != null && phaseLabel!.isNotEmpty) ...[
                Flexible(
                  child: WorldChip(
                    profile: mapWorldProfile,
                    label: phaseLabel!,
                    dense: true,
                    backgroundColor: hud.chipBg,
                    foregroundColor: hud.chipFg,
                  ),
                ),
                const SizedBox(width: 6),
              ],
              if (connectionChipLabel != null &&
                  connectionChipLabel!.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: Chip(
                    label: Text(connectionChipLabel!),
                    visualDensity: VisualDensity.compact,
                    padding: EdgeInsets.zero,
                    backgroundColor: hud.warningBg,
                    labelStyle: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: hud.warningFg,
                    ),
                  ),
                ),
              Text(
                timerText,
                style: theme.textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: hud.title,
                ),
              ),
              const Spacer(),
              IconButton(
                key: displaySettingsKey,
                tooltip: '表示の切替',
                visualDensity: VisualDensity.compact,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                onPressed: onOpenDisplaySettings,
                icon: Icon(Icons.tune, size: 20, color: hud.icon),
              ),
              IconButton(
                tooltip: 'HUDを折りたたむ',
                visualDensity: VisualDensity.compact,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                onPressed: onToggleExpanded,
                icon: Icon(Icons.expand_less, size: 20, color: hud.muted),
              ),
            ],
          ),
          Row(
            children: [
              Text(
                '暴露$revealCount · ステルス$safeZoneCharges',
                style: theme.textTheme.labelSmall?.copyWith(color: hud.muted),
              ),
              const Spacer(),
              TextButton(
                onPressed: onOpenIntelLog,
                style: TextButton.styleFrom(
                  visualDensity: VisualDensity.compact,
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  foregroundColor: hud.accent,
                ),
                child: const Text('ログ', style: TextStyle(fontSize: 11)),
              ),
              if (editing)
                WorldChip(
                  profile: mapWorldProfile,
                  label: '編集中',
                  dense: true,
                  backgroundColor: hud.chipBg,
                  foregroundColor: hud.chipFg,
                ),
            ],
          ),
          if (werewolfHudSummary != null ||
              werewolfOniActive ||
              werewolfCooldownSeconds > 0 ||
              werewolfForcedSeconds > 0 ||
              fakeCooldownSeconds > 0 ||
              fakeIntelRevealCooldownSeconds > 0) ...[
            const SizedBox(height: 4),
            Wrap(
              spacing: 6,
              runSpacing: 4,
              children: [
                if (_showWerewolfChips) ..._werewolfChipChildren(),
                if (fakeCooldownSeconds > 0)
                  CooldownChip(
                    label: '偽位置CD',
                    seconds: fakeCooldownSeconds,
                    worldProfile: mapWorldProfile,
                  ),
                if (fakeIntelRevealCooldownSeconds > 0)
                  CooldownChip(
                    label: '偽情報CD',
                    seconds: fakeIntelRevealCooldownSeconds,
                    worldProfile: mapWorldProfile,
                  ),
              ],
            ),
          ],
          if (eventFeedLine != null && eventFeedLine!.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              eventFeedLine!,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.labelSmall?.copyWith(
                fontWeight: FontWeight.w600,
                color: hud.accent,
              ),
            ),
          ],
          if (showIntelLine) ...[
            const SizedBox(height: 4),
            Text(
              intelLine,
              style: theme.textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w600,
                color: hud.body,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
          if (showConditionLine) ...[
            Text(
              conditionText,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodySmall?.copyWith(color: hud.muted),
            ),
          ],
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
          if (showStatusLine && statusText.isNotEmpty) ...[
            const SizedBox(height: 2),
            Text(
              statusText,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.labelSmall?.copyWith(color: hud.muted),
            ),
          ],
        ],
      ),
    ),
    );
  }

  bool get _showWerewolfChips =>
      werewolfHudSummary != null ||
      werewolfOniActive ||
      werewolfCooldownSeconds > 0 ||
      werewolfForcedSeconds > 0;

  List<Widget> _werewolfChipChildren() => [
        if (werewolfHudSummary != null)
          CooldownChip(
            label: werewolfHudSummary!,
            seconds: 0,
            worldProfile: mapWorldProfile,
          ),
        if (werewolfOniActive && werewolfHudSummary == null)
          CooldownChip(
            label: '鬼化中',
            seconds: 0,
            worldProfile: mapWorldProfile,
          ),
        if (werewolfForcedSeconds > 0)
          CooldownChip(
            label: '強制まで',
            seconds: werewolfForcedSeconds,
            worldProfile: mapWorldProfile,
          ),
        if (werewolfCooldownSeconds > 0)
          CooldownChip(
            label: '切替CD',
            seconds: werewolfCooldownSeconds,
            worldProfile: mapWorldProfile,
          ),
      ];

  Widget? _werewolfChipRow() {
    if (!_showWerewolfChips) return null;
    return Wrap(
      spacing: 6,
      runSpacing: 4,
      children: _werewolfChipChildren(),
    );
  }
}
