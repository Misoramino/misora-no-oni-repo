import 'package:flutter/material.dart';

import '../presentation/world/world_presentation_context.dart';
import '../presentation/world/world_typography.dart';
import 'world_profile.dart';
import '../presentation/world/world_presentation_catalog.dart';

abstract final class AppThemeFactory {
  static ThemeData create(WorldProfile profile) {
    final pack = WorldPresentationCatalog.of(profile);
    final seed = pack.accent;

    final baseScheme = ColorScheme.fromSeed(
      seedColor: seed,
      brightness: profile == WorldProfile.sport
          ? Brightness.light
          : Brightness.dark,
      primary: pack.accent,
      secondary: pack.accentMuted,
      surface: pack.panelSurface,
      error: pack.dangerColor,
    );
    final scheme = baseScheme.copyWith(
      onSurface: pack.textOnPanel,
      onSurfaceVariant: pack.mutedOnPanel,
      onPrimary: pack.buttonLabelOnAccent,
    );

    final base = ThemeData(
      colorScheme: scheme,
      useMaterial3: true,
      extensions: [WorldProfileTheme(profile)],
    );

    final textTheme = WorldTypography.apply(base.textTheme, pack).apply(
      bodyColor: pack.textOnPanel,
      displayColor: pack.textOnPanel,
    );

    final dialogTextStyle = textTheme.bodyMedium!.copyWith(
      height: pack.bodyLineHeight,
      color: pack.textOnPanel,
    );
    final dialogTitleStyle = textTheme.titleLarge!.copyWith(
      fontWeight: pack.headlineWeight,
      letterSpacing: pack.headlineLetterSpacing,
      color: pack.textOnPanel,
    );

    return base.copyWith(
      textTheme: textTheme,
      primaryTextTheme: textTheme,
      scaffoldBackgroundColor: pack.scaffoldBottom,
      appBarTheme: base.appBarTheme.copyWith(
        centerTitle: false,
        backgroundColor: pack.scaffoldTop.withValues(alpha: 0.92),
        foregroundColor: pack.accentOnScaffold,
        elevation: 0,
      ),
      snackBarTheme: base.snackBarTheme.copyWith(
        behavior: SnackBarBehavior.floating,
        backgroundColor: pack.panelOnScaffold,
        contentTextStyle: textTheme.bodyMedium?.copyWith(
          color: pack.textOnPanelOverScaffold,
        ),
      ),
      cardTheme: base.cardTheme.copyWith(
        elevation: profile == WorldProfile.sport ? 2 : 0,
        color: pack.panelSurfaceOpaque,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(pack.hudCornerRadius + 4),
          side: BorderSide(color: pack.panelBorder),
        ),
      ),
      dialogTheme: base.dialogTheme.copyWith(
        backgroundColor: pack.panelSurfaceOpaque,
        titleTextStyle: dialogTitleStyle,
        contentTextStyle: dialogTextStyle,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(pack.hudCornerRadius + 8),
          side: BorderSide(color: pack.panelBorder, width: 1.2),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: pack.accent,
          foregroundColor: pack.buttonLabelOnAccent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(pack.buttonShape.borderRadius),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: pack.accent,
          side: BorderSide(
            color: pack.accent,
            width: pack.buttonShape.borderWidth > 0
                ? pack.buttonShape.borderWidth
                : 1.5,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(pack.buttonShape.borderRadius),
          ),
        ),
      ),
      chipTheme: base.chipTheme.copyWith(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(pack.chipBorderRadius),
          side: BorderSide(color: pack.panelBorder),
        ),
        labelStyle: textTheme.labelSmall?.copyWith(color: pack.textOnPanel),
      ),
      dividerColor: pack.panelBorder,
    );
  }
}
