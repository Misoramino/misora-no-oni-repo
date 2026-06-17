import '../theme/world_profile.dart';

/// 同梱しているBGM楽曲。`assets/audio/bgm/<asset>.mp3`。
///
/// 音量は ffmpeg の loudnorm で概ね揃えてあるため、再生時の追加ゲインは不要。
enum BgmId {
  // --- Urban Horror ---
  urbanSilentTension('urban_silent_tension', 'Urban — Silent Tension'),
  urbanSilentPursuit('urban_silent_pursuit', 'Urban — Silent Pursuit'),
  urbanSilentShot('urban_silent_shot', 'Urban — Silent Shot'),
  horror('horror', 'Urban — Horror (Legacy)'),

  // --- Pop City ---
  pop('pop', 'Pop City — Light'),
  pop2('pop2', 'Pop City — Bustle'),
  funky('funky', 'Pop City — Funky'),

  // --- Cyber Night ---
  cyber('cyber', 'Cyber — Synth'),
  cyberSuspense('cyber_suspense', 'Cyber — Suspense'),

  // --- Stealth Tactical ---
  tactical('tactical', 'Stealth — Tactical'),

  // --- Magical World ---
  magicalEthereal('magical_ethereal', 'Magical — Ethereal'),
  magicalOrchestra('magical_orchestra', 'Magical — Orchestra'),
  magicalVictory('magical_victory', 'Magical — Victory'),
  magical('magical', 'Magical — Legacy'),

  // --- Astronomy ---
  astroAloneMoon('astro_alone_moon', 'Astro — Alone on Moon'),
  astroDeepUnderscore('astro_deep_underscore', 'Astro — Deep Underscore'),
  space('space', 'Astro — Space (Legacy)'),

  // --- Zen Kyoto ---
  zenTsukiyomi('zen_tsukiyomi', 'Zen — Tsukiyomi'),

  // --- Royal Classic ---
  royalSarabande('royal_sarabande', 'Royal — Sarabande'),
  royalLarghetto('royal_larghetto', 'Royal — Larghetto'),
  royalQueenOfSheba('royal_queen_of_sheba', 'Royal — Queen of Sheba');

  const BgmId(this.asset, this.label);

  /// `assets/audio/bgm/<asset>.mp3`
  final String asset;

  /// 設定画面に出す表示名。
  final String label;

  static BgmId? fromName(String? raw) {
    if (raw == null) return null;
    for (final b in values) {
      if (b.name == raw) return b;
    }
    return null;
  }
}

/// 対戦中に「たまに」鳴らす環境音／効果音。`assets/audio/ambient/<asset>.mp3`。
enum AmbientId {
  wind('wind', 'Wind — Breeze'),
  forest('forest', 'Forest — Woodland'),
  comms('comms', 'Radio — Comms'),
  sonar('sonar', 'Sonar — Ping'),
  popCity('pop_city', 'City — Pop'),
  beep('beep', 'Telemetry — Beep'),
  zenWoodJungle('zen_wood_jungle', 'Zen — Wood & Jungle'),
  zenWindLeaves('zen_wind_leaves', 'Zen — Wind & Leaves'),
  zenBirdSubtle('zen_bird_subtle', 'Zen — Birds (Subtle)'),
  royalBellIndoor('royal_bell_indoor', 'Royal — Indoor Bell'),
  royalFireplace('royal_fireplace', 'Royal — Fireplace'),
  cyberAmbientDeep('cyber_ambient_deep', 'Cyber — Deep Ambient'),
  urbanRainCity('urban_rain_city', 'Urban — Rain'),
  magicalFireplace('magical_fireplace', 'Magical — Fireplace'),
  argBadRadio('arg_bad_radio', 'ARG — Bad Radio');

  const AmbientId(this.asset, this.label);

  final String asset;
  final String label;

  static AmbientId? fromName(String? raw) {
    if (raw == null) return null;
    for (final a in values) {
      if (a.name == raw) return a;
    }
    return null;
  }
}

/// 世界観ごとの既定サウンド（タイトル/ロビーのBGM・対戦中の環境音）。
abstract final class WorldAudio {
  static BgmId defaultBgm(WorldProfile profile) => switch (profile) {
        WorldProfile.horror => BgmId.urbanSilentPursuit,
        WorldProfile.sport => BgmId.pop,
        WorldProfile.sciFi => BgmId.cyberSuspense,
        WorldProfile.arg => BgmId.tactical,
        WorldProfile.magical => BgmId.magicalOrchestra,
        WorldProfile.astronomy => BgmId.astroAloneMoon,
        WorldProfile.japaneseLuxury => BgmId.zenTsukiyomi,
        WorldProfile.westernLuxury => BgmId.royalLarghetto,
      };

  /// 対戦中ワンショット環境音のプライマリ。
  static AmbientId ambient(WorldProfile profile) => ambientPool(profile).first;

  /// 世界観ごとの環境音プール（プライマリ + セカンダリ）。
  static List<AmbientId> ambientPool(WorldProfile profile) => switch (profile) {
        WorldProfile.japaneseLuxury => [
            AmbientId.zenWoodJungle,
            AmbientId.zenWindLeaves,
            AmbientId.wind,
          ],
        WorldProfile.westernLuxury => [
            AmbientId.royalFireplace,
            AmbientId.royalBellIndoor,
          ],
        WorldProfile.sciFi => [AmbientId.cyberAmbientDeep],
        WorldProfile.horror => [
            AmbientId.urbanRainCity,
            AmbientId.wind,
          ],
        WorldProfile.magical => [
            AmbientId.magicalFireplace,
            AmbientId.forest,
          ],
        WorldProfile.astronomy => [AmbientId.beep],
        WorldProfile.arg => [
            AmbientId.argBadRadio,
            AmbientId.comms,
          ],
        WorldProfile.sport => [AmbientId.popCity],
      };
}
