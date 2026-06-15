import 'package:flutter_test/flutter_test.dart';

import 'package:oni_game/presentation/world/world_presentation_pack.dart';
import 'package:oni_game/presentation/world/world_presentation_catalog.dart';
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

  test('luxury profiles use distinct accent colors from magical', () {
    final zen = WorldPresentationCatalog.of(WorldProfile.japaneseLuxury);
    final magical = WorldPresentationCatalog.of(WorldProfile.magical);
    expect(zen.accent, isNot(magical.accent));
    expect(zen.momentParticle, WorldParticleKind.goldInk);
    expect(magical.momentParticle, WorldParticleKind.sparks);
  });

  test('Zen Kyoto and Royal Classic have Japanese/English result copy', () {
    final zen = WorldPresentationCatalog.of(WorldProfile.japaneseLuxury);
    final royal = WorldPresentationCatalog.of(WorldProfile.westernLuxury);
    expect(zen.resultHeadlineWin, contains('静'));
    expect(royal.resultHeadlineWin, 'VERDICT');
  });
}
