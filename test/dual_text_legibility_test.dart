import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oni_game/features/onboarding/guide_bullet_list.dart';
import 'package:oni_game/presentation/world/world_legibility.dart';
import 'package:oni_game/presentation/world/world_presentation_catalog.dart';
import 'package:oni_game/presentation/world/world_ui_helpers.dart';
import 'package:oni_game/theme/world_profile.dart';

import 'helpers/legibility_test_helpers.dart';

/// ウェルカム／遊び方と同型：暗スキャフォールド＋明パネル箇条書き。
class _DualTextHarness extends StatelessWidget {
  const _DualTextHarness({required this.profile});

  final WorldProfile profile;

  static const _scaffoldTitle = 'スキャフォールド見出し';
  static const _panelLine = 'パネル上の説明文';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: WorldScaffoldThemed(
        profile: profile,
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                _scaffoldTitle,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: context.worldBodyOnScaffold,
                    ),
              ),
              const SizedBox(height: 16),
              GuideBulletList(
                lines: const [_panelLine],
                accent: const Color(0xFF2E86DE),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

void main() {
  group('dual scaffold + panel text', () {
    for (final profile in WorldProfile.values) {
      testWidgets('${profile.name} keeps both text colors readable', (tester) async {
        final pack = WorldPresentationCatalog.of(profile);

        await tester.pumpWidget(
          legibilityApp(
            profile: profile,
            home: _DualTextHarness(profile: profile),
          ),
        );
        await tester.pumpAndSettle();

        final scaffoldText = tester.widget<Text>(find.text(_DualTextHarness._scaffoldTitle));
        final panelText = tester.widget<Text>(find.text(_DualTextHarness._panelLine));

        expect(scaffoldText.style?.color, pack.textOnScaffold);
        expect(panelText.style?.color, pack.textOn(pack.panelSurfaceOpaque));

        expectReadable(
          scaffoldText.style!.color!,
          pack.scaffoldBottom,
          reason: '$profile scaffold headline',
        );
        expectReadable(
          panelText.style!.color!,
          pack.panelSurfaceOpaque,
          reason: '$profile panel bullet',
        );

        // 暗背景＋明パネル世界では白系と黒系が同時に使われる。
        if (pack.isLightPanel && !pack.isLightScaffold) {
          expect(
            scaffoldText.style!.color!.computeLuminance(),
            greaterThan(0.5),
          );
          expect(
            panelText.style!.color!.computeLuminance(),
            lessThan(0.35),
          );
        }

        expect(tester.takeException(), isNull);
      });
    }
  });
}
