import 'dart:async';
import 'dart:math' as math;

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show AssetManifest, rootBundle;

import '../session/audio_prefs.dart';
import '../theme/world_profile.dart';
import 'audio_library.dart';
import 'sfx_id.dart';
import 'sfx_synth.dart';

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
  static const _ambientFirstMinSec = 8;
  static const _ambientFirstMaxSec = 18;

  /// 環境音どうしの間隔（秒, ランダム下限/上限）。
  static const _ambientGapMinSec = 35;
  static const _ambientGapMaxSec = 80;

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

  /// マニフェスト上に存在するアセットのパス集合（`assets/...`）。
  Set<String> _assets = <String>{};
  bool _initialized = false;

  _MusicMode _mode = _MusicMode.none;
  WorldProfile? _profile;
  BgmId? _playingBgm;

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

    // メニュー中は選曲/音量を即反映。対戦中の環境音は次のワンショットから反映される。
    if (_mode == _MusicMode.menu) {
      final profile = _profile;
      if (profile != null) await playMenuBgm(profile);
    }
  }

  Future<void> toggleMute() => updateSettings(
        settings.value.copyWith(muted: !settings.value.muted),
      );

  // ---- 効果音 ----

  /// 効果音を一度だけ鳴らす。失敗しても例外は投げない。
  Future<void> playSfx(SfxId id) async {
    if (kIsWeb || _sfxPool.isEmpty) return;
    final vol = settings.value.effectiveSfx;
    if (vol <= 0) return;

    final player = _sfxPool[_sfxCursor];
    _sfxCursor = (_sfxCursor + 1) % _sfxPool.length;

    try {
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

  // ---- 音楽（BGM / 環境音）----

  /// タイトル/ロビー/リザルト用のBGM。世界観既定 or 設定で選んだ曲をフェード付きでループ。
  ///
  /// 設定が「OFF（効果音・環境音のみ）」の場合は何も鳴らさない。
  Future<void> playMenuBgm(WorldProfile profile) async {
    if (kIsWeb) return;
    _mode = _MusicMode.menu;
    _profile = profile;

    _stopAmbientSchedule();

    final s = settings.value;
    if (!s.bgmEnabled) {
      await _stopBgm(fadeOut: true);
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

    await _stopBgm(fadeOut: true);
    _startAmbientSchedule();
  }

  /// 全ての音楽（BGM・環境音）を停止。
  Future<void> stopMusic() async {
    _mode = _MusicMode.none;
    await _stopBgm();
    _stopAmbientSchedule();
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
    final id = WorldAudio.ambient(profile);
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

  /// `assets/<dir>/<base>.<ext>` のうち同梱済みの最初の候補を返す。
  /// 戻り値は AssetSource 用に `assets/` を取り除いた相対パス。
  String? _resolveAsset(String dir, String base, List<String> exts) {
    for (final ext in exts) {
      final full = 'assets/$dir/$base.$ext';
      if (_assets.contains(full)) return '$dir/$base.$ext';
    }
    return null;
  }

  Future<void> dispose() async {
    _ambientTimer?.cancel();
    _ambientTimer = null;
    _bgmFadeTimer?.cancel();
    _bgmFadeTimer = null;
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
