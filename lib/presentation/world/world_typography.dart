import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../theme/world_profile.dart';
import 'world_presentation_catalog.dart';
import 'world_presentation_pack.dart';

/// 世界観別タイポグラフィを [ThemeData] に適用。
abstract final class WorldTypography {
  static TextTheme apply(TextTheme base, WorldPresentationPack pack) {
    TextStyle headline(TextStyle? s) => GoogleFonts.getFont(
          pack.headlineFont,
          textStyle: s,
          fontWeight: pack.headlineWeight,
          letterSpacing: pack.headlineLetterSpacing,
          height: pack.bodyLineHeight,
        );

    TextStyle body(TextStyle? s) => GoogleFonts.getFont(
          pack.bodyFont,
          textStyle: s,
          letterSpacing: pack.bodyLetterSpacing,
          height: pack.bodyLineHeight,
        );

    return base.copyWith(
      displayLarge: headline(base.displayLarge),
      displayMedium: headline(base.displayMedium),
      displaySmall: headline(base.displaySmall),
      headlineLarge: headline(base.headlineLarge),
      headlineMedium: headline(base.headlineMedium),
      headlineSmall: headline(base.headlineSmall),
      titleLarge: headline(base.titleLarge),
      titleMedium: body(base.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
      titleSmall: body(base.titleSmall?.copyWith(fontWeight: FontWeight.w600)),
      bodyLarge: body(base.bodyLarge),
      bodyMedium: body(base.bodyMedium),
      bodySmall: body(base.bodySmall),
      labelLarge: body(base.labelLarge?.copyWith(fontWeight: FontWeight.w600)),
      labelMedium: body(base.labelMedium),
      labelSmall: body(base.labelSmall),
    );
  }

  static TextStyle headlineStyle(
    BuildContext context,
    WorldProfile profile, {
    double? fontSize,
    Color? color,
  }) {
    final pack = WorldPresentationCatalog.of(profile);
    return GoogleFonts.getFont(
      pack.headlineFont,
      fontSize: fontSize ?? Theme.of(context).textTheme.headlineSmall?.fontSize,
      fontWeight: pack.headlineWeight,
      letterSpacing: pack.headlineLetterSpacing,
      height: pack.bodyLineHeight,
      color: color,
    );
  }

  static TextStyle bodyStyle(
    BuildContext context,
    WorldProfile profile, {
    double? fontSize,
    Color? color,
  }) {
    final pack = WorldPresentationCatalog.of(profile);
    return GoogleFonts.getFont(
      pack.bodyFont,
      fontSize: fontSize ?? Theme.of(context).textTheme.bodyMedium?.fontSize,
      letterSpacing: pack.bodyLetterSpacing,
      height: pack.bodyLineHeight,
      color: color,
    );
  }
}
