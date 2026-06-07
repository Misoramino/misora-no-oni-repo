import 'package:flutter/material.dart';

/// 端末ローカルの個人設定ハブ（三点リーダーから）。
Future<void> showPersonalSettingsHubSheet(
  BuildContext context, {
  required VoidCallback onOpenProfile,
  required VoidCallback onOpenOniSettings,
  required VoidCallback onOpenPrivacy,
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
                padding: const EdgeInsets.fromLTRB(12, 4, 12, 4),
                child: Text('個人設定', style: theme.textTheme.titleLarge),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                child: Text(
                  'この端末だけに保存されます。ルーム全体のルールは準備画面の「ルール・役職」から。',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
              ListTile(
                leading: const Icon(Icons.person_outline),
                title: const Text('プロフィール'),
                subtitle: const Text('表示名・写真・世界観・BLE・軌跡保存'),
                onTap: () {
                  Navigator.pop(ctx);
                  onOpenProfile();
                },
              ),
              ListTile(
                leading: const Icon(Icons.nightlight_round),
                title: const Text('鬼設定'),
                subtitle: const Text('鬼役の端末向け（近接・演出）'),
                onTap: () {
                  Navigator.pop(ctx);
                  onOpenOniSettings();
                },
              ),
              ListTile(
                leading: const Icon(Icons.privacy_tip_outlined),
                title: const Text('プライバシー管理'),
                subtitle: const Text('位置・データの取り扱い'),
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
