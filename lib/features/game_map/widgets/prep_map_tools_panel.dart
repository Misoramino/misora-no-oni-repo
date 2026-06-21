import 'package:flutter/material.dart';

import '../../../game/match_ui_terms.dart';
import '../../../theme/map_hud_contrast.dart';
import '../../../theme/world_profile.dart';

/// 準備フェーズの「地図確認・エリア編集」専用ツール（ゲーム中 HUD とは別ウィジェット）。
class PrepMapToolsPanel extends StatelessWidget {
  const PrepMapToolsPanel({
    required this.isEditing,
    required this.onToggleAreaEdit,
    required this.onRecenterGps,
    required this.onRefreshGps,
    required this.onClearTraces,
    required this.onOpenHelp,
    required this.onDismissPrepSheet,
    required this.worldProfile,
    this.onCreateNewArea,
    this.playAreaSummary,
    super.key,
  });

  final bool isEditing;
  final VoidCallback onToggleAreaEdit;
  final VoidCallback onRecenterGps;
  final VoidCallback onRefreshGps;
  final VoidCallback onClearTraces;
  final VoidCallback onOpenHelp;
  final VoidCallback onDismissPrepSheet;
  final WorldProfile worldProfile;
  final VoidCallback? onCreateNewArea;
  final String? playAreaSummary;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final leg = MapHudMapPanelLegibility.resolve(scheme, worldProfile);
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 14),
      decoration: BoxDecoration(
        color: leg.panelBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: leg.border.withValues(alpha: 0.55)),
        boxShadow: const [
          BoxShadow(color: Colors.black26, blurRadius: 8, offset: Offset(0, 2)),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Text(
                'マップ・プレイエリア',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: leg.title,
                    ),
              ),
              const Spacer(),
              IconButton(
                tooltip: 'パネルを閉じる',
                onPressed: onDismissPrepSheet,
                icon: Icon(Icons.expand_more, color: leg.muted),
              ),
            ],
          ),
          Text(
            '円・多角形の編集とスロットへの保存。',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: leg.muted,
                  height: 1.35,
                ),
          ),
          if (playAreaSummary != null && playAreaSummary!.isNotEmpty) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: leg.highlightBg,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: leg.border.withValues(alpha: 0.45)),
              ),
              child: Row(
                children: [
                  Icon(Icons.crop_free, size: 18, color: leg.accent),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '現在: ${playAreaSummary!}',
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: leg.body,
                          ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 10),
          FilledButton.tonalIcon(
            onPressed: onToggleAreaEdit,
            icon: Icon(
              isEditing ? Icons.check_circle : Icons.edit_location_alt,
            ),
            label: Text(isEditing ? '編集をやめる（地図のまま）' : 'エリア編集'),
          ),
          if (onCreateNewArea != null) ...[
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: onCreateNewArea,
              icon: const Icon(Icons.add_location_alt_outlined),
              label: const Text('新規エリアを作成'),
            ),
          ],
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: MapLobbyToolButton(
                  icon: Icons.center_focus_strong,
                  label: '地図を現在地へ',
                  subtitle: 'カメラ移動',
                  onPressed: isEditing ? null : onRecenterGps,
                  worldProfile: worldProfile,
                  lightStyle: true,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: MapLobbyToolButton(
                  icon: Icons.gps_not_fixed,
                  label: 'GPSを再取得',
                  subtitle: '位置の更新',
                  onPressed: onRefreshGps,
                  worldProfile: worldProfile,
                  lightStyle: true,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: [
              TextButton.icon(
                onPressed: onClearTraces,
                icon: Icon(
                  Icons.cleaning_services_outlined,
                  size: 18,
                  color: leg.accent,
                ),
                label: Text(
                  '痕跡クリア',
                  style: TextStyle(color: leg.body, fontSize: 12),
                ),
              ),
              TextButton.icon(
                onPressed: onOpenHelp,
                icon: Icon(Icons.help_outline, size: 18, color: leg.accent),
                label: Text(
                  MatchUiTerms.operationsManual,
                  style: TextStyle(color: leg.body, fontSize: 12),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// マップ準備パネルおよび試合中パネル内の地図操作ボタン。
class MapLobbyToolButton extends StatelessWidget {
  const MapLobbyToolButton({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.onPressed,
    required this.lightStyle,
    this.worldProfile,
    super.key,
  });

  final IconData icon;
  final String label;
  final String subtitle;
  final VoidCallback? onPressed;
  final bool lightStyle;
  final WorldProfile? worldProfile;

  @override
  Widget build(BuildContext context) {
    final profile = worldProfile ?? WorldProfile.horror;
    final runningLeg = !lightStyle
        ? MapHudRunningLegibility.resolve(
            Theme.of(context).colorScheme,
            profile,
          )
        : null;
    final mapLeg = lightStyle
        ? MapHudMapPanelLegibility.resolve(
            Theme.of(context).colorScheme,
            profile,
          )
        : null;
    final bg = lightStyle ? mapLeg!.tileBg : runningLeg!.skillButtonBg;
    final iconColor = lightStyle ? mapLeg!.accent : runningLeg!.icon;
    final textColor = lightStyle ? mapLeg!.body : runningLeg!.skillButtonFg;
    final subColor = lightStyle ? mapLeg!.muted : runningLeg!.skillButtonMuted;

    return Material(
      color: bg,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(10),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          child: Row(
            children: [
              Icon(icon, color: iconColor, size: 22),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: TextStyle(
                        color: textColor,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      subtitle,
                      style: TextStyle(color: subColor, fontSize: 10),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
