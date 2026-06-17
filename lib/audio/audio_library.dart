import '../theme/world_profile.dart';

/// 同梱しているBGM楽曲。`assets/audio/bgm/<asset>.mp3`。
///
/// 音量は ffmpeg の loudnorm で概ね揃えてあるため、再生時の追加ゲインは不要。
enum BgmId {
  horror('horror', 'ホラー（緊迫）'),
  pop('pop', 'ポップ（軽快）'),
  pop2('pop2', 'ポップ＋（賑やか）'),
  cyber('cyber', 'サイバー（シンセ）'),
  tactical('tactical', 'タクティカル（スパイ）'),
  space('space', 'アストロ（壮大）'),
  magical('magical', 'マジカル（古楽器）'),
  funky('funky', 'ファンキー'),
  /// Royal Classic — Handel Water Music: Sarabande（Title/Gallery/Final tension）
  royalSarabande('royal_sarabande', 'Royal — Sarabande'),
  /// Royal Classic — Dvořák Serenade Op.22: IV. Larghetto（Lobby/Match/Lose）
  royalLarghetto('royal_larghetto', 'Royal — Larghetto'),
  /// Royal Classic — Handel Arrival of the Queen of Sheba（Victory）
  royalQueenOfSheba('royal_queen_of_sheba', 'Royal — Queen of Sheba'),
  /// Zen Kyoto — Tsukiyomi calm zen piano（Title / Gallery / Lobby のみ）
  zenTsukiyomi('zen_tsukiyomi', 'Zen — Tsukiyomi'),
  /// Cyber Night — suspense cyberpunk（Lobby / Match）
  cyberSuspense('cyber_suspense', 'Cyber — Suspense'),
  /// Astronomy — alone on the moon（Title / Gallery / Lobby）
  astroAloneMoon('astro_alone_moon', 'Astro — Alone on Moon'),
  /// Astronomy — deep space underscore（Match / Danger）
  astroDeepUnderscore('astro_deep_underscore', 'Astro — Deep Underscore'),
  /// Urban Horror — silent tension（Title）
  urbanSilentTension('urban_silent_tension', 'Urban — Silent Tension'),
  /// Urban Horror — silent pursuit（Lobby / Match）
  urbanSilentPursuit('urban_silent_pursuit', 'Urban — Silent Pursuit'),
  /// Urban Horror — silent shot（Moment / Capture）
  urbanSilentShot('urban_silent_shot', 'Urban — Silent Shot'),
  /// Magical World — ethereal magic（Title / Gallery）
  magicalEthereal('magical_ethereal', 'Magical — Ethereal'),
  /// Magical World — orchestra（Lobby / Match）
  magicalOrchestra('magical_orchestra', 'Magical — Orchestra'),
  /// Magical World — victory orchestra
  magicalVictory('magical_victory', 'Magical — Victory');

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
  wind('wind'),
  forest('forest'),
  comms('comms'),
  sonar('sonar'),
  popCity('pop_city'),
  beep('beep'),
  zenWoodJungle('zen_wood_jungle'),
  zenWindLeaves('zen_wind_leaves'),
  zenBirdSubtle('zen_bird_subtle'),
  royalBellIndoor('royal_bell_indoor'),
  royalFireplace('royal_fireplace'),
  cyberAmbientDeep('cyber_ambient_deep'),
  urbanRainCity('urban_rain_city'),
  magicalFireplace('magical_fireplace'),
  argBadRadio('arg_bad_radio');

  const AmbientId(this.asset);

  final String asset;
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
