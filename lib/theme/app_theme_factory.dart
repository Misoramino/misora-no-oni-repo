import 'package:flutter/material.dart';

import 'world_profile.dart';

abstract final class AppThemeFactory {
  static ThemeData create(WorldProfile profile) {
    final seed = switch (profile) {
      WorldProfile.horror => Colors.red,
      WorldProfile.sport => Colors.blue,
      WorldProfile.sciFi => Colors.teal,
      WorldProfile.arg => Colors.deepPurple,
    };

    final base = ThemeData(
      colorScheme: ColorScheme.fromSeed(seedColor: seed),
      useMaterial3: true,
    );

    return base.copyWith(
      appBarTheme: base.appBarTheme.copyWith(centerTitle: false),
      snackBarTheme: base.snackBarTheme.copyWith(
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
