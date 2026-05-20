import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../game/elimination_aftermath_rule.dart';
import '../../../game/game_config.dart';
import '../../../game/oni_intel_mode.dart';
import '../../../game/player_role.dart';
import '../../../game/skill_ids.dart';
import '../../../session/avatar_image_store.dart';
import '../../../session/game_map_prefs.dart';
import '../../../session/world_profile_prefs.dart';
import '../../../sync/firebase_bootstrap.dart';
import '../../../theme/world_profile.dart';
import '../../../theme/world_visual_pack_factory.dart';
import 'game_custom_settings_models.dart';

typedef JoinFirestoreRoomCallback =
    Future<String?> Function({
      required String roomId,
      required String nickname,
      required String role,
    });

/// カスタム設定ボトムシート。適用で [GameCustomSettingsResult]、キャンセルで null。
Future<GameCustomSettingsResult?> showGameCustomSettingsSheet({
  required BuildContext context,
  required GameCustomSettingsInitial initial,
  required bool isHost,
  required JoinFirestoreRoomCallback onJoinRoom,
  required Future<void> Function() onLeaveRoom,
  Future<void> Function()? onRequestGameDefaultsReset,
}) async {
  WorldProfile selectedProfile = initial.profile;
  OniIntelMode selectedIntel = initial.oniIntelMode;
  bool selectedConsent = initial.trajectoryConsent;
  EliminationAftermathRule selectedElimination =
      initial.eliminationAftermathRule;
  PlayerRole selectedRole = initial.localRole;
  bool selectedCustomRuleMode = initial.customRuleMode;
  var selectedParticipantRulesOpen = initial.participantRulesOpen;
  double selectedDurationMinutes = initial.matchDurationMinutes;
  final selectedSkills = Set<String>.from(initial.skillLoadout);
  var selectedUseBle = initial.useBleScan;
  var selectedAvatarPath = initial.avatarImagePath;
  var selectedGimmickDensity = initial.gimmickDensity.clamp(0.45, 1.55);
  final roomController = TextEditingController();
  final nickController = TextEditingController(text: 'player1');
  var firebaseWarmScheduled = false;

  bool? ok;
  try {
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
            final messenger = ScaffoldMessenger.of(ctx);
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
                        '個人向け（端末）とホスト向け（ルーム共有）に分けています。',
                        style: Theme.of(ctx).textTheme.bodySmall?.copyWith(
                          color: Theme.of(ctx).colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        '個人向け（この端末）',
                        style: Theme.of(ctx).textTheme.titleSmall,
                      ),
                      DropdownButtonFormField<WorldProfile>(
                        initialValue: selectedProfile,
                        decoration: const InputDecoration(labelText: '世界観'),
                        items: WorldProfile.values
                            .map(
                              (p) => DropdownMenuItem(
                                value: p,
                                child: Text(p.label),
                              ),
                            )
                            .toList(),
                        onChanged: (v) {
                          if (v == null) return;
                          setModalState(() => selectedProfile = v);
                        },
                      ),
                      const SizedBox(height: 8),
                      if (selectedAvatarPath != null &&
                          selectedAvatarPath!.isNotEmpty)
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.file(
                            File(selectedAvatarPath!),
                            height: 72,
                            width: 72,
                            fit: BoxFit.cover,
                            errorBuilder: (_, _, _) => const SizedBox(
                              height: 72,
                              width: 72,
                              child: Icon(Icons.broken_image_outlined),
                            ),
                          ),
                        ),
                      if (selectedAvatarPath != null &&
                          selectedAvatarPath!.isNotEmpty)
                        const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () async {
                                final file = await ImagePicker().pickImage(
                                  source: ImageSource.gallery,
                                  maxWidth: 512,
                                  maxHeight: 512,
                                  imageQuality: 85,
                                );
                                if (file == null) return;
                                final stored =
                                    await AvatarImageStore.persistFromPicker(
                                      file.path,
                                    );
                                setModalState(
                                  () => selectedAvatarPath = stored,
                                );
                              },
                              icon: const Icon(Icons.photo_camera_outlined),
                              label: const Text('ピン用写真を選ぶ'),
                            ),
                          ),
                          if (selectedAvatarPath != null &&
                              selectedAvatarPath!.isNotEmpty)
                            IconButton(
                              tooltip: '写真をクリア',
                              onPressed: () => setModalState(
                                () => selectedAvatarPath = null,
                              ),
                              icon: const Icon(Icons.close),
                            ),
                        ],
                      ),
                      Text(
                        _photoPinHelperText(selectedProfile),
                        style: Theme.of(ctx).textTheme.bodySmall,
                      ),
                      const SizedBox(height: 10),
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('実機 BLE スキャン（近接推定）'),
                        subtitle: const Text(
                          'オフ時はモック BLE。Android では Bluetooth 権限が必要です。',
                        ),
                        value: selectedUseBle,
                        onChanged: (v) =>
                            setModalState(() => selectedUseBle = v),
                      ),
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('軌跡を端末保存（同意）'),
                        value: selectedConsent,
                        onChanged: (v) =>
                            setModalState(() => selectedConsent = v),
                      ),
                      const Divider(height: 28),
                      Text(
                        'ホスト向け・ルーム共有',
                        style: Theme.of(ctx).textTheme.titleSmall,
                      ),
                      if (!isHost)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 6, top: 2),
                          child: Text(
                            '試合時間・共有ルール・脱落後ルールはホストのみ変更できます。「参加者にルール編集を許可」がオンなら、開かれた項目も調整できます。',
                            style: Theme.of(ctx).textTheme.bodySmall?.copyWith(
                              color: Theme.of(ctx).colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ),
                      if (isHost)
                        SwitchListTile(
                          contentPadding: EdgeInsets.zero,
                          title: const Text('参加者にカスタムルール編集を許可'),
                          subtitle: const Text(
                            '役職固定・スキル・脱落ルールなど。制限時間とエリアはホストが準備画面で設定',
                          ),
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
                              '情報屋で入手する鬼の手がかりの出し方。未設定時は方角のみ・距離帯のみ・断片のいずれかがランダム相当で切り替わります。「断片」は約${GameConfig.fragmentedPhaseSeconds}秒ごとにフェーズが変わります。',
                          helperMaxLines: 4,
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
                          helperText: 'カスタム公開ルールON時だけ固定されます',
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
                        subtitle: const Text('オフ時は開始時に役職/スキル/ルールを秘密ランダム割当'),
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
                        'ホストは準備画面のスライダーで変更するのが基本です。ここは上級者向けの同じ設定です。',
                        style: TextStyle(fontSize: 12),
                      ),
                      Slider(
                        min: 1,
                        max: 20,
                        divisions: 19,
                        value: selectedDurationMinutes.clamp(1, 20),
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
                      ExpansionTile(
                        initiallyExpanded: true,
                        tilePadding: EdgeInsets.zero,
                        title: const Text('オンラインルーム（Firestore）'),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              FirebaseBootstrap.isReady
                                  ? '接続済み ・ 下のボタンでルームに参加できます'
                                  : '未接続 ・ 「参加」で Firebase を再初期化します',
                              style: Theme.of(ctx).textTheme.bodySmall,
                            ),
                            Text(
                              'まだ誰も使っていないルームIDで参加すると、Firestore に rooms と members が作成されます。',
                              style: Theme.of(ctx).textTheme.bodySmall
                                  ?.copyWith(
                                    fontSize: 11,
                                    color: Theme.of(
                                      ctx,
                                    ).colorScheme.onSurfaceVariant,
                                  ),
                            ),
                          ],
                        ),
                        children: [
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
                          TextField(
                            controller: roomController,
                            textInputAction: TextInputAction.next,
                            decoration: const InputDecoration(
                              labelText: 'ルームID',
                              hintText: '例: demo-room-1',
                              border: OutlineInputBorder(),
                              isDense: true,
                            ),
                          ),
                          const SizedBox(height: 8),
                          TextField(
                            controller: nickController,
                            textInputAction: TextInputAction.done,
                            decoration: const InputDecoration(
                              labelText: '表示名',
                              border: OutlineInputBorder(),
                              isDense: true,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: FilledButton(
                                  style: FilledButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 14,
                                    ),
                                  ),
                                  onPressed: () async {
                                    FocusScope.of(ctx).unfocus();
                                    await FirebaseBootstrap.tryInit();
                                    if (!ctx.mounted) return;
                                    setModalState(() {});
                                    if (!FirebaseBootstrap.isReady) {
                                      messenger.showSnackBar(
                                        SnackBar(
                                          content: Text(
                                            'Firebase に接続できません。\n\n'
                                            '1) android/app/google-services.json を配置してフル再ビルド\n'
                                            '2) または dart-define で FIREBASE_* を指定\n\n'
                                            '${FirebaseBootstrap.lastErrorBrief ?? ""}',
                                          ),
                                          behavior: SnackBarBehavior.floating,
                                          margin: const EdgeInsets.fromLTRB(
                                            16,
                                            0,
                                            16,
                                            220,
                                          ),
                                          duration: const Duration(seconds: 10),
                                        ),
                                      );
                                      return;
                                    }
                                    final rid = roomController.text.trim();
                                    final nick = nickController.text.trim();
                                    if (rid.isEmpty || nick.isEmpty) {
                                      messenger.showSnackBar(
                                        const SnackBar(
                                          behavior: SnackBarBehavior.floating,
                                          margin: EdgeInsets.fromLTRB(
                                            16,
                                            0,
                                            16,
                                            220,
                                          ),
                                          content: Text('ルームIDと表示名を入力してください'),
                                        ),
                                      );
                                      return;
                                    }
                                    showDialog<void>(
                                      context: ctx,
                                      barrierDismissible: false,
                                      useRootNavigator: true,
                                      builder: (dCtx) => const AlertDialog(
                                        content: Row(
                                          children: [
                                            CircularProgressIndicator(),
                                            SizedBox(width: 16),
                                            Expanded(
                                              child: Text('ルームに参加しています…'),
                                            ),
                                          ],
                                        ),
                                      ),
                                    );
                                    String? err;
                                    try {
                                      err = await onJoinRoom(
                                        roomId: rid,
                                        nickname: nick,
                                        role: 'runner',
                                      );
                                    } finally {
                                      if (ctx.mounted) {
                                        Navigator.of(
                                          ctx,
                                          rootNavigator: true,
                                        ).pop();
                                      }
                                    }
                                    if (!ctx.mounted) return;
                                    if (err != null) {
                                      messenger.showSnackBar(
                                        SnackBar(
                                          content: Text(err),
                                          behavior: SnackBarBehavior.floating,
                                          margin: const EdgeInsets.fromLTRB(
                                            16,
                                            0,
                                            16,
                                            220,
                                          ),
                                          duration: const Duration(seconds: 10),
                                        ),
                                      );
                                    } else {
                                      await showDialog<void>(
                                        context: ctx,
                                        builder: (dCtx) => AlertDialog(
                                          icon: Icon(
                                            Icons.check_circle,
                                            color: Theme.of(
                                              dCtx,
                                            ).colorScheme.primary,
                                            size: 40,
                                          ),
                                          title: const Text('ルームに接続しました'),
                                          content: SingleChildScrollView(
                                            child: Text(
                                              'ルームID「$rid」への参加が完了しました。\n\n'
                                              'Firestore では次のパスにメンバーが作成されています。\n'
                                              'rooms / $rid / members / （あなたの UID）\n\n'
                                              'このシートの「適用」で閉じたあと、地図画面で「開始」から鬼ごっこを始められます。',
                                            ),
                                          ),
                                          actions: [
                                            FilledButton(
                                              onPressed: () =>
                                                  Navigator.pop(dCtx),
                                              child: const Text('OK'),
                                            ),
                                          ],
                                        ),
                                      );
                                    }
                                    if (ctx.mounted) setModalState(() {});
                                  },
                                  child: const Text('ルームに参加'),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: OutlinedButton(
                                  style: OutlinedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 14,
                                    ),
                                  ),
                                  onPressed: () async {
                                    FocusScope.of(ctx).unfocus();
                                    await onLeaveRoom();
                                    if (!ctx.mounted) return;
                                    setModalState(() {});
                                    messenger.showSnackBar(
                                      const SnackBar(
                                        behavior: SnackBarBehavior.floating,
                                        margin: EdgeInsets.fromLTRB(
                                          16,
                                          0,
                                          16,
                                          220,
                                        ),
                                        content: Text('オフラインに戻しました'),
                                      ),
                                    );
                                  },
                                  child: const Text('退出'),
                                ),
                              ),
                            ],
                          ),
                        ],
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
  } finally {
    roomController.dispose();
    nickController.dispose();
  }

  if (ok != true) return null;

  await WorldProfilePrefs.save(selectedProfile);

  final prefs = await SharedPreferences.getInstance();
  await prefs.setString(
    GameMapPrefs.eliminationAftermathRule,
    selectedElimination.name,
  );
  await prefs.setBool(GameMapPrefs.useBleScanProximity, selectedUseBle);
  await prefs.setDouble(GameMapPrefs.gimmickDensity, selectedGimmickDensity);
  if (selectedAvatarPath != null && selectedAvatarPath!.isNotEmpty) {
    await prefs.setString(GameMapPrefs.avatarImagePath, selectedAvatarPath!);
  } else {
    await prefs.remove(GameMapPrefs.avatarImagePath);
    await AvatarImageStore.deleteStored();
  }

  return GameCustomSettingsResult(
    profile: selectedProfile,
    oniIntelMode: selectedIntel,
    trajectoryConsent: selectedConsent,
    eliminationAftermathRule: selectedElimination,
    localRole: selectedRole,
    customRuleMode: selectedCustomRuleMode,
    participantRulesOpen: selectedParticipantRulesOpen,
    matchDurationMinutes: selectedDurationMinutes,
    skillLoadout: selectedSkills,
    useBleScan: selectedUseBle,
    avatarImagePath: selectedAvatarPath,
    gimmickDensity: selectedGimmickDensity,
  );
}

String _photoPinHelperText(WorldProfile profile) {
  final pack = WorldVisualPackFactory.of(profile);
  final base = '写真はこの端末だけに保存（Firestore には送りません）。';
  if (pack.showPhotoPinByDefault && !pack.photoOnlyOnReveal) {
    return '$base ${profile.label} では常時写真ピンを表示します。';
  }
  if (pack.photoOnlyOnReveal) {
    return '$base ${profile.label} では位置暴露後のみ写真ピンを表示します。';
  }
  return '$base この世界観では位置暴露後に写真ピンが使えます。';
}
