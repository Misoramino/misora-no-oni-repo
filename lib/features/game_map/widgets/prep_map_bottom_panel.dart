import 'package:flutter/material.dart';

import 'area_editor_card.dart';
import 'prep_map_tools_panel.dart';

/// 準備中の地図下パネル（マップツール + 折りたたみ可能なエリア編集）。
class PrepMapBottomPanel extends StatelessWidget {
  const PrepMapBottomPanel({
    required this.isEditing,
    required this.areaEditorExpanded,
    required this.onToggleAreaEditorExpanded,
    required this.editCircleMode,
    required this.onModeChanged,
    required this.circleRadiusMeters,
    required this.onRadiusChanged,
    required this.waitingCenterTap,
    required this.onRequestCenterTap,
    required this.onCenterGps,
    required this.onUndo,
    required this.onClear,
    required this.polygonClosed,
    required this.onClosePolygon,
    required this.onReopenPolygon,
    required this.vertexCount,
    required this.onApply,
    required this.onCancelEdit,
    required this.onToggleAreaEdit,
    required this.onRecenterGps,
    required this.onRefreshGps,
    required this.onClearTraces,
    required this.onOpenHelp,
    required this.onDismissPrepSheet,
    this.playAreaSummary,
    super.key,
  });

  final bool isEditing;
  final bool areaEditorExpanded;
  final VoidCallback onToggleAreaEditorExpanded;
  final bool editCircleMode;
  final ValueChanged<bool> onModeChanged;
  final double circleRadiusMeters;
  final ValueChanged<double> onRadiusChanged;
  final bool waitingCenterTap;
  final VoidCallback onRequestCenterTap;
  final VoidCallback onCenterGps;
  final VoidCallback onUndo;
  final VoidCallback onClear;
  final bool polygonClosed;
  final VoidCallback onClosePolygon;
  final VoidCallback onReopenPolygon;
  final int vertexCount;
  final VoidCallback onApply;
  final VoidCallback onCancelEdit;
  final VoidCallback onToggleAreaEdit;
  final VoidCallback onRecenterGps;
  final VoidCallback onRefreshGps;
  final VoidCallback onClearTraces;
  final VoidCallback onOpenHelp;
  final VoidCallback onDismissPrepSheet;
  final String? playAreaSummary;

  @override
  Widget build(BuildContext context) {
    final maxH = MediaQuery.sizeOf(context).height * 0.48;
    return Material(
      color: Colors.transparent,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: maxH),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (isEditing) ...[
                Material(
                  color: Theme.of(context).colorScheme.surfaceContainerHigh,
                  borderRadius: BorderRadius.circular(12),
                  elevation: 4,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      InkWell(
                        onTap: onToggleAreaEditorExpanded,
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(12),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 10,
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.edit_location_alt,
                                size: 20,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  waitingCenterTap
                                      ? 'エリア編集 — 地図をタップして中心を指定'
                                      : 'エリア編集 — 地図をタップして頂点を追加',
                                  style: Theme.of(context).textTheme.titleSmall,
                                ),
                              ),
                              Icon(
                                areaEditorExpanded
                                    ? Icons.expand_less
                                    : Icons.expand_more,
                              ),
                            ],
                          ),
                        ),
                      ),
                      if (areaEditorExpanded)
                        Padding(
                          padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
                          child: AreaEditorCard(
                            editCircleMode: editCircleMode,
                            onModeChanged: onModeChanged,
                            circleRadiusMeters: circleRadiusMeters,
                            onRadiusChanged: onRadiusChanged,
                            waitingCenterTap: waitingCenterTap,
                            onRequestCenterTap: onRequestCenterTap,
                            onCenterGps: onCenterGps,
                            onUndo: onUndo,
                            onClear: onClear,
                            polygonClosed: polygonClosed,
                            onClosePolygon: onClosePolygon,
                            onReopenPolygon: onReopenPolygon,
                            vertexCount: vertexCount,
                            onApply: onApply,
                            onCancel: onCancelEdit,
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
              ],
              PrepMapToolsPanel(
                isEditing: isEditing,
                playAreaSummary: playAreaSummary,
                onToggleAreaEdit: onToggleAreaEdit,
                onRecenterGps: onRecenterGps,
                onRefreshGps: onRefreshGps,
                onClearTraces: onClearTraces,
                onOpenHelp: onOpenHelp,
                onDismissPrepSheet: onDismissPrepSheet,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
