import 'package:flutter/material.dart';

import '../audio/audio_settings_sheet.dart';
import '../onboarding/onboarding_replay_sheet.dart';
import '../game_map/widgets/how_to_play_sheet.dart';
import '../../game/player_role.dart';

/// サウンド・ガイド再視聴などを1か所にまとめた設定ハブ。
Future<void> showSettingsHubSheet(
  BuildContext context, {
  PlayerRole? yourRole,
  VoidCallback? onOpenPrivacy,
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
                leading: const Icon(Icons.graphic_eq_rounded),
                title: const Text('サウンド'),
                subtitle: const Text('BGM・効果音の音量'),
                onTap: () {
                  Navigator.pop(ctx);
                  showAudioSettingsSheet(context);
                },
              ),
              ListTile(
                leading: const Icon(Icons.replay_rounded),
                title: const Text('ガイド再視聴'),
                subtitle: const Text('かんたんガイド・コーチマーク'),
                onTap: () {
                  Navigator.pop(ctx);
                  showOnboardingReplaySheet(context);
                },
              ),
              ListTile(
                leading: const Icon(Icons.help_outline_rounded),
                title: const Text('遊び方'),
                subtitle: const Text('ルール・スキル・ギミック'),
                onTap: () {
                  Navigator.pop(ctx);
                  showHowToPlaySheet(context, yourRole: yourRole);
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
              if (onOpenPrivacy != null)
                ListTile(
                  leading: const Icon(Icons.privacy_tip_outlined),
                  title: const Text('プライバシー管理'),
                  onTap: () {
                    Navigator.pop(ctx);
                    onOpenPrivacy();
                  },
                ),
            ],
          ),
        ),
      );
    },
  );
}
