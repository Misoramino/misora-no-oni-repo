import 'package:flutter/material.dart';

import '../../session/onboarding_prefs.dart';
import '../../widgets/app_dialog.dart';
import 'welcome_flow.dart';

/// かんたんガイド（スライド・コーチマーク・リセット）。
Future<void> showOnboardingReplaySheet(
  BuildContext context, {
  Future<void> Function()? showPrepCoachMarksNow,
  Future<void> Function()? showMatchCoachMarksNow,
}) {
  return showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (ctx) {
      final theme = Theme.of(ctx);
      return DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.62,
        minChildSize: 0.35,
        maxChildSize: 0.92,
        builder: (context, scrollController) {
          return SafeArea(
            top: false,
            child: ListView(
              controller: scrollController,
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 28),
              children: [
                Text('かんたんガイド', style: theme.textTheme.titleLarge),
                const SizedBox(height: 8),
                Text(
                  '基本ルールのスライドと、画面ごとの案内（コーチマーク）を再表示できます。',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 12),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.auto_awesome_rounded),
                  title: const Text('基本ルールのスライド'),
                  subtitle: const Text('初回ウェルカムと同じ内容'),
                  onTap: () {
                    Navigator.pop(ctx);
                    showWelcomeFlow(context, offerTutorial: true);
                  },
                ),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.flag_outlined),
                  title: const Text('準備コーチマークをもう一度'),
                  subtitle: Text(
                    showPrepCoachMarksNow != null
                        ? '今すぐ表示、または次に準備画面を開いたとき'
                        : '次に準備画面を開いたとき',
                  ),
                  onTap: () async {
                    await OnboardingPrefs.resetPrepCoachMarks();
                    if (ctx.mounted) Navigator.pop(ctx);
                    if (showPrepCoachMarksNow != null && context.mounted) {
                      await showPrepCoachMarksNow();
                    } else if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('準備画面でコーチマークが再表示されます'),
                        ),
                      );
                    }
                  },
                ),
                if (showPrepCoachMarksNow != null)
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.play_circle_outline),
                    title: const Text('準備コーチマークを今すぐ'),
                    subtitle: const Text('いまの準備画面で案内を表示'),
                    onTap: () async {
                      if (ctx.mounted) Navigator.pop(ctx);
                      if (context.mounted) {
                        await showPrepCoachMarksNow();
                      }
                    },
                  ),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.sports_esports_outlined),
                  title: const Text('試合コーチマークをもう一度'),
                  subtitle: Text(
                    showMatchCoachMarksNow != null
                        ? '今すぐ表示、または次の試合開始時'
                        : '次に試合が始まったとき',
                  ),
                  onTap: () async {
                    await OnboardingPrefs.resetMatchCoachMarks();
                    if (ctx.mounted) Navigator.pop(ctx);
                    if (showMatchCoachMarksNow != null && context.mounted) {
                      await showMatchCoachMarksNow();
                    } else if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('次の試合開始時にガイドが再表示されます'),
                        ),
                      );
                    }
                  },
                ),
                if (showMatchCoachMarksNow != null)
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.play_circle_outline),
                    title: const Text('試合コーチマークを今すぐ'),
                    subtitle: const Text('いまの試合画面で HUD 案内を表示'),
                    onTap: () async {
                      if (ctx.mounted) Navigator.pop(ctx);
                      if (context.mounted) {
                        await showMatchCoachMarksNow();
                      }
                    },
                  ),
                const Divider(height: 28),
                OutlinedButton.icon(
                  onPressed: () async {
                    final ok = await showAppDialog<bool>(
                      context: ctx,
                      builder: (dialogCtx) => AppDialog(
                        title: '初回ガイドをすべてリセット',
                        icon: Icons.restart_alt_rounded,
                        actions: [
                          AppDialogAction(
                            label: 'キャンセル',
                            filled: false,
                            onPressed: () => Navigator.pop(dialogCtx, false),
                          ),
                          AppDialogAction(
                            label: 'リセット',
                            onPressed: () => Navigator.pop(dialogCtx, true),
                          ),
                        ],
                        child: const Text(
                          'ウェルカム・準備・試合の「初回のみ」表示をすべて最初からに戻します。',
                        ),
                      ),
                    );
                    if (ok != true) return;
                    await OnboardingPrefs.resetAll();
                    if (ctx.mounted) Navigator.pop(ctx);
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('初回ガイドをリセットしました')),
                      );
                    }
                  },
                  icon: const Icon(Icons.restart_alt_rounded),
                  label: const Text('初回ガイドをすべてリセット'),
                ),
              ],
            ),
          );
        },
      );
    },
  );
}
