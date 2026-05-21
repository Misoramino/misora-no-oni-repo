import 'dart:io';

import 'package:flutter/material.dart';

import '../../../theme/map_hud_contrast.dart';

/// 準備画面の「個人設定」サマリー（名前・アイコンタップで詳細へ）。
class PrepPersonalTile extends StatelessWidget {
  const PrepPersonalTile({
    required this.displayName,
    required this.avatarImagePath,
    required this.prepLegibility,
    required this.onOpenSettings,
    super.key,
  });

  final String displayName;
  final String? avatarImagePath;
  final MapHudPrepLegibility prepLegibility;
  final VoidCallback onOpenSettings;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final leg = prepLegibility;

    Widget avatar() {
      const radius = 22.0;
      if (avatarImagePath != null && avatarImagePath!.isNotEmpty) {
        final file = File(avatarImagePath!);
        if (file.existsSync()) {
          return CircleAvatar(
            radius: radius,
            backgroundImage: FileImage(file),
          );
        }
      }
      return CircleAvatar(
        radius: radius,
        backgroundColor: leg.tileIcon.withValues(alpha: 0.18),
        child: Icon(Icons.person, color: leg.tileIcon, size: 24),
      );
    }

    return Material(
      color: leg.tileSurface,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: onOpenSettings,
        borderRadius: BorderRadius.circular(10),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 10, 8, 10),
          child: Row(
            children: [
              avatar(),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '個人設定',
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: leg.tileTitle,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      displayName.isEmpty ? '（名前未設定）' : displayName,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: leg.tileValue,
                      ),
                    ),
                    Text(
                      '名前・写真をタップ / 展開で BLE など',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: leg.muted,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: leg.tileMutedIcon),
            ],
          ),
        ),
      ),
    );
  }
}
