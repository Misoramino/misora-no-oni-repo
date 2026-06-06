import 'package:flutter/material.dart';

import '../../audio/game_audio.dart';
import '../../audio/sfx_id.dart';
import '../../game/player_role.dart';
import '../../widgets/app_dialog.dart';
import '../../widgets/scene_transitions.dart';
import '../game_map/widgets/role_briefing_dialog.dart';
import 'tutorial_sandbox_screen.dart';

/// 役職を選んでチュートリアル（サンドボックス）を始める。
Future<void> openTutorialPicker(BuildContext context) async {
  final role = await showAppDialog<PlayerRole>(
    context: context,
    builder: (ctx) {
      final theme = Theme.of(ctx);
      return AppDialog(
        title: 'チュートリアル',
        icon: Icons.school_rounded,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'どの役職を体験しますか？（GPS不要・1〜2分）',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 12),
            for (final role in PlayerRole.values) ...[
              _RolePickTile(
                role: role,
                onTap: () => Navigator.pop(ctx, role),
              ),
              const SizedBox(height: 8),
            ],
          ],
        ),
      );
    },
  );
  if (role == null || !context.mounted) return;
  await AppNav.push<void>(
    context,
    (_) => TutorialSandboxScreen(role: role),
    direction: SceneTransitionDirection.up,
  );
}

class _RolePickTile extends StatelessWidget {
  const _RolePickTile({required this.role, required this.onTap});

  final PlayerRole role;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accent = roleAccentColor(role);
    return Material(
      color: accent.withValues(alpha: 0.10),
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () {
          GameAudio.instance.playSfx(SfxId.uiConfirm);
          onTap();
        },
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: accent.withValues(alpha: 0.22),
                foregroundColor: accent,
                child: Icon(roleIcon(role)),
              ),
              const SizedBox(width: 12),
              Text(
                role.displayName,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              Icon(Icons.chevron_right_rounded,
                  color: theme.colorScheme.onSurfaceVariant),
            ],
          ),
        ),
      ),
    );
  }
}
