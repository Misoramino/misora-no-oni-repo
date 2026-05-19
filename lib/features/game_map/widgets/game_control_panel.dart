import 'package:flutter/material.dart';

import '../../../game/skill_ids.dart';
import '../control_sheet_mode.dart';
import 'skill_action_button.dart';

/// 準備時の詳細設定シート / 試合中のスキル・操作パネル。
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
        style: TextStyle(fontSize: compact ? 11 : 12),
      );
    }
    if (compact) {
      return Row(
        children: [
          for (var i = 0; i < skills.length; i++) ...[
            if (i > 0) const SizedBox(width: 6),
            Expanded(child: skills[i]),
          ],
        ],
      );
    }
    return Wrap(spacing: 8, runSpacing: 8, children: skills);
  }

  @override
  Widget build(BuildContext context) {
    final expanded = sheetMode == ControlSheetMode.expanded;
    return Container(
      padding: EdgeInsets.fromLTRB(8, 4, 8, isRunning ? 6 : 10),
      decoration: BoxDecoration(
        color: isRunning
            ? Colors.black.withValues(alpha: 0.45)
            : Colors.white.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(12),
        boxShadow: isRunning
            ? null
            : const [
                BoxShadow(
                  color: Colors.black26,
                  blurRadius: 6,
                  offset: Offset(0, 2),
                ),
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
                    padding: EdgeInsets.zero,
                  ),
                  child: const Text('閉じる'),
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
                    style: TextStyle(
                      color: isRunning ? Colors.white70 : null,
                      fontSize: 12,
                    ),
                  ),
                ),
              TextButton(
                onPressed: onCycleSheetMode,
                style: TextButton.styleFrom(
                  visualDensity: VisualDensity.compact,
                  padding: EdgeInsets.zero,
                ),
                child: Text(
                  sheetMode.hint,
                  style: TextStyle(
                    color: isRunning ? Colors.white : null,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          if (!isRunning) ...[
            Text(
              prepLobbyMapHidden ? '詳細設定（地図オフ）' : '詳細設定',
              style: Theme.of(context).textTheme.labelLarge,
            ),
            if (expanded) ...[
              const SizedBox(height: 6),
              FilledButton.tonalIcon(
                onPressed: onToggleAreaEdit,
                icon: Icon(
                  isEditing ? Icons.check_circle : Icons.map_outlined,
                ),
                label: Text(isEditing ? '編集を閉じる' : 'エリア編集'),
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
            ] else
              Text(
                'エリア編集など。時間・エリアは準備画面で変更。',
                style: Theme.of(context).textTheme.bodySmall,
              ),
          ] else ...[
            _buildSkillRow(compact: sheetMode == ControlSheetMode.skillsOnly),
            if (expanded) ...[
              const SizedBox(height: 6),
              Row(
                children: [
                  IconButton(
                    tooltip: '現在地へ',
                    onPressed: isEditing ? null : onRecenterGps,
                    icon: const Icon(Icons.my_location, color: Colors.white),
                    visualDensity: VisualDensity.compact,
                  ),
                  IconButton(
                    tooltip: 'GPS更新',
                    onPressed: onRefreshGps,
                    icon: const Icon(Icons.gps_fixed, color: Colors.white70),
                    visualDensity: VisualDensity.compact,
                  ),
                  IconButton(
                    tooltip: '遊び方',
                    onPressed: onOpenHelp,
                    icon: const Icon(Icons.help_outline, color: Colors.white70),
                    visualDensity: VisualDensity.compact,
                  ),
                ],
              ),
            ],
          ],
        ],
      ),
    );
  }
}
