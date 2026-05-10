import 'package:flutter/material.dart';

import 'screens/game_map_screen.dart';
import 'theme/app_theme_factory.dart';
import 'theme/world_profile.dart';

class OniGameApp extends StatelessWidget {
  const OniGameApp({super.key});

  @override
  Widget build(BuildContext context) {
    // UI/世界観を後差ししやすいように、入口でプロファイルを決定する。
    const profile = WorldProfile.horror;
    return MaterialApp(
      title: 'Oni Game',
      theme: AppThemeFactory.create(profile),
      home: const GameMapScreen(profile: profile),
    );
  }
}
