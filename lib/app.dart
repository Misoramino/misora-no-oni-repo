import 'package:flutter/material.dart';

import 'screens/branded_launch_screen.dart';
import 'screens/title_screen.dart';
import 'session/world_profile_prefs.dart';
import 'theme/app_theme_factory.dart';
import 'theme/world_profile.dart';

class OniGameApp extends StatefulWidget {
  const OniGameApp({super.key});

  @override
  State<OniGameApp> createState() => _OniGameAppState();
}

class _OniGameAppState extends State<OniGameApp> {
  WorldProfile _profile = WorldProfile.horror;
  bool _launchDone = false;

  @override
  void initState() {
    super.initState();
    Future<void>.microtask(_loadProfile);
  }

  Future<void> _loadProfile() async {
    final p = await WorldProfilePrefs.load();
    if (!mounted) return;
    setState(() => _profile = p);
  }

  void _onLaunchFinished() {
    if (!mounted) return;
    setState(() => _launchDone = true);
  }

  @override
  Widget build(BuildContext context) {
    final theme = AppThemeFactory.create(_profile);

    if (!_launchDone) {
      return MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: theme,
        home: BrandedLaunchScreen(
          profile: _profile,
          onFinished: _onLaunchFinished,
        ),
      );
    }

    return MaterialApp(
      title: 'Oni Game',
      theme: theme,
      home: TitleScreen(
        initialProfile: _profile,
        onProfileChanged: (p) async {
          await WorldProfilePrefs.save(p);
          if (mounted) setState(() => _profile = p);
        },
      ),
    );
  }
}
