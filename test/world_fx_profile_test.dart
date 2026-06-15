import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oni_game/audio/sfx_id.dart';
import 'package:oni_game/theme/world_fx_profile.dart';
import 'package:oni_game/theme/world_profile.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('WorldFxCatalog defines all eight profiles', () {
    for (final p in WorldProfile.values) {
      final fx = WorldFxCatalog.forProfile(p);
      expect(fx.profile, p);
      expect(fx.namedRevealBanner, isNotEmpty);
      expect(fx.uiTapAsset, 'ui_tap');
    }
  });

  test('assetBaseFor maps SfxId to world asset names', () {
    final fx = WorldFxCatalog.forProfile(WorldProfile.sciFi);
    expect(fx.assetBaseFor(SfxId.reveal), 'reveal');
    expect(fx.assetBaseFor(SfxId.uiTap), 'ui_tap');
    expect(fx.transitionAsset, 'transition');
  });

  test('anon reveal is subtler than named reveal', () {
    final fx = WorldFxCatalog.forProfile(WorldProfile.horror);
    expect(
      fx.anonRevealFlashMs,
      lessThan(fx.namedRevealFlashMs),
    );
    expect(
      fx.anonRevealFlashOpacity,
      lessThan(fx.namedRevealFlashOpacity),
    );
  });

  test('expectedWorldAssetPaths lists world folder paths', () {
    final paths = WorldFxCatalog.expectedWorldAssetPaths(WorldProfile.magical);
    expect(
      paths.any((p) => p.contains('assets/audio/sfx/worlds/magical/reveal.')),
      isTrue,
    );
  });

  test('P0 world SFX wav files are bundled', () async {
    await _expectBundledWorldSfx({
      WorldProfile.sciFi: ['ui_tap', 'reveal', 'transition'],
      WorldProfile.magical: ['ui_tap', 'reveal', 'transition'],
      WorldProfile.horror: ['ui_tap', 'reveal', 'transition'],
    });
  });

  test('P1 world SFX wav files are bundled', () async {
    await _expectBundledWorldSfx({
      WorldProfile.sport: ['ui_tap', 'reveal', 'transition'],
      WorldProfile.arg: ['ui_tap', 'reveal', 'transition'],
      WorldProfile.astronomy: ['ui_tap', 'reveal', 'transition'],
    });
  });

  test('P2 luxury world SFX wav files are bundled', () async {
    await _expectBundledWorldSfx({
      WorldProfile.japaneseLuxury: ['ui_tap', 'reveal', 'transition'],
      WorldProfile.westernLuxury: ['ui_tap', 'reveal', 'transition'],
    });
  });

  test('all profiles define default volume coefficients', () {
    for (final p in WorldProfile.values) {
      final fx = WorldFxCatalog.forProfile(p);
      expect(fx.uiTapVolume, greaterThan(0));
      expect(fx.revealVolume, greaterThan(0));
      expect(fx.transitionVolume, greaterThan(0));
    }
  });
}

Future<void> _expectBundledWorldSfx(
  Map<WorldProfile, List<String>> worlds,
) async {
  final manifest = await AssetManifest.loadFromAssetBundle(rootBundle);
  final assets = manifest.listAssets().toSet();
  for (final entry in worlds.entries) {
    for (final base in entry.value) {
      final path =
          'assets/audio/sfx/worlds/${entry.key.storageName}/$base.wav';
      expect(assets, contains(path), reason: 'missing $path');
    }
  }
}