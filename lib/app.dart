import 'package:flutter/material.dart';

import 'navigation/room_lobby_route.dart';
import 'screens/app_launch_shell.dart';
import 'screens/room_lobby_screen.dart';
import 'sync/firestore_room_session.dart';
import 'session/world_profile_prefs.dart';
import 'theme/app_theme_factory.dart';
import 'theme/world_profile.dart';
import 'widgets/scene_transitions.dart';

class OniGameApp extends StatefulWidget {
  const OniGameApp({super.key});

  @override
  State<OniGameApp> createState() => _OniGameAppState();
}

class _OniGameAppState extends State<OniGameApp> {
  WorldProfile _profile = WorldProfile.horror;

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

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ONI PIN',
      debugShowCheckedModeBanner: false,
      theme: AppThemeFactory.create(_profile),
      onGenerateRoute: _onGenerateRoute,
      home: AppLaunchShell(
        initialProfile: _profile,
        onProfileChanged: (p) async {
          await WorldProfilePrefs.save(p);
          if (mounted) setState(() => _profile = p);
        },
      ),
    );
  }

  Route<dynamic>? _onGenerateRoute(RouteSettings settings) {
    if (settings.name == RoomLobbyRoute.name) {
      final args = settings.arguments as RoomLobbyRouteArgs?;
      return ScenePageRoute<FirestoreRoomSession?>(
        settings: settings,
        builder: (_) => RoomLobbyScreen(
          existingSession: args?.existingSession,
        ),
        worldProfile: args?.worldProfile ?? _profile,
      );
    }
    return null;
  }
}
