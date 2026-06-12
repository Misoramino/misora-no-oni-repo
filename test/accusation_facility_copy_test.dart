import 'package:flutter_test/flutter_test.dart';
import 'package:oni_game/features/how_to_play/guide_terms.dart';
import 'package:oni_game/theme/accusation_facility_copy.dart';
import 'package:oni_game/theme/world_profile.dart';

void main() {
  group('AccusationFacilityCopy', () {
    for (final profile in WorldProfile.values) {
      test('${profile.name} targets true oni and accurate locked hint', () {
        final copy = AccusationFacilityCopy.forProfile(profile);
        expect(copy.accuseActionLabel, contains(GuideTerms.trueOni));
        expect(copy.lockedHint, AccusationFacilityCopy.lockedHintBase);
        expect(copy.unlockLines.last, contains(GuideTerms.trueOni));
        expect(copy.accuseActionLabel, isNot(contains('容疑者')));
        expect(copy.accuseActionLabel, isNot(contains('犯人')));
      });
    }

    test('accuseTargetLine clarifies werewolf is not target', () {
      expect(
        AccusationFacilityCopy.accuseTargetLine,
        contains(GuideTerms.trueOni),
      );
      expect(
        AccusationFacilityCopy.accuseTargetLine,
        contains(GuideTerms.werewolf),
      );
    });
  });
}
