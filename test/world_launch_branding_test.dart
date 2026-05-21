import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oni_game/theme/world_launch_branding.dart';
import 'package:oni_game/theme/world_profile.dart';

void main() {
  test('branding derives from each world profile', () {
    for (final p in WorldProfile.values) {
      final b = WorldLaunchBranding.of(p);
      expect(b.profile, p);
      expect(b.profileLabel, p.label);
      expect(b.accent, isA<Color>());
      expect(b.backgroundTop.a, greaterThan(0));
      expect(b.effect, isA<LaunchEffectKind>());
    }
  });

  test('each profile has a dedicated launch effect', () {
    expect(
      WorldLaunchBranding.of(WorldProfile.sciFi).effect,
      LaunchEffectKind.cyber,
    );
    expect(
      WorldLaunchBranding.of(WorldProfile.horror).effect,
      LaunchEffectKind.horror,
    );
    expect(
      WorldLaunchBranding.of(WorldProfile.sport).effect,
      LaunchEffectKind.pop,
    );
    expect(
      WorldLaunchBranding.of(WorldProfile.arg).effect,
      LaunchEffectKind.tactical,
    );
    expect(
      WorldLaunchBranding.of(WorldProfile.magical).effect,
      LaunchEffectKind.magical,
    );
    expect(
      WorldLaunchBranding.of(WorldProfile.astronomy).effect,
      LaunchEffectKind.astronomy,
    );
  });

  test('magical and astronomy use dark premium palettes', () {
    final magical = WorldLaunchBranding.of(WorldProfile.magical);
    expect(magical.isLightBackground, isFalse);
    expect(magical.accent, const Color(0xFFD4AF37));

    final astro = WorldLaunchBranding.of(WorldProfile.astronomy);
    expect(astro.isLightBackground, isFalse);
    expect(astro.effect, LaunchEffectKind.astronomy);
  });
}
