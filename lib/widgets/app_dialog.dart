import 'package:flutter/material.dart';

import '../audio/game_audio.dart';
import '../audio/sfx_id.dart';
import 'juicy_tap.dart';

/// スケール＋フェードで登場する、テーマ配色の演出付きダイアログを表示する。
///
/// 中身は [AppDialog] を使うとヘッダ/本文/アクションの体裁が揃う。
Future<T?> showAppDialog<T>({
  required BuildContext context,
  required WidgetBuilder builder,
  bool barrierDismissible = true,
  SfxId openSfx = SfxId.uiConfirm,
}) {
  GameAudio.instance.playSfx(openSfx);
  return showGeneralDialog<T>(
    context: context,
    barrierDismissible: barrierDismissible,
    barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
    barrierColor: Colors.black54,
    transitionDuration: const Duration(milliseconds: 320),
    pageBuilder: (ctx, animation, secondary) => builder(ctx),
    transitionBuilder: (ctx, animation, secondary, child) {
      final curved = CurvedAnimation(
        parent: animation,
        curve: Curves.easeOutBack,
        reverseCurve: Curves.easeInCubic,
      );
      return FadeTransition(
        opacity: CurvedAnimation(parent: animation, curve: Curves.easeOut),
        child: ScaleTransition(
          scale: Tween<double>(begin: 0.88, end: 1).animate(curved),
          child: child,
        ),
      );
    },
  );
}

/// 角丸・アクセントヘッダ・ジューシーなアクションを備えた共通ダイアログ本体。
class AppDialog extends StatelessWidget {
  const AppDialog({
    super.key,
    required this.title,
    required this.child,
    this.icon,
    this.accent,
    this.actions = const [],
    this.maxWidth = 420,
  });

  final String title;
  final Widget child;
  final IconData? icon;
  final Color? accent;
  final List<Widget> actions;
  final double maxWidth;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final color = accent ?? scheme.primary;

    return Dialog(
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(22),
      ),
      insetPadding: const EdgeInsets.symmetric(horizontal: 28, vertical: 32),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    color.withValues(alpha: 0.30),
                    color.withValues(alpha: 0.08),
                  ],
                ),
              ),
              child: Row(
                children: [
                  if (icon != null) ...[
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.22),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(icon, color: color),
                    ),
                    const SizedBox(width: 12),
                  ],
                  Expanded(
                    child: Text(
                      title,
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                child: child,
              ),
            ),
            if (actions.isNotEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    for (final a in actions) ...[
                      a,
                      if (a != actions.last) const SizedBox(width: 8),
                    ],
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// ダイアログ用の主アクション（押下アニメ＋SE付き）。
class AppDialogAction extends StatelessWidget {
  const AppDialogAction({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.filled = true,
    this.destructive = false,
    this.sfx = SfxId.uiTap,
  });

  final String label;
  final VoidCallback onPressed;
  final IconData? icon;
  final bool filled;
  final bool destructive;
  final SfxId sfx;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final child = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (icon != null) ...[Icon(icon, size: 18), const SizedBox(width: 6)],
        Text(label),
      ],
    );
    final button = filled
        ? FilledButton(
            style: destructive
                ? FilledButton.styleFrom(
                    backgroundColor: scheme.error,
                    foregroundColor: scheme.onError,
                  )
                : null,
            onPressed: onPressed,
            child: child,
          )
        : TextButton(onPressed: onPressed, child: child);

    return JuicyTap(
      onTap: onPressed,
      sfx: sfx,
      pressedScale: 0.92,
      child: IgnorePointer(child: button),
    );
  }
}
