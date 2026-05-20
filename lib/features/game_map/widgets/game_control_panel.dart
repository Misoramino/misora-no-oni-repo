import 'package:flutter/material.dart';

import '../../../game/skill_ids.dart';
import '../../../theme/map_hud_contrast.dart';
import '../../../theme/world_profile.dart';
import '../control_sheet_mode.dart';
import 'prep_map_tools_panel.dart';
import 'skill_action_button.dart';

/// 準備時の詳細設定シート / 試合中のスキル・操作パネル。
///
/// [mapToolsOnlyPanel] が true のときはマップ確認・編集専用（カスタムルール等なし、開閉のみ）。
class GameControlPanel extends StatelessWidget {
  const GameControlPanel({
    required this.sheetMode,
    required this.onCycleSheetMode,
    required this.onStart,
    required this.onReset,
    required this.onOpenResult,
    required this.onFakeSkill,
    required this.onFakeIntelReveal,
    required this.onWerewolfHunter,
    required this.onCaptureZone,
    required this.onBodyThrow,
    required this.onRecenterGps,
    required this.onRefreshGps,
    required this.onClearTraces,
    required this.onToggleAreaEdit,
    required this.onOpenCustomMenu,
    required this.onOpenHelp,
    required this.onDismissPrepSheet,
    required this.onHidePanel,
    required this.isHost,
    required this.isRunning,
    required this.matchEnded,
    required this.canStartMatch,
    required this.isEditing,
    required this.fakeSkillActive,
    required this.roleLabel,
    required this.matchDurationLabel,
    required this.canFakeSkill,
    required this.canFakeIntelReveal,
    required this.canWerewolfHunter,
    required this.canCaptureZone,
    required this.canBodyThrow,
    required this.fakeCooldownSeconds,
    required this.captureCooldownSeconds,
    required this.bodyThrowCooldownSeconds,
    required this.werewolfBuffSeconds,
    required this.werewolfCooldownSeconds,
    required this.prepLobbyMapHidden,
    required this.mapWorldProfile,
    required this.onPrepShowMap,
    this.mapToolsOnlyPanel = false,
    super.key,
  });

  final ControlSheetMode sheetMode;
  final VoidCallback onCycleSheetMode;
  final VoidCallback onStart;
  final VoidCallback onReset;
  final VoidCallback onOpenResult;
  final VoidCallback onFakeSkill;
  final VoidCallback onFakeIntelReveal;
  final VoidCallback onWerewolfHunter;
  final VoidCallback onCaptureZone;
  final VoidCallback onBodyThrow;
  final VoidCallback onRecenterGps;
  final VoidCallback onRefreshGps;
  final VoidCallback onClearTraces;
  final VoidCallback onToggleAreaEdit;
  final VoidCallback onOpenCustomMenu;
  final VoidCallback onOpenHelp;
  final VoidCallback onDismissPrepSheet;
  final VoidCallback onHidePanel;
  final bool isHost;
  final bool isRunning;
  final bool matchEnded;
  final bool canStartMatch;
  final bool isEditing;
  final bool fakeSkillActive;
  final String roleLabel;
  final String matchDurationLabel;
  final bool canFakeSkill;
  final bool canFakeIntelReveal;
  final bool canWerewolfHunter;
  final bool canCaptureZone;
  final bool canBodyThrow;
  final int fakeCooldownSeconds;
  final int captureCooldownSeconds;
  final int bodyThrowCooldownSeconds;
  final int? werewolfBuffSeconds;
  final int werewolfCooldownSeconds;
  final bool prepLobbyMapHidden;

  /// 準備中かつ地図がオフのとき、地図を表示する（マップパネルから呼ぶ）。
  final VoidCallback onPrepShowMap;

  /// 地図スタイル（HUD 背景のコントラスト調整用）。
  final WorldProfile mapWorldProfile;

  /// 準備中かつ地図表示中のみ true（マップ専用ツール列）。
  final bool mapToolsOnlyPanel;

  Widget _buildSkillRow({required bool compact}) {
    final skills = <Widget>[
      if (canFakeSkill)
        SkillActionButton(
          label: skillShortLabel(SkillIds.fakePosition),
          icon: Icons.flare,
          active: fakeSkillActive,
          cooldownSeconds: fakeCooldownSeconds,
          compact: compact,
          onPressed: isEditing ? null : onFakeSkill,
        ),
      if (canFakeIntelReveal)
        SkillActionButton(
          label: skillShortLabel(SkillIds.fakeIntelReveal),
          icon: Icons.report,
          compact: compact,
          onPressed: isEditing ? null : onFakeIntelReveal,
        ),
      if (canWerewolfHunter)
        SkillActionButton(
          label: skillShortLabel(SkillIds.werewolfTransform),
          icon: Icons.nightlight,
          buffSeconds: werewolfBuffSeconds,
          cooldownSeconds: werewolfCooldownSeconds,
          compact: compact,
          onPressed: isEditing ? null : onWerewolfHunter,
        ),
      if (canCaptureZone)
        SkillActionButton(
          label: skillShortLabel(SkillIds.captureZone),
          icon: Icons.trip_origin,
          cooldownSeconds: captureCooldownSeconds,
          compact: compact,
          onPressed: isEditing ? null : onCaptureZone,
        ),
      if (canBodyThrow)
        SkillActionButton(
          label: skillShortLabel(SkillIds.bodyThrow),
          icon: Icons.near_me,
          cooldownSeconds: bodyThrowCooldownSeconds,
          compact: compact,
          onPressed: isEditing ? null : onBodyThrow,
        ),
    ];
    if (skills.isEmpty) {
      return Text(
        '装備スキルなし',
        style: TextStyle(
          fontSize: compact ? 11 : 12,
          color: isRunning ? Colors.white70 : null,
        ),
      );
    }
    if (compact) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (var i = 0; i < skills.length; i++) ...[
              if (i > 0) const SizedBox(width: 6),
              Expanded(child: skills[i]),
            ],
          ],
        ),
      );
    }
    return Wrap(spacing: 8, runSpacing: 8, children: skills);
  }

  @override
  Widget build(BuildContext context) {
    if (!isRunning && mapToolsOnlyPanel) {
      return PrepMapToolsPanel(
        isEditing: isEditing,
        onToggleAreaEdit: onToggleAreaEdit,
        onRecenterGps: onRecenterGps,
        onRefreshGps: onRefreshGps,
        onClearTraces: onClearTraces,
        onOpenHelp: onOpenHelp,
        onDismissPrepSheet: onDismissPrepSheet,
      );
    }

    if (!isRunning && prepLobbyMapHidden) {
      return _PrepMapPanelMapOff(
        onDismissPrepSheet: onDismissPrepSheet,
        onShowMap: onPrepShowMap,
      );
    }

    final expanded = sheetMode == ControlSheetMode.expanded;
    final scheme = Theme.of(context).colorScheme;
    final onDark = isRunning;
    final panelBg = onDark
        ? MapHudContrast.runningControlPanelBg(scheme, mapWorldProfile)
        : scheme.surfaceContainerHigh.withValues(alpha: 0.97);
    final fg = onDark ? scheme.onSurface : scheme.onSurface;
    final fgMuted = scheme.onSurfaceVariant;
    final outlineAlpha = onDark
        ? (mapWorldProfile == WorldProfile.horror ||
                mapWorldProfile == WorldProfile.astronomy)
            ? 0.44
            : mapWorldProfile == WorldProfile.arg
            ? 0.4
            : 0.35
        : 0.5;

    return Container(
      padding: EdgeInsets.fromLTRB(10, 6, 10, isRunning ? 12 : 12),
      decoration: BoxDecoration(
        color: panelBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: scheme.outlineVariant.withValues(alpha: outlineAlpha),
        ),
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
              if (!isRunning)
                TextButton(
                  onPressed: onDismissPrepSheet,
                  style: TextButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                  ),
                  child: const Text('閉じる'),
                ),
              if (isRunning)
                Text(
                  'スキル',
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: fg,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              const Spacer(),
              if (isRunning)
                TextButton(
                  onPressed: onHidePanel,
                  style: TextButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                    padding: EdgeInsets.zero,
                  ),
                  child: Text(
                    '非表示',
                    style: TextStyle(color: fgMuted, fontSize: 12),
                  ),
                ),
              if (isRunning)
                FilledButton.tonal(
                  onPressed: onCycleSheetMode,
                  style: FilledButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 4,
                    ),
                  ),
                  child: Text(
                    sheetMode.hint,
                    style: const TextStyle(fontSize: 12),
                  ),
                ),
              if (!isRunning)
                FilledButton.tonal(
                  onPressed: onCycleSheetMode,
                  style: FilledButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 4,
                    ),
                  ),
                  child: Text(
                    sheetMode.prepMapHint,
                    style: const TextStyle(fontSize: 12),
                  ),
                ),
            ],
          ),
          if (!isRunning) ...[
            Text(
              'マップ・位置（試合後）',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 4),
            Text(
              '試合時間・役職・スキル・共有ルールは準備の「カスタム設定」から。',
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: fgMuted, height: 1.35),
            ),
            if (expanded) ...[
              const SizedBox(height: 10),
              FilledButton.tonalIcon(
                onPressed: onToggleAreaEdit,
                icon: Icon(isEditing ? Icons.check_circle : Icons.map_outlined),
                label: Text(isEditing ? '編集を閉じる' : 'エリア編集'),
              ),
              const SizedBox(height: 6),
              OutlinedButton.icon(
                onPressed: onOpenCustomMenu,
                icon: const Icon(Icons.tune, size: 18),
                label: const Text('カスタムルール'),
              ),
              if (matchEnded)
                OutlinedButton.icon(
                  onPressed: onOpenResult,
                  icon: const Icon(Icons.emoji_events_outlined),
                  label: const Text('リザルト'),
                ),
              if (isHost)
                OutlinedButton.icon(
                  onPressed: onReset,
                  icon: const Icon(Icons.settings_backup_restore),
                  label: const Text('設定リセット'),
                ),
            ],
          ] else ...[
            _buildSkillRow(compact: sheetMode == ControlSheetMode.skillsOnly),
            if (expanded) ...[
              const SizedBox(height: 8),
              Divider(
                height: 1,
                color: scheme.outlineVariant.withValues(alpha: 0.5),
              ),
              const SizedBox(height: 6),
              Text('地図・位置', style: TextStyle(color: fgMuted, fontSize: 11)),
              const SizedBox(height: 4),
              Row(
                children: [
                  Expanded(
                    child: MapLobbyToolButton(
                      icon: Icons.center_focus_strong,
                      label: '地図を現在地へ',
                      subtitle: 'カメラ移動',
                      onPressed: isEditing ? null : onRecenterGps,
                      lightStyle: false,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: MapLobbyToolButton(
                      icon: Icons.gps_not_fixed,
                      label: 'GPSを再取得',
                      subtitle: '位置の更新',
                      onPressed: onRefreshGps,
                      lightStyle: false,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Wrap(
                spacing: 8,
                children: [
                  TextButton.icon(
                    onPressed: onClearTraces,
                    icon: Icon(
                      Icons.cleaning_services_outlined,
                      size: 18,
                      color: fgMuted,
                    ),
                    label: Text(
                      '痕跡クリア',
                      style: TextStyle(color: fgMuted, fontSize: 12),
                    ),
                  ),
                  TextButton.icon(
                    onPressed: onOpenHelp,
                    icon: Icon(Icons.help_outline, size: 18, color: fgMuted),
                    label: Text(
                      '遊び方',
                      style: TextStyle(color: fgMuted, fontSize: 12),
                    ),
                  ),
                ],
              ),
              Text(
                '地図のピン表示は上部 HUD の「詳細」から切り替えられます。',
                style: TextStyle(color: fgMuted, fontSize: 10, height: 1.3),
              ),
            ],
          ],
        ],
      ),
    );
  }
}

/// 準備中・地図オフ時のマップパネル（2 段階: 閉じる / 地図表示のみ。カスタムルール等は準備画面へ）。
class _PrepMapPanelMapOff extends StatelessWidget {
  const _PrepMapPanelMapOff({
    required this.onDismissPrepSheet,
    required this.onShowMap,
  });

  final VoidCallback onDismissPrepSheet;
  final VoidCallback onShowMap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final fgMuted = scheme.onSurfaceVariant;
    final panelBg = scheme.surfaceContainerHigh.withValues(alpha: 0.97);
    final outlineAlpha = 0.5;

    return Container(
      padding: const EdgeInsets.fromLTRB(10, 6, 10, 12),
      decoration: BoxDecoration(
        color: panelBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: scheme.outlineVariant.withValues(alpha: outlineAlpha),
        ),
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
              TextButton(
                onPressed: onDismissPrepSheet,
                style: TextButton.styleFrom(
                  visualDensity: VisualDensity.compact,
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                ),
                child: const Text('閉じる'),
              ),
              const Spacer(),
            ],
          ),
          Text(
            'マップパネル',
            style: Theme.of(
              context,
            ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 6),
          Text(
            'プレイエリアの編集・保存は地図上で行います。'
            '役職・スキル・共有ルールは準備画面の「カスタム設定」から。',
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: fgMuted, height: 1.35),
          ),
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed: onShowMap,
            icon: const Icon(Icons.map_outlined),
            label: const Padding(
              padding: EdgeInsets.symmetric(vertical: 10),
              child: Text('地図を表示（編集・エリア保存）'),
            ),
          ),
        ],
      ),
    );
  }
}
