import 'package:flutter/widgets.dart';

import 'app.dart';
import 'audio/game_audio.dart';
import 'audio/world_audio_director.dart';
import 'services/background_crisis_alert.dart';
import 'sync/firebase_bootstrap.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await FirebaseBootstrap.tryInit();
  await GameAudio.instance.init();
  WorldAudioDirector.instance.attachToAudio();
  await BackgroundCrisisAlert.init();
  runApp(const OniGameApp());
}