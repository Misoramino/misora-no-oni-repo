import 'package:flutter/material.dart';

import 'world_profile.dart';

abstract final class AppThemeFactory {
  static ThemeData create(WorldProfile profile) {
    final seed = switch (profile) {
      WorldProfile.horror => Colors.red.shade900,
      WorldProfile.sport => const Color(0xFFFF4081),
      WorldProfile.sciFi => const Color(0xFF00BCD4),
      WorldProfile.arg => const Color(0xFF607D8B),
      WorldProfile.magical => const Color(0xFF9C27B0),
      WorldProfile.astronomy => const Color(0xFF1A237E),
    };

    final base = ThemeData(
      colorScheme: ColorScheme.fromSeed(
        seedColor: seed,
        brightness: switch (profile) {
          WorldProfile.sport => Brightness.light,
          _ => Brightness.dark,
        },
      ),
      useMaterial3: true,
    );

    return base.copyWith(
      appBarTheme: base.appBarTheme.copyWith(centerTitle: false),
      snackBarTheme: base.snackBarTheme.copyWith(
        behavior: SnackBarBehavior.floating,
      ),
      cardTheme: base.cardTheme.copyWith(
        elevation: profile == WorldProfile.sport ? 2 : 0,
      ),
    );
  }
}
