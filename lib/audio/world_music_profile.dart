import 'package:flutter/material.dart';

import 'audio_library.dart';

/// BGM レイヤースロット（Base + Ambient + Tension + Moment）。
enum WorldMusicLayer {
  base,
  ambient,
  tension,
  moment,
}

/// レイヤー1枚分のトラック指定（BGM または環境音ループ）。
class LayerTrackRef {
  const LayerTrackRef.bgm(this.bgm, {this.gain = 1.0})
      : ambient = null;

  const LayerTrackRef.ambient(this.ambient, {this.gain = 1.0}) : bgm = null;

  final BgmId? bgm;
  final AmbientId? ambient;
  final double gain;
}

/// 世界観ごとの4レイヤー構成。
class WorldMusicLayers {
  const WorldMusicLayers({
    required this.base,
    this.titleBase,
    this.matchBase,
    this.ambient,
    this.tension,
    this.moment,
  });

  final LayerTrackRef base;

  /// Title / Gallery 用（未指定時は [base]）。
  final LayerTrackRef? titleBase;

  /// 試合専用ループ（未指定時は [base] と同じ）。
  final LayerTrackRef? matchBase;
  final LayerTrackRef? ambient;
  final LayerTrackRef? tension;
  final LayerTrackRef? moment;

  LayerTrackRef get effectiveTitleBase => titleBase ?? base;
  LayerTrackRef get effectiveMatchBase => matchBase ?? base;
}

/// 世界観ごとの音楽プロファイル（MP3 差し替え前提の設計）。
class WorldMusicProfile {
  const WorldMusicProfile({
    required this.introMusic,
    required this.loopMusic,
    required this.galleryPreviewMusic,
    required this.finalMinuteMusic,
    required this.victoryMusic,
    required this.loseMusic,
    required this.drawMusic,
    required this.resultPauseMs,
    required this.crossFadeMs,
    required this.ambientGain,
    required this.volumeCurve,
    required this.layers,
    this.lobbyGain = 0.62,
    this.matchBaseGain = 0.88,
    this.dangerTensionBoost = 0.28,
    this.finalFiveMinTensionGain = 0.38,
    this.finalMinuteTensionGain = 0.62,
    this.finalTenSecMomentGain = 0.55,
    this.countdownSilenceMs = 180,
    this.countdownIntroGain = 0.72,
    this.galleryPreviewSeconds = 15,
    this.captureDuckDb = 3.0,
    this.captureDuckHoldMs = 480,
    this.accusationSilenceMs = 220,
    this.matchAmbientOneShotsEnabled = true,
    this.replayMusic,
    this.replayGain = 0.4,
    this.replayAmbientGain = 0.14,
  });

  final BgmId introMusic;
  final BgmId loopMusic;
  final BgmId galleryPreviewMusic;
  final BgmId finalMinuteMusic;
  final BgmId victoryMusic;
  final BgmId loseMusic;
  final BgmId drawMusic;

  /// リザルト前の無音（ms）。[WorldStudioIdentity.silence.resultPauseMs] と揃える。
  final int resultPauseMs;

  /// レイヤー／世界観切替のクロスフェード（ms）。null 禁止。
  final int crossFadeMs;

  /// Ambient レイヤーの基準ゲイン（0..1、BGM マスターに対する相対）。
  final double ambientGain;

  /// フェード用カーブ。
  final Curve volumeCurve;

  final WorldMusicLayers layers;

  final double lobbyGain;
  final double matchBaseGain;
  final double dangerTensionBoost;
  final double finalFiveMinTensionGain;
  final double finalMinuteTensionGain;
  final double finalTenSecMomentGain;
  final int countdownSilenceMs;
  final double countdownIntroGain;
  final int galleryPreviewSeconds;
  final double captureDuckDb;
  final int captureDuckHoldMs;
  final int accusationSilenceMs;

  /// 対戦中のワンショット環境音（40–120s）を有効にするか。
  ///
  /// 常時 Ambient レイヤーがある世界観は `false` にして二重再生を防ぐ。
  final bool matchAmbientOneShotsEnabled;

  /// リプレイ専用（未指定時は [galleryPreviewMusic]）。
  final BgmId? replayMusic;
  final double replayGain;
  final double replayAmbientGain;

  BgmId get effectiveReplayMusic => replayMusic ?? galleryPreviewMusic;
}
