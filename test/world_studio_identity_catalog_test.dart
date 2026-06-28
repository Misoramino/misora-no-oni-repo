import 'package:flutter_test/flutter_test.dart';
import 'package:oni_game/presentation/world/world_studio_identity_catalog.dart';
import 'package:oni_game/theme/world_profile.dart';

void main() {
  group('WorldStudioIdentityCatalog', () {
    test('defines identity for every world profile', () {
      for (final profile in WorldProfile.values) {
        final studio = WorldStudioIdentityCatalog.of(profile);
        expect(studio.profile, profile);
        expect(studio.microcopy.confirm, isNotEmpty);
        expect(studio.microcopy.gallerySelect, isNotEmpty);
        expect(studio.resultCopy.win, isNotEmpty);
        expect(studio.motion.transitionMs, greaterThan(0));
        expect(studio.camera.tilt, inInclusiveRange(0, 65));
      }
    });

    test('worlds have distinct motion tempos', () {
      final sciFi = WorldStudioIdentityCatalog.of(WorldProfile.sciFi);
      final zen = WorldStudioIdentityCatalog.of(WorldProfile.japaneseLuxury);
      expect(sciFi.motion.transitionMs, lessThan(zen.motion.transitionMs));
    });

    test('layout rhythm has positive padding values', () {
      final layout =
          WorldStudioIdentityCatalog.of(WorldProfile.westernLuxury).layout;
      expect(layout.screenPaddingH, greaterThan(0));
      expect(layout.hudEdgeInset, greaterThanOrEqualTo(0));
    });

    // ハイブリッド言語方針: 機能マイクロコピー（決定/取消/閉じる/次/戻る/読込/
    // コーチ）は日本語に統一。gallerySelect だけは世界観の英語フレーバーを許容。
    test('functional microcopy is Japanese across all worlds', () {
      final asciiLetters = RegExp(r'[A-Za-z]');
      for (final profile in WorldProfile.values) {
        final m = WorldStudioIdentityCatalog.of(profile).microcopy;
        final functional = <String>[
          m.confirm,
          m.cancel,
          m.close,
          m.next,
          m.back,
          m.loading,
          m.coachNext,
          m.coachDone,
        ];
        for (final label in functional) {
          expect(
            asciiLetters.hasMatch(label),
            isFalse,
            reason: '${profile.name}: "$label" should be Japanese',
          );
        }
      }
    });
  });
}
