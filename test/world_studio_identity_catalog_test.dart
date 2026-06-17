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

    test('recommended flags are disabled in gallery UI', () {
      for (final profile in WorldProfile.values) {
        expect(
          WorldStudioIdentityCatalog.of(profile).recommended,
          isFalse,
          reason: profile.name,
        );
      }
    });
  });
}
