import 'package:flutter/material.dart';

import '../presentation/world/world_studio_identity_catalog.dart';
import '../theme/world_profile.dart';
import 'audio_library.dart';
import 'world_music_profile.dart';

/// 8 世界観の音楽プロファイル（最終統合版）。
abstract final class WorldMusicProfileCatalog {
  /// `true` のとき Astronomy Match は従来の [BgmId.space] を使用（比較用）。
  static const astronomyUseLegacySpaceBgm = false;

  static WorldMusicProfile of(WorldProfile profile) => switch (profile) {
        WorldProfile.horror => _horror,
        WorldProfile.sport => _sport,
        WorldProfile.sciFi => _sciFi,
        WorldProfile.arg => _arg,
        WorldProfile.magical => _magical,
        WorldProfile.astronomy => _astronomy,
        WorldProfile.japaneseLuxury => _zen,
        WorldProfile.westernLuxury => _royal,
      };

  static Iterable<WorldProfile> get profiles => WorldProfile.values;

  static int resultPauseFor(WorldProfile profile) {
    final studio = WorldStudioIdentityCatalog.of(profile);
    return studio.silence.resultPauseMs;
  }

  static int crossFadeFor(WorldProfile profile) {
    final music = of(profile);
    final studio = WorldStudioIdentityCatalog.of(profile);
    return music.crossFadeMs + studio.silence.transitionBreathMs ~/ 2;
  }

  // Urban Horror — Silent シリーズ + 雨（常時）/ 風（ワンショット）
  static final _horror = WorldMusicProfile(
    introMusic: BgmId.urbanSilentTension,
    loopMusic: BgmId.urbanSilentPursuit,
    galleryPreviewMusic: BgmId.urbanSilentTension,
    finalMinuteMusic: BgmId.urbanSilentPursuit,
    victoryMusic: BgmId.urbanSilentPursuit,
    loseMusic: BgmId.urbanSilentTension,
    drawMusic: BgmId.urbanSilentTension,
    resultPauseMs: resultPauseFor(WorldProfile.horror),
    crossFadeMs: 1200,
    ambientGain: 0.26,
    volumeCurve: Curves.easeInOutQuad,
    lobbyGain: 0.62,
    matchBaseGain: 0.76,
    countdownSilenceMs: 200,
    matchAmbientOneShotsEnabled: true,
    replayMusic: BgmId.astroDeepUnderscore,
    replayAmbientGain: 0.12,
    layers: WorldMusicLayers(
      titleBase: LayerTrackRef.bgm(BgmId.urbanSilentTension),
      base: LayerTrackRef.bgm(BgmId.urbanSilentPursuit),
      matchBase: LayerTrackRef.bgm(BgmId.urbanSilentPursuit),
      ambient: LayerTrackRef.ambient(AmbientId.urbanRainCity, gain: 0.22),
      tension: LayerTrackRef.ambient(AmbientId.wind, gain: 0.2),
      moment: LayerTrackRef.bgm(BgmId.urbanSilentShot, gain: 0.5),
    ),
  );

  // Pop City — 変更なし
  static final _sport = WorldMusicProfile(
    introMusic: BgmId.pop,
    loopMusic: BgmId.pop,
    galleryPreviewMusic: BgmId.pop2,
    finalMinuteMusic: BgmId.pop2,
    victoryMusic: BgmId.pop2,
    loseMusic: BgmId.pop,
    drawMusic: BgmId.pop,
    resultPauseMs: resultPauseFor(WorldProfile.sport),
    crossFadeMs: 480,
    ambientGain: 0.28,
    volumeCurve: Curves.elasticOut,
    lobbyGain: 0.68,
    matchBaseGain: 0.92,
    countdownSilenceMs: 80,
    matchAmbientOneShotsEnabled: true,
    replayMusic: BgmId.pop2,
    replayGain: 0.36,
    layers: WorldMusicLayers(
      base: LayerTrackRef.bgm(BgmId.pop),
      matchBase: LayerTrackRef.bgm(BgmId.pop2),
      ambient: LayerTrackRef.ambient(AmbientId.popCity, gain: 0.38),
      tension: LayerTrackRef.bgm(BgmId.pop2, gain: 0.45),
      moment: LayerTrackRef.bgm(BgmId.funky, gain: 0.5),
    ),
  );

  // Cyber Night — cyber（Title）/ suspense（Lobby・Match）/ deep ambient
  static final _sciFi = WorldMusicProfile(
    introMusic: BgmId.cyber,
    loopMusic: BgmId.cyberSuspense,
    galleryPreviewMusic: BgmId.cyber,
    finalMinuteMusic: BgmId.cyberSuspense,
    victoryMusic: BgmId.cyberSuspense,
    loseMusic: BgmId.cyber,
    drawMusic: BgmId.cyber,
    resultPauseMs: resultPauseFor(WorldProfile.sciFi),
    crossFadeMs: 420,
    ambientGain: 0.26,
    volumeCurve: Curves.easeOutExpo,
    lobbyGain: 0.64,
    matchBaseGain: 0.84,
    countdownSilenceMs: 60,
    matchAmbientOneShotsEnabled: false,
    replayMusic: BgmId.cyber,
    replayGain: 0.34,
    layers: WorldMusicLayers(
      titleBase: LayerTrackRef.bgm(BgmId.cyber, gain: 0.7),
      base: LayerTrackRef.bgm(BgmId.cyberSuspense),
      matchBase: LayerTrackRef.bgm(BgmId.cyberSuspense),
      ambient: LayerTrackRef.ambient(AmbientId.cyberAmbientDeep, gain: 0.28),
      moment: LayerTrackRef.ambient(AmbientId.sonar, gain: 0.22),
    ),
  );

  // Stealth Tactical — 現状維持
  static final _arg = WorldMusicProfile(
    introMusic: BgmId.tactical,
    loopMusic: BgmId.tactical,
    galleryPreviewMusic: BgmId.tactical,
    finalMinuteMusic: BgmId.tactical,
    victoryMusic: BgmId.tactical,
    loseMusic: BgmId.tactical,
    drawMusic: BgmId.tactical,
    resultPauseMs: resultPauseFor(WorldProfile.arg),
    crossFadeMs: 520,
    ambientGain: 0.3,
    volumeCurve: Curves.easeOutQuart,
    lobbyGain: 0.55,
    matchBaseGain: 0.78,
    countdownSilenceMs: 140,
    matchAmbientOneShotsEnabled: false,
    replayMusic: BgmId.tactical,
    replayGain: 0.32,
    layers: WorldMusicLayers(
      base: LayerTrackRef.bgm(BgmId.tactical),
      matchBase: LayerTrackRef.bgm(BgmId.horror, gain: 0.75),
      ambient: LayerTrackRef.ambient(AmbientId.argBadRadio, gain: 0.28),
      tension: LayerTrackRef.ambient(AmbientId.comms, gain: 0.24),
      moment: LayerTrackRef.bgm(BgmId.tactical, gain: 0.58),
    ),
  );

  // Magical World — Ethereal / Orchestra / Victory + fireplace
  static final _magical = WorldMusicProfile(
    introMusic: BgmId.magicalEthereal,
    loopMusic: BgmId.magicalOrchestra,
    galleryPreviewMusic: BgmId.magicalEthereal,
    finalMinuteMusic: BgmId.magicalOrchestra,
    victoryMusic: BgmId.magicalVictory,
    loseMusic: BgmId.magicalOrchestra,
    drawMusic: BgmId.magicalEthereal,
    resultPauseMs: resultPauseFor(WorldProfile.magical),
    crossFadeMs: 960,
    ambientGain: 0.3,
    volumeCurve: Curves.easeOutBack,
    lobbyGain: 0.56,
    matchBaseGain: 0.68,
    countdownSilenceMs: 220,
    matchAmbientOneShotsEnabled: false,
    replayMusic: BgmId.magicalEthereal,
    replayGain: 0.38,
    layers: WorldMusicLayers(
      titleBase: LayerTrackRef.bgm(BgmId.magicalEthereal, gain: 0.66),
      base: LayerTrackRef.bgm(BgmId.magicalOrchestra, gain: 0.58),
      matchBase: LayerTrackRef.bgm(BgmId.magicalOrchestra, gain: 0.5),
      ambient: LayerTrackRef.ambient(AmbientId.magicalFireplace, gain: 0.18),
      moment: LayerTrackRef.ambient(AmbientId.forest, gain: 0.32),
    ),
  );

  // Astronomy — Alone on Moon / Deep Underscore（space は比較用）
  static final _astronomy = WorldMusicProfile(
    introMusic: BgmId.astroAloneMoon,
    loopMusic: BgmId.astroAloneMoon,
    galleryPreviewMusic: BgmId.astroAloneMoon,
    finalMinuteMusic: astronomyUseLegacySpaceBgm
        ? BgmId.space
        : BgmId.astroDeepUnderscore,
    victoryMusic: BgmId.astroAloneMoon,
    loseMusic: BgmId.astroDeepUnderscore,
    drawMusic: BgmId.astroAloneMoon,
    resultPauseMs: resultPauseFor(WorldProfile.astronomy),
    crossFadeMs: 1100,
    ambientGain: 0.2,
    volumeCurve: Curves.easeOutCubic,
    lobbyGain: 0.52,
    matchBaseGain: 0.74,
    countdownSilenceMs: 280,
    matchAmbientOneShotsEnabled: true,
    replayMusic: BgmId.astroAloneMoon,
    replayGain: 0.36,
    layers: WorldMusicLayers(
      base: LayerTrackRef.bgm(BgmId.astroAloneMoon, gain: 0.86),
      matchBase: astronomyUseLegacySpaceBgm
          ? LayerTrackRef.bgm(BgmId.space)
          : LayerTrackRef.bgm(BgmId.astroDeepUnderscore, gain: 0.8),
      moment: LayerTrackRef.ambient(AmbientId.beep, gain: 0.28),
    ),
  );

  // Zen Kyoto — Tsukiyomi（Title/Gallery/Lobby）+ Match は Ambient のみ
  static final _zen = WorldMusicProfile(
    introMusic: BgmId.zenTsukiyomi,
    loopMusic: BgmId.zenTsukiyomi,
    galleryPreviewMusic: BgmId.zenTsukiyomi,
    finalMinuteMusic: BgmId.zenTsukiyomi,
    victoryMusic: BgmId.zenTsukiyomi,
    loseMusic: BgmId.zenTsukiyomi,
    drawMusic: BgmId.zenTsukiyomi,
    resultPauseMs: resultPauseFor(WorldProfile.japaneseLuxury),
    crossFadeMs: 1400,
    ambientGain: 0.4,
    volumeCurve: Curves.easeInOutCubic,
    lobbyGain: 0.46,
    matchBaseGain: 0.5,
    countdownSilenceMs: 320,
    finalFiveMinTensionGain: 0.18,
    finalMinuteTensionGain: 0.26,
    matchAmbientOneShotsEnabled: false,
    replayMusic: BgmId.zenTsukiyomi,
    replayGain: 0.34,
    layers: WorldMusicLayers(
      titleBase: LayerTrackRef.bgm(BgmId.zenTsukiyomi, gain: 0.5),
      base: LayerTrackRef.bgm(BgmId.zenTsukiyomi, gain: 0.44),
      matchBase: LayerTrackRef.ambient(AmbientId.zenWoodJungle, gain: 0.38),
      ambient: LayerTrackRef.ambient(AmbientId.zenWindLeaves, gain: 0.18),
      tension: LayerTrackRef.ambient(AmbientId.wind, gain: 0.16),
      moment: LayerTrackRef.ambient(AmbientId.zenBirdSubtle, gain: 0.06),
    ),
  );

  // Royal Classic — Sarabande / Larghetto / Queen of Sheba + fireplace
  static final _royal = WorldMusicProfile(
    introMusic: BgmId.royalSarabande,
    loopMusic: BgmId.royalLarghetto,
    galleryPreviewMusic: BgmId.royalSarabande,
    finalMinuteMusic: BgmId.royalSarabande,
    victoryMusic: BgmId.royalQueenOfSheba,
    loseMusic: BgmId.royalLarghetto,
    drawMusic: BgmId.royalLarghetto,
    resultPauseMs: resultPauseFor(WorldProfile.westernLuxury),
    crossFadeMs: 1300,
    ambientGain: 0.16,
    volumeCurve: Curves.easeOutQuart,
    lobbyGain: 0.54,
    matchBaseGain: 0.36,
    countdownSilenceMs: 200,
    matchAmbientOneShotsEnabled: true,
    replayMusic: BgmId.royalLarghetto,
    replayGain: 0.38,
    layers: WorldMusicLayers(
      titleBase: LayerTrackRef.bgm(BgmId.royalSarabande),
      base: LayerTrackRef.bgm(BgmId.royalLarghetto, gain: 0.9),
      matchBase: LayerTrackRef.bgm(BgmId.royalLarghetto, gain: 0.46),
      ambient: LayerTrackRef.ambient(AmbientId.royalFireplace, gain: 0.14),
      tension: LayerTrackRef.bgm(BgmId.royalSarabande, gain: 0.24),
      moment: LayerTrackRef.bgm(BgmId.royalQueenOfSheba, gain: 0.46),
    ),
  );
}
