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
      expect(b.pinStroke, isA<Color>());
      expect(b.coreColor, isA<Color>());
      expect(b.backgroundTop.a, greaterThan(0));
      expect(b.effect, isA<LaunchEffectKind>());
    }
  });

  test('pop city uses bright logo colors', () {
    final b = WorldLaunchBranding.of(WorldProfile.sport);
    expect(b.isLightBackground, isTrue);
    expect(b.pinStroke, const Color(0xFFFFFFFF));
    expect(b.glow, isNot(const Color(0x66000000)));
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
    expect(magical.accent, const Color(0xFFC9A227));

    final astro = WorldLaunchBranding.of(WorldProfile.astronomy);
    expect(astro.isLightBackground, isFalse);
    expect(astro.coreColor, const Color(0xFFFFFFFF));
    expect(astro.effect, LaunchEffectKind.astronomy);
  });

  test('cyber core is matrix green without red glow', () {
    final b = WorldLaunchBranding.of(WorldProfile.sciFi);
    expect(b.coreColor, const Color(0xFF00FF41));
    expect(b.coreGlow, const Color(0xAA00FF41));
  });

  test('tactical core is monochrome silver', () {
    final b = WorldLaunchBranding.of(WorldProfile.arg);
    expect(b.coreColor, const Color(0xFFECEFF1));
  });
}
