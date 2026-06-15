import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oni_game/audio/audio_library.dart';
import 'package:oni_game/audio/bgm_layer_engine.dart';
import 'package:oni_game/audio/game_audio.dart';
import 'package:oni_game/audio/world_audio_director.dart';
import 'package:oni_game/audio/world_audio_state.dart';
import 'package:oni_game/audio/world_music_profile.dart';
import 'package:oni_game/audio/world_music_profile_catalog.dart';
import 'package:oni_game/presentation/world/world_presentation_catalog.dart';
import 'package:oni_game/presentation/world/world_studio_identity_catalog.dart';
import 'package:oni_game/session/audio_prefs.dart';
import 'package:oni_game/theme/world_fx_profile.dart';
import 'package:oni_game/theme/world_profile.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('WorldMusicProfileCatalog', () {
    test('every world has a profile with non-null crossFade', () {
      for (final profile in WorldProfile.values) {
        final music = WorldMusicProfileCatalog.of(profile);
        expect(music.crossFadeMs, greaterThan(0));
        expect(music.loopMusic.asset, isNotEmpty);
        expect(music.galleryPreviewMusic.asset, isNotEmpty);
        expect(music.victoryMusic.asset, isNotEmpty);
        expect(music.loseMusic.asset, isNotEmpty);
        expect(music.layers.base.bgm, isNotNull);
      }
    });

    test('gallery preview duration is 15 seconds', () {
      for (final profile in WorldProfile.values) {
        expect(
          WorldMusicProfileCatalog.of(profile).galleryPreviewSeconds,
          15,
        );
      }
    });
  });

  group('Presentation coverage', () {
    test('WorldPresentationCatalog covers eight worlds', () {
      for (final profile in WorldProfile.values) {
        expect(WorldPresentationCatalog.of(profile).profile, profile);
      }
    });

    test('WorldStudioIdentityCatalog covers eight worlds', () {
      for (final profile in WorldProfile.values) {
        expect(WorldStudioIdentityCatalog.of(profile).profile, profile);
      }
    });

    test('WorldFxCatalog covers eight worlds', () {
      for (final profile in WorldProfile.values) {
        expect(WorldFxCatalog.forProfile(profile).profile, profile);
      }
    });

    test('display names avoid internal enum ids', () {
      for (final profile in WorldProfile.values) {
        final label = profile.label;
        expect(label, isNot(contains('sport')));
        expect(label, isNot(contains('arg')));
        expect(label, isNot(contains('japaneseLuxury')));
        expect(label, isNot(contains('westernLuxury')));
      }
      expect(WorldProfile.japaneseLuxury.label, 'Zen Kyoto');
      expect(WorldProfile.westernLuxury.label, 'Royal Classic');
    });
  });

  group('BgmLayerEngine', () {
    test('does not play after dispose', () async {
      final engine = BgmLayerEngine(resolveAsset: (_, __) => 'audio/bgm/cyber.mp3');
      await engine.dispose();
      expect(engine.isDisposed, isTrue);
      await engine.setLayer(
        slot: WorldMusicLayer.base,
        track: LayerTrackRef.bgm(BgmId.cyber),
        relativeGain: 1,
        loop: true,
        crossFadeMs: 100,
        curve: Curves.linear,
      );
      await engine.stopAll();
      expect(engine.isDisposed, isTrue);
    });
  });

  group('WorldAudioDirector', () {
    test('covers all audio states', () {
      expect(kWorldAudioDirectorStates.length, WorldAudioState.values.length);
      for (final state in WorldAudioState.values) {
        expect(kWorldAudioDirectorStates, contains(state));
      }
    });

    test('enter does not throw for each state (legacy mode)', () async {
      GameAudio.instance.settings.value = const AudioSettings(
        worldBgmEnabled: false,
        bgmChoice: AudioSettings.bgmOff,
      );
      final director = WorldAudioDirector.instance;
      for (final profile in WorldProfile.values) {
        director.bindProfile(profile);
        for (final state in WorldAudioState.values) {
          await expectLater(
            director.enter(state, profile: profile),
            completes,
          );
        }
      }
    });

    test('layer state transitions do not throw in legacy mode', () async {
      GameAudio.instance.settings.value = const AudioSettings(
        worldBgmEnabled: false,
        bgmChoice: AudioSettings.bgmOff,
      );
      final director = WorldAudioDirector.instance;
      final profile = WorldProfile.sciFi;
      director.bindProfile(profile);
      await director.enter(WorldAudioState.match, profile: profile);
      director.onMatchTick(299);
      director.onMatchTick(59);
      director.onMatchTick(9);
      director.setDangerActive(true);
      director.setDangerActive(false);
      await director.onCaptureMoment();
      await director.onAccusationUnlock();
      await director.onAccusationSequence();
    });

    test('world BGM off skips layered preview', () async {
      GameAudio.instance.settings.value = const AudioSettings(
        worldBgmEnabled: false,
      );
      final director = WorldAudioDirector.instance;
      director.bindProfile(WorldProfile.horror);
      await director.enter(WorldAudioState.gallery, profile: WorldProfile.horror);
      await director.previewGalleryBgm(WorldProfile.horror);
      expect(director.isGalleryPreviewActive, isFalse);
      expect(GameAudio.instance.layersActive, isFalse);
    });

    test('gallery preview timer restores after 15 seconds', () async {
      GameAudio.instance.settings.value = const AudioSettings();
      final director = WorldAudioDirector.instance;
      director.bindProfile(WorldProfile.sport);
      await director.enter(WorldAudioState.gallery, profile: WorldProfile.sport);
      await director.previewGalleryBgm(WorldProfile.sport);
      expect(director.isGalleryPreviewActive, isTrue);
      await Future<void>.delayed(const Duration(seconds: 15));
      expect(director.isGalleryPreviewActive, isFalse);
    });

    test('onMatchTick does not re-enter same climax state', () async {
      GameAudio.instance.settings.value = const AudioSettings(
        worldBgmEnabled: false,
        bgmChoice: AudioSettings.bgmOff,
      );
      final director = WorldAudioDirector.instance;
      director.bindProfile(WorldProfile.arg);
      await director.enter(WorldAudioState.finalMinute, profile: WorldProfile.arg);
      director.onMatchTick(45);
      expect(director.state, WorldAudioState.finalMinute);
    });
  });

  group('AudioSettings', () {
    test('layeredBgmEnabled respects world and bgm toggles', () {
      const on = AudioSettings();
      expect(on.layeredBgmEnabled, isTrue);
      expect(
        const AudioSettings(worldBgmEnabled: false).layeredBgmEnabled,
        isFalse,
      );
      expect(
        const AudioSettings(bgmChoice: AudioSettings.bgmOff).layeredBgmEnabled,
        isFalse,
      );
    });
  });
}
