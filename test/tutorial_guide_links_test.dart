import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:oni_game/features/how_to_play/guide_diagram_type.dart';
import 'package:oni_game/features/how_to_play/guide_sections.dart';
import 'package:oni_game/features/how_to_play/guide_terms.dart';
import 'package:oni_game/features/how_to_play/widgets/guide_diagram_views.dart';
import 'package:oni_game/features/how_to_play/widgets/how_to_play_guide_body.dart';
import 'package:oni_game/features/tutorial/second_game_tutorial_kind.dart';
import 'package:oni_game/features/tutorial/tutorial_copy.dart';
import 'package:oni_game/game/elimination_aftermath_rule.dart';
import 'package:oni_game/game/player_role.dart';
import 'package:oni_game/session/onboarding_prefs.dart';

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

  test('guide index highlights resolve to sections', () {
    for (final id in guideIndexSectionIds) {
      expect(guideSectionById(id), isNotNull, reason: id);
    }
  });

  test('runner tutorial has accusation lead-in before facility step', () {
    final steps = TutorialCopyCatalog.stepsFor(PlayerRole.runner);
    expect(steps.length, 6);
    expect(steps[3].interaction, TutorialStepInteraction.skillInstant);
    expect(steps[4].showAccusationMarker, isFalse);
    expect(steps[5].showAccusationMarker, isTrue);
  });

  test('hunter tutorial includes map placement skill step', () {
    final steps = TutorialCopyCatalog.stepsFor(PlayerRole.hunter);
    expect(steps.length, 6);
    expect(steps[4].interaction, TutorialStepInteraction.skillMapPlace);
    expect(steps[4].text, contains('②地図を長押し'));
    expect(steps[5].interaction, TutorialStepInteraction.chaseRunner);
  });

  test('werewolf tutorial uses instant skill for transform', () {
    final steps = TutorialCopyCatalog.stepsFor(PlayerRole.werewolf);
    expect(steps[2].interaction, TutorialStepInteraction.skillInstant);
  });

  test('werewolf tutorial finish points to guide for transform details', () {
    final finish = TutorialCopyCatalog.finishFor(PlayerRole.werewolf);
    expect(finish.body, contains('自動切替'));
    expect(finish.body, contains(GuideTerms.werewolf));
  });

  test('guide spec card ids are unique', () {
    final ids = guideSpecCardIds.toList();
    expect(ids.toSet().length, ids.length);
    expect(ids, contains('spec_skills'));
  });

  test('second game tutorial finish links map to guide sections', () {
    for (final kind in SecondGameTutorialKind.values) {
      final finish = TutorialCopyCatalog.finishForSecondGame(kind);
      for (final link in finish.relatedGuides) {
        expect(
          guideSectionById(link.sectionId),
          isNotNull,
          reason: '${kind.name} → ${link.sectionId}',
        );
      }
    }
  });

  test('second game tutorials have three steps each', () {
    for (final kind in SecondGameTutorialKind.values) {
      expect(TutorialCopyCatalog.stepsForSecondGame(kind).length, 3);
    }
  });

  test('second game tutorial kind maps from elimination rule', () {
    expect(
      secondGameTutorialKindForRule(
        EliminationAftermathRule.spectralOperative,
      ),
      SecondGameTutorialKind.echoForm,
    );
    expect(
      secondGameTutorialKindForRule(EliminationAftermathRule.revenantOni),
      SecondGameTutorialKind.vengefulShadow,
    );
    expect(
      secondGameTutorialKindForRule(EliminationAftermathRule.ghostSpectator),
      isNull,
    );
  });

  test('second game tutorial offer prefs keys are distinct', () {
    expect(
      OnboardingPrefs.secondGameTutorialOfferKeyFor('echoForm'),
      isNot(OnboardingPrefs.secondGameTutorialOfferKeyFor('vengefulShadow')),
    );
  });

  testWidgets('all guide diagram types build without error', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => SingleChildScrollView(
              child: Column(
                children: [
                  for (final type in GuideDiagramType.values)
                    buildGuideDiagram(context, type),
                ],
              ),
            ),
          ),
        ),
      ),
    );
    expect(tester.takeException(), isNull);
  });

  test('new guide sections reference valid diagram types', () {
    expect(
      guideSectionById('info')?.cards.any((c) => c.id == 'info_strength'),
      isTrue,
    );
    expect(
      guideSectionById('online')?.sectionDiagram?.type,
      GuideDiagramType.onlineMatch,
    );
    expect(
      guideSectionById('online')?.sectionDiagram?.title,
      contains('通話'),
    );
  });

  test('echo form and vengeful shadow tutorials differ', () {
    final echo = TutorialCopyCatalog.stepsForSecondGame(
      SecondGameTutorialKind.echoForm,
    );
    final shadow = TutorialCopyCatalog.stepsForSecondGame(
      SecondGameTutorialKind.vengefulShadow,
    );
    expect(echo.first.text, contains('残響体'));
    expect(shadow.first.text, contains('復讐の鬼影'));
    expect(echo[1].showTerminal, isTrue);
    expect(shadow[2].showCamera, isTrue);
  });
}
