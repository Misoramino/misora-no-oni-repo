import 'package:flutter/widgets.dart';

import 'app.dart';
import 'audio/game_audio.dart';
import 'sync/firebase_bootstrap.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await FirebaseBootstrap.tryInit();
  await GameAudio.instance.init();
  runApp(const OniGameApp());
}