import 'package:flutter/material.dart';

import '../../theme/app_theme_factory.dart';
import '../../theme/world_profile.dart';
import 'world_presentation_catalog.dart';
import 'world_presentation_context.dart';
import 'world_studio_identity_catalog.dart';
import 'world_ui_layout.dart';

/// 世界観別スナックバー。
void showWorldSnackBar(
  BuildContext context, {
  required String message,
  WorldProfile? profile,
  Duration? duration,
}) {
  final p = profile ?? context.worldProfile;
  final pack = WorldPresentationCatalog.of(p);
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(
        message,
        style: TextStyle(color: pack.textOnPanelOverScaffold),
      ),
      behavior: SnackBarBehavior.floating,
      backgroundColor: pack.panelOnScaffold,
      duration: duration ?? const Duration(seconds: 3),
      margin: WorldUILayout.dialogInsets(context),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(pack.chipBorderRadius + 2),
        side: BorderSide(color: pack.panelBorder),
      ),
    ),
  );
}

/// 世界観テーマを適用した子ウィジェット（シート・ガイド用）。
class WorldThemed extends StatelessWidget {
  const WorldThemed({
    required this.profile,
    required this.child,
    super.key,
  });

  final WorldProfile profile;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: AppThemeFactory.create(profile),
      child: child,
    );
  }
}

/// 「スキャフォールド地（グラデーション背景）」に内容を直接置くシート・
/// 全画面向けのテーマ。既定文字色をスキャフォールド向けに上書きし、
/// 明パネル＋暗背景の世界観（マジカル/禅京都など）でも文字が読めるように
/// する。カード等のパネル要素は各自 textOnPanel を明示すること。
class WorldScaffoldThemed extends StatelessWidget {
  const WorldScaffoldThemed({
    required this.profile,
    required this.child,
    super.key,
  });

  final WorldProfile profile;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final pack = WorldPresentationCatalog.of(profile);
    final base = AppThemeFactory.create(profile);
    final scaffoldTextTheme = base.textTheme.apply(
      bodyColor: pack.textOnScaffold,
      displayColor: pack.textOnScaffold,
    );
    return Theme(
      data: base.copyWith(
        textTheme: scaffoldTextTheme,
        primaryTextTheme: scaffoldTextTheme,
        colorScheme: base.colorScheme.copyWith(
          onSurface: pack.textOnScaffold,
          onSurfaceVariant: pack.mutedOnScaffold,
        ),
      ),
      child: child,
    );
  }
}

/// 世界観別ボトムシート（グラデーション枠）。
Future<T?> showWorldSheet<T>(
  BuildContext context, {
  required WidgetBuilder builder,
  WorldProfile? profile,
  bool isScrollControlled = true,
}) {
  final p = profile ?? context.worldProfile;
  final pack = WorldPresentationCatalog.of(p);
  final studio = WorldStudioIdentityCatalog.of(p);
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: isScrollControlled,
    useSafeArea: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) => AnimatedContainer(
      duration: studio.motion.dialog,
      curve: studio.motion.sheetCurve,
      decoration: BoxDecoration(
        gradient: pack.scaffoldGradient,
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(pack.hudCornerRadius + 12),
        ),
        border: Border.all(color: pack.panelBorder),
      ),
      child: builder(ctx),
    ),
  );
}
