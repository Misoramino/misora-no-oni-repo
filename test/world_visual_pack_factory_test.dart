import 'package:flutter_test/flutter_test.dart';
import 'package:oni_game/features/game_map/map/map_zoom_lod.dart';
import 'package:oni_game/theme/world_profile.dart';
import 'package:oni_game/theme/world_visual_pack_factory.dart';

void main() {
  test('horror pack enables VHS and reveal noise', () {
    final pack = WorldVisualPackFactory.of(WorldProfile.horror);
    expect(pack.useVhsOverlay, isTrue);
    expect(pack.useRevealNoise, isTrue);
    expect(pack.photoOnlyOnReveal, isTrue);
    expect(pack.revealFlashColor, isNotNull);
    expect(pack.lodPolicy, MapZoomLodPolicy.urbanHorror);
    expect(pack.layerDefaults.ghostRough, isFalse);
  });

  test('sport pack enables pin bounce flash', () {
    final pack = WorldVisualPackFactory.of(WorldProfile.sport);
    expect(pack.usePinBounceFlash, isTrue);
    expect(pack.showPhotoPinByDefault, isTrue);
    expect(pack.vignetteColor, isNull);
    expect(pack.lodPolicy, MapZoomLodPolicy.popCity);
  });

  test('sci-fi uses cyber night LOD and scan overlay', () {
    final pack = WorldVisualPackFactory.of(WorldProfile.sciFi);
    expect(pack.useScanOverlay, isTrue);
    expect(pack.lodPolicy, MapZoomLodPolicy.cyberNight);
  });

  test('stealth tactical uses sparse markers policy', () {
    final pack = WorldVisualPackFactory.of(WorldProfile.arg);
    expect(pack.lodPolicy, MapZoomLodPolicy.stealthTactical);
    expect(pack.layerDefaults.traces, isFalse);
    expect(pack.layerDefaults.reveals, isFalse);
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
