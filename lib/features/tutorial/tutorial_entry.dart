import 'package:flutter/material.dart';

import '../../audio/game_audio.dart';
import '../../audio/sfx_id.dart';
import '../../game/elimination_aftermath_rule.dart';
import '../../game/player_role.dart';
import '../../session/onboarding_prefs.dart';
import '../../widgets/app_dialog.dart';
import '../../widgets/scene_transitions.dart';
import '../game_map/widgets/how_to_play_sheet.dart';
import '../game_map/widgets/role_briefing_dialog.dart';
import '../how_to_play/guide_terms.dart';
import 'second_game_tutorial_kind.dart';
import 'second_game_tutorial_screen.dart';
import 'tutorial_copy.dart';
import 'tutorial_sandbox_screen.dart';

/// 役職または脱落後を選んでチュートリアル（サンドボックス）を始める。
Future<void> openTutorialPicker(BuildContext context) async {
  final pick = await showAppDialog<_TutorialPick>(
    context: context,
    builder: (ctx) {
      final theme = Theme.of(ctx);
      return AppDialog(
        title: 'チュートリアル',
        icon: Icons.school_rounded,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'GPS不要・各約1分。終了後は作戦マニュアルへ進めます。',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  height: 1.45,
                ),
              ),
              const SizedBox(height: 14),
              Text(
                '役職チュートリアル',
                style: theme.textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              for (final role in PlayerRole.values) ...[
                _RolePickTile(
                  role: role,
                  onTap: () => Navigator.pop(ctx, _TutorialPick.role(role)),
                ),
                const SizedBox(height: 8),
              ],
              const SizedBox(height: 8),
              Text(
                '脱落後チュートリアル',
                style: theme.textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '脱落しても${GuideTerms.secondGame}で勝敗に関われます。',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 8),
              for (final kind in SecondGameTutorialKind.values) ...[
                _SecondGamePickTile(
                  kind: kind,
                  onTap: () => Navigator.pop(ctx, _TutorialPick.secondGame(kind)),
                ),
                const SizedBox(height: 8),
              ],
              const Divider(height: 28),
              TextButton.icon(
                onPressed: () {
                  Navigator.pop(ctx);
                  showHowToPlaySheet(context);
                },
                icon: const Icon(Icons.menu_book_outlined),
                label: const Text('作戦マニュアルを見る'),
              ),
            ],
          ),
        ),
      );
    },
  );
  if (pick == null || !context.mounted) return;

  switch (pick) {
    case _TutorialPickRole(:final role):
      await openRoleTutorial(context, role);
    case _TutorialPickSecondGame(:final kind):
      await openSecondGameTutorial(context, kind);
  }
}

/// 役職チュートリアル（サンドボックス）を開く。
Future<void> openRoleTutorial(BuildContext context, PlayerRole role) {
  return AppNav.push<void>(
    context,
    (_) => TutorialSandboxScreen(role: role),
    direction: SceneTransitionDirection.up,
  );
}

/// 脱落後チュートリアルを開く。
Future<void> openSecondGameTutorial(
  BuildContext context,
  SecondGameTutorialKind kind,
) {
  return AppNav.push<void>(
    context,
    (_) => SecondGameTutorialScreen(kind: kind),
    direction: SceneTransitionDirection.up,
  );
}

/// 初回脱落時に第二ゲームチュートリアルへ誘導する（1種別につき1回）。
Future<void> offerSecondGameTutorialIfNeeded(
  BuildContext context, {
  required EliminationAftermathRule rule,
}) async {
  final kind = secondGameTutorialKindForRule(rule);
  if (kind == null) return;
  final offerKey = OnboardingPrefs.secondGameTutorialOfferKeyFor(kind.name);
  if (await OnboardingPrefs.secondGameTutorialOfferSeen(offerKey)) return;
  if (!context.mounted) return;

  final title = TutorialCopyCatalog.secondGameTutorialTitle(kind);
  final practice = await showAppDialog<bool>(
    context: context,
    builder: (ctx) {
      final theme = Theme.of(ctx);
      return AppDialog(
        title: '第二ゲームを練習',
        icon: Icons.school_outlined,
        actions: [
          AppDialogAction(
            label: 'あとで',
            filled: false,
            onPressed: () => Navigator.pop(ctx, false),
          ),
          AppDialogAction(
            label: '練習する',
            onPressed: () => Navigator.pop(ctx, true),
          ),
        ],
        child: Text(
          '脱落は終わりではありません。約1分で$titleの操作を体験できます。',
          style: theme.textTheme.bodyMedium?.copyWith(height: 1.45),
        ),
      );
    },
  );
  await OnboardingPrefs.markSecondGameTutorialOfferSeen(offerKey);
  if (practice == true && context.mounted) {
    await openSecondGameTutorial(context, kind);
  }
}

sealed class _TutorialPick {
  const _TutorialPick();
  const factory _TutorialPick.role(PlayerRole role) = _TutorialPickRole;
  const factory _TutorialPick.secondGame(SecondGameTutorialKind kind) =
      _TutorialPickSecondGame;
}

final class _TutorialPickRole extends _TutorialPick {
  const _TutorialPickRole(this.role);
  final PlayerRole role;
}

final class _TutorialPickSecondGame extends _TutorialPick {
  const _TutorialPickSecondGame(this.kind);
  final SecondGameTutorialKind kind;
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

class _SecondGamePickTile extends StatelessWidget {
  const _SecondGamePickTile({required this.kind, required this.onTap});

  final SecondGameTutorialKind kind;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accent = secondGameTutorialAccent(kind);
    final label = TutorialCopyCatalog.secondGameTutorialTitle(kind);
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
                child: Icon(secondGameTutorialIcon(kind)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      kind == SecondGameTutorialKind.echoForm
                          ? '人側脱落後'
                          : '鬼側脱落後',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right_rounded,
                  color: theme.colorScheme.onSurfaceVariant),
            ],
          ),
        ),
      ),
    );
  }
}
