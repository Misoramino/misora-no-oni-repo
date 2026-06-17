import 'dart:async';

import 'package:flutter/material.dart';

import 'audio/game_audio.dart';
import 'audio/world_audio_director.dart';
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

class _OniGameAppState extends State<OniGameApp> with WidgetsBindingObserver {
  WorldProfile _profile = WorldProfile.horror;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    Future<void>.microtask(_loadProfile);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.paused:
      case AppLifecycleState.inactive:
      case AppLifecycleState.detached:
      case AppLifecycleState.hidden:
        unawaited(GameAudio.instance.pauseForBackground());
        unawaited(WorldAudioDirector.instance.pauseForBackground());
      case AppLifecycleState.resumed:
        unawaited(GameAudio.instance.resumeFromBackground());
        unawaited(WorldAudioDirector.instance.resumeFromBackground());
    }
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
      themeAnimationDuration: const Duration(milliseconds: 850),
      themeAnimationCurve: Curves.easeInOutCubic,
      onGenerateRoute: _onGenerateRoute,
      home: AppLaunchShell(
        initialProfile: _profile,
        onProfileChanged: (p) async {
          await WorldProfilePrefs.save(p);
          if (mounted) setState(() => _profile = p);
          unawaited(WorldAudioDirector.instance.onProfileChanged(p));
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
