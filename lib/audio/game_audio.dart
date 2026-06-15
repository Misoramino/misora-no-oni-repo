import 'dart:async';
import 'dart:math' as math;

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart' show Curve, Curves;
import 'package:flutter/services.dart' show AssetManifest, rootBundle;

import '../session/audio_prefs.dart';
import '../theme/world_fx_profile.dart';
import '../theme/world_profile.dart';
import 'audio_library.dart';
import 'bgm_layer_engine.dart';
import 'sfx_id.dart';
import 'sfx_synth.dart';
import 'world_music_profile.dart';
import 'world_sfx_debounce.dart';
import 'world_sfx_preview.dart';
enum _MusicMode { none, menu, match }

/// アプリ全体の効果音 / 音楽を司るシングルトン。
///
/// - 効果音: `assets/audio/sfx/<id>.(wav|mp3|ogg)` があればそれを、
///   無ければ [SfxSynth] のコード合成音を再生する。
/// - 音楽は2系統:
///   - **BGM**（タイトル/ロビー/リザルト）: 世界観ごとの既定曲、または設定で選んだ曲を
///     フェード付きでループ。
///   - **環境音**（対戦中）: BGMの代わりに世界観ごとの環境音を *たまに* ワンショットで鳴らす
///     （鳴りっぱなしにしない）。
/// - 設定（音量・ミュート・BGM選択）は [settings] で監視・更新できる。
class GameAudio {
  GameAudio._();

  static final GameAudio instance = GameAudio._();

  static const _sfxExts = ['wav', 'mp3', 'ogg', 'm4a'];
  static const _musicExts = ['mp3', 'ogg', 'wav', 'm4a'];
  static const _sfxPoolSize = 4;

  /// 対戦開始から最初の環境音までの遅延（秒, ランダム下限/上限）。
  static const _ambientFirstMinSec = 900;
  static const _ambientFirstMaxSec = 1500;

  /// 環境音どうしの間隔（秒, ランダム下限/上限）— おおよそ20分前後。
  static const _ambientGapMinSec = 1080;
  static const _ambientGapMaxSec = 1320;

  /// 通常の世界観音以外が流れる確率（珍しい音）。
  static const _ambientRareChance = 0.12;

  /// 現在のサウンド設定。UI から監視・更新する。
  final ValueNotifier<AudioSettings> settings =
      ValueNotifier<AudioSettings>(const AudioSettings());

  final List<AudioPlayer> _sfxPool = [];
  int _sfxCursor = 0;
  final math.Random _rand = math.Random();

  AudioPlayer? _bgmPlayer;
  AudioPlayer? _ambientPlayer;
  Timer? _ambientTimer;
  Timer? _bgmFadeTimer;
  Timer? _duckRestoreTimer;

  late final BgmLayerEngine _layerEngine = BgmLayerEngine(
    resolveAsset: (dir, base) => resolveMusicAsset(_assets, dir, base),
  );

  bool _layersActive = false;
  bool _backgroundPaused = false;
  /// マニフェスト上に存在するアセットのパス集合（`assets/...`）。
  Set<String> _assets = <String>{};
  bool _initialized = false;

  _MusicMode _mode = _MusicMode.none;
  WorldProfile? _profile;
  WorldProfile? _activeWorldProfile;
  BgmId? _playingBgm;

  final WorldSfxDebounce _worldSfxDebounce = WorldSfxDebounce();

  /// 試合画面などの現在の世界観（BGM/環境音・試聴用）。
  void setActiveWorldProfile(WorldProfile? profile) {
    _activeWorldProfile = profile;
  }

  WorldProfile? get activeWorldProfile => _activeWorldProfile;

  Future<void> init() async {
    if (_initialized) return;
    _initialized = true;

    settings.value = await AudioPrefs.load();

    if (!kIsWeb) {
      for (var i = 0; i < _sfxPoolSize; i++) {
        final p = AudioPlayer(playerId: 'sfx_$i');
        unawaited(p.setReleaseMode(ReleaseMode.stop));
        _sfxPool.add(p);
      }
    }

    try {
      final manifest = await AssetManifest.loadFromAssetBundle(rootBundle);
      _assets = manifest.listAssets().toSet();
    } catch (e) {
      _assets = <String>{};
      debugPrint('GameAudio: asset manifest load failed: $e');
    }
  }

  Future<void> updateSettings(AudioSettings next) async {
    settings.value = next;
    await AudioPrefs.save(next);
    _layerEngine.setMasterBgm(next.effectiveBgm);

    if (!next.layeredBgmEnabled && _layersActive) {
      await stopAllMusicLayers(fadeMs: 280);
    }

    if (next.layeredBgmEnabled && _layersActive) {
      return;
    }

    if (next.layeredBgmEnabled) {
      return;
    }

    if (_mode == _MusicMode.menu) {
      final profile = _profile;
      if (profile != null) await playMenuBgm(profile);
      return;
    }
    if (_mode == _MusicMode.match) {
      final profile = _profile;
      if (profile == null) return;
      if (next.bgmEnabled) {
        await _playMatchBgm(profile, next);
      } else {
        await _stopBgm(fadeOut: true);
      }
    }
  }

  Future<void> _playMatchBgm(WorldProfile profile, AudioSettings s) async {
    if (kIsWeb) return;
    final id = _resolveBgm(profile, s);
    final assetPath = _resolveAsset('audio/bgm', id.asset, _musicExts);
    if (assetPath == null) {
      await _stopBgm();
      return;
    }
    final vol = s.effectiveBgm;
    if (_playingBgm == id && _bgmPlayer != null) {
      _bgmFadeTimer?.cancel();
      _bgmFadeTimer = null;
      await _bgmPlayer!.setVolume(vol);
      return;
    }
    _playingBgm = id;
    try {
      final p = _bgmPlayer ??= AudioPlayer(playerId: 'bgm');
      await p.setReleaseMode(ReleaseMode.loop);
      _bgmFadeTimer?.cancel();
      _bgmFadeTimer = null;
      await p.stop();
      await p.play(AssetSource(assetPath), volume: 0);
      _fadeBgm(from: 0, to: vol);
    } catch (e) {
      debugPrint('GameAudio._playMatchBgm($id): $e');
    }
  }

  Future<void> toggleMute() => updateSettings(
        settings.value.copyWith(muted: !settings.value.muted),
      );

  // ---- 効果音 ----

  /// 汎用 UI 効果音（世界観フォルダは使わない）。
  Future<void> playSfx(SfxId id) async {
    if (kIsWeb || _sfxPool.isEmpty) return;
    final vol = settings.value.effectiveSfx;
    if (vol <= 0) return;

    final player = _sfxPool[_sfxCursor];
    _sfxCursor = (_sfxCursor + 1) % _sfxPool.length;

    try {
      if (_layersActive) {
        _duckForSfx();
      }
      final assetPath = _resolveAsset('audio/sfx', id.asset, _sfxExts);
      if (assetPath != null) {
        await player.play(AssetSource(assetPath), volume: vol);
      } else {
        await player.play(
          BytesSource(SfxSynth.wavFor(id), mimeType: 'audio/wav'),
          volume: vol,
        );
      }
    } catch (e) {
      debugPrint('GameAudio.playSfx($id): $e');
    }
  }

  /// 世界観モーメント SE（reveal / capture / unlock / matchStart 等）。
  Future<void> playWorldSfx(
    SfxId id, {
    required WorldProfile profile,
  }) async {
    if (kIsWeb || _sfxPool.isEmpty) return;
    final baseVol = settings.value.effectiveSfx;
    if (baseVol <= 0) return;

    final fx = WorldFxCatalog.forProfile(profile);
    final assetBase = fx.worldMomentAssetFor(id);
    if (assetBase == null) {
      await playSfx(id);
      return;
    }

    final previewKind = _previewKindForSfx(id);
    if (previewKind != null &&
        !_worldSfxDebounce.tryAcquire(profile, previewKind)) {
      return;
    }

    final vol = _volumeForWorldSfx(id, fx, baseVol);
    if (vol <= 0) return;

    final player = _sfxPool[_sfxCursor];
    _sfxCursor = (_sfxCursor + 1) % _sfxPool.length;

    try {
      if (_layersActive) {
        _duckForSfx();
      }
      final assetPath = _resolveWorldSfxAsset(profile, assetBase);
      if (assetPath != null) {
        await player.play(AssetSource(assetPath), volume: vol);
      } else {
        await player.play(
          BytesSource(SfxSynth.wavFor(id), mimeType: 'audio/wav'),
          volume: vol,
        );
      }
    } catch (e) {
      debugPrint('GameAudio.playWorldSfx($id, ${profile.name}): $e');
    }
  }

  /// 設定画面などから世界観 SE を試聴する。
  Future<void> previewWorldSfx(
    WorldProfile profile,
    WorldSfxPreviewKind kind,
  ) async {
    switch (kind) {
      case WorldSfxPreviewKind.uiTap:
        await playWorldSfx(SfxId.uiTap, profile: profile);
      case WorldSfxPreviewKind.reveal:
        await playWorldSfx(SfxId.reveal, profile: profile);
      case WorldSfxPreviewKind.transition:
        await playTransitionSfx(profile);
    }
  }

  /// 画面遷移用の世界観 SE。
  Future<void> playTransitionSfx(WorldProfile profile) async {
    if (kIsWeb || _sfxPool.isEmpty) return;
    final baseVol = settings.value.effectiveSfx;
    if (baseVol <= 0) return;
    if (!_worldSfxDebounce.tryAcquire(
      profile,
      WorldSfxPreviewKind.transition,
    )) {
      return;
    }

    final fx = WorldFxCatalog.forProfile(profile);
    final vol = baseVol * fx.transitionVolume;
    if (vol <= 0) return;

    final path = _resolveWorldSfxAsset(profile, fx.transitionAssetBase);
    final player = _sfxPool[_sfxCursor];
    _sfxCursor = (_sfxCursor + 1) % _sfxPool.length;
    try {
      if (path != null) {
        await player.play(AssetSource(path), volume: vol);
      } else {
        await player.play(
          BytesSource(SfxSynth.wavFor(SfxId.uiTap), mimeType: 'audio/wav'),
          volume: vol * 0.92,
        );
      }
    } catch (e) {
      debugPrint('GameAudio.playTransitionSfx(${profile.name}): $e');
    }
  }

  WorldSfxPreviewKind? _previewKindForSfx(SfxId id) => switch (id) {
        SfxId.uiTap => WorldSfxPreviewKind.uiTap,
        SfxId.reveal => WorldSfxPreviewKind.reveal,
        _ => null,
      };

  double _volumeForWorldSfx(SfxId id, WorldFxProfile fx, double baseVol) {
    final coeff = switch (id) {
      SfxId.uiTap => fx.uiTapVolume,
      SfxId.reveal => fx.revealVolume,
      SfxId.anonReveal => fx.anonRevealVolume,
      SfxId.capture => fx.captureVolume,
      SfxId.unlock => fx.accusationUnlockVolume,
      SfxId.matchStart => fx.countdownVolume,
      _ => 1.0,
    };
    return baseVol * coeff;
  }

  /// レイヤー BGM スロットを設定（[WorldAudioDirector] 用）。
  Future<void> setMusicLayer(
    WorldMusicLayer slot, {
    required LayerTrackRef track,
    required double relativeGain,
    bool loop = true,
    required int crossFadeMs,
    Curve curve = Curves.easeOutCubic,
  }) async {
    if (kIsWeb) return;
    final s = settings.value;
    if (!s.layeredBgmEnabled || !s.bgmEnabled) return;
    await _stopLegacyBgm();
    _layersActive = true;
    _layerEngine.setMasterBgm(s.effectiveBgm);
    await _layerEngine.setLayer(
      slot: slot,
      track: track,
      relativeGain: relativeGain,
      loop: loop,
      crossFadeMs: crossFadeMs,
      curve: curve,
    );
  }

  Future<void> stopMusicLayer(
    WorldMusicLayer slot, {
    int fadeMs = 400,
  }) =>
      _layerEngine.stopLayer(slot, fadeMs: fadeMs);

  Future<void> fadeMusicLayer(
    WorldMusicLayer slot, {
    required double relativeGain,
    required int ms,
  }) =>
      _layerEngine.fadeLayerGain(slot, relativeGain: relativeGain, ms: ms);

  Future<void> fadeAllMusicLayers({
    required double relativeGain,
    required int ms,
  }) async {
    for (final slot in WorldMusicLayer.values) {
      await fadeMusicLayer(slot, relativeGain: relativeGain, ms: ms);
    }
  }

  Future<void> stopAllMusicLayers({int fadeMs = 500}) async {
    _layersActive = false;
    if (!_layerEngine.isDisposed) {
      await _layerEngine.stopAll(fadeMs: fadeMs);
    }
  }

  /// アプリがバックグラウンドへ入ったときの一時停止。
  Future<void> pauseForBackground() async {
    if (_backgroundPaused || kIsWeb) return;
    _backgroundPaused = true;
    _duckRestoreTimer?.cancel();
    _duckRestoreTimer = null;
    _ambientTimer?.cancel();
    _ambientTimer = null;
    try {
      await _bgmPlayer?.pause();
      if (!_layerEngine.isDisposed) {
        await _layerEngine.pauseAll();
      }
      await _ambientPlayer?.pause();
    } catch (_) {}
  }

  /// フォアグラウンド復帰時の再開。
  Future<void> resumeFromBackground() async {
    if (!_backgroundPaused || kIsWeb) return;
    _backgroundPaused = false;
    try {
      if (_layersActive && !_layerEngine.isDisposed) {
        await _layerEngine.resumeAll();
      } else {
        await _bgmPlayer?.resume();
      }
      if (_mode == _MusicMode.match) {
        _startAmbientSchedule();
      }
    } catch (_) {}
  }

  bool get layersActive => _layersActive;

  /// SE 再生時の BGM ダック（2〜4 dB）。
  Future<void> duckMusic({
    double db = 3.0,
    int holdMs = 400,
  }) async {
    if (!_layersActive || _layerEngine.isDisposed) return;
    _layerEngine.setDuckFactor(BgmLayerEngine.dbToFactor(db));
    _duckRestoreTimer?.cancel();
    _duckRestoreTimer = Timer(Duration(milliseconds: holdMs), () {
      _layerEngine.setDuckFactor(1.0);
    });
  }

  void _duckForSfx() {
    final s = settings.value;
    if (!s.layeredBgmEnabled) return;
    unawaited(duckMusic(db: 3.0, holdMs: 360));
  }

  /// 対戦中の環境音ワンショット（レイヤー BGM と併用可）。
  void startMatchAmbientSchedule(WorldProfile profile) {
    if (kIsWeb) return;
    _mode = _MusicMode.match;
    _profile = profile;
    _startAmbientSchedule();
  }

  void stopMatchAmbientSchedule() => _stopAmbientSchedule();

  // ---- 音楽（BGM / 環境音）----

  /// タイトル/ロビー/リザルト用のBGM。世界観既定 or 設定で選んだ曲をフェード付きでループ。
  ///
  /// 設定が「OFF（効果音・環境音のみ）」の場合は何も鳴らさない。
  Future<void> playMenuBgm(WorldProfile profile) async {
    if (kIsWeb) return;
    final s = settings.value;
    if (s.layeredBgmEnabled) return;

    _mode = _MusicMode.menu;
    _profile = profile;

    _stopAmbientSchedule();
    await stopAllMusicLayers(fadeMs: 0);

    if (!s.bgmEnabled) {
      await _stopLegacyBgm(fadeOut: true);
      return;
    }

    final id = _resolveBgm(profile, s);
    final assetPath = _resolveAsset('audio/bgm', id.asset, _musicExts);
    if (assetPath == null) {
      await _stopBgm();
      return;
    }

    final vol = s.effectiveBgm;
    if (_playingBgm == id && _bgmPlayer != null) {
      // 同じ曲を継続再生中: フェードを止めて音量だけ合わせる。
      _bgmFadeTimer?.cancel();
      _bgmFadeTimer = null;
      await _bgmPlayer!.setVolume(vol);
      return;
    }

    _playingBgm = id;
    try {
      final p = _bgmPlayer ??= AudioPlayer(playerId: 'bgm');
      await p.setReleaseMode(ReleaseMode.loop);
      _bgmFadeTimer?.cancel();
      _bgmFadeTimer = null;
      await p.stop();
      await p.play(AssetSource(assetPath), volume: 0);
      _fadeBgm(from: 0, to: vol);
    } catch (e) {
      debugPrint('GameAudio.playMenuBgm($id): $e');
    }
  }

  /// 対戦中の環境音。BGMをフェードアウトし、世界観ごとの環境音を *たまに* 鳴らし始める。
  ///
  /// BGM が OFF でも環境音は鳴る（各自で好きな音楽を流せるように）。
  Future<void> playMatchAmbient(WorldProfile profile) async {
    if (kIsWeb) return;
    _mode = _MusicMode.match;
    _profile = profile;

    if (!settings.value.layeredBgmEnabled) {
      await _stopLegacyBgm(fadeOut: true);
    }
    _startAmbientSchedule();
  }

  /// 全ての音楽（BGM・環境音）を停止。
  Future<void> stopMusic() async {
    _mode = _MusicMode.none;
    _duckRestoreTimer?.cancel();
    _duckRestoreTimer = null;
    await _stopLegacyBgm();
    await stopAllMusicLayers(fadeMs: 320);
    _stopAmbientSchedule();
  }

  Future<void> _stopLegacyBgm({bool fadeOut = false}) async {
    _playingBgm = null;
    final p = _bgmPlayer;
    if (p == null) return;
    if (fadeOut) {
      _fadeBgm(from: settings.value.effectiveBgm, to: 0, stopAtEnd: true);
      return;
    }
    _bgmFadeTimer?.cancel();
    _bgmFadeTimer = null;
    try {
      await p.stop();
    } catch (_) {}
  }

  BgmId _resolveBgm(WorldProfile profile, AudioSettings s) {
    if (s.bgmChoice == AudioSettings.bgmWorldDefault) {
      return WorldAudio.defaultBgm(profile);
    }
    return BgmId.fromName(s.bgmChoice) ?? WorldAudio.defaultBgm(profile);
  }

  // ---- 環境音スケジューラ ----

  void _startAmbientSchedule() {
    _stopAmbientSchedule();
    _scheduleNextAmbient(initial: true);
  }

  void _scheduleNextAmbient({bool initial = false}) {
    final span = initial
        ? _ambientFirstMinSec +
            _rand.nextInt(_ambientFirstMaxSec - _ambientFirstMinSec + 1)
        : _ambientGapMinSec +
            _rand.nextInt(_ambientGapMaxSec - _ambientGapMinSec + 1);
    _ambientTimer = Timer(Duration(seconds: span), () {
      unawaited(_playAmbientOneShot());
      _scheduleNextAmbient();
    });
  }

  Future<void> _playAmbientOneShot() async {
    if (_mode != _MusicMode.match) return;
    final profile = _profile;
    if (profile == null) return;
    final vol = settings.value.effectiveAmbient;
    if (vol <= 0) return;
    final id = _pickAmbientId(profile);
    final assetPath = _resolveAsset('audio/ambient', id.asset, _musicExts);
    if (assetPath == null) return;
    try {
      final p = _ambientPlayer ??= AudioPlayer(playerId: 'ambient');
      await p.setReleaseMode(ReleaseMode.stop);
      await p.stop();
      await p.play(AssetSource(assetPath), volume: vol);
    } catch (e) {
      debugPrint('GameAudio._playAmbientOneShot($id): $e');
    }
  }

  AmbientId _pickAmbientId(WorldProfile profile) {
    final usual = WorldAudio.ambient(profile);
    if (_rand.nextDouble() >= _ambientRareChance) return usual;
    final pool = AmbientId.values.where((a) => a != usual).toList();
    if (pool.isEmpty) return usual;
    return pool[_rand.nextInt(pool.length)];
  }

  void _stopAmbientSchedule() {
    _ambientTimer?.cancel();
    _ambientTimer = null;
    try {
      _ambientPlayer?.stop();
    } catch (_) {}
  }

  // ---- BGM フェード ----

  /// [_bgmPlayer] の音量を [from]→[to] に滑らかに変化させる。
  void _fadeBgm({
    required double from,
    required double to,
    Duration duration = const Duration(milliseconds: 700),
    bool stopAtEnd = false,
  }) {
    final p = _bgmPlayer;
    if (p == null) return;
    _bgmFadeTimer?.cancel();
    const steps = 14;
    final stepMs = (duration.inMilliseconds / steps).round().clamp(16, 200);
    var i = 0;
    p.setVolume(from.clamp(0.0, 1.0));
    _bgmFadeTimer = Timer.periodic(Duration(milliseconds: stepMs), (t) {
      i++;
      final v = (from + (to - from) * (i / steps)).clamp(0.0, 1.0);
      p.setVolume(v);
      if (i >= steps) {
        t.cancel();
        _bgmFadeTimer = null;
        if (stopAtEnd) {
          try {
            p.stop();
          } catch (_) {}
        }
      }
    });
  }

  Future<void> _stopBgm({bool fadeOut = false}) async {
    await _stopLegacyBgm(fadeOut: fadeOut);
  }

  /// `assets/<dir>/<base>.<ext>` のうち同梱済みの最初の候補を返す。
  /// 戻り値は AssetSource 用に `assets/` を取り除いた相対パス。
  String? _resolveAsset(String dir, String base, List<String> exts) {
    for (final ext in exts) {
      final full = 'assets/$dir/$base.$ext';
      if (_assets.contains(full)) return '$dir/$base.$ext';
    }
    return null;
  }

  String? _resolveWorldSfxAsset(WorldProfile profile, String base) {
    return _resolveAsset(
      'audio/sfx/worlds/${profile.storageName}',
      base,
      _sfxExts,
    );
  }

  Future<void> dispose() async {
    _ambientTimer?.cancel();
    _ambientTimer = null;
    _bgmFadeTimer?.cancel();
    _bgmFadeTimer = null;
    _duckRestoreTimer?.cancel();
    _duckRestoreTimer = null;
    await _layerEngine.dispose();
    for (final p in _sfxPool) {
      await p.dispose();
    }
    _sfxPool.clear();
    await _bgmPlayer?.dispose();
    _bgmPlayer = null;
    await _ambientPlayer?.dispose();
    _ambientPlayer = null;
    _initialized = false;
  }
}
