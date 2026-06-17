import 'package:shared_preferences/shared_preferences.dart';

/// 試合中の通知設定（端末ローカル保存）。
abstract final class OniOperatorPrefs {
  static const notifyVibrationKey = 'oni_notify_vibration_v1';
  static const notifySoundKey = 'oni_notify_sound_v1';
  static const notifyAggressiveKey = 'oni_notify_aggressive_v1';
  static const crisisVibrationKey = 'match_crisis_vibration_v1';
  static const crisisNotificationKey = 'match_crisis_notification_v1';

  static OniOperatorSnapshot fromPrefs(SharedPreferences prefs) {
    return OniOperatorSnapshot(
      notifyVibration: prefs.getBool(notifyVibrationKey) ?? true,
      notifySound: prefs.getBool(notifySoundKey) ?? true,
      notifyAggressive: prefs.getBool(notifyAggressiveKey) ?? false,
      crisisVibration: prefs.getBool(crisisVibrationKey) ?? true,
      crisisNotification: prefs.getBool(crisisNotificationKey) ?? true,
    );
  }

  static Future<void> save(
    SharedPreferences prefs,
    OniOperatorSnapshot s,
  ) async {
    await prefs.setBool(notifyVibrationKey, s.notifyVibration);
    await prefs.setBool(notifySoundKey, s.notifySound);
    await prefs.setBool(notifyAggressiveKey, s.notifyAggressive);
    await prefs.setBool(crisisVibrationKey, s.crisisVibration);
    await prefs.setBool(crisisNotificationKey, s.crisisNotification);
  }
}

class OniOperatorSnapshot {
  const OniOperatorSnapshot({
    required this.notifyVibration,
    required this.notifySound,
    required this.notifyAggressive,
    required this.crisisVibration,
    required this.crisisNotification,
  });

  /// 接近・拘束中の詳細フィードバック（振動／音の個別制御）。
  final bool notifyVibration;
  final bool notifySound;
  final bool notifyAggressive;
  /// バックグラウンド含む危機アラートの振動。
  final bool crisisVibration;
  /// バックグラウンド危機のローカル通知。
  final bool crisisNotification;
}
