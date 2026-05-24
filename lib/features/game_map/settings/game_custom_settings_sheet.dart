import 'dart:async';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../game/elimination_aftermath_rule.dart';
import '../../../game/game_config.dart';
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
                      Text('カスタム設定', style: Theme.of(ctx).textTheme.titleLarge),
                      Text(
                        '役職・スキル・ルール。個人設定は準備画面から。',
                        style: Theme.of(ctx).textTheme.bodySmall?.copyWith(
                          color: Theme.of(ctx).colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'ルーム共有',
                        style: Theme.of(ctx).textTheme.titleSmall,
                      ),
                      if (!isHost)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 6, top: 2),
                          child: Text(
                            'ホストのみ編集。開放中は参加者も一部変更可。',
                            style: Theme.of(ctx).textTheme.bodySmall?.copyWith(
                              color: Theme.of(ctx).colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ),
                      if (isHost)
                        SwitchListTile(
                          contentPadding: EdgeInsets.zero,
                          title: const Text('参加者にカスタムルール編集を許可'),
                          subtitle: const Text('時間・エリアは準備画面'),
                          value: selectedParticipantRulesOpen,
                          onChanged: (v) => setModalState(
                            () => selectedParticipantRulesOpen = v,
                          ),
                        ),
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
                        title: const Text('カスタム公開ルール'),
                        subtitle: const Text('オフ時は開始時にランダム割当'),
                        value: selectedCustomRuleMode,
                        onChanged: (isHost || selectedParticipantRulesOpen)
                            ? (v) => setModalState(
                                () => selectedCustomRuleMode = v,
                              )
                            : null,
                      ),
                      Text(
                        '制限時間: ${selectedDurationMinutes.round()} 分',
                        style: Theme.of(ctx).textTheme.titleSmall,
                      ),
                      const Text(
                        '準備画面と同じ設定（上級者向け）',
                        style: TextStyle(fontSize: 12),
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
                          'ギミック密度: ${selectedGimmickDensity.toStringAsFixed(2)}',
                          style: Theme.of(ctx).textTheme.titleSmall,
                        ),
                        Text(
                          '安全地帯・情報屋・監視カメラ・イベントエリアの個数に掛けられます（次の試合開始で全員に同じ配置が適用されます）。',
                          style: Theme.of(ctx).textTheme.bodySmall?.copyWith(
                                color: Theme.of(ctx).colorScheme.onSurfaceVariant,
                              ),
                        ),
                        Tooltip(
                          message:
                              '低いほどマップがすっきり、高いほどギミックが増えます（試合開始時にホストが同期した値が使われます）。',
                          child: Slider(
                            min: 0.45,
                            max: 1.55,
                            divisions: 22,
                            value: selectedGimmickDensity.clamp(0.45, 1.55),
                            onChanged: (v) => setModalState(
                              () => selectedGimmickDensity = v.clamp(0.45, 1.55),
                            ),
                          ),
                        ),
                      ],
                      const SizedBox(height: 10),
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
                      const SizedBox(height: 10),
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: Icon(
                          Icons.cloud_outlined,
                          color: Theme.of(ctx).colorScheme.primary,
                        ),
                        title: const Text('オンラインルーム'),
                        subtitle: Text(
                          '参加・メンバー一覧は「タイトル」画面のオンラインルーム、'
                          'またはゲーム画面上部の Lobby から行います。'
                          'ホームに戻るとルームから退出した扱いになります。',
                          style: Theme.of(ctx).textTheme.bodySmall?.copyWith(
                                height: 1.35,
                              ),
                        ),
                      ),
                      if (!FirebaseBootstrap.isReady &&
                          FirebaseBootstrap.lastErrorBrief != null)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: SelectableText(
                            FirebaseBootstrap.lastErrorBrief!,
                            style: TextStyle(
                              fontSize: 11,
                              color: Theme.of(ctx).colorScheme.error,
                            ),
                          ),
                        ),
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: Icon(
                          Icons.nightlight_round,
                          color: Theme.of(ctx).colorScheme.primary,
                        ),
                        title: const Text('鬼ロール・鬼向け通知'),
                        subtitle: const Text(
                          'AppBar の「鬼コンソール」アイコンから設定します（バイブ・サウンド等）。',
                        ),
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
                            label: const Text('ゲーム設定をデフォルトに戻す'),
                          ),
                        ),
                      if (isHost && onRequestGameDefaultsReset != null)
                        const SizedBox(height: 8),
                      Align(
                        alignment: Alignment.centerRight,
                        child: FilledButton(
                          onPressed: () => Navigator.pop(ctx, true),
                          child: const Text('適用'),
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

  return GameCustomSettingsResult(
    oniIntelMode: selectedIntel,
    eliminationAftermathRule: selectedElimination,
    localRole: selectedRole,
    customRuleMode: selectedCustomRuleMode,
    participantRulesOpen: selectedParticipantRulesOpen,
    matchDurationMinutes: selectedDurationMinutes,
    skillLoadout: selectedSkills,
    gimmickDensity: selectedGimmickDensity,
  );
}
