import 'package:flutter_test/flutter_test.dart';
import 'package:oni_game/features/how_to_play/guide_sections.dart';
import 'package:oni_game/game/game_config.dart';
import 'package:oni_game/game/player_role.dart';
import 'package:oni_game/game/skill_reference.dart';

void main() {
  test('all equip skills have unique ids and guide card ids', () {
    final ids = SkillReference.all.map((s) => s.id).toList();
    final cardIds = SkillReference.all.map((s) => s.guideCardId).toList();
    expect(ids.toSet().length, ids.length);
    expect(cardIds.toSet().length, cardIds.length);
  });

  test('guide skills section contains every skill card', () {
    final section = guideSectionById('skills');
    expect(section, isNotNull);
    final cardIds = section!.cards.map((c) => c.id).toSet();
    for (final spec in SkillReference.all) {
      expect(cardIds, contains(spec.guideCardId), reason: spec.id);
    }
  });

  test('spec_skills groups match SkillReference', () {
    final specSection = guideSectionById('spec');
    expect(specSection, isNotNull);
    final skillsCard = specSection!.cards.firstWhere((c) => c.id == 'spec_skills');
    final expected = SkillReference.specSkillGroups();
    expect(skillsCard.specGroups.length, expected.length);
    for (var i = 0; i < expected.length; i++) {
      expect(skillsCard.specGroups[i].title, expected[i].title);
      expect(skillsCard.specGroups[i].rows.length, expected[i].rows.length);
    }
  });

  test('forRole covers each role without duplicates', () {
    for (final role in PlayerRole.values) {
      final skills = SkillReference.forRole(role);
      expect(skills, isNotEmpty, reason: role.name);
      expect(
        skills.map((s) => s.id).toSet().length,
        skills.length,
        reason: role.name,
      );
    }
  });

  test('spec_zone rows match capture zone spec', () {
    final specSection = guideSectionById('spec');
    final zoneCard =
        specSection!.cards.firstWhere((c) => c.id == 'spec_zone');
    final expected = SkillReference.captureZone.specRows;
    expect(zoneCard.specRows.length, expected.length);
    for (var i = 0; i < expected.length; i++) {
      expect(zoneCard.specRows[i].label, expected[i].label);
      expect(zoneCard.specRows[i].value, expected[i].value);
    }
  });

  test('spec rows align with GameConfig constants', () {
    expect(
      SkillReference.fakePosition.specRows.any(
        (r) => r.label == '持続' && r.value.contains('${GameConfig.fakeSkillDurationSeconds}'),
      ),
      isTrue,
    );
    expect(
      SkillReference.captureZone.specRows.any(
        (r) =>
            r.label == '持続' &&
            r.value.contains('${GameConfig.captureZoneDurationSeconds}'),
      ),
      isTrue,
    );
    expect(
      SkillReference.bodyThrow.specRows.any(
        (r) =>
            r.label == '設置射程' &&
            r.value.contains(
              GameConfig.bodyThrowDistanceMeters.toStringAsFixed(0),
            ),
      ),
      isTrue,
    );
  });
}
