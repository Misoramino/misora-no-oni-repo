import 'package:shared_preferences/shared_preferences.dart';

/// サウンド設定（端末ローカル）。マスター/効果音/BGM の音量とミュート。
class AudioSettings {
  const AudioSettings({
    this.muted = false,
    this.masterVolume = 0.70,
    this.sfxVolume = 0.85,
    this.bgmVolume = 0.38,
    this.ambientVolume = 0.26,
    this.bgmChoice = bgmWorldDefault,
    this.crossFadeEnabled = true,
    this.worldBgmEnabled = true,
  });

  /// [bgmChoice] の特別値: 世界観ごとの既定BGMに従う。
  static const String bgmWorldDefault = 'world';

  /// [bgmChoice] の特別値: BGMを鳴らさない（効果音・環境音のみ）。
  static const String bgmOff = 'off';

  final bool muted;
  final double masterVolume;
  final double sfxVolume;
  final double bgmVolume;

  /// 対戦中の環境音の音量（BGMとは独立）。
  final double ambientVolume;

  /// `'world'`（世界観既定）/ `'off'`（OFF）/ `BgmId.name`（楽曲指定）。
  final String bgmChoice;

  /// 世界観レイヤー BGM のクロスフェード。
  final bool crossFadeEnabled;

  /// 世界観別レイヤー BGM（Director）を有効にする。
  final bool worldBgmEnabled;

  /// タイトル/ロビー/リザルトでBGMを鳴らすか。
  bool get bgmEnabled => bgmChoice != bgmOff;

  /// レイヤー BGM ディレクターが動作するか。
  bool get layeredBgmEnabled => bgmEnabled && worldBgmEnabled;

  /// 実際に効果音へ適用する音量（0..1）。
  double get effectiveSfx => muted ? 0 : (masterVolume * sfxVolume).clamp(0, 1);

  /// 実際に BGM へ適用する音量（0..1）。
  double get effectiveBgm => muted ? 0 : (masterVolume * bgmVolume).clamp(0, 1);

  /// 実際に環境音へ適用する音量（0..1）。
  double get effectiveAmbient =>
      muted ? 0 : (masterVolume * ambientVolume).clamp(0, 1);

  AudioSettings copyWith({
    bool? muted,
    double? masterVolume,
    double? sfxVolume,
    double? bgmVolume,
    double? ambientVolume,
    String? bgmChoice,
    bool? crossFadeEnabled,
    bool? worldBgmEnabled,
  }) {
    return AudioSettings(
      muted: muted ?? this.muted,
      masterVolume: masterVolume ?? this.masterVolume,
      sfxVolume: sfxVolume ?? this.sfxVolume,
      bgmVolume: bgmVolume ?? this.bgmVolume,
      ambientVolume: ambientVolume ?? this.ambientVolume,
      bgmChoice: bgmChoice ?? this.bgmChoice,
      crossFadeEnabled: crossFadeEnabled ?? this.crossFadeEnabled,
      worldBgmEnabled: worldBgmEnabled ?? this.worldBgmEnabled,
    );
  }
}

abstract final class AudioPrefs {
  static const _mutedKey = 'audio_muted_v1';
  static const _masterKey = 'audio_master_v1';
  static const _sfxKey = 'audio_sfx_v1';
  static const _bgmKey = 'audio_bgm_v1';
  static const _ambientKey = 'audio_ambient_v1';
  static const _bgmChoiceKey = 'audio_bgm_choice_v1';
  static const _crossFadeKey = 'audio_crossfade_v1';
  static const _worldBgmKey = 'audio_world_bgm_v1';

  static Future<AudioSettings> load() async {
    final prefs = await SharedPreferences.getInstance();
    const d = AudioSettings();
    return AudioSettings(
      muted: prefs.getBool(_mutedKey) ?? d.muted,
      masterVolume: prefs.getDouble(_masterKey) ?? d.masterVolume,
      sfxVolume: prefs.getDouble(_sfxKey) ?? d.sfxVolume,
      bgmVolume: prefs.getDouble(_bgmKey) ?? d.bgmVolume,
      ambientVolume: prefs.getDouble(_ambientKey) ?? d.ambientVolume,
      bgmChoice: prefs.getString(_bgmChoiceKey) ?? d.bgmChoice,
      crossFadeEnabled: prefs.getBool(_crossFadeKey) ?? d.crossFadeEnabled,
      worldBgmEnabled: prefs.getBool(_worldBgmKey) ?? d.worldBgmEnabled,
    );
  }

  static Future<void> save(AudioSettings s) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_mutedKey, s.muted);
    await prefs.setDouble(_masterKey, s.masterVolume);
    await prefs.setDouble(_sfxKey, s.sfxVolume);
    await prefs.setDouble(_bgmKey, s.bgmVolume);
    await prefs.setDouble(_ambientKey, s.ambientVolume);
    await prefs.setString(_bgmChoiceKey, s.bgmChoice);
    await prefs.setBool(_crossFadeKey, s.crossFadeEnabled);
    await prefs.setBool(_worldBgmKey, s.worldBgmEnabled);
  }
}
