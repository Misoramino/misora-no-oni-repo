import 'package:flutter/material.dart';

import '../audio/game_audio.dart';
import '../audio/sfx_id.dart';
import '../presentation/world/world_presentation_catalog.dart';
import '../presentation/world/world_presentation_context.dart';
import '../presentation/world/world_studio_identity_catalog.dart';
import '../presentation/world/world_ui_layout.dart';
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
  final studio = WorldStudioIdentityCatalog.of(context.worldProfile);
  GameAudio.instance.playSfx(openSfx);
  return showGeneralDialog<T>(
    context: context,
    barrierDismissible: barrierDismissible,
    barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
    barrierColor: Colors.black.withValues(alpha: 0.72),
  transitionDuration: const Duration(milliseconds: 220),
  pageBuilder: (ctx, animation, secondary) => builder(ctx),
  transitionBuilder: (ctx, animation, secondary, child) {
    final curved = CurvedAnimation(
      parent: animation,
      curve: Curves.easeOutBack,
      reverseCurve: studio.motion.exitCurve,
    );
    return SlideTransition(
      position: Tween<Offset>(
        begin: const Offset(0, 0.08),
        end: Offset.zero,
      ).animate(curved),
      child: FadeTransition(
        opacity: CurvedAnimation(parent: animation, curve: Curves.easeOut),
        child: ScaleTransition(
          scale: Tween<double>(begin: 0.96, end: 1).animate(curved),
          child: child,
        ),
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
    this.maxHeightFraction = 0.85,
  });

  final String title;
  final Widget child;
  final IconData? icon;
  final Color? accent;
  final List<Widget> actions;
  final double maxWidth;
  final double maxHeightFraction;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final color = accent ?? scheme.primary;
    final pack = WorldPresentationCatalog.of(context.worldProfile);
    final maxHeight = MediaQuery.sizeOf(context).height * maxHeightFraction;

    return Dialog(
      clipBehavior: Clip.antiAlias,
      backgroundColor: theme.colorScheme.surface.withValues(alpha: 0.98),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(WorldUILayout.dialogBorderRadius),
      ),
      insetPadding: WorldUILayout.dialogInsets(context),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth, maxHeight: maxHeight),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(18, 16, 18, 14),
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
                        color: pack.textOnPanel,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(18, 12, 18, 4),
                child: child,
              ),
            ),
            if (actions.isNotEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 4, 14, 14),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final narrow = constraints.maxWidth < 300;
                    if (narrow) {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          for (final a in actions) ...[
                            a,
                            if (a != actions.last) const SizedBox(height: 8),
                          ],
                        ],
                      );
                    }
                    return Wrap(
                      alignment: WrapAlignment.end,
                      spacing: 8,
                      runSpacing: 8,
                      children: actions,
                    );
                  },
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
