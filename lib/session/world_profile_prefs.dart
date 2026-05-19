import 'package:shared_preferences/shared_preferences.dart';

import '../session/game_map_prefs.dart';
import '../theme/world_profile.dart';

/// 世界観の端末保存（Firestore とは無関係）。
abstract final class WorldProfilePrefs {
  static Future<WorldProfile> load() async {
    final prefs = await SharedPreferences.getInstance();
    return WorldProfile.fromStorageName(
      prefs.getString(GameMapPrefs.worldProfile),
    );
  }

  static Future<void> save(WorldProfile profile) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(GameMapPrefs.worldProfile, profile.storageName);
  }
}
