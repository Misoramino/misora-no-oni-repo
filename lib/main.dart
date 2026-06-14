import 'package:flutter/widgets.dart';

import 'app.dart';
import 'audio/game_audio.dart';
import 'services/background_crisis_alert.dart';
import 'sync/firebase_bootstrap.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await FirebaseBootstrap.tryInit();
  await GameAudio.instance.init();
  await BackgroundCrisisAlert.init();
  runApp(const OniGameApp());
}