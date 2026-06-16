import 'dart:async';

import '../presentation/world/world_studio_identity.dart';
import '../presentation/world/world_studio_identity_catalog.dart';
import '../session/audio_prefs.dart';
import '../theme/world_profile.dart';
import 'audio_library.dart';
import 'game_audio.dart';
import 'world_audio_state.dart';
import 'world_music_profile.dart';
import 'world_music_profile_catalog.dart';

/// ゲーム状態に応じて「何を鳴らすか」だけを管理するオーディオディレクター。
///
/// ゲームロジック・通信・同期には一切触れない。Presentation 層から呼ぶ。
class WorldAudioDirector {
  WorldAudioDirector._();

  static final WorldAudioDirector instance = WorldAudioDirector._();

  WorldAudioState _state = WorldAudioState.title;
  WorldProfile? _profile;
  bool _dangerActive = false;
  int? _matchRemainingSeconds;
  Timer? _galleryPreviewTimer;
  Timer? _resultStingTimer;
  int _enterSerial = 0;

  WorldAudioState get state => _state;
  WorldProfile? get profile => _profile;
  bool get isGalleryPreviewActive => _galleryPreviewTimer?.isActive ?? false;
  /// 初期化（[GameAudio.init] 後に呼ぶ）。
  void bindProfile(WorldProfile profile) {
    _profile = profile;
    GameAudio.instance.setActiveWorldProfile(profile);
  }

  /// 状態遷移の主入口。
  Future<void> enter(
    WorldAudioState next, {
    WorldProfile? profile,
  }) async {
    final serial = ++_enterSerial;
    if (profile != null) {
      _profile = profile;
      GameAudio.instance.setActiveWorldProfile(profile);
    }
    final p = _profile;
    if (p == null) return;

    _cancelGalleryPreview();
    _state = next;
    if (!_isCurrentEnter(serial)) return;

    final audio = GameAudio.instance;
    final settings = audio.settings.value;
    if (!settings.layeredBgmEnabled) {
      await _enterLegacy(next, p, settings);
      return;
    }

    final music = WorldMusicProfileCatalog.of(p);
    final studio = WorldStudioIdentityCatalog.of(p);
    final crossFade = settings.crossFadeEnabled
        ? WorldMusicProfileCatalog.crossFadeFor(p)
        : 120;

    switch (next) {
      case WorldAudioState.title:
        await _applyTitleLayers(music, crossFade);
      case WorldAudioState.gallery:
        await _applyTitleLayers(music, crossFade);
      case WorldAudioState.lobby:
        await _applyLobbyLayers(music, crossFade);
      case WorldAudioState.preMatchPresentation:
        await _applyLobbyLayers(music, crossFade);
      case WorldAudioState.matchCountdown:
        await _applyCountdownLayers(p, music, crossFade);
      case WorldAudioState.match:
        _dangerActive = false;
        await _applyMatchLayers(p, music, crossFade);
      case WorldAudioState.finalFiveMinutes:
      case WorldAudioState.finalMinute:
      case WorldAudioState.finalTenSeconds:
        await _applyClimaxLayers(music, crossFade, next);
      case WorldAudioState.danger:
        await _applyDangerOverlay(music, crossFade);
      case WorldAudioState.accusationAvailable:
        await _applyAccusationAvailable(music, crossFade);
      case WorldAudioState.accusationSequence:
        await _applyAccusationSequence(music, studio);
      case WorldAudioState.resultVictory:
        await _applyResult(music, crossFade, studio, victory: true);
      case WorldAudioState.resultLose:
        await _applyResult(music, crossFade, studio, victory: false);
      case WorldAudioState.resultDraw:
        await _applyResultDraw(music, crossFade, studio);
      case WorldAudioState.resultSpectator:
        await _applyResultSpectator(music, crossFade);
      case WorldAudioState.returnTitle:
        await _applyReturnTitle(music, crossFade, studio);
    }
  }

  bool _isCurrentEnter(int serial) => serial == _enterSerial;

  /// ギャラリーを閉じる（未確定時は保存済み世界観へ戻す）。
  Future<void> leaveGallery({required WorldProfile restoreProfile}) async {
    _cancelGalleryPreview();
    if (_state != WorldAudioState.gallery) return;
    await enter(WorldAudioState.title, profile: restoreProfile);
  }
  /// 世界観変更時のクロスフェード（タイトル／ギャラリー）。
  Future<void> onProfileChanged(WorldProfile next) async {
    final prev = _profile;
    _profile = next;
    GameAudio.instance.setActiveWorldProfile(next);
    if (prev == next) return;
    if (_state == WorldAudioState.gallery) {
      await enter(WorldAudioState.gallery, profile: next);
      return;
    }
    if (_state == WorldAudioState.title || _state == WorldAudioState.returnTitle) {
      await enter(WorldAudioState.title, profile: next);
    }
  }

  /// ギャラリー BGM 試聴（15 秒で自動停止し、ギャラリー Base へ復帰）。
  Future<void> previewGalleryBgm(WorldProfile profile) async {
    _cancelGalleryPreview();
    _profile = profile;
    if (!GameAudio.instance.settings.value.layeredBgmEnabled) {
      return;
    }
    final music = WorldMusicProfileCatalog.of(profile);
    final crossFade = GameAudio.instance.settings.value.crossFadeEnabled
        ? music.crossFadeMs
        : 80;
    final track = LayerTrackRef.bgm(music.galleryPreviewMusic);
    await GameAudio.instance.stopMusicLayer(
      WorldMusicLayer.ambient,
      fadeMs: crossFade ~/ 2,
    );
    await GameAudio.instance.setMusicLayer(
      WorldMusicLayer.base,
      track: track,
      relativeGain: 1.0,
      crossFadeMs: crossFade,
      curve: music.volumeCurve,
    );
    _galleryPreviewTimer = Timer(
      Duration(seconds: music.galleryPreviewSeconds),
      () => unawaited(_restoreGalleryBase()),
    );
  }

  Future<void> _restoreGalleryBase() async {
    _galleryPreviewTimer = null;
    if (_state != WorldAudioState.gallery) return;
    final p = _profile;
    if (p == null) return;
    final music = WorldMusicProfileCatalog.of(p);
    final crossFade = GameAudio.instance.settings.value.crossFadeEnabled
        ? music.crossFadeMs
        : 80;
    await _applyTitleLayers(music, crossFade);
  }
  void _cancelGalleryPreview() {
    _galleryPreviewTimer?.cancel();
    _galleryPreviewTimer = null;
  }

  /// 試合中タイマー（残り秒）— 同じフェーズへの重複 enter を抑止。
  void onMatchTick(int remainingSeconds) {
    if (_state != WorldAudioState.match &&
        _state != WorldAudioState.finalFiveMinutes &&
        _state != WorldAudioState.finalMinute &&
        _state != WorldAudioState.finalTenSeconds &&
        _state != WorldAudioState.danger) {
      return;
    }
    _matchRemainingSeconds = remainingSeconds;
    final p = _profile;
    if (p == null) return;
    if (!GameAudio.instance.settings.value.layeredBgmEnabled) return;

    final WorldAudioState? target;
    if (remainingSeconds <= 10) {
      target = WorldAudioState.finalTenSeconds;
    } else if (remainingSeconds <= 60) {
      target = WorldAudioState.finalMinute;
    } else if (remainingSeconds <= 300) {
      target = WorldAudioState.finalFiveMinutes;
    } else {
      target = null;
    }
    if (target == null || target == _state) return;
    unawaited(enter(target, profile: p));
  }
  /// 近接危険（proximity danger）— BGM テンション追加。
  Future<void> setDangerActive(bool active) async {
    if (_dangerActive == active) return;
    _dangerActive = active;
    final p = _profile;
    if (p == null) return;
    if (!GameAudio.instance.settings.value.layeredBgmEnabled) return;
    if (_state != WorldAudioState.match &&
        _state != WorldAudioState.finalFiveMinutes &&
        _state != WorldAudioState.finalMinute &&
        _state != WorldAudioState.finalTenSeconds) {
      return;
    }
    if (active) {
      await enter(WorldAudioState.danger, profile: p);
    } else {
      await enter(
        _climaxStateForRemaining(_matchRemainingSeconds ?? 9999),
        profile: p,
      );
    }
  }

  WorldAudioState _climaxStateForRemaining(int sec) {
    if (sec <= 10) return WorldAudioState.finalTenSeconds;
    if (sec <= 60) return WorldAudioState.finalMinute;
    if (sec <= 300) return WorldAudioState.finalFiveMinutes;
    return WorldAudioState.match;
  }

  /// 捕獲モーメント — BGM ダック。
  Future<void> onCaptureMoment() async {
    final p = _profile;
    if (p == null) return;
    final music = WorldMusicProfileCatalog.of(p);
    await GameAudio.instance.duckMusic(
      db: music.captureDuckDb,
      holdMs: music.captureDuckHoldMs,
    );
  }

  /// 告発解禁。
  Future<void> onAccusationUnlock() async {
    final p = _profile;
    if (p == null) return;
    await enter(WorldAudioState.accusationAvailable, profile: p);
  }

  /// 告発シーケンス（成功時 impact → victory へ遷移は呼び出し側）。
  Future<void> onAccusationSequence() async {
    final p = _profile;
    if (p == null) return;
    await enter(WorldAudioState.accusationSequence, profile: p);
  }

  /// カウントダウン「開始!」— SE のみ（BGM レイヤーは増やさない）。
  Future<void> onMatchCountdownGo() async {
    final p = _profile;
    if (p == null) return;
    await restorePresentationVolume();
  }

  /// 試合開始演出（ロスター・軌道・説明）— ロビー音量を維持。
  Future<void> beginMatchPresentation() async {
    final p = _profile;
    if (p == null) return;
    await enter(WorldAudioState.preMatchPresentation, profile: p);
  }

  /// カウントダウン UI 表示中の短いダック（二重再生・無音化しない）。
  Future<void> dipForCountdown() async {
    final p = _profile;
    if (p == null) return;
    if (!GameAudio.instance.settings.value.layeredBgmEnabled) return;
    final music = WorldMusicProfileCatalog.of(p);
    final crossFade = GameAudio.instance.settings.value.crossFadeEnabled
        ? music.crossFadeMs ~/ 3
        : 80;
    await GameAudio.instance.fadeMusicLayer(
      WorldMusicLayer.base,
      relativeGain: music.lobbyGain * 0.55,
      ms: crossFade,
    );
    await _clearClimaxLayers(crossFade);
  }

  /// カウントダウン後・役職説明中にロビー相当の音量へ戻す。
  Future<void> restorePresentationVolume() async {
    final p = _profile;
    if (p == null) return;
    if (!GameAudio.instance.settings.value.layeredBgmEnabled) return;
    if (_state != WorldAudioState.preMatchPresentation &&
        _state != WorldAudioState.matchCountdown) {
      return;
    }
    final music = WorldMusicProfileCatalog.of(p);
    final crossFade = GameAudio.instance.settings.value.crossFadeEnabled
        ? WorldMusicProfileCatalog.crossFadeFor(p)
        : 120;
    await _applyLobbyLayers(music, crossFade);
  }

  /// @deprecated 試合開始全体では [beginMatchPresentation] を使う。
  Future<void> beginMatchCountdown() async {
    await beginMatchPresentation();
  }

  /// アプリがバックグラウンドへ入ったとき。
  Future<void> pauseForBackground() => GameAudio.instance.pauseForBackground();

  /// フォアグラウンド復帰時。
  Future<void> resumeFromBackground() =>
      GameAudio.instance.resumeFromBackground();

  Future<void> _clearClimaxLayers(int crossFade) async {
    await GameAudio.instance.stopMusicLayer(
      WorldMusicLayer.tension,
      fadeMs: crossFade,
    );
    await GameAudio.instance.stopMusicLayer(
      WorldMusicLayer.moment,
      fadeMs: crossFade,
    );
  }

  Future<void> _setAmbientLayer(
    WorldMusicProfile music,
    int crossFade, {
    required double gainMultiplier,
  }) async {
    final amb = music.layers.ambient;
    if (amb == null) {
      await GameAudio.instance.stopMusicLayer(
        WorldMusicLayer.ambient,
        fadeMs: crossFade,
      );
      return;
    }
    await GameAudio.instance.setMusicLayer(
      WorldMusicLayer.ambient,
      track: amb,
      relativeGain: music.ambientGain * gainMultiplier,
      crossFadeMs: crossFade,
      curve: music.volumeCurve,
    );
  }

  Future<void> _applyTitleLayers(
    WorldMusicProfile music,
    int crossFade,
  ) async {
    GameAudio.instance.stopMatchAmbientSchedule();
    await GameAudio.instance.setMusicLayer(
      WorldMusicLayer.base,
      track: music.layers.effectiveTitleBase,
      relativeGain: 1.0,
      crossFadeMs: crossFade,
      curve: music.volumeCurve,
    );
    await _clearClimaxLayers(crossFade);
    await _setAmbientLayer(music, crossFade, gainMultiplier: 0.35);
  }

  Future<void> _applyLobbyLayers(
    WorldMusicProfile music,
    int crossFade,
  ) async {
    GameAudio.instance.stopMatchAmbientSchedule();
    await GameAudio.instance.setMusicLayer(
      WorldMusicLayer.base,
      track: music.layers.base,
      relativeGain: music.lobbyGain,
      crossFadeMs: crossFade,
      curve: music.volumeCurve,
    );
    await _setAmbientLayer(music, crossFade, gainMultiplier: 0.55);
    if (_profile == WorldProfile.westernLuxury &&
        WorldMusicProfileCatalog.royalLobbyUseSarabandeUndertone) {
      await GameAudio.instance.setMusicLayer(
        WorldMusicLayer.tension,
        track: LayerTrackRef.bgm(BgmId.royalSarabande, gain: 0.16),
        relativeGain: 0.22,
        crossFadeMs: crossFade,
        curve: music.volumeCurve,
      );
    } else {
      await GameAudio.instance.stopMusicLayer(
        WorldMusicLayer.tension,
        fadeMs: crossFade,
      );
    }
    await GameAudio.instance.stopMusicLayer(
      WorldMusicLayer.moment,
      fadeMs: crossFade,
    );
  }
  Future<void> _applyCountdownLayers(
    WorldProfile p,
    WorldMusicProfile music,
    int crossFade,
  ) async {
    await dipForCountdown();
  }

  Future<void> _applyMatchLayers(
    WorldProfile p,
    WorldMusicProfile music,
    int crossFade,
  ) async {
    final audio = GameAudio.instance;
    audio.startMatchAmbientSchedule(p);
    final matchTrack = music.layers.effectiveMatchBase;
    await audio.setMusicLayer(
      WorldMusicLayer.base,
      track: matchTrack,
      relativeGain: music.matchBaseGain,
      crossFadeMs: crossFade,
      curve: music.volumeCurve,
    );
    final amb = music.layers.ambient;
    if (amb != null) {
      await audio.setMusicLayer(
        WorldMusicLayer.ambient,
        track: amb,
        relativeGain: music.ambientGain,
        crossFadeMs: crossFade,
        curve: music.volumeCurve,
      );
    } else {
      await audio.stopMusicLayer(
        WorldMusicLayer.ambient,
        fadeMs: crossFade,
      );
    }
    await _clearClimaxLayers(crossFade);
  }

  String _layerTrackKey(LayerTrackRef track) {
    if (track.bgm != null) return 'bgm:${track.bgm!.name}';
    return 'amb:${track.ambient!.name}';
  }

  Future<void> _applyClimaxLayers(
    WorldMusicProfile music,
    int crossFade,
    WorldAudioState phase,
  ) async {
    GameAudio.instance.stopMatchAmbientSchedule();
    final tension = music.layers.tension;
    final moment = music.layers.moment;
    if (phase == WorldAudioState.finalFiveMinutes) {
      if (tension != null) {
        await GameAudio.instance.setMusicLayer(
          WorldMusicLayer.tension,
          track: tension,
          relativeGain: music.finalFiveMinTensionGain,
          crossFadeMs: crossFade,
          curve: music.volumeCurve,
        );
      } else if (music.layers.ambient != null) {
        await GameAudio.instance.fadeMusicLayer(
          WorldMusicLayer.ambient,
          relativeGain: music.ambientGain * 1.15,
          ms: crossFade,
        );
      }
    } else if (phase == WorldAudioState.finalMinute) {
      final matchBase = music.layers.effectiveMatchBase;
      if (matchBase.bgm != null) {
        final finalTrack = LayerTrackRef.bgm(music.finalMinuteMusic);
        await GameAudio.instance.setMusicLayer(
          WorldMusicLayer.base,
          track: finalTrack,
          relativeGain: music.matchBaseGain,
          crossFadeMs: crossFade,
          curve: music.volumeCurve,
        );
        if (tension != null &&
            _layerTrackKey(tension) != _layerTrackKey(finalTrack)) {
          await GameAudio.instance.setMusicLayer(
            WorldMusicLayer.tension,
            track: tension,
            relativeGain: music.finalMinuteTensionGain,
            crossFadeMs: crossFade,
            curve: music.volumeCurve,
          );
        }
      } else if (tension != null) {
        await GameAudio.instance.setMusicLayer(
          WorldMusicLayer.tension,
          track: tension,
          relativeGain: music.finalMinuteTensionGain,
          crossFadeMs: crossFade,
          curve: music.volumeCurve,
        );
      } else if (music.layers.ambient != null) {
        await GameAudio.instance.fadeMusicLayer(
          WorldMusicLayer.ambient,
          relativeGain: music.ambientGain * 1.2,
          ms: crossFade,
        );
      }
    } else if (phase == WorldAudioState.finalTenSeconds) {
      if (tension != null) {
        await GameAudio.instance.fadeMusicLayer(
          WorldMusicLayer.tension,
          relativeGain: music.finalMinuteTensionGain * 1.1,
          ms: crossFade ~/ 2,
        );
      }
      if (moment != null) {
        await GameAudio.instance.setMusicLayer(
          WorldMusicLayer.moment,
          track: moment,
          relativeGain: music.finalTenSecMomentGain,
          crossFadeMs: crossFade ~/ 2,
          curve: music.volumeCurve,
        );
      }
    }
  }

  Future<void> _applyDangerOverlay(
    WorldMusicProfile music,
    int crossFade,
  ) async {
    GameAudio.instance.stopMatchAmbientSchedule();
    final tension = music.layers.tension;
    final moment = music.layers.moment;
    final base = _matchRemainingSeconds != null &&
            _matchRemainingSeconds! <= 60
        ? music.finalMinuteTensionGain
        : music.finalFiveMinTensionGain;
    final gain = base + music.dangerTensionBoost;
    if (tension != null) {
      await GameAudio.instance.setMusicLayer(
        WorldMusicLayer.tension,
        track: tension,
        relativeGain: gain,
        crossFadeMs: crossFade ~/ 2,
        curve: music.volumeCurve,
      );
      return;
    }
    if (moment != null) {
      await GameAudio.instance.setMusicLayer(
        WorldMusicLayer.moment,
        track: moment,
        relativeGain: gain * 0.85,
        crossFadeMs: crossFade ~/ 2,
        curve: music.volumeCurve,
      );
    }
  }

  Future<void> _applyAccusationAvailable(
    WorldMusicProfile music,
    int crossFade,
  ) async {
    GameAudio.instance.stopMatchAmbientSchedule();
    final moment = music.layers.moment;
    if (moment == null) return;
    await GameAudio.instance.setMusicLayer(
      WorldMusicLayer.moment,
      track: moment,
      relativeGain: music.ambientGain * 0.9,
      crossFadeMs: crossFade,
      curve: music.volumeCurve,
    );
  }

  Future<void> _applyAccusationSequence(
    WorldMusicProfile music,
    WorldStudioIdentity studio,
  ) async {
    final pause = music.accusationSilenceMs + studio.silence.sfxTailMs;
    await GameAudio.instance.fadeAllMusicLayers(relativeGain: 0.08, ms: 280);
    if (pause > 0) await Future<void>.delayed(Duration(milliseconds: pause));
    final moment = music.layers.moment;
    if (moment != null) {
      await GameAudio.instance.setMusicLayer(
        WorldMusicLayer.moment,
        track: moment,
        relativeGain: 1.0,
        loop: false,
        crossFadeMs: 200,
        curve: music.volumeCurve,
      );
    }
  }

  Future<void> _applyResult(
    WorldMusicProfile music,
    int crossFade,
    WorldStudioIdentity studio, {
    required bool victory,
  }) async {
    GameAudio.instance.stopMatchAmbientSchedule();
    final pause = music.resultPauseMs + studio.silence.sfxLeadMs;
    await GameAudio.instance.fadeAllMusicLayers(relativeGain: 0.05, ms: 400);
    if (pause > 0) await Future<void>.delayed(Duration(milliseconds: pause));

    final sting = LayerTrackRef.bgm(
      victory ? music.victoryMusic : music.loseMusic,
      gain: victory ? 0.95 : 0.85,
    );
    await GameAudio.instance.setMusicLayer(
      WorldMusicLayer.base,
      track: sting,
      relativeGain: victory ? 0.92 : 0.78,
      loop: false,
      crossFadeMs: crossFade,
      curve: music.volumeCurve,
    );
    await GameAudio.instance.stopMusicLayer(
      WorldMusicLayer.tension,
      fadeMs: crossFade,
    );
    _resultStingTimer?.cancel();
    _resultStingTimer = Timer(const Duration(seconds: 8), () {
      unawaited(
        GameAudio.instance.fadeMusicLayer(
          WorldMusicLayer.base,
          relativeGain: 0.35,
          ms: crossFade,
        ),
      );
    });
  }

  Future<void> _applyResultDraw(
    WorldMusicProfile music,
    int crossFade,
    WorldStudioIdentity studio,
  ) async {
    GameAudio.instance.stopMatchAmbientSchedule();
    await Future<void>.delayed(
      Duration(milliseconds: music.resultPauseMs + studio.silence.sfxLeadMs),
    );
    await GameAudio.instance.fadeMusicLayer(
      WorldMusicLayer.base,
      relativeGain: 0.25,
      ms: crossFade,
    );
    final amb = music.layers.ambient;
    if (amb != null) {
      await GameAudio.instance.setMusicLayer(
        WorldMusicLayer.ambient,
        track: amb,
        relativeGain: music.ambientGain * 0.7,
        crossFadeMs: crossFade,
        curve: music.volumeCurve,
      );
    }
  }

  Future<void> _applyResultSpectator(
    WorldMusicProfile music,
    int crossFade,
  ) async {
    GameAudio.instance.stopMatchAmbientSchedule();
    await GameAudio.instance.setMusicLayer(
      WorldMusicLayer.base,
      track: LayerTrackRef.bgm(music.loopMusic),
      relativeGain: 0.42,
      crossFadeMs: crossFade,
      curve: music.volumeCurve,
    );
  }

  Future<void> _applyReturnTitle(
    WorldMusicProfile music,
    int crossFade,
    WorldStudioIdentity studio,
  ) async {
    final breath = studio.silence.transitionBreathMs;
    if (breath > 0) {
      await Future<void>.delayed(Duration(milliseconds: breath));
    }
    await _applyTitleLayers(music, crossFade);
  }

  Future<void> _enterLegacy(
    WorldAudioState next,
    WorldProfile p,
    AudioSettings settings,
  ) async {
    final audio = GameAudio.instance;
    switch (next) {
      case WorldAudioState.title:
      case WorldAudioState.gallery:
      case WorldAudioState.lobby:
      case WorldAudioState.preMatchPresentation:
      case WorldAudioState.returnTitle:
      case WorldAudioState.resultVictory:
      case WorldAudioState.resultLose:
      case WorldAudioState.resultDraw:
      case WorldAudioState.resultSpectator:
        if (settings.bgmEnabled) {
          await audio.playMenuBgm(p);
        } else {
          await audio.stopMusic();
        }
      case WorldAudioState.matchCountdown:
        await audio.stopMusic();
      case WorldAudioState.match:
      case WorldAudioState.finalFiveMinutes:
      case WorldAudioState.finalMinute:
      case WorldAudioState.finalTenSeconds:
      case WorldAudioState.danger:
      case WorldAudioState.accusationAvailable:
      case WorldAudioState.accusationSequence:
        await audio.playMatchAmbient(p);
    }
  }
}
