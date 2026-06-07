import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../theme/map_hud_contrast.dart';
import '../../../theme/world_profile.dart';
import '../../../game/play_area.dart';
import '../../../services/play_area_slot_store.dart';
import '../../../widgets/play_area_shape_preview.dart';
import 'prep_personal_tile.dart';
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
    required this.onOpenPersonalSettings,
    required this.displayName,
    required this.avatarImagePath,
    required this.participantRulesOpen,
    required this.worldVisualProfile,
    this.settingsSummaryLine,
    this.rulesOverviewLine,
    this.startButtonKey,
    this.customRulesKey,
    this.hostAbsent = false,
    this.hostLabel,
    this.onClaimHost,
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
  final VoidCallback onOpenPersonalSettings;
  final String displayName;
  final String? avatarImagePath;
  final bool participantRulesOpen;
  final WorldProfile worldVisualProfile;
  final String? settingsSummaryLine;
  final String? rulesOverviewLine;
  final GlobalKey? startButtonKey;
  final GlobalKey? customRulesKey;
  final bool hostAbsent;
  final String? hostLabel;
  final VoidCallback? onClaimHost;

  @override
  State<PrepLobbyPanel> createState() => _PrepLobbyPanelState();
}

class _PrepLobbyPanelState extends State<PrepLobbyPanel> {
  bool _durationExpanded = false;
  bool _areaExpanded = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final leg = MapHudContrast.prepLegibility(scheme, widget.worldVisualProfile);
    final minutes = widget.matchDurationMinutes.round();

    return Material(
      color: leg.background,
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
                    widget.isHost ? '試合の準備' : '開始を待っています',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: leg.title,
                    ),
                  ),
                  if (widget.isHost)
                    Padding(
                      padding: const EdgeInsets.only(top: 4, bottom: 4),
                      child: Text(
                        '時間・エリア・ルールを決めて開始。',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: leg.muted,
                        ),
                      ),
                    ),
                  const SizedBox(height: 12),
                  if (widget.hostAbsent)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Material(
                        color: scheme.tertiaryContainer,
                        borderRadius: BorderRadius.circular(10),
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    Icons.cloud_off_rounded,
                                    color: scheme.onTertiaryContainer,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      'ホストがオフラインです',
                                      style: theme.textTheme.titleSmall?.copyWith(
                                        color: scheme.onTertiaryContainer,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              if (widget.hostLabel != null &&
                                  widget.hostLabel!.isNotEmpty) ...[
                                const SizedBox(height: 4),
                                Text(
                                  '「${widget.hostLabel}」が応答していません。',
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: scheme.onTertiaryContainer,
                                  ),
                                ),
                              ],
                              if (widget.onClaimHost != null) ...[
                                const SizedBox(height: 10),
                                FilledButton.tonal(
                                  onPressed: widget.onClaimHost,
                                  child: const Text('ホストを引き継ぐ'),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    ),
                  Material(
                    key: widget.customRulesKey,
                    color: leg.tileSurface,
                    borderRadius: BorderRadius.circular(10),
                    child: InkWell(
                      onTap: widget.onOpenCustomSettings,
                      borderRadius: BorderRadius.circular(10),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(Icons.tune_rounded, size: 22, color: leg.link),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'ルール・役職',
                                    style: theme.textTheme.labelMedium?.copyWith(
                                      color: leg.tileTitle,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    widget.isHost
                                        ? (widget.settingsSummaryLine ?? 'タップして編集')
                                        : (widget.rulesOverviewLine ??
                                            (widget.participantRulesOpen
                                                ? '編集可 — タップ'
                                                : 'ホスト待ち — タップで確認')),
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: leg.body,
                                      height: 1.35,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Icon(Icons.chevron_right, color: leg.muted),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  PrepSummaryTile(
                    prepLegibility: leg,
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
                        ? Theme(
                            data: theme.copyWith(
                              sliderTheme: SliderThemeData(
                                activeTrackColor: scheme.primary,
                                inactiveTrackColor:
                                    leg.muted.withValues(alpha: 0.35),
                                thumbColor: scheme.primary,
                                overlayColor: scheme.primary
                                    .withValues(alpha: 0.14),
                              ),
                            ),
                            child: Slider(
                              min: 10,
                              max: 90,
                              divisions: 16,
                              value: widget.matchDurationMinutes.clamp(10, 90),
                              onChanged: widget.onDurationChanged,
                            ),
                          )
                        : null,
                  ),
                  const SizedBox(height: 8),
                  PrepSummaryTile(
                    prepLegibility: leg,
                    icon: Icons.crop_free,
                    title: 'プレイエリア',
                    value: widget.playAreaLabel,
                    subtitle: '試合の舞台 · 枠の外は位置がバレやすい',
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
                                  '右下のマップパネルで形状を編集し、保存してください。',
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: leg.body,
                                  ),
                                )
                              else
                                ...widget.savedAreas.map((slot) {
                                  final selected =
                                      slot.id == widget.selectedAreaId;
                                  return Card(
                                    margin: const EdgeInsets.only(bottom: 8),
                                    color: selected
                                        ? Color.alphaBlend(
                                            scheme.primary
                                                .withValues(alpha: 0.28),
                                            leg.tileSurface,
                                          )
                                        : leg.tileSurface,
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
                                                      .textTheme.titleSmall
                                                      ?.copyWith(
                                                    color: leg.tileValue,
                                                  ),
                                                ),
                                              ),
                                              IconButton(
                                                tooltip: '削除',
                                                icon: Icon(
                                                  Icons.delete_outline,
                                                  size: 20,
                                                  color: leg.muted,
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
                  PrepPersonalTile(
                    displayName: widget.displayName,
                    avatarImagePath: widget.avatarImagePath,
                    prepLegibility: leg,
                    onOpenSettings: widget.onOpenPersonalSettings,
                  ),
                  const SizedBox(height: 8),
                  ListTile(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    leading: Icon(
                      Icons.groups_outlined,
                      size: 20,
                      color: leg.muted,
                    ),
                    title: Text(
                      widget.roomLabel,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: leg.body,
                      ),
                    ),
                  ),
                  if (!widget.isHost)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Text(
                        widget.participantRulesOpen
                            ? 'ルール編集: 開放中'
                            : 'ルール編集: ホスト待ち',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: leg.muted,
                        ),
                      ),
                    ),
                  SizedBox(
                    key: widget.startButtonKey,
                    height: 52,
                    child: Semantics(
                      button: true,
                      enabled: widget.canStart,
                      label: widget.isHost
                          ? '試合を開始'
                          : 'ホストの開始を待っています',
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
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'エリアの編集は右下「地図を表示」。',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: leg.muted,
                    ),
                  ),
                  SizedBox(height: math.max(16, constraints.maxHeight * 0.06)),
                        Icon(
                          Icons.shield_moon_outlined,
                          size: 36,
                          color: leg.decorativeIcon,
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
