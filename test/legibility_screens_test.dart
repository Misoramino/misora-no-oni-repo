import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oni_game/features/how_to_play/guide_diagram_type.dart';
import 'package:oni_game/features/how_to_play/guide_sections.dart';
import 'package:oni_game/features/how_to_play/how_to_play_screen.dart';
import 'package:oni_game/presentation/world/world_presentation_catalog.dart';
import 'package:oni_game/theme/world_profile.dart';

import 'helpers/legibility_test_helpers.dart';

/// 暗背景＋明パネルで過去に不具合が出た世界観。
const _highRiskProfiles = [
  WorldProfile.magical,
  WorldProfile.japaneseLuxury,
];

/// 明背景世界観。
const _lightScaffoldProfiles = [
  WorldProfile.sport,
  WorldProfile.westernLuxury,
];

void main() {
  group('HowToPlayScreen legibility', () {
    for (final profile in [
      ..._highRiskProfiles,
      ..._lightScaffoldProfiles,
      WorldProfile.horror,
      WorldProfile.sciFi,
    ]) {
      testWidgets('${profile.name} header and index use scaffold/panel tokens',
          (tester) async {
        final pack = WorldPresentationCatalog.of(profile);

        await tester.pumpWidget(
          legibilityApp(
            profile: profile,
            home: const HowToPlayScreen(),
          ),
        );
        await tester.pumpAndSettle();

        expectTextColor(
          tester,
          find.text(guideHeader.title),
          pack.textOnPanel,
          reason: 'header title on panel card',
        );
        expectTextColor(
          tester,
          find.text(guideHeader.indexPrompt),
          pack.textOnScaffold,
          reason: 'index prompt on scaffold gradient',
        );

        // 章チップ（明パネル上・継承色含む）
        for (final chip in tester.widgetList<ActionChip>(find.byType(ActionChip))) {
          final label = chip.label;
          if (label is! Text) continue;
          final bg = chip.backgroundColor ?? pack.panelSurfaceOpaque;
          final color = label.style?.color ?? pack.textOnPanel;
          expectReadable(
            color,
            bg,
            reason: '${profile.name} index chip "${label.data}"',
          );
        }

        expect(tester.takeException(), isNull);
      });
    }

    for (final profile in WorldProfile.values) {
      testWidgets('${profile.name} expands win section without error',
          (tester) async {
        await tester.pumpWidget(
          legibilityApp(profile: profile, home: const HowToPlayScreen()),
        );
        await tester.pumpAndSettle();

        final winTitle = guideSectionById('win')!.title;
        final chipFinder = find.byWidgetPredicate(
          (w) =>
              w is ActionChip &&
              w.label is Text &&
              (w.label as Text).data == winTitle,
        );
        await tester.tap(chipFinder.first);
        await tester.pumpAndSettle();

        expect(find.text('関連'), findsWidgets);
        expect(tester.takeException(), isNull);
      });
    }
  });

  group('Guide diagrams on panel', () {
    for (final profile in WorldProfile.values) {
      for (final type in GuideDiagramType.values) {
        testWidgets('${profile.name} / $type builds with panel theme',
            (tester) async {
          final pack = WorldPresentationCatalog.of(profile);
          final panelBg = pack.panelSurfaceOpaque;

          await tester.pumpWidget(
            legibilityApp(
              profile: profile,
              home: DiagramLegibilityHarness(profile: profile, type: type),
            ),
          );
          await tester.pumpAndSettle();

          final card = tester.element(find.byType(Card).first);
          final panelTheme = Theme.of(card);
          final inheritedBody = panelTheme.textTheme.bodyMedium?.color ??
              panelTheme.colorScheme.onSurface;
          expectReadable(
            inheritedBody,
            panelBg,
            reason: '$profile $type inherited body on panel',
          );

          for (final text in tester.widgetList<Text>(find.byType(Text))) {
            final color = text.style?.color;
            if (color == null || color.a < 0.5) continue;
            // セマンティック色（赤・緑・紫バッジ等）はスキップ。
            final lum = color.computeLuminance();
            final panelLum = panelBg.computeLuminance();
            final looksLikeBody =
                (lum < 0.35 && panelLum > 0.45) ||
                (lum > 0.55 && panelLum < 0.45);
            if (!looksLikeBody) continue;
            expectReadable(
              color,
              panelBg,
              reason: '$profile $type "${text.data}"',
            );
          }

          expect(tester.takeException(), isNull);
        });
      }
    }
  });
}
