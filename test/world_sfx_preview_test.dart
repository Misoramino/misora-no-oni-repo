import 'package:flutter_test/flutter_test.dart';
import 'package:oni_game/audio/sfx_id.dart';
import 'package:oni_game/audio/sfx_synth.dart';
import 'package:oni_game/audio/world_sfx_debounce.dart';
import 'package:oni_game/audio/world_sfx_preview.dart';
import 'package:oni_game/theme/world_fx_profile.dart';
import 'package:oni_game/theme/world_profile.dart';

void main() {
  test('all eight profiles expose sfx volume coefficients in range', () {
    for (final p in WorldProfile.values) {
      final fx = WorldFxCatalog.forProfile(p);
      expect(fx.uiTapVolume, inInclusiveRange(0.0, 1.0), reason: p.name);
      expect(fx.revealVolume, inInclusiveRange(0.0, 1.0), reason: p.name);
      expect(fx.transitionVolume, inInclusiveRange(0.0, 1.0), reason: p.name);
    }
  });

  test('profile-specific volume overrides', () {
    expect(
      WorldFxCatalog.forProfile(WorldProfile.horror).revealVolume,
      0.58,
    );
    expect(
      WorldFxCatalog.forProfile(WorldProfile.horror).anonRevealVolume,
      0.46,
    );
    expect(
      WorldFxCatalog.forProfile(WorldProfile.horror).captureVolume,
      0.74,
    );
    expect(
      WorldFxCatalog.forProfile(WorldProfile.horror).uiTapVolume,
      0.48,
    );
    expect(
      WorldFxCatalog.forProfile(WorldProfile.sciFi).revealVolume,
      0.62,
    );
    expect(
      WorldFxCatalog.forProfile(WorldProfile.sciFi).captureVolume,
      0.66,
    );
    expect(
      WorldFxCatalog.forProfile(WorldProfile.magical).captureVolume,
      0.62,
    );
    expect(
      WorldFxCatalog.forProfile(WorldProfile.magical).uiTapVolume,
      0.50,
    );
    expect(
      WorldFxCatalog.forProfile(WorldProfile.sport).uiTapVolume,
      0.55,
    );
    expect(
      WorldFxCatalog.forProfile(WorldProfile.japaneseLuxury).uiTapVolume,
      0.22,
    );
    expect(
      WorldFxCatalog.forProfile(WorldProfile.japaneseLuxury).revealVolume,
      0.58,
    );
    expect(
      WorldFxCatalog.forProfile(WorldProfile.westernLuxury).uiTapVolume,
      0.50,
    );
    expect(
      WorldFxCatalog.forProfile(WorldProfile.westernLuxury).revealVolume,
      0.62,
    );
    expect(
      WorldFxCatalog.forProfile(WorldProfile.arg).uiTapVolume,
      0.42,
    );
    expect(
      WorldFxCatalog.forProfile(WorldProfile.arg).transitionVolume,
      0.60,
    );
    expect(
      WorldFxCatalog.forProfile(WorldProfile.astronomy).uiTapVolume,
      0.52,
    );
    expect(
      WorldFxCatalog.forProfile(WorldProfile.astronomy).revealVolume,
      0.68,
    );
  });

  test('preview maps SfxId and volume for each kind', () {
    expect(
      WorldSfxPreview.sfxIdFor(WorldSfxPreviewKind.uiTap),
      SfxId.uiTap,
    );
    expect(
      WorldSfxPreview.sfxIdFor(WorldSfxPreviewKind.reveal),
      SfxId.reveal,
    );
    expect(
      WorldSfxPreview.sfxIdFor(WorldSfxPreviewKind.transition),
      isNull,
    );
    expect(
      WorldSfxPreview.volumeFor(WorldProfile.horror, WorldSfxPreviewKind.reveal),
      0.58,
    );
    expect(
      WorldSfxPreview.volumeFor(
        WorldProfile.japaneseLuxury,
        WorldSfxPreviewKind.transition,
      ),
      0.55,
    );
    expect(
      WorldSfxPreview.volumeFor(
        WorldProfile.japaneseLuxury,
        WorldSfxPreviewKind.reveal,
      ),
      0.58,
    );
  });

  test('debounce suppresses rapid replay of same world sfx', () {
    var now = DateTime(2026, 6, 6, 12);
    final gate = WorldSfxDebounce(() => now);
    const profile = WorldProfile.sciFi;

    expect(gate.tryAcquire(profile, WorldSfxPreviewKind.uiTap), isTrue);
    expect(gate.tryAcquire(profile, WorldSfxPreviewKind.uiTap), isFalse);

    now = now.add(const Duration(milliseconds: 99));
    expect(gate.tryAcquire(profile, WorldSfxPreviewKind.uiTap), isFalse);

    now = now.add(const Duration(milliseconds: 2));
    expect(gate.tryAcquire(profile, WorldSfxPreviewKind.uiTap), isTrue);

    expect(gate.tryAcquire(profile, WorldSfxPreviewKind.reveal), isTrue);
    expect(gate.tryAcquire(profile, WorldSfxPreviewKind.reveal), isFalse);

    now = now.add(const Duration(milliseconds: 500));
    expect(gate.tryAcquire(profile, WorldSfxPreviewKind.reveal), isTrue);
    expect(
      gate.tryAcquire(profile, WorldSfxPreviewKind.transition),
      isTrue,
    );
    expect(
      gate.tryAcquire(profile, WorldSfxPreviewKind.transition),
      isFalse,
    );
  });

  test('synth fallback wav exists for previewable sfx', () {
    for (final id in [SfxId.uiTap, SfxId.reveal]) {
      final wav = SfxSynth.wavFor(id);
      expect(wav.length, greaterThan(44));
      expect(String.fromCharCodes(wav.sublist(0, 4)), 'RIFF');
    }
  });
}
