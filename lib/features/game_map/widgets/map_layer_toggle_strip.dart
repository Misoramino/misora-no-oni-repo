import 'package:flutter/material.dart';

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
    final style = Theme.of(context).textTheme.labelSmall;
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
              label: 'エリア',
              icon: Icons.crop_free,
              on: toggles.playArea,
              onToggle: (v) => onChanged(toggles.copyWith(playArea: v)),
            ),
            _chip(
              label: '参加者',
              icon: Icons.people_outline,
              on: toggles.remotePlayers,
              onToggle: (v) => onChanged(toggles.copyWith(remotePlayers: v)),
            ),
            _chip(
              label: '安全地帯',
              icon: Icons.shield_outlined,
              on: toggles.safeZones,
              onToggle: (v) => onChanged(toggles.copyWith(safeZones: v)),
            ),
            _chip(
              label: '情報屋',
              icon: Icons.storefront_outlined,
              on: toggles.infoBrokers,
              onToggle: (v) => onChanged(toggles.copyWith(infoBrokers: v)),
            ),
            _chip(
              label: '通信障害',
              icon: Icons.wifi_off,
              on: toggles.commJamming,
              onToggle: (v) => onChanged(toggles.copyWith(commJamming: v)),
            ),
            _chip(
              label: 'カメラ',
              icon: Icons.videocam_outlined,
              on: toggles.cameras,
              onToggle: (v) => onChanged(toggles.copyWith(cameras: v)),
            ),
            _chip(
              label: '痕跡',
              icon: Icons.timeline,
              on: toggles.traces,
              onToggle: (v) => onChanged(toggles.copyWith(traces: v)),
            ),
            _chip(
              label: '暴露ログ',
              icon: Icons.visibility_outlined,
              on: toggles.reveals,
              onToggle: (v) => onChanged(toggles.copyWith(reveals: v)),
            ),
            _chip(
              label: '鬼の手がかり痕跡',
              icon: Icons.radar,
              on: toggles.oniIntel,
              onToggle: (v) => onChanged(toggles.copyWith(oniIntel: v)),
            ),
            _chip(
              label: '結界',
              icon: Icons.trip_origin,
              on: toggles.captureZone,
              onToggle: (v) => onChanged(toggles.copyWith(captureZone: v)),
            ),
            _chip(
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

  Widget _chip({
    required String label,
    required IconData icon,
    required bool on,
    required ValueChanged<bool> onToggle,
  }) {
    return FilterChip(
      label: Text(label, style: TextStyle(fontSize: dense ? 11 : 12)),
      avatar: Icon(icon, size: dense ? 14 : 16),
      selected: on,
      showCheckmark: false,
      visualDensity: dense ? VisualDensity.compact : VisualDensity.standard,
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      onSelected: onToggle,
    );
  }
}
