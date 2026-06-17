import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oni_game/audio/audio_library.dart';
import 'package:oni_game/theme/accusation_facility_copy.dart';
import 'package:oni_game/theme/world_fx_profile.dart';
import 'package:oni_game/theme/world_launch_branding.dart';
import 'package:oni_game/theme/world_profile.dart';
import 'package:oni_game/theme/world_visual_pack_factory.dart';

void main() {
  test('WorldProfile has eight entries', () {
    expect(WorldProfile.values, hasLength(8));
    expect(WorldProfile.values, contains(WorldProfile.japaneseLuxury));
    expect(WorldProfile.values, contains(WorldProfile.westernLuxury));
  });

  test('each profile exposes label assetKey storageName', () {
    for (final p in WorldProfile.values) {
      expect(p.label, isNotEmpty, reason: '${p.name} label');
      expect(p.assetKey, isNotEmpty, reason: '${p.name} assetKey');
      expect(p.storageName, isNotEmpty, reason: '${p.name} storageName');
      expect(p.storageName, p.name);
    }
    expect(WorldProfile.japaneseLuxury.label, 'Zen Kyoto');
    expect(WorldProfile.japaneseLuxury.assetKey, 'japanese_luxury');
    expect(WorldProfile.westernLuxury.label, 'Royal Classic');
    expect(WorldProfile.westernLuxury.assetKey, 'western_luxury');
  });

  test('WorldFxCatalog covers all profiles', () {
    for (final p in WorldProfile.values) {
      final fx = WorldFxCatalog.forProfile(p);
      expect(fx.profile, p);
      expect(fx.namedRevealBanner, isNotEmpty);
    }
  });

  test('WorldVisualPackFactory covers all profiles', () {
    for (final p in WorldProfile.values) {
      final pack = WorldVisualPackFactory.of(p);
      expect(pack.profile, p);
      expect(pack.mapStyleAssetPath, contains('assets/map_styles/'));
      expect(pack.tokens.markerAccent, isA<Color>());
    }
    expect(
      WorldVisualPackFactory.of(WorldProfile.japaneseLuxury).mapStyleAssetPath,
      contains('japanese_luxury'),
    );
    expect(
      WorldVisualPackFactory.of(WorldProfile.westernLuxury).mapStyleAssetPath,
      contains('western_luxury'),
    );
  });

  test('WorldLaunchBranding covers all profiles', () {
    for (final p in WorldProfile.values) {
      final b = WorldLaunchBranding.of(p);
      expect(b.profile, p);
      expect(b.profileLabel, p.label);
      expect(b.effect, isA<LaunchEffectKind>());
    }
  });

  test('AccusationFacilityCopy covers all profiles', () {
    for (final p in WorldProfile.values) {
      final copy = AccusationFacilityCopy.forProfile(p);
      expect(copy.facilityName, isNotEmpty);
      expect(copy.unlockLines, isNotEmpty);
      expect(copy.accuseActionLabel, isNotEmpty);
    }
    expect(
      AccusationFacilityCopy.forProfile(WorldProfile.japaneseLuxury).facilityName,
      '陰陽寮',
    );
    expect(
      AccusationFacilityCopy.forProfile(WorldProfile.westernLuxury).facilityName,
      '宮廷調査局',
    );
  });

  test('luxury profiles use polish-pass BGM and ambient', () {
    expect(WorldAudio.defaultBgm(WorldProfile.japaneseLuxury), BgmId.zenTsukiyomi);
    expect(WorldAudio.defaultBgm(WorldProfile.westernLuxury), BgmId.royalLarghetto);
    expect(WorldAudio.ambient(WorldProfile.japaneseLuxury), AmbientId.zenWoodJungle);
    expect(WorldAudio.ambient(WorldProfile.westernLuxury), AmbientId.royalFireplace);
  });
}
