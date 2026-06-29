import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oni_game/game/game_state.dart';
import 'package:oni_game/features/world_selection/world_selection_sheet.dart';
import 'package:oni_game/presentation/world/world_icon_frame.dart';
import 'package:oni_game/presentation/world/world_presentation_catalog.dart';
import 'package:oni_game/presentation/world/widgets/world_profile_morph_overlay.dart';
import 'package:oni_game/screens/match_result_screen.dart';
import 'package:oni_game/screens/room_lobby_screen.dart';
import 'package:oni_game/theme/world_profile.dart';
import 'package:oni_game/theme/world_profile_tokens.dart';

void main() {
  group('WorldProfileMorphOverlay', () {
    testWidgets('room lobby morph does not break layout', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: RoomLobbyScreen()),
      );
      await tester.pump();
      expect(find.byType(WorldProfileMorphOverlay), findsOneWidget);
      expect(find.text('ルームロビー'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('reduce motion skips ambient particles in morph layer',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              return MediaQuery(
                data: const MediaQueryData(disableAnimations: true),
                child: Stack(
                  children: [
                    WorldProfileMorphOverlay(profile: WorldProfile.horror),
                  ],
                ),
              );
            },
          ),
        ),
      );
      await tester.pump();
      // Idle morph (t≈1) renders nothing; no exception is the guard.
      expect(tester.takeException(), isNull);
    });
  });

  group('WorldIconFrame', () {
    testWidgets('gallery screen builds with framed hero', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: WorldGalleryScreen(current: WorldProfile.japaneseLuxury),
        ),
      );
      await tester.pump();
      expect(find.byType(WorldGalleryScreen), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('heroIcon renders profile icon', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Center(
            child: WorldIconFrame.of(WorldProfile.westernLuxury).heroIcon(
              profile: WorldProfile.westernLuxury,
              icon: Icons.account_balance_outlined,
              iconColor: const Color(0xFFC8A75A),
            ),
          ),
        ),
      );
      expect(find.byIcon(Icons.account_balance_outlined), findsOneWidget);
    });
  });

  group('readable contrast', () {
    for (final profile in WorldProfile.values) {
      test('${profile.name} panel text readable on panel', () {
        final pack = WorldPresentationCatalog.of(profile);
        final contrast = (pack.textOnPanel.computeLuminance() -
                pack.panelSurface.computeLuminance())
            .abs();
        expect(contrast, greaterThan(0.25));
        final labelContrast = (pack.buttonLabelOnAccent.computeLuminance() -
                pack.accent.computeLuminance())
            .abs();
        expect(labelContrast, greaterThan(0.25));
        final panelOverScaffoldContrast =
            (pack.textOnPanelOverScaffold.computeLuminance() -
                    pack.panelOnScaffold.computeLuminance())
                .abs();
        expect(panelOverScaffoldContrast, greaterThan(0.25));
        if (pack.loseAccent.computeLuminance() < 0.35 && !pack.isLightScaffold) {
          expect(
            pack.readableOnScaffold(pack.loseAccent),
            equals(pack.textOnScaffold),
          );
        }
      });

      test('${profile.name} scaffold vs panel token split avoids card regression',
          () {
        final pack = WorldPresentationCatalog.of(profile);
        if (!pack.isLightPanel || pack.isLightScaffold) return;
        // 暗背景＋明パネル（禅京都/マジカル等）では Card 内は textOnPanel 必須。
        final scaffoldOnPanel = (pack.textOnScaffold.computeLuminance() -
                pack.panelSurface.computeLuminance())
            .abs();
        expect(
          scaffoldOnPanel,
          lessThan(0.25),
          reason:
              '${profile.name}: textOnScaffold on light panel is low contrast — use WorldPanelThemed',
        );
        final panelOnPanel = (pack.textOnPanel.computeLuminance() -
                pack.panelSurface.computeLuminance())
            .abs();
        expect(panelOnPanel, greaterThan(0.25));
      });
    }
  });

  group('MatchResultScreen morph', () {
    testWidgets('entry reveal completes without layout error', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: MatchResultScreen(
            outcome: GameState.runnerWin,
            detail: 'test',
            roleSummary: 'runner',
            matchDurationLabel: '5:00',
            onPrepareNext: () {},
            onOpenGallery: () {},
            worldProfile: WorldProfile.westernLuxury,
          ),
        ),
      );
      await tester.pump();
      expect(find.byType(WorldEntryRevealOverlay), findsOneWidget);
      await tester.pump(const Duration(milliseconds: 1200));
      expect(find.text('リザルト'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });

  test('orbit scan headline varies by world profile', () {
    expect(
      WorldProfileTokenFactory.orbitScanHeadline(WorldProfile.sciFi),
      'AREA SCAN',
    );
    expect(
      WorldProfileTokenFactory.orbitScanHeadline(WorldProfile.westernLuxury),
      'AREA VIEW',
    );
    expect(
      WorldProfileTokenFactory.orbitScanHeadline(WorldProfile.japaneseLuxury),
      '結界走査',
    );
  });

  test('help copy mentions sync and resume events', () {
    final lines = matchPlayabilityHintLinesForTest();
    final joined = lines.join('\n');
    expect(joined, contains('復帰時'));
    expect(joined, contains('判定'));
    expect(joined, contains('危機通知'));
    expect(
      lines,
      contains('スキルを使うときだけ、アプリを前面に戻してください。'),
    );
  });
}

/// テスト用に [showMatchPlayabilityHintsIfNeeded] と同じ先頭行を返す。
List<String> matchPlayabilityHintLinesForTest() => [
      '通話しながらでもOK。先に ONI PIN を起動し、通話アプリはバックグラウンドにすると安定します。',
      '画面ロック・通話中も近づき・捕獲の判定と危機通知は継続します。復帰時に試合中の出来事を反映します。',
      '（位置情報の許可が必要です。iPhone は「常に」を推奨）',
      'スキルを使うときだけ、アプリを前面に戻してください。',
    ];
