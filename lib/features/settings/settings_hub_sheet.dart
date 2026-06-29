import 'package:flutter/material.dart';

import '../audio/audio_settings_sheet.dart';
import '../../features/game_map/settings/player_personal_settings_models.dart';
import '../../presentation/world/world_presentation_context.dart';
import '../../presentation/world/world_ui_helpers.dart';
import '../../screens/data_management_screen.dart';
import '../../screens/personal_settings_screen.dart';
import '../../session/world_profile_prefs.dart';
import '../../theme/world_profile.dart';
import '../../widgets/scene_transitions.dart';

/// 個人設定・サウンド・データ管理をまとめた設定ハブ。
Future<void> showSettingsHubSheet(
  BuildContext context, {
  void Function(PlayerPersonalSettingsResult result)? onPersonalSettingsApplied,
  ValueChanged<WorldProfile>? onWorldProfileChanged,
  VoidCallback? onOpenDisplaySettings,
}) {
  final profile = context.worldProfile;
  return showWorldSheet<void>(
    context,
    profile: profile,
    builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(8, 4, 8, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 4, 12, 8),
                child: Text(
                  '設定',
                  style: Theme.of(ctx).textTheme.titleLarge?.copyWith(
                        color: ctx.worldPresentation.textOnScaffold,
                      ),
                ),
              ),
              ListTile(
                leading: Icon(
                  Icons.person_outline,
                  color: ctx.worldPresentation.accentOnScaffold,
                ),
                title: const Text('個人設定'),
                subtitle: const Text('プロフィール・鬼設定・プライバシー'),
                onTap: () async {
                  Navigator.pop(ctx);
                  final savedProfile = await WorldProfilePrefs.load();
                  if (!context.mounted) return;
                  final applied =
                      await AppNav.push<PlayerPersonalSettingsResult?>(
                    context,
                    (_) => PersonalSettingsScreen(
                      onWorldProfileChanged: onWorldProfileChanged,
                    ),
                    worldProfile: savedProfile,
                  );
                  if (applied != null) {
                    onPersonalSettingsApplied?.call(applied);
                  }
                },
              ),
              ListTile(
                leading: Icon(
                  Icons.graphic_eq_rounded,
                  color: ctx.worldPresentation.accentOnScaffold,
                ),
                title: const Text('サウンド'),
                subtitle: const Text('BGM・効果音の音量'),
                onTap: () async {
                  final audioProfile = await WorldProfilePrefs.load();
                  if (!ctx.mounted) return;
                  await showAudioSettingsSheet(
                    ctx,
                    worldProfile: audioProfile,
                  );
                },
              ),
              ListTile(
                leading: Icon(
                  Icons.storage_outlined,
                  color: ctx.worldPresentation.accentOnScaffold,
                ),
                title: const Text('データ管理'),
                subtitle: const Text('試合ギャラリー・軌跡保存'),
                onTap: () async {
                  Navigator.pop(ctx);
                  final dataProfile = await WorldProfilePrefs.load();
                  if (!context.mounted) return;
                  await AppNav.push<void>(
                    context,
                    (_) => const DataManagementScreen(),
                    worldProfile: dataProfile,
                  );
                },
              ),
              if (onOpenDisplaySettings != null)
                ListTile(
                  leading: Icon(
                    Icons.dashboard_customize_outlined,
                    color: ctx.worldPresentation.accentOnScaffold,
                  ),
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
      ),
  );
}
