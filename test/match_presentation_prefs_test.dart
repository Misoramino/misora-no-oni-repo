import 'package:flutter_test/flutter_test.dart';
import 'package:oni_game/session/match_presentation_prefs.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('short match start ceremony roundtrips', () async {
    SharedPreferences.setMockInitialValues({});
    expect(await MatchPresentationPrefs.shortMatchStartCeremony(), isFalse);
    await MatchPresentationPrefs.setShortMatchStartCeremony(true);
    expect(await MatchPresentationPrefs.shortMatchStartCeremony(), isTrue);
  });
}
