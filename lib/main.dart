import 'package:flutter/widgets.dart';

import 'app.dart';
import 'sync/firebase_bootstrap.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await FirebaseBootstrap.tryInit();
  runApp(const OniGameApp());
}