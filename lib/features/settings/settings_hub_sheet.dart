import 'package:flutter/material.dart';

import '../audio/audio_settings_sheet.dart';
import '../../features/game_map/settings/player_personal_settings_models.dart';
import '../../screens/data_management_screen.dart';
import '../../screens/personal_settings_screen.dart';
import '../../session/world_profile_prefs.dart';
import '../../widgets/scene_transitions.dart';

/// 個人設定・サウンド・データ管理をまとめた設定ハブ。
Future<void> showSettingsHubSheet(
  BuildContext context, {
  void Function(PlayerPersonalSettingsResult result)? onPersonalSettingsApplied,
  VoidCallback? onOpenDisplaySettings,
}) {
  return showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    builder: (ctx) {
      final theme = Theme.of(ctx);
      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(8, 4, 8, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 4, 12, 8),
                child: Text('設定', style: theme.textTheme.titleLarge),
              ),
              ListTile(
                leading: const Icon(Icons.person_outline),
                title: const Text('個人設定'),
                subtitle: const Text('プロフィール・鬼設定・プライバシー'),
                onTap: () async {
                  Navigator.pop(ctx);
                  final profile = await WorldProfilePrefs.load();
                  if (!context.mounted) return;
                  final applied =
                      await AppNav.push<PlayerPersonalSettingsResult?>(
                    context,
                    (_) => const PersonalSettingsScreen(),
                    worldProfile: profile,
                  );
                  if (applied != null) {
                    onPersonalSettingsApplied?.call(applied);
                  }
                },
              ),
              ListTile(
                leading: const Icon(Icons.graphic_eq_rounded),
                title: const Text('サウンド'),
                subtitle: const Text('BGM・効果音の音量'),
                onTap: () async {
                  final profile = await WorldProfilePrefs.load();
                  if (!ctx.mounted) return;
                  await showAudioSettingsSheet(
                    ctx,
                    worldProfile: profile,
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.storage_outlined),
                title: const Text('データ管理'),
                subtitle: const Text('試合ギャラリー・軌跡保存'),
                onTap: () async {
                  Navigator.pop(ctx);
                  final profile = await WorldProfilePrefs.load();
                  if (!context.mounted) return;
                  await AppNav.push<void>(
                    context,
                    (_) => const DataManagementScreen(),
                    worldProfile: profile,
                  );
                },
              ),
              if (onOpenDisplaySettings != null)
                ListTile(
                  leading: const Icon(Icons.dashboard_customize_outlined),
                  title: const Text('HUD・地図表示'),
                  subtitle: const Text('試合中の表示項目'),
                  onTap: () {
                    Navigator.pop(ctx);
                    onOpenDisplaySettings();
                  },
                ),
            ],
          ),
        ),
      );
    },
  );
}
