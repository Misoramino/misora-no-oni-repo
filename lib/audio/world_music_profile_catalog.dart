import 'package:flutter/material.dart';

import '../presentation/world/world_studio_identity_catalog.dart';
import '../theme/world_profile.dart';
import 'audio_library.dart';
import 'world_music_profile.dart';

/// 8 世界観の音楽プロファイル（暫定 BGM 割り当て、差し替え前提）。
abstract final class WorldMusicProfileCatalog {
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

  // Urban Horror — 雨・風・高周波テンション
  static final _horror = WorldMusicProfile(
    introMusic: BgmId.horror,
    loopMusic: BgmId.horror,
    galleryPreviewMusic: BgmId.horror,
    finalMinuteMusic: BgmId.horror,
    victoryMusic: BgmId.horror,
    loseMusic: BgmId.horror,
    drawMusic: BgmId.horror,
    resultPauseMs: resultPauseFor(WorldProfile.horror),
    crossFadeMs: 820,
    ambientGain: 0.34,
    volumeCurve: Curves.easeInOutQuad,
    lobbyGain: 0.58,
    matchBaseGain: 0.82,
    countdownSilenceMs: 200,
    layers: WorldMusicLayers(
      base: LayerTrackRef.bgm(BgmId.horror),
      ambient: LayerTrackRef.ambient(AmbientId.wind, gain: 0.42),
      tension: LayerTrackRef.bgm(BgmId.funky, gain: 0.35),
      moment: LayerTrackRef.ambient(AmbientId.wind, gain: 0.55),
    ),
  );

  // Pop City — 軽快 Base + 街 Ambient
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
    layers: WorldMusicLayers(
      base: LayerTrackRef.bgm(BgmId.pop),
      ambient: LayerTrackRef.ambient(AmbientId.popCity, gain: 0.38),
      tension: LayerTrackRef.bgm(BgmId.pop2, gain: 0.45),
      moment: LayerTrackRef.bgm(BgmId.funky, gain: 0.5),
    ),
  );

  // Cyber Night — Base + 通信ノイズ + Pulse
  static final _sciFi = WorldMusicProfile(
    introMusic: BgmId.cyber,
    loopMusic: BgmId.cyber,
    galleryPreviewMusic: BgmId.cyber,
    finalMinuteMusic: BgmId.cyber,
    victoryMusic: BgmId.cyber,
    loseMusic: BgmId.cyber,
    drawMusic: BgmId.cyber,
    resultPauseMs: resultPauseFor(WorldProfile.sciFi),
    crossFadeMs: 360,
    ambientGain: 0.32,
    volumeCurve: Curves.easeOutExpo,
    lobbyGain: 0.64,
    matchBaseGain: 0.9,
    countdownSilenceMs: 60,
    layers: WorldMusicLayers(
      base: LayerTrackRef.bgm(BgmId.cyber),
      ambient: LayerTrackRef.ambient(AmbientId.sonar, gain: 0.4),
      tension: LayerTrackRef.ambient(AmbientId.comms, gain: 0.48),
      moment: LayerTrackRef.bgm(BgmId.funky, gain: 0.42),
    ),
  );

  // Stealth Tactical — ミニマル Base + 無線
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
    layers: WorldMusicLayers(
      base: LayerTrackRef.bgm(BgmId.tactical),
      ambient: LayerTrackRef.ambient(AmbientId.comms, gain: 0.36),
      tension: LayerTrackRef.ambient(AmbientId.beep, gain: 0.32),
      moment: LayerTrackRef.bgm(BgmId.tactical, gain: 0.65),
    ),
  );

  // Magical World — 古楽器 Base + 森
  static final _magical = WorldMusicProfile(
    introMusic: BgmId.magical,
    loopMusic: BgmId.magical,
    galleryPreviewMusic: BgmId.magical,
    finalMinuteMusic: BgmId.magical,
    victoryMusic: BgmId.magical,
    loseMusic: BgmId.magical,
    drawMusic: BgmId.magical,
    resultPauseMs: resultPauseFor(WorldProfile.magical),
    crossFadeMs: 960,
    ambientGain: 0.36,
    volumeCurve: Curves.easeOutBack,
    lobbyGain: 0.6,
    matchBaseGain: 0.84,
    countdownSilenceMs: 220,
    layers: WorldMusicLayers(
      base: LayerTrackRef.bgm(BgmId.magical),
      ambient: LayerTrackRef.ambient(AmbientId.forest, gain: 0.44),
      tension: LayerTrackRef.bgm(BgmId.space, gain: 0.3),
      moment: LayerTrackRef.ambient(AmbientId.forest, gain: 0.52),
    ),
  );

  // Astronomy — パッド Base + 微かな機械音
  static final _astronomy = WorldMusicProfile(
    introMusic: BgmId.space,
    loopMusic: BgmId.space,
    galleryPreviewMusic: BgmId.space,
    finalMinuteMusic: BgmId.space,
    victoryMusic: BgmId.space,
    loseMusic: BgmId.space,
    drawMusic: BgmId.space,
    resultPauseMs: resultPauseFor(WorldProfile.astronomy),
    crossFadeMs: 1100,
    ambientGain: 0.26,
    volumeCurve: Curves.easeOutCubic,
    lobbyGain: 0.56,
    matchBaseGain: 0.8,
    countdownSilenceMs: 280,
    layers: WorldMusicLayers(
      base: LayerTrackRef.bgm(BgmId.space),
      ambient: LayerTrackRef.ambient(AmbientId.beep, gain: 0.22),
      tension: LayerTrackRef.bgm(BgmId.magical, gain: 0.28),
      moment: LayerTrackRef.ambient(AmbientId.beep, gain: 0.38),
    ),
  );

  // Zen Kyoto — 風 → 尺八(仮: magical) → 鐘(仮: beep) → 静寂
  static final _zen = WorldMusicProfile(
    introMusic: BgmId.magical,
    loopMusic: BgmId.magical,
    galleryPreviewMusic: BgmId.magical,
    finalMinuteMusic: BgmId.magical,
    victoryMusic: BgmId.magical,
    loseMusic: BgmId.magical,
    drawMusic: BgmId.magical,
    resultPauseMs: resultPauseFor(WorldProfile.japaneseLuxury),
    crossFadeMs: 1400,
    ambientGain: 0.4,
    volumeCurve: Curves.easeInOutCubic,
    lobbyGain: 0.52,
    matchBaseGain: 0.72,
    countdownSilenceMs: 320,
    finalFiveMinTensionGain: 0.28,
    finalMinuteTensionGain: 0.45,
    layers: WorldMusicLayers(
      base: LayerTrackRef.bgm(BgmId.magical, gain: 0.85),
      ambient: LayerTrackRef.ambient(AmbientId.wind, gain: 0.5),
      tension: LayerTrackRef.bgm(BgmId.space, gain: 0.25),
      moment: LayerTrackRef.ambient(AmbientId.beep, gain: 0.3),
    ),
  );

  // Royal Classic — 弦・ホールリバーブ風
  static final _royal = WorldMusicProfile(
    introMusic: BgmId.space,
    loopMusic: BgmId.space,
    galleryPreviewMusic: BgmId.space,
    finalMinuteMusic: BgmId.space,
    victoryMusic: BgmId.space,
    loseMusic: BgmId.space,
    drawMusic: BgmId.space,
    resultPauseMs: resultPauseFor(WorldProfile.westernLuxury),
    crossFadeMs: 900,
    ambientGain: 0.32,
    volumeCurve: Curves.easeOutQuart,
    lobbyGain: 0.58,
    matchBaseGain: 0.8,
    countdownSilenceMs: 200,
    layers: WorldMusicLayers(
      base: LayerTrackRef.bgm(BgmId.space),
      ambient: LayerTrackRef.ambient(AmbientId.wind, gain: 0.38),
      tension: LayerTrackRef.bgm(BgmId.magical, gain: 0.32),
      moment: LayerTrackRef.bgm(BgmId.magical, gain: 0.48),
    ),
  );
}
