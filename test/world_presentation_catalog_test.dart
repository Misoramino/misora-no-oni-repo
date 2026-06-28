import 'package:flutter_test/flutter_test.dart';

import 'package:oni_game/presentation/world/world_presentation_catalog.dart';
import 'package:oni_game/presentation/world/world_studio_identity_catalog.dart';
import 'package:oni_game/theme/world_profile.dart';

void main() {
  test('WorldPresentationCatalog covers all eight profiles', () {
    for (final p in WorldProfile.values) {
      final pack = WorldPresentationCatalog.of(p);
      expect(pack.profile, p);
      expect(pack.tagline, isNotEmpty);
      expect(pack.headlineFont, isNotEmpty);
      expect(pack.bodyFont, isNotEmpty);
    }
  });

  test('luxury and magical profiles stay visually distinct', () {
    final zen = WorldPresentationCatalog.of(WorldProfile.japaneseLuxury);
    final magical = WorldPresentationCatalog.of(WorldProfile.magical);
    expect(zen.accent, isNot(magical.accent));
    expect(zen.momentParticle, isNot(magical.momentParticle));
  });

  test('result copy lives on studio identity (resultCopy), not the pack', () {
    final zen = WorldStudioIdentityCatalog.of(WorldProfile.japaneseLuxury);
    final royal = WorldStudioIdentityCatalog.of(WorldProfile.westernLuxury);
    expect(zen.resultCopy.win, contains('静'));
    expect(royal.resultCopy.win, 'VERDICT');
  });
}
