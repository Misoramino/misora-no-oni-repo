/// 世界観プロファイル（ゲームルールとは独立した見た目パックのキー）。
enum WorldProfile {
  /// Urban Horror — 深夜・ARG・低情報
  horror,

  /// Pop City — Zenly 風・明るい・情報多め
  sport,

  /// Cyber Night — ネオン・サイバー
  sciFi,

  /// Stealth Tactical — 低彩度・ミニマル
  arg,

  /// Magical World — ファンタジー・星・きらめき
  magical,

  /// Astronomy — 宇宙・星座・観測
  astronomy;

  static WorldProfile fromStorageName(String? raw) {
    if (raw == null) return WorldProfile.horror;
    for (final p in WorldProfile.values) {
      if (p.name == raw) return p;
    }
    return WorldProfile.horror;
  }
}

extension WorldProfileLabel on WorldProfile {
  String get label => switch (this) {
        WorldProfile.horror => 'Urban Horror',
        WorldProfile.sport => 'Pop City',
        WorldProfile.sciFi => 'Cyber Night',
        WorldProfile.arg => 'Stealth Tactical',
        WorldProfile.magical => 'Magical World',
        WorldProfile.astronomy => 'Astronomy',
      };

  /// SharedPreferences / assets フォルダ名
  String get storageName => name;

  String get assetKey => switch (this) {
        WorldProfile.horror => 'urban_horror',
        WorldProfile.sport => 'pop_city',
        WorldProfile.sciFi => 'cyber_night',
        WorldProfile.arg => 'stealth_tactical',
        WorldProfile.magical => 'magical_world',
        WorldProfile.astronomy => 'astronomy',
      };
}
