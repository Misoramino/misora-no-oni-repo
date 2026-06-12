import 'package:flutter_test/flutter_test.dart';
import 'package:oni_game/features/how_to_play/guide_sections.dart';
import 'package:oni_game/features/tutorial/tutorial_copy.dart';
import 'package:oni_game/game/player_role.dart';

void main() {
  test('tutorial finish related guides map to guide sections', () {
    for (final role in PlayerRole.values) {
      final finish = TutorialCopyCatalog.finishFor(role);
      for (final link in finish.relatedGuides) {
        expect(
          guideSectionById(link.sectionId),
          isNotNull,
          reason: '${role.name} → ${link.sectionId}',
        );
        expect(link.title, isNotEmpty);
      }
    }
  });

  test('howToPlaySections has unique ids', () {
    final ids = howToPlaySections.map((s) => s.id).toList();
    expect(ids.toSet().length, ids.length);
  });
}
