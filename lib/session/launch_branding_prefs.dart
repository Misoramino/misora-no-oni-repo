import 'package:shared_preferences/shared_preferences.dart';

/// 起動演出の効果音 ON/OFF（端末ローカル）。
abstract final class LaunchBrandingPrefs {
  static const _soundEnabledKey = 'launch_sound_enabled_v1';

  static Future<bool> loadSoundEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_soundEnabledKey) ?? true;
  }

  static Future<void> saveSoundEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_soundEnabledKey, enabled);
  }
}
