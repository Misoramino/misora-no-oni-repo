import 'package:flutter/material.dart';

import 'screens/title_screen.dart';
import 'theme/app_theme_factory.dart';
import 'theme/world_profile.dart';

class OniGameApp extends StatelessWidget {
  const OniGameApp({super.key});

  @override
  Widget build(BuildContext context) {
    const profile = WorldProfile.horror;
    return MaterialApp(
      title: 'Oni Game',
      theme: AppThemeFactory.create(profile),
      home: const TitleScreen(),
    );
  }
}
