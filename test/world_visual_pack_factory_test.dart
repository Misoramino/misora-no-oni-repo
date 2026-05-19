import 'package:flutter_test/flutter_test.dart';
import 'package:oni_game/theme/world_profile.dart';
import 'package:oni_game/theme/world_visual_pack_factory.dart';

void main() {
  test('horror pack enables VHS and reveal noise', () {
    final pack = WorldVisualPackFactory.of(WorldProfile.horror);
    expect(pack.useVhsOverlay, isTrue);
    expect(pack.useRevealNoise, isTrue);
    expect(pack.photoOnlyOnReveal, isTrue);
    expect(pack.revealFlashColor, isNotNull);
  });

  test('sport pack enables pin bounce flash', () {
    final pack = WorldVisualPackFactory.of(WorldProfile.sport);
    expect(pack.usePinBounceFlash, isTrue);
    expect(pack.showPhotoPinByDefault, isTrue);
    expect(pack.vignetteColor, isNull);
  });

  test('all profiles expose overlay token colors', () {
    for (final p in WorldProfile.values) {
      final pack = WorldVisualPackFactory.of(p);
      expect(pack.tokens.playAreaColor, isNotNull);
      expect(pack.tokens.captureZoneColor, isNotNull);
      expect(pack.mapStyleAssetPath, contains('assets/map_styles/'));
    }
  });
}
