import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../theme/map_hud_contrast.dart';
import '../../../theme/world_profile.dart';
import '../../../theme/world_profile_tokens.dart';
import '../../../game/play_area.dart';
import '../../../services/play_area_slot_store.dart';
import '../../../sync/firestore_room_session.dart';
import 'prep_personal_tile.dart';
import 'prep_play_area_collapsed_preview.dart';
import 'prep_play_area_hub.dart';
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
    required this.onHostApplyArea,
    this.onProposeToHost,
    this.hostAppliedAreaNote,
    this.areaProposals = const {},
    this.onApplyAreaProposal,
    required this.activePlayArea,
    required this.onOpenMapEdit,
    required this.onOpenMapPreview,
    required this.onOpenMapBrowse,
    required this.onOpenAreaGallery,
    required this.mapStyleJson,
    required this.mapTokens,
    required this.onStart,
    required this.canStart,
    this.startBlockedHint,
    this.startGpsHint,
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
    this.playAreaKey,
    this.prepReadyKey,
    this.prepReady = false,
    this.onTogglePrepReady,
    this.prepReadySummaryLine,
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
  final VoidCallback onHostApplyArea;
  final VoidCallback? onProposeToHost;
  final String? hostAppliedAreaNote;
  final Map<String, PlayAreaProposalSnapshot> areaProposals;
  final void Function(PlayAreaProposalSnapshot proposal)? onApplyAreaProposal;
  final PlayArea activePlayArea;
  final VoidCallback onOpenMapEdit;
  final VoidCallback onOpenMapPreview;
  final VoidCallback onOpenMapBrowse;
  final VoidCallback onOpenAreaGallery;
  final String? mapStyleJson;
  final WorldProfileTokens mapTokens;
  final VoidCallback onStart;
  final bool canStart;
  final String? startBlockedHint;
  final String? startGpsHint;
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
  final GlobalKey? playAreaKey;
  final GlobalKey? prepReadyKey;
  final bool prepReady;
  final VoidCallback? onTogglePrepReady;
  final String? prepReadySummaryLine;
  final bool hostAbsent;
  final String? hostLabel;
  final VoidCallback? onClaimHost;

  @override
  State<PrepLobbyPanel> createState() => _PrepLobbyPanelState();
}

class _PrepLobbyPanelState extends State<PrepLobbyPanel> {
  bool _durationExpanded = false;
  bool _areaExpanded = false;

  String? _selectedSlotName() {
    final id = widget.selectedAreaId;
    if (id == null) return null;
    for (final s in widget.savedAreas) {
      if (s.id == id) return s.name;
    }
    return null;
  }

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
                        '時間・プレイエリア・ルールを決めて開始。',
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
                        color: Color.alphaBlend(
                          leg.link.withValues(alpha: 0.12),
                          leg.tileSurface,
                        ),
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
                                    color: leg.link,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      'ホストがオフラインです',
                                      style: theme.textTheme.titleSmall?.copyWith(
                                        color: leg.title,
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
                                    color: leg.muted,
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
                  if (widget.isHost && widget.areaProposals.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    for (final proposal in widget.areaProposals.values)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Material(
                          color: scheme.secondaryContainer,
                          borderRadius: BorderRadius.circular(10),
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Text(
                                  'エリア提案 — ${proposal.proposerName}',
                                  style: theme.textTheme.titleSmall?.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                Text(
                                  '「${proposal.slotName}」 — ${proposal.area.coarseLocationLabel()}',
                                  style: theme.textTheme.bodySmall,
                                ),
                                const SizedBox(height: 8),
                                FilledButton.tonal(
                                  onPressed: widget.onApplyAreaProposal == null
                                      ? null
                                      : () => widget.onApplyAreaProposal!(
                                            proposal,
                                          ),
                                  child: const Text('この提案を試合に適用'),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                  ],
                  if (widget.isHost && widget.prepReadySummaryLine != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Text(
                        widget.prepReadySummaryLine!,
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: leg.muted,
                        ),
                      ),
                    ),
                  const SizedBox(height: 8),
                  PrepSummaryTile(
                    key: widget.playAreaKey,
                    prepLegibility: leg,
                    icon: Icons.crop_free,
                    title: 'プレイエリア',
                    value: widget.playAreaLabel,
                    subtitle: widget.hostAppliedAreaNote,
                    expanded: _areaExpanded,
                    canEdit: true,
                    onTap: () => setState(() => _areaExpanded = !_areaExpanded),
                    preview: !_areaExpanded
                        ? PrepPlayAreaCollapsedPreview(
                            area: widget.activePlayArea,
                            summary: widget.playAreaLabel,
                            prepLegibility: leg,
                          )
                        : null,
                    child: _areaExpanded
                        ? PrepPlayAreaHub(
                            activePlayArea: widget.activePlayArea,
                            playAreaSummary: widget.playAreaLabel,
                            selectedSlotName: _selectedSlotName(),
                            savedCount: widget.savedAreas.length,
                            isHost: widget.isHost,
                            worldProfile: widget.worldVisualProfile,
                            mapStyleJson: widget.mapStyleJson,
                            tokens: widget.mapTokens,
                            prepLegibility: leg,
                            onOpenMapEdit: widget.onOpenMapEdit,
                            onOpenMapPreview: widget.onOpenMapPreview,
                            onOpenMapBrowse: widget.onOpenMapBrowse,
                            onOpenAreaGallery: widget.onOpenAreaGallery,
                            onHostApplyArea: widget.onHostApplyArea,
                            onProposeToHost: widget.onProposeToHost,
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
                        'ルールはホストがカスタム設定で決めます。プレイエリアの形は提案できます。',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: leg.muted,
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
                  if (!widget.isHost && widget.onTogglePrepReady != null) ...[
                    SizedBox(
                      key: widget.prepReadyKey,
                      height: 48,
                      child: OutlinedButton.icon(
                        onPressed: widget.onTogglePrepReady,
                        icon: Icon(
                          widget.prepReady
                              ? Icons.check_circle_rounded
                              : Icons.check_circle_outline_rounded,
                        ),
                        label: Text(
                          widget.prepReady ? '準備完了（タップで解除）' : '準備完了',
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                  ],
                  if (!widget.isHost)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Text(
                        widget.prepReady
                            ? 'ホストの開始を待っています。ルールの確認とプレイエリアの提案以外はできません。'
                            : '設定が済んだら「準備完了」を押してください。',
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
                      enabled: widget.isHost,
                      label: widget.isHost
                          ? '試合を開始'
                          : 'ホストの開始を待っています',
                      child: FilledButton.icon(
                        onPressed: widget.isHost ? widget.onStart : null,
                        style: widget.isHost && !widget.canStart
                            ? FilledButton.styleFrom(
                                backgroundColor: scheme.primary
                                    .withValues(alpha: 0.72),
                              )
                            : null,
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
                  if (widget.isHost &&
                      (widget.startBlockedHint != null ||
                          widget.startGpsHint != null))
                    Padding(
                      padding: const EdgeInsets.only(top: 8, bottom: 4),
                      child: Text(
                        widget.startBlockedHint ?? widget.startGpsHint!,
                        textAlign: TextAlign.center,
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: widget.startBlockedHint != null
                              ? theme.colorScheme.error
                              : leg.muted,
                          fontWeight: FontWeight.w600,
                          height: 1.35,
                        ),
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
