import 'package:flutter/material.dart';

import '../../session/onboarding_prefs.dart';
import '../../widgets/app_dialog.dart';
import 'welcome_flow.dart';

/// 初回ガイドの再視聴・リセット。
Future<void> showOnboardingReplaySheet(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    builder: (ctx) {
      final theme = Theme.of(ctx);
      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('ガイドの再視聴', style: theme.textTheme.titleLarge),
              const SizedBox(height: 8),
              Text(
                'かんたんガイドはいつでも見られます。'
                'コーチマークは次に該当画面を開いたときに再表示されます。',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 16),
              ListTile(
                leading: const Icon(Icons.auto_awesome_rounded),
                title: const Text('かんたんガイド'),
                subtitle: const Text('基本ルールのスライド'),
                onTap: () {
                  Navigator.pop(ctx);
                  showWelcomeFlow(context, offerTutorial: true);
                },
              ),
              ListTile(
                leading: const Icon(Icons.flag_outlined),
                title: const Text('準備コーチマークをもう一度'),
                subtitle: const Text('次に準備画面を開いたとき'),
                onTap: () async {
                  await OnboardingPrefs.resetPrepCoachMarks();
                  if (ctx.mounted) Navigator.pop(ctx);
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('準備画面でコーチマークが再表示されます'),
                      ),
                    );
                  }
                },
              ),
              ListTile(
                leading: const Icon(Icons.sports_esports_outlined),
                title: const Text('試合コーチマークをもう一度'),
                subtitle: const Text('次に試合が始まったとき'),
                onTap: () async {
                  await OnboardingPrefs.resetMatchCoachMarks();
                  if (ctx.mounted) Navigator.pop(ctx);
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('次の試合開始時にガイドが再表示されます'),
                      ),
                    );
                  }
                },
              ),
              const Divider(height: 24),
              TextButton(
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
                child: const Text('初回ガイドをすべてリセット'),
              ),
            ],
          ),
        ),
      );
    },
  );
}
