import 'package:shared_preferences/shared_preferences.dart';

/// 鬼オペレーター向け設定（鬼コンソールと逃走側ロジックで共有）。
abstract final class OniOperatorPrefs {
  static const roleEnabledKey = 'oni_role_enabled_v1';
  static const notifyVibrationKey = 'oni_notify_vibration_v1';
  static const notifySoundKey = 'oni_notify_sound_v1';
  static const notifyAggressiveKey = 'oni_notify_aggressive_v1';

  static OniOperatorSnapshot fromPrefs(SharedPreferences prefs) {
    return OniOperatorSnapshot(
      roleEnabled: prefs.getBool(roleEnabledKey) ?? false,
      notifyVibration: prefs.getBool(notifyVibrationKey) ?? true,
      notifySound: prefs.getBool(notifySoundKey) ?? true,
      notifyAggressive: prefs.getBool(notifyAggressiveKey) ?? false,
    );
  }

  static Future<void> save(
    SharedPreferences prefs,
    OniOperatorSnapshot s,
  ) async {
    await prefs.setBool(roleEnabledKey, s.roleEnabled);
    await prefs.setBool(notifyVibrationKey, s.notifyVibration);
    await prefs.setBool(notifySoundKey, s.notifySound);
    await prefs.setBool(notifyAggressiveKey, s.notifyAggressive);
  }
}

class OniOperatorSnapshot {
  const OniOperatorSnapshot({
    required this.roleEnabled,
    required this.notifyVibration,
    required this.notifySound,
    required this.notifyAggressive,
  });

  final bool roleEnabled;
  final bool notifyVibration;
  final bool notifySound;
  final bool notifyAggressive;
}
