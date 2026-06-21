import 'package:flutter/material.dart';

import '../../../presentation/world/world_legibility.dart';
import '../../../theme/map_hud_contrast.dart';
import '../map/game_map_layer_toggles.dart';

/// 地図レイヤーの表示切替（コンパクトな FilterChip 列）。
class MapLayerToggleStrip extends StatelessWidget {
  const MapLayerToggleStrip({
    required this.toggles,
    required this.onChanged,
    this.dense = false,
    this.showTitle = true,
    super.key,
  });

  final GameMapLayerToggles toggles;
  final ValueChanged<GameMapLayerToggles> onChanged;
  final bool dense;
  final bool showTitle;

  @override
  Widget build(BuildContext context) {
    final leg = context.mapPanelLegibility();
    final style = Theme.of(context).textTheme.labelSmall?.copyWith(
          color: leg.muted,
        );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (showTitle) ...[
          Text('地図の表示', style: style),
          const SizedBox(height: 4),
        ],
        Wrap(
          spacing: dense ? 4 : 6,
          runSpacing: dense ? 2 : 4,
          children: [
            _chip(
              context,
              leg,
              label: 'エリア',
              icon: Icons.crop_free,
              on: toggles.playArea,
              onToggle: (v) => onChanged(toggles.copyWith(playArea: v)),
            ),
            _chip(
              context,
              leg,
              label: '参加者',
              icon: Icons.people_outline,
              on: toggles.remotePlayers,
              onToggle: (v) => onChanged(toggles.copyWith(remotePlayers: v)),
            ),
            _chip(
              context,
              leg,
              label: '安全地帯',
              icon: Icons.shield_outlined,
              on: toggles.safeZones,
              onToggle: (v) => onChanged(toggles.copyWith(safeZones: v)),
            ),
            _chip(
              context,
              leg,
              label: '情報屋',
              icon: Icons.storefront_outlined,
              on: toggles.infoBrokers,
              onToggle: (v) => onChanged(toggles.copyWith(infoBrokers: v)),
            ),
            _chip(
              context,
              leg,
              label: '告発施設',
              icon: Icons.account_balance_outlined,
              on: toggles.accusationFacilities,
              onToggle: (v) =>
                  onChanged(toggles.copyWith(accusationFacilities: v)),
            ),
            _chip(
              context,
              leg,
              label: '通信障害',
              icon: Icons.wifi_off,
              on: toggles.commJamming,
              onToggle: (v) => onChanged(toggles.copyWith(commJamming: v)),
            ),
            _chip(
              context,
              leg,
              label: 'カメラ',
              icon: Icons.videocam_outlined,
              on: toggles.cameras,
              onToggle: (v) => onChanged(toggles.copyWith(cameras: v)),
            ),
            _chip(
              context,
              leg,
              label: '痕跡',
              icon: Icons.timeline,
              on: toggles.traces,
              onToggle: (v) => onChanged(toggles.copyWith(traces: v)),
            ),
            _chip(
              context,
              leg,
              label: '暴露ログ',
              icon: Icons.visibility_outlined,
              on: toggles.reveals,
              onToggle: (v) => onChanged(toggles.copyWith(reveals: v)),
            ),
            _chip(
              context,
              leg,
              label: '鬼の手がかり痕跡',
              icon: Icons.radar,
              on: toggles.oniIntel,
              onToggle: (v) => onChanged(toggles.copyWith(oniIntel: v)),
            ),
            _chip(
              context,
              leg,
              label: '結界',
              icon: Icons.trip_origin,
              on: toggles.captureZone,
              onToggle: (v) => onChanged(toggles.copyWith(captureZone: v)),
            ),
            _chip(
              context,
              leg,
              label: 'スキル印',
              icon: Icons.bolt_outlined,
              on: toggles.skillMarkers,
              onToggle: (v) => onChanged(toggles.copyWith(skillMarkers: v)),
            ),
          ],
        ),
      ],
    );
  }

  Widget _chip(
    BuildContext context,
    MapHudMapPanelLegibility leg, {
    required String label,
    required IconData icon,
    required bool on,
    required ValueChanged<bool> onToggle,
  }) {
    final fg = on ? leg.accent : leg.muted;
    final bg = on ? leg.highlightBg : leg.tileBg;
    return Material(
      color: bg,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: () => onToggle(!on),
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: dense ? 8 : 10,
            vertical: dense ? 4 : 6,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: dense ? 14 : 16, color: fg),
              const SizedBox(width: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: dense ? 11 : 12,
                  fontWeight: on ? FontWeight.w700 : FontWeight.w500,
                  color: fg,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
