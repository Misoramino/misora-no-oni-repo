import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oni_game/features/how_to_play/guide_diagram_type.dart';
import 'package:oni_game/features/how_to_play/widgets/guide_diagram_views.dart';
import 'package:oni_game/presentation/world/world_ui_helpers.dart';
import 'package:oni_game/theme/app_theme_factory.dart';
import 'package:oni_game/theme/world_profile.dart';
/// 前景色と背景色の明度差（簡易コントラスト指標）。
double legibilityContrast(Color foreground, Color background) =>
    (foreground.computeLuminance() - background.computeLuminance()).abs();

/// 世界観付き [MaterialApp] で子を pump する。
Widget legibilityApp({
  required WorldProfile profile,
  required Widget home,
}) {
  return MaterialApp(
    theme: AppThemeFactory.create(profile),
    home: home,
  );
}

/// 図解をパネル上に載せた状態で pump するハーネス。
class DiagramLegibilityHarness extends StatelessWidget {
  const DiagramLegibilityHarness({
    required this.profile,
    required this.type,
  });

  final WorldProfile profile;
  final GuideDiagramType type;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: WorldScaffoldThemed(
        profile: profile,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: WorldPanelThemed(
            profile: profile,
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: buildGuideDiagram(context, type),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

void expectReadable(Color foreground, Color background, {String? reason}) {
  expect(
    legibilityContrast(foreground, background),
    greaterThan(0.22),
    reason: reason,
  );
}

void expectTextColor(
  WidgetTester tester,
  Finder finder,
  Color expected, {
  String? reason,
}) {
  expect(finder, findsWidgets);
  for (final element in finder.evaluate()) {
    final text = element.widget as Text;
    expect(text.style?.color, expected, reason: reason);
  }
}
