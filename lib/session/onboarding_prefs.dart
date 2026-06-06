import 'package:shared_preferences/shared_preferences.dart';

/// 初回導入（ウェルカム・準備ガイド・コーチマーク）の表示済みフラグ。
abstract final class OnboardingPrefs {
  static const _welcomeKey = 'onboarding_welcome_seen_v1';
  static const _prepGuideKey = 'onboarding_prep_guide_seen_v1';
  static const _coachKey = 'onboarding_coach_marks_seen_v1';

  static Future<bool> welcomeSeen() => _get(_welcomeKey);
  static Future<void> markWelcomeSeen() => _set(_welcomeKey, true);

  static Future<bool> prepGuideSeen() => _get(_prepGuideKey);
  static Future<void> markPrepGuideSeen() => _set(_prepGuideKey, true);

  static Future<bool> coachMarksSeen() => _get(_coachKey);
  static Future<void> markCoachMarksSeen() => _set(_coachKey, true);

  /// すべての初回フラグを消し、導入を最初から見られるようにする。
  static Future<void> resetAll() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_welcomeKey);
    await prefs.remove(_prepGuideKey);
    await prefs.remove(_coachKey);
  }

  static Future<bool> _get(String key) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(key) ?? false;
  }

  static Future<void> _set(String key, bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(key, value);
  }
}
