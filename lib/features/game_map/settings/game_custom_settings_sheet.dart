import 'dart:async';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../game/accusation_weight.dart';
import '../../../game/elimination_aftermath_rule.dart';
import '../../../game/game_config.dart';
import '../../../game/match_quick_preset.dart';
import '../../../game/oni_intel_mode.dart';
import '../../../game/player_role.dart';
import '../../../game/skill_ids.dart';
import '../../../session/game_map_prefs.dart';
import '../../../sync/firebase_bootstrap.dart';
import 'game_custom_settings_models.dart';

Future<GameCustomSettingsResult?> showGameCustomSettingsSheet({
  required BuildContext context,
  required GameCustomSettingsInitial initial,
  required bool isHost,
  Future<void> Function()? onRequestGameDefaultsReset,
}) async {
  OniIntelMode selectedIntel = initial.oniIntelMode;
  EliminationAftermathRule selectedElimination =
      initial.eliminationAftermathRule;
  PlayerRole selectedRole = initial.localRole;
  bool selectedCustomRuleMode = initial.customRuleMode;
  var selectedParticipantRulesOpen = initial.participantRulesOpen;
  double selectedDurationMinutes = initial.matchDurationMinutes;
  final selectedSkills = Set<String>.from(initial.skillLoadout);
  var selectedGimmickDensity = initial.gimmickDensity.clamp(0.45, 1.55);
  var selectedRoleAssignMode = initial.roleAssignMode;
  var selectedOniCount = initial.oniCount.clamp(0, 12);
  var selectedWerewolfCount = initial.werewolfCount.clamp(0, 12);
  var selectedAccusationWeight = initial.accusationWeight;
  MatchQuickPreset? selectedQuickPreset;
  var firebaseWarmScheduled = false;

  bool? ok;
  ok = await showModalBottomSheet<bool>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setModalState) {
            final screenH = MediaQuery.sizeOf(ctx).height;
            final kb = MediaQuery.viewInsetsOf(ctx).bottom;
            final sheetH = (screenH * 0.86 - kb).clamp(280.0, screenH * 0.92);
            if (!firebaseWarmScheduled) {
              firebaseWarmScheduled = true;
              WidgetsBinding.instance.addPostFrameCallback((_) {
                unawaited(
                  FirebaseBootstrap.tryInit().then((_) {
                    if (ctx.mounted) setModalState(() {});
                  }),
                );
              });
            }
            return Padding(
              padding: EdgeInsets.only(
                left: 16,
                right: 16,
                top: 8,
                bottom: 16 + kb,
              ),
              child: SizedBox(
                height: sheetH,
                child: SingleChildScrollView(
                  physics: const ClampingScrollPhysics(),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('ルール設定', style: Theme.of(ctx).textTheme.titleLarge),
                      if (!isHost)
                        Padding(
                          padding: const EdgeInsets.only(top: 4, bottom: 8),
                          child: Text(
                            'ホストが編集。開放中は一部変更できます。',
                            style: Theme.of(ctx).textTheme.bodySmall?.copyWith(
                              color: Theme.of(ctx).colorScheme.onSurfaceVariant,
                            ),
                          ),
                        )
                      else
                        const SizedBox(height: 8),
                      if (isHost)
                        SwitchListTile(
                          contentPadding: EdgeInsets.zero,
                          title: const Text('参加者に編集を許可'),
                          value: selectedParticipantRulesOpen,
                          onChanged: (v) => setModalState(
                            () => selectedParticipantRulesOpen = v,
                          ),
                        ),
                      _SettingsSection(
                        title: '役職・スキル',
                        initiallyExpanded: false,
                        children: [
                      DropdownButtonFormField<OniIntelMode>(
                        initialValue: selectedIntel,
                        decoration: InputDecoration(
                          labelText: '情報屋の鬼情報モード',
                          helperText:
                              '情報屋の鬼情報の出し方。断片は約${GameConfig.fragmentedPhaseSeconds}秒で切替。',
                          helperMaxLines: 2,
                        ),
                        items: OniIntelMode.values
                            .map(
                              (m) => DropdownMenuItem(
                                value: m,
                                child: Text(m.label),
                              ),
                            )
                            .toList(),
                        onChanged: (isHost || selectedParticipantRulesOpen)
                            ? (v) {
                                if (v == null) return;
                                setModalState(() => selectedIntel = v);
                              }
                            : null,
                      ),
                      const SizedBox(height: 10),
                      DropdownButtonFormField<PlayerRole>(
                        initialValue: selectedRole,
                        decoration: const InputDecoration(
                          labelText: 'ローカル役職',
                          helperText: '公開ルールON時のみ固定',
                        ),
                        items: assignablePlayerRoles
                            .map(
                              (r) => DropdownMenuItem(
                                value: r,
                                child: Text(r.displayName),
                              ),
                            )
                            .toList(),
                        onChanged:
                            selectedCustomRuleMode &&
                                (isHost || selectedParticipantRulesOpen)
                            ? (v) {
                                if (v == null) return;
                                setModalState(() {
                                  selectedRole = v;
                                  selectedSkills
                                    ..clear()
                                    ..addAll(
                                      skillCandidatesForRole(
                                        v,
                                      ).take(v == PlayerRole.hunter ? 2 : 1),
                                    );
                                });
                              }
                            : null,
                      ),
                      Wrap(
                        spacing: 8,
                        children: [
                          for (final s in skillCandidatesForRole(selectedRole))
                            FilterChip(
                              label: Text(skillLabel(s)),
                              selected: selectedSkills.contains(s),
                              onSelected:
                                  selectedCustomRuleMode &&
                                      (isHost || selectedParticipantRulesOpen)
                                  ? (v) {
                                      setModalState(() {
                                        if (v) {
                                          if (selectedRole !=
                                              PlayerRole.hunter) {
                                            selectedSkills.clear();
                                          }
                                          if (selectedRole ==
                                                  PlayerRole.hunter &&
                                              selectedSkills.length >= 2) {
                                            selectedSkills.remove(
                                              selectedSkills.first,
                                            );
                                          }
                                          selectedSkills.add(s);
                                        } else {
                                          selectedSkills.remove(s);
                                        }
                                      });
                                    }
                                  : null,
                            ),
                        ],
                      ),
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('役職公開ルール'),
                        subtitle: const Text('オフ時は開始時にランダム割当'),
                        value: selectedCustomRuleMode,
                        onChanged: (isHost || selectedParticipantRulesOpen)
                            ? (v) => setModalState(
                                () => selectedCustomRuleMode = v,
                              )
                            : null,
                      ),
                      if (isHost && !selectedCustomRuleMode) ...[
                        const SizedBox(height: 4),
                        DropdownButtonFormField<RoleAssignMode>(
                          initialValue: selectedRoleAssignMode,
                          decoration: const InputDecoration(
                            labelText: 'ランダム割当の方式',
                            helperText: 'おまかせ＝人数バランス自動／人数指定＝役職ごとの人数を指定',
                            helperMaxLines: 2,
                          ),
                          items: const [
                            DropdownMenuItem(
                              value: RoleAssignMode.random,
                              child: Text('おまかせ（自動バランス）'),
                            ),
                            DropdownMenuItem(
                              value: RoleAssignMode.counts,
                              child: Text('役職人数を指定して配分'),
                            ),
                          ],
                          onChanged: (v) {
                            if (v == null) return;
                            setModalState(() => selectedRoleAssignMode = v);
                          },
                        ),
                        if (selectedRoleAssignMode == RoleAssignMode.counts) ...[
                          const SizedBox(height: 4),
                          _CountStepper(
                            label: '鬼の人数',
                            value: selectedOniCount,
                            onChanged: (v) =>
                                setModalState(() => selectedOniCount = v),
                          ),
                          _CountStepper(
                            label: '人狼の人数',
                            value: selectedWerewolfCount,
                            onChanged: (v) =>
                                setModalState(() => selectedWerewolfCount = v),
                          ),
                          Padding(
                            padding: const EdgeInsets.only(top: 2, bottom: 4),
                            child: Text(
                              '残りのメンバーは逃走者になります。人数がメンバー数を超える場合は自動で調整されます。',
                              style: Theme.of(ctx).textTheme.bodySmall?.copyWith(
                                    color: Theme.of(ctx)
                                        .colorScheme
                                        .onSurfaceVariant,
                                  ),
                            ),
                          ),
                        ],
                      ],
                        ],
                      ),
                      _SettingsSection(
                        title: '試合設定',
                        initiallyExpanded: false,
                        children: [
                      Text(
                        '制限時間: ${selectedDurationMinutes.round()} 分',
                        style: Theme.of(ctx).textTheme.titleSmall,
                      ),
                      Text(
                        '準備画面と同期されます',
                        style: Theme.of(ctx).textTheme.labelSmall?.copyWith(
                              color: Theme.of(ctx).colorScheme.onSurfaceVariant,
                            ),
                      ),
                      Slider(
                        min: 10,
                        max: 90,
                        divisions: 16,
                        value: selectedDurationMinutes.clamp(10, 90),
                        onChanged: isHost
                            ? (v) => setModalState(
                                () => selectedDurationMinutes = v,
                              )
                            : null,
                      ),
                      if (isHost) ...[
                        const SizedBox(height: 12),
                        Text(
                          'プリセット',
                          style: Theme.of(ctx).textTheme.titleSmall,
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            for (final p in MatchQuickPreset.values)
                              ChoiceChip(
                                label: Text('${p.label}\n${p.subtitle}',
                                    style: const TextStyle(fontSize: 11)),
                                selected: selectedQuickPreset == p,
                                onSelected: (_) => setModalState(() {
                                  selectedQuickPreset = p;
                                  selectedDurationMinutes = p.durationMinutes;
                                  selectedGimmickDensity = p.gimmickDensity;
                                }),
                              ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        DropdownButtonFormField<AccusationWeight>(
                          initialValue: selectedAccusationWeight,
                          decoration: const InputDecoration(
                            labelText: '告発の重み',
                            helperText: '正解・失敗時の試合への影響',
                            helperMaxLines: 3,
                          ),
                          items: AccusationWeight.values
                              .map(
                                (w) => DropdownMenuItem(
                                  value: w,
                                  child: Text(w.label),
                                ),
                              )
                              .toList(),
                          onChanged: (v) {
                            if (v == null) return;
                            setModalState(() => selectedAccusationWeight = v);
                          },
                        ),
                        Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Text(
                            selectedAccusationWeight.helperText,
                            style: Theme.of(ctx).textTheme.bodySmall?.copyWith(
                                  color: Theme.of(ctx)
                                      .colorScheme
                                      .onSurfaceVariant,
                                ),
                          ),
                        ),
                        Text(
                          'ギミック密度: ${selectedGimmickDensity.toStringAsFixed(2)}',
                          style: Theme.of(ctx).textTheme.titleSmall,
                        ),
                        Slider(
                            min: 0.45,
                            max: 1.55,
                            divisions: 22,
                            value: selectedGimmickDensity.clamp(0.45, 1.55),
                            onChanged: (v) => setModalState(
                              () => selectedGimmickDensity = v.clamp(0.45, 1.55),
                            ),
                          ),
                      ],
                        ],
                      ),
                      _SettingsSection(
                        title: '脱落後',
                        initiallyExpanded: false,
                        children: [
                      DropdownButtonFormField<EliminationAftermathRule>(
                        initialValue: selectedElimination,
                        decoration: const InputDecoration(
                          labelText: '脱落後ルール（ルーム設定）',
                        ),
                        items: EliminationAftermathRule.values
                            .map(
                              (r) => DropdownMenuItem(
                                value: r,
                                child: Text(r.label),
                              ),
                            )
                            .toList(),
                        onChanged: (isHost || selectedParticipantRulesOpen)
                            ? (v) {
                                if (v == null) return;
                                setModalState(() => selectedElimination = v);
                              }
                            : null,
                      ),
                      ],
                      ),
                      const SizedBox(height: 10),
                      if (isHost && onRequestGameDefaultsReset != null)
                        Align(
                          alignment: Alignment.centerLeft,
                          child: OutlinedButton.icon(
                            onPressed: () async {
                              await onRequestGameDefaultsReset();
                            },
                            icon: const Icon(Icons.settings_backup_restore),
                            label: const Text('デフォルトに戻す'),
                          ),
                        ),
                      if (isHost && onRequestGameDefaultsReset != null)
                        const SizedBox(height: 8),
                      Align(
                        alignment: Alignment.centerRight,
                        child: FilledButton(
                          onPressed: () => Navigator.pop(ctx, true),
                          child: const Text('保存して閉じる'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );

  if (ok != true) return null;

  final prefs = await SharedPreferences.getInstance();
  await prefs.setString(
    GameMapPrefs.eliminationAftermathRule,
    selectedElimination.name,
  );
  await prefs.setDouble(GameMapPrefs.gimmickDensity, selectedGimmickDensity);
  await prefs.setString(
    GameMapPrefs.roleAssignMode,
    selectedRoleAssignMode.name,
  );
  await prefs.setInt(GameMapPrefs.roleOniCount, selectedOniCount);
  await prefs.setInt(GameMapPrefs.roleWerewolfCount, selectedWerewolfCount);
  await prefs.setString(
    GameMapPrefs.accusationWeight,
    selectedAccusationWeight.name,
  );

  return GameCustomSettingsResult(
    oniIntelMode: selectedIntel,
    eliminationAftermathRule: selectedElimination,
    localRole: selectedRole,
    customRuleMode: selectedCustomRuleMode,
    participantRulesOpen: selectedParticipantRulesOpen,
    matchDurationMinutes: selectedDurationMinutes,
    skillLoadout: selectedSkills,
    gimmickDensity: selectedGimmickDensity,
    roleAssignMode: selectedRoleAssignMode,
    oniCount: selectedOniCount,
    werewolfCount: selectedWerewolfCount,
    accusationWeight: selectedAccusationWeight,
    quickPresetApplied: selectedQuickPreset,
  );
}

/// ルール設定シート内の折りたたみセクション。
class _SettingsSection extends StatelessWidget {
  const _SettingsSection({
    required this.title,
    required this.children,
    this.initiallyExpanded = false,
  });

  final String title;
  final List<Widget> children;
  final bool initiallyExpanded;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      clipBehavior: Clip.antiAlias,
      child: ExpansionTile(
        initiallyExpanded: initiallyExpanded,
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
        childrenPadding: const EdgeInsets.fromLTRB(0, 0, 0, 8),
        children: children,
      ),
    );
  }
}

/// 0〜12 のシンプルな増減ステッパー。
class _CountStepper extends StatelessWidget {
  const _CountStepper({
    required this.label,
    required this.value,
    required this.onChanged,
  });

  final String label;
  final int value;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Expanded(child: Text(label)),
          IconButton(
            visualDensity: VisualDensity.compact,
            onPressed: value > 0 ? () => onChanged(value - 1) : null,
            icon: const Icon(Icons.remove_circle_outline),
          ),
          SizedBox(
            width: 28,
            child: Text(
              '$value',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
          IconButton(
            visualDensity: VisualDensity.compact,
            onPressed: value < 12 ? () => onChanged(value + 1) : null,
            icon: const Icon(Icons.add_circle_outline),
          ),
        ],
      ),
    );
  }
}
