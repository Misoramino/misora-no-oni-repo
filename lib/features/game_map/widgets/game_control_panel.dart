import 'package:flutter/material.dart';

import '../../../game/game_config.dart';
import '../../../game/skill_ids.dart';
import '../../../theme/map_hud_contrast.dart';
import '../../../theme/world_profile.dart';
import '../control_sheet_mode.dart';
import 'prep_map_tools_panel.dart';
import 'skill_action_button.dart';

/// 準備時の詳細設定シート / 試合中のスキル・操作パネル。
///
/// [mapToolsOnlyPanel] が true のときはマップ確認・編集専用（ルール設定なし、開閉のみ）。
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
    required this.onOpenPersonalSettings,
    required this.onOpenHelp,
    required this.onDismissPrepSheet,
    required this.onHidePanel,
    required this.isHost,
    required this.isRunning,
    this.secondGameMode = false,
    required this.matchEnded,
    required this.canStartMatch,
    required this.isEditing,
    required this.fakeSkillActive,
    this.fakeActiveSeconds = 0,
    required this.roleLabel,
    required this.matchDurationLabel,
    required this.canFakeSkill,
    required this.canFakeIntelReveal,
    required this.canWerewolfHunter,
    required this.canCaptureZone,
    required this.canBodyThrow,
    required this.fakeCooldownSeconds,
    required this.fakeIntelCooldownSeconds,
    required this.captureCooldownSeconds,
    required this.bodyThrowCooldownSeconds,
    this.bodyThrowPuppetActive = false,
    this.bodyThrowRecoverInRange = false,
    this.skillsLockedByBodyThrow = false,
    this.werewolfOniActive = false,
    required this.werewolfCooldownSeconds,
    required this.prepLobbyMapHidden,
    required this.mapWorldProfile,
    required this.onPrepShowMap,
    this.mapToolsOnlyPanel = false,
    this.skillPanelKey,
    this.playAreaSummary,
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
  final VoidCallback onOpenPersonalSettings;
  final VoidCallback onOpenHelp;
  final VoidCallback onDismissPrepSheet;
  final VoidCallback onHidePanel;
  final bool isHost;
  final bool isRunning;
  final bool secondGameMode;
  final bool matchEnded;
  final bool canStartMatch;
  final bool isEditing;
  final bool fakeSkillActive;

  /// 偽位置スキルの効果残り秒（>0 のときボタンにライブ表示）。
  final int fakeActiveSeconds;
  final String roleLabel;
  final String matchDurationLabel;
  final bool canFakeSkill;
  final bool canFakeIntelReveal;
  final bool canWerewolfHunter;
  final bool canCaptureZone;
  final bool canBodyThrow;
  final int fakeCooldownSeconds;
  final int fakeIntelCooldownSeconds;
  final int captureCooldownSeconds;
  final int bodyThrowCooldownSeconds;
  final bool bodyThrowPuppetActive;
  final bool bodyThrowRecoverInRange;
  final bool skillsLockedByBodyThrow;
  final bool werewolfOniActive;
  final int werewolfCooldownSeconds;
  final bool prepLobbyMapHidden;

  /// 準備中かつ地図がオフのとき、地図を表示する（マップパネルから呼ぶ）。
  final VoidCallback onPrepShowMap;

  /// 地図スタイル（HUD 背景のコントラスト調整用）。
  final WorldProfile mapWorldProfile;

  /// 準備中かつ地図表示中のみ true（マップ専用ツール列）。
  final bool mapToolsOnlyPanel;

  /// 試合中スキルパネル（コーチマーク用）。
  final GlobalKey? skillPanelKey;

  /// 準備中マップパネル向けプレイエリアサマリー。
  final String? playAreaSummary;

  Widget _buildSkillRow({required bool compact}) {
    final locked = skillsLockedByBodyThrow;
    final skills = <Widget>[
      if (canFakeSkill)
        SkillActionButton(
          label: skillShortLabel(SkillIds.fakePosition),
          icon: Icons.flare,
          active: fakeSkillActive,
          buffSeconds: fakeActiveSeconds > 0 ? fakeActiveSeconds : null,
          cooldownSeconds: fakeCooldownSeconds,
          compact: compact,
          blocked: locked,
          onPressed: isEditing || locked ? null : onFakeSkill,
        ),
      if (canFakeIntelReveal)
        SkillActionButton(
          label: skillShortLabel(SkillIds.fakeIntelReveal),
          icon: Icons.report,
          cooldownSeconds: fakeIntelCooldownSeconds,
          compact: compact,
          blocked: locked,
          onPressed: isEditing || locked ? null : onFakeIntelReveal,
        ),
      if (canWerewolfHunter)
        SkillActionButton(
          label: werewolfTransformActionLabel(inOniForm: werewolfOniActive),
          icon: Icons.nightlight,
          active: werewolfOniActive,
          cooldownSeconds: werewolfCooldownSeconds,
          compact: compact,
          blocked: locked,
          onPressed: isEditing || locked ? null : onWerewolfHunter,
        ),
      if (canCaptureZone)
        SkillActionButton(
          label: skillShortLabel(SkillIds.captureZone),
          icon: Icons.trip_origin,
          cooldownSeconds: captureCooldownSeconds,
          compact: compact,
          blocked: locked,
          onPressed: isEditing || locked ? null : onCaptureZone,
        ),
      if (canBodyThrow)
        SkillActionButton(
          label: bodyThrowPuppetActive ? '回収' : skillShortLabel(SkillIds.bodyThrow),
          icon: Icons.near_me,
          active: bodyThrowPuppetActive && bodyThrowRecoverInRange,
          auxLine: bodyThrowPuppetActive && !bodyThrowRecoverInRange
              ? '約${GameConfig.bodyThrowRecoveryDistanceMeters.toStringAsFixed(0)}m以内'
              : null,
          cooldownSeconds: bodyThrowPuppetActive ? 0 : bodyThrowCooldownSeconds,
          compact: compact,
          onPressed: isEditing ||
                  (bodyThrowPuppetActive && !bodyThrowRecoverInRange)
              ? null
              : onBodyThrow,
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
        playAreaSummary: playAreaSummary,
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
        playAreaSummary: playAreaSummary,
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
    final fg = onDark
        ? (mapWorldProfile == WorldProfile.sport
            ? const Color(0xFF1A1C1E)
            : scheme.onSurface)
        : scheme.onSurface;
    final fgMuted = onDark && mapWorldProfile == WorldProfile.sport
        ? const Color(0xFF3D4048)
        : scheme.onSurfaceVariant;
    final outlineAlpha = onDark
        ? (mapWorldProfile == WorldProfile.horror ||
                mapWorldProfile == WorldProfile.astronomy)
            ? 0.44
            : mapWorldProfile == WorldProfile.arg
            ? 0.4
            : mapWorldProfile == WorldProfile.sport
            ? 0.42
            : 0.35
        : 0.5;

    return Container(
      key: isRunning ? skillPanelKey : null,
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
                  secondGameMode ? '第二ゲーム' : 'スキル',
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
              '個人設定・ルールは準備画面の「ルール・役職」から。',
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: fgMuted, height: 1.35),
            ),
            if (expanded) ...[
              const SizedBox(height: 10),
              FilledButton.tonalIcon(
                onPressed: onToggleAreaEdit,
                icon: Icon(isEditing ? Icons.check_circle : Icons.map_outlined),
                label: Text(isEditing ? '編集を閉じる' : 'プレイエリア編集'),
              ),
              const SizedBox(height: 6),
              OutlinedButton.icon(
                onPressed: onOpenPersonalSettings,
                icon: const Icon(Icons.person_outline, size: 18),
                label: const Text('個人設定'),
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
          ] else if (secondGameMode) ...[
            Text(
              '上部 HUD からログを確認できます。地図の施設マーカーで支援操作ができます。',
              style: TextStyle(color: fgMuted, fontSize: 11, height: 1.35),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: onOpenHelp,
                    icon: const Icon(Icons.help_outline, size: 18),
                    label: const Text('遊び方'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: onRecenterGps,
                    icon: const Icon(Icons.center_focus_strong, size: 18),
                    label: const Text('現在地へ'),
                  ),
                ),
              ],
            ),
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
                '地図のピン表示は上部 HUD の tune アイコンから切り替えられます。',
                style: TextStyle(color: fgMuted, fontSize: 10, height: 1.3),
              ),
            ],
          ],
        ],
      ),
    );
  }
}

/// 準備中・地図オフ時のマップパネル（2 段階: 閉じる / 地図表示のみ。ルール等は準備画面へ）。
class _PrepMapPanelMapOff extends StatelessWidget {
  const _PrepMapPanelMapOff({
    required this.onDismissPrepSheet,
    required this.onShowMap,
    this.playAreaSummary,
  });

  final VoidCallback onDismissPrepSheet;
  final VoidCallback onShowMap;
  final String? playAreaSummary;

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
            '地図',
            style: Theme.of(
              context,
            ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 6),
          if (playAreaSummary != null && playAreaSummary!.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Text(
                '現在: ${playAreaSummary!}',
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: scheme.primary,
                    ),
              ),
            ),
          Text(
            'エリア編集は準備画面の「プレイエリア」タブからも開けます。',
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
              child: Text('地図を開く'),
            ),
          ),
        ],
      ),
    );
  }
}
