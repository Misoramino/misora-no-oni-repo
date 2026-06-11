import 'package:shared_preferences/shared_preferences.dart';

import 'game_map_prefs.dart';

/// 試合開始演出（ロスター・オービット）の端末設定。
abstract final class MatchPresentationPrefs {
  static Future<bool> shortMatchStartCeremony() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(GameMapPrefs.shortMatchStartCeremony) ?? false;
  }

  static Future<void> setShortMatchStartCeremony(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(GameMapPrefs.shortMatchStartCeremony, value);
  }
}
