import 'package:shared_preferences/shared_preferences.dart';

import '../features/game_map/hud/hud_compact_line.dart';
import '../session/game_map_prefs.dart';

/// 試合中 HUD 一行表示の端末保存。
abstract final class HudDisplayPrefs {
  static Future<HudCompactLineSlot> loadCompactLineSlot() async {
    final prefs = await SharedPreferences.getInstance();
    return HudCompactLineSlotLabel.fromStorage(
      prefs.getString(GameMapPrefs.hudCompactLineSlot),
    );
  }

  static Future<void> saveCompactLineSlot(HudCompactLineSlot slot) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(GameMapPrefs.hudCompactLineSlot, slot.name);
  }
}
