import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../../session/avatar_image_store.dart';
import '../../../session/world_profile_prefs.dart';
import '../../../theme/world_profile.dart';
import '../../../theme/world_visual_pack_factory.dart';
import 'player_personal_settings_models.dart';

Future<PlayerPersonalSettingsResult?> showPlayerPersonalSettingsSheet({
  required BuildContext context,
  required PlayerPersonalSettingsInitial initial,
}) async {
  final nameController = TextEditingController(text: initial.displayName);
  var selectedProfile = initial.profile;
  var selectedUseBle = initial.useBleScan;
  var selectedConsent = initial.trajectoryConsent;
  var selectedAvatarPath = initial.avatarImagePath;
  var deviceExpanded = false;

  bool? ok;
  ok = await showModalBottomSheet<bool>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (ctx) {
      return StatefulBuilder(
        builder: (ctx, setModal) {
          final kb = MediaQuery.viewInsetsOf(ctx).bottom;
          final screenH = MediaQuery.sizeOf(ctx).height;
          final sheetH = (screenH * 0.82 - kb).clamp(320.0, screenH * 0.92);

          Widget avatarWidget() {
            if (selectedAvatarPath != null && selectedAvatarPath!.isNotEmpty) {
              return ClipOval(
                child: Image.file(
                  File(selectedAvatarPath!),
                  width: 88,
                  height: 88,
                  fit: BoxFit.cover,
                  errorBuilder: (_, _, _) => const CircleAvatar(
                    radius: 44,
                    child: Icon(Icons.broken_image_outlined, size: 36),
                  ),
                ),
              );
            }
            return CircleAvatar(
              radius: 44,
              child: Icon(
                Icons.person_outline,
                size: 44,
                color: Theme.of(ctx).colorScheme.onPrimaryContainer,
              ),
            );
          }

          return Padding(
            padding: EdgeInsets.fromLTRB(16, 8, 16, 16 + kb),
            child: SizedBox(
              height: sheetH,
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      '個人設定',
                      style: Theme.of(ctx).textTheme.titleLarge,
                    ),
                    Text(
                      'この端末だけの設定です。',
                      style: Theme.of(ctx).textTheme.bodySmall?.copyWith(
                            color: Theme.of(ctx).colorScheme.onSurfaceVariant,
                          ),
                    ),
                    const SizedBox(height: 20),
                    Center(
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          customBorder: const CircleBorder(),
                          onTap: () async {
                            final file = await ImagePicker().pickImage(
                              source: ImageSource.gallery,
                              maxWidth: 512,
                              maxHeight: 512,
                              imageQuality: 85,
                            );
                            if (file == null) return;
                            final stored = await AvatarImageStore.persistFromPicker(
                              file.path,
                            );
                            setModal(() => selectedAvatarPath = stored);
                          },
                          child: avatarWidget(),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Center(
                      child: TextButton.icon(
                        onPressed: () async {
                          final file = await ImagePicker().pickImage(
                            source: ImageSource.gallery,
                            maxWidth: 512,
                            maxHeight: 512,
                            imageQuality: 85,
                          );
                          if (file == null) return;
                          final stored = await AvatarImageStore.persistFromPicker(
                            file.path,
                          );
                          setModal(() => selectedAvatarPath = stored);
                        },
                        icon: const Icon(Icons.photo_camera_outlined),
                        label: const Text('ピン用の写真を変更'),
                      ),
                    ),
                    if (selectedAvatarPath != null && selectedAvatarPath!.isNotEmpty)
                      Align(
                        alignment: Alignment.center,
                        child: TextButton(
                          onPressed: () => setModal(() => selectedAvatarPath = null),
                          child: const Text('写真をクリア'),
                        ),
                      ),
                    Text(
                      _photoPinHelperText(selectedProfile),
                      textAlign: TextAlign.center,
                      style: Theme.of(ctx).textTheme.bodySmall,
                    ),
                    const SizedBox(height: 20),
                    Text(
                      '表示名',
                      style: Theme.of(ctx).textTheme.labelLarge,
                    ),
                    const SizedBox(height: 6),
                    TextField(
                      controller: nameController,
                      textInputAction: TextInputAction.done,
                      decoration: const InputDecoration(
                        hintText: 'ルームで表示される名前',
                        border: OutlineInputBorder(),
                      ),
                      onTap: () => setModal(() {}),
                    ),
                    const SizedBox(height: 16),
                    ExpansionTile(
                      initiallyExpanded: deviceExpanded,
                      onExpansionChanged: (v) =>
                          setModal(() => deviceExpanded = v),
                      title: const Text('端末・近接'),
                      subtitle: const Text('BLE・軌跡保存など'),
                      children: [
                        SwitchListTile(
                          contentPadding: const EdgeInsets.only(left: 8),
                          title: const Text('実機 BLE スキャン（近接推定）'),
                          subtitle: const Text(
                            'オン: 同一ルーム端末のみ検出。オフ: GPS中心（開発テスト時のみモック）',
                          ),
                          value: selectedUseBle,
                          onChanged: (v) => setModal(() => selectedUseBle = v),
                        ),
                        SwitchListTile(
                          contentPadding: const EdgeInsets.only(left: 8),
                          title: const Text('軌跡を端末保存（同意）'),
                          value: selectedConsent,
                          onChanged: (v) => setModal(() => selectedConsent = v),
                        ),
                      ],
                    ),
                    ExpansionTile(
                      title: const Text('見た目'),
                      subtitle: Text(selectedProfile.label),
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: DropdownButtonFormField<WorldProfile>(
                            initialValue: selectedProfile,
                            decoration: const InputDecoration(
                              labelText: '世界観',
                              border: OutlineInputBorder(),
                            ),
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
                              setModal(() => selectedProfile = v);
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    FilledButton(
                      onPressed: () {
                        final name = nameController.text.trim();
                        if (name.isEmpty) {
                          ScaffoldMessenger.of(ctx).showSnackBar(
                            const SnackBar(content: Text('表示名を入力してください')),
                          );
                          return;
                        }
                        Navigator.pop(ctx, true);
                      },
                      child: const Text('適用'),
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

  if (ok != true) {
    nameController.dispose();
    return null;
  }

  final displayName = nameController.text.trim();
  nameController.dispose();
  await WorldProfilePrefs.save(selectedProfile);

  return PlayerPersonalSettingsResult(
    displayName: displayName,
    profile: selectedProfile,
    useBleScan: selectedUseBle,
    trajectoryConsent: selectedConsent,
    avatarImagePath: selectedAvatarPath,
  );
}

String _photoPinHelperText(WorldProfile profile) {
  final pack = WorldVisualPackFactory.of(profile);
  const base =
      '選んだ写真は自動で縮小して保存されます。オンライン中は保存時にルームへ共有し、';
  if (pack.photoOnlyOnReveal || !pack.showPhotoPinByDefault) {
    return '$base 名前付き暴露時に他プレイヤーにも写真ピンで表示（試合後に追加した場合も再保存で反映）。';
  }
  return '$base 自分のピンと名前付き暴露時に他プレイヤーへ表示（後から追加した場合も再保存で反映）。';
}
