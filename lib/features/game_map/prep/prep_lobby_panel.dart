import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../theme/map_hud_contrast.dart';
import '../../../theme/world_profile.dart';
import '../../../game/play_area.dart';
import '../../../services/play_area_slot_store.dart';
import '../../../widgets/play_area_shape_preview.dart';
import 'prep_summary_tile.dart';

/// 準備フェーズ（地図オフ）のメインパネル。
class PrepLobbyPanel extends StatefulWidget {
  const PrepLobbyPanel({
    required this.roomLabel,
    required this.playAreaLabel,
    required this.matchDurationMinutes,
    required this.isHost,
    required this.onDurationChanged,
    required this.savedAreas,
    required this.selectedAreaId,
    required this.onSelectArea,
    required this.onHostApplyArea,
    required this.onDeleteSavedArea,
    required this.activePlayArea,
    required this.onStart,
    required this.canStart,
    required this.onOpenCustomSettings,
    required this.participantRulesOpen,
    required this.onShowMap,
    required this.onOpenLobby,
    required this.worldVisualProfile,
    super.key,
  });

  final String roomLabel;
  final String playAreaLabel;
  final double matchDurationMinutes;
  final bool isHost;
  final ValueChanged<double> onDurationChanged;
  final List<SavedPlayArea> savedAreas;
  final String? selectedAreaId;
  final ValueChanged<String?> onSelectArea;
  final VoidCallback onHostApplyArea;
  final void Function(String id, String name) onDeleteSavedArea;
  final PlayArea activePlayArea;
  final VoidCallback onStart;
  final bool canStart;
  final VoidCallback onOpenCustomSettings;
  final bool participantRulesOpen;
  final VoidCallback onShowMap;
  final VoidCallback onOpenLobby;
  final WorldProfile worldVisualProfile;

  @override
  State<PrepLobbyPanel> createState() => _PrepLobbyPanelState();
}

class _PrepLobbyPanelState extends State<PrepLobbyPanel> {
  bool _durationExpanded = false;
  bool _areaExpanded = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final minutes = widget.matchDurationMinutes.round();

    return Material(
      color: MapHudContrast.prepScaffoldBg(
        theme.colorScheme,
        widget.worldVisualProfile,
      ),
      child: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 420),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                  Text(
                    '準備',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    widget.isHost
                        ? '制限時間とエリアを決めてから開始。エリアの形は誰でも保存、適用はホストのみ。'
                        : 'ホストの設定を待っています。エリアの形は地図で保存できます。',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 12),
                  PrepSummaryTile(
                    icon: Icons.timer_outlined,
                    title: '制限時間',
                    value: '$minutes 分',
                    expanded: _durationExpanded,
                    canEdit: widget.isHost,
                    onTap: widget.isHost
                        ? () => setState(
                              () => _durationExpanded = !_durationExpanded,
                            )
                        : null,
                    child: _durationExpanded && widget.isHost
                        ? Slider(
                            min: 1,
                            max: 20,
                            divisions: 19,
                            value: widget.matchDurationMinutes.clamp(1, 20),
                            onChanged: widget.onDurationChanged,
                          )
                        : null,
                  ),
                  const SizedBox(height: 8),
                  PrepSummaryTile(
                    icon: Icons.crop_free,
                    title: 'プレイエリア',
                    value: widget.playAreaLabel,
                    expanded: _areaExpanded,
                    canEdit: widget.isHost,
                    onTap: () => setState(() => _areaExpanded = !_areaExpanded),
                    preview: PlayAreaShapePreview(
                      area: widget.activePlayArea,
                      height: 48,
                    ),
                    child: _areaExpanded
                        ? Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              if (widget.savedAreas.isEmpty)
                                Text(
                                  '保存済みエリアがありません。地図で編集して「エリアを保存」してください。',
                                  style: theme.textTheme.bodySmall,
                                )
                              else
                                ...widget.savedAreas.map((slot) {
                                  final selected =
                                      slot.id == widget.selectedAreaId;
                                  return Card(
                                    margin: const EdgeInsets.only(bottom: 8),
                                    color: selected
                                        ? theme.colorScheme.primaryContainer
                                            .withValues(alpha: 0.35)
                                        : null,
                                    child: Padding(
                                      padding: const EdgeInsets.all(8),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.stretch,
                                        children: [
                                          Row(
                                            children: [
                                              Expanded(
                                                child: Text(
                                                  slot.name,
                                                  style: theme
                                                      .textTheme.titleSmall,
                                                ),
                                              ),
                                              IconButton(
                                                tooltip: '削除',
                                                icon: const Icon(
                                                  Icons.delete_outline,
                                                  size: 20,
                                                ),
                                                onPressed: () =>
                                                    widget.onDeleteSavedArea(
                                                  slot.id,
                                                  slot.name,
                                                ),
                                              ),
                                            ],
                                          ),
                                          PlayAreaShapePreview(
                                            area: slot.area,
                                            height: 64,
                                          ),
                                          const SizedBox(height: 6),
                                          Row(
                                            children: [
                                              Expanded(
                                                child: OutlinedButton(
                                                  onPressed: () => widget
                                                      .onSelectArea(slot.id),
                                                  child: Text(
                                                    selected ? '選択中' : '選択',
                                                  ),
                                                ),
                                              ),
                                              const SizedBox(width: 8),
                                              if (widget.isHost)
                                                Expanded(
                                                  child: FilledButton.tonal(
                                                    onPressed: selected
                                                        ? widget
                                                            .onHostApplyArea
                                                        : null,
                                                    child: const Text('適用'),
                                                  ),
                                                ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                }),
                            ],
                          )
                        : null,
                  ),
                  const SizedBox(height: 8),
                  ListTile(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.groups_outlined, size: 20),
                    title: Text(
                      widget.roomLabel,
                      style: theme.textTheme.bodySmall,
                    ),
                  ),
                  if (!widget.isHost)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Text(
                        widget.participantRulesOpen
                            ? 'ホストがカスタムルールの編集を開放しています'
                            : 'カスタムルールはホストの開放待ち',
                        style: theme.textTheme.labelSmall,
                      ),
                    ),
                  SizedBox(
                    height: 52,
                    child: FilledButton.icon(
                      onPressed: widget.canStart ? widget.onStart : null,
                      icon: const Icon(Icons.play_circle_fill, size: 28),
                      label: Text(
                        widget.isHost ? '試合を開始' : 'ホストの開始待ち',
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  OutlinedButton.icon(
                    onPressed: widget.onShowMap,
                    icon: const Icon(Icons.map_outlined, size: 18),
                    label: const Text('地図（編集・エリア保存）'),
                  ),
                  TextButton(
                    onPressed: widget.onOpenCustomSettings,
                    child: const Text('カスタム設定（役職・スキル・ルール）'),
                  ),
                  OutlinedButton.icon(
                    onPressed: widget.onOpenLobby,
                    icon: const Icon(Icons.groups_2_outlined, size: 20),
                    label: const Text('オンラインルーム（参加・退出）'),
                  ),
                        SizedBox(height: math.max(16, constraints.maxHeight * 0.06)),
                        Icon(
                          Icons.shield_moon_outlined,
                          size: 36,
                          color: theme.colorScheme.outlineVariant
                              .withValues(alpha: 0.5),
                        ),
                        const SizedBox(height: 8),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
