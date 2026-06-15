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
  funky('funky', 'ファンキー');

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
  beep('beep');

  const AmbientId(this.asset);

  final String asset;
}

/// 世界観ごとの既定サウンド（タイトル/ロビーのBGM・対戦中の環境音）。
abstract final class WorldAudio {
  static BgmId defaultBgm(WorldProfile profile) => switch (profile) {
        WorldProfile.horror => BgmId.horror,
        WorldProfile.sport => BgmId.pop,
        WorldProfile.sciFi => BgmId.cyber,
        WorldProfile.arg => BgmId.tactical,
        WorldProfile.magical => BgmId.magical,
        WorldProfile.astronomy => BgmId.space,
        WorldProfile.japaneseLuxury => BgmId.magical,
        WorldProfile.westernLuxury => BgmId.space,
      };

  static AmbientId ambient(WorldProfile profile) => switch (profile) {
        WorldProfile.horror => AmbientId.wind, // 風（遠くの環境音）
        WorldProfile.sport => AmbientId.popCity, // 街の賑わい
        WorldProfile.sciFi => AmbientId.sonar, // 電子的なソナー
        WorldProfile.arg => AmbientId.comms, // 無線・通信
        WorldProfile.magical => AmbientId.forest, // 森・妖精
        WorldProfile.astronomy => AmbientId.beep, // 微かな機械音
        WorldProfile.japaneseLuxury => AmbientId.forest,
        WorldProfile.westernLuxury => AmbientId.wind,
      };
}
