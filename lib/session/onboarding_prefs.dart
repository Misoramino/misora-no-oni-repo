import 'package:shared_preferences/shared_preferences.dart';

/// 初回導入（ウェルカム・準備ガイド・コーチマーク）の表示済みフラグ。
abstract final class OnboardingPrefs {
  static const _welcomeKey = 'onboarding_welcome_seen_v1';
  static const _prepGuideKey = 'onboarding_prep_guide_seen_v1';
  static const _coachKey = 'onboarding_coach_marks_seen_v1';
  static const _matchCoachKey = 'onboarding_match_coach_marks_seen_v1';
  static const _accusationIntroKey = 'onboarding_accusation_intro_seen_v1';
  static const _echoTutorialOfferKey =
      'onboarding_echo_tutorial_offer_seen_v1';
  static const _shadowTutorialOfferKey =
      'onboarding_shadow_tutorial_offer_seen_v1';

  static const _structureGuideKey = 'onboarding_structure_guide_seen_v1';
  static const _matchPlayabilityKey =
      'onboarding_match_playability_hints_seen_v1';
  static const _matchPlayabilityConditionalAtKey =
      'onboarding_match_playability_conditional_at_ms_v1';

  static Future<bool> welcomeSeen() => _get(_welcomeKey);
  static Future<void> markWelcomeSeen() => _set(_welcomeKey, true);

  static Future<bool> structureGuideSeen() => _get(_structureGuideKey);
  static Future<void> markStructureGuideSeen() =>
      _set(_structureGuideKey, true);

  static Future<bool> matchPlayabilityHintsSeen() =>
      _get(_matchPlayabilityKey);
  static Future<void> markMatchPlayabilityHintsSeen() =>
      _set(_matchPlayabilityKey, true);

  static Future<DateTime?> matchPlayabilityConditionalLastShown() async {
    final prefs = await SharedPreferences.getInstance();
    final ms = prefs.getInt(_matchPlayabilityConditionalAtKey);
    if (ms == null) return null;
    return DateTime.fromMillisecondsSinceEpoch(ms);
  }

  static Future<void> markMatchPlayabilityConditionalShown() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(
      _matchPlayabilityConditionalAtKey,
      DateTime.now().millisecondsSinceEpoch,
    );
  }

  static Future<bool> prepGuideSeen() => _get(_prepGuideKey);
  static Future<void> markPrepGuideSeen() => _set(_prepGuideKey, true);

  static Future<bool> coachMarksSeen() => _get(_coachKey);
  static Future<void> markCoachMarksSeen() => _set(_coachKey, true);

  static Future<bool> matchCoachMarksSeen() => _get(_matchCoachKey);
  static Future<void> markMatchCoachMarksSeen() =>
      _set(_matchCoachKey, true);

  static Future<bool> accusationIntroSeen() => _get(_accusationIntroKey);
  static Future<void> markAccusationIntroSeen() =>
      _set(_accusationIntroKey, true);

  /// 初回脱落時の第二ゲームチュートリアル案内を表示済みか。
  static Future<bool> secondGameTutorialOfferSeen(String prefsKey) =>
      _get(prefsKey);

  static Future<void> markSecondGameTutorialOfferSeen(String prefsKey) =>
      _set(prefsKey, true);

  static Future<void> resetPrepCoachMarks() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_coachKey);
    await prefs.remove(_prepGuideKey);
  }

  static Future<void> resetMatchCoachMarks() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_matchCoachKey);
  }

  static Future<void> resetStructureGuide() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_structureGuideKey);
  }

  /// すべての初回フラグを消し、導入を最初から見られるようにする。
  static Future<void> resetAll() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_welcomeKey);
    await prefs.remove(_structureGuideKey);
    await prefs.remove(_matchPlayabilityKey);
    await prefs.remove(_matchPlayabilityConditionalAtKey);
    await prefs.remove(_prepGuideKey);
    await prefs.remove(_coachKey);
    await prefs.remove(_matchCoachKey);
    await prefs.remove(_accusationIntroKey);
    await prefs.remove(_echoTutorialOfferKey);
    await prefs.remove(_shadowTutorialOfferKey);
  }

  static String secondGameTutorialOfferKeyFor(String kindName) =>
      switch (kindName) {
        'echoForm' => _echoTutorialOfferKey,
        'vengefulShadow' => _shadowTutorialOfferKey,
        _ => _echoTutorialOfferKey,
      };

  static Future<bool> _get(String key) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(key) ?? false;
  }

  static Future<void> _set(String key, bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(key, value);
  }
}
