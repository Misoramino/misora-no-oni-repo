import '../../theme/world_profile.dart';

/// 世界観ギャラリーの説明文（キーワード中心・改行位置固定）。
abstract final class WorldGalleryCopy {
  /// 2 行固定。各行はその世界の空気を示すキーワード列（`・` 区切り）。
  static String description(WorldProfile profile) =>
      _descriptions[profile] ?? _descriptions[WorldProfile.horror]!;

  static const _descriptions = <WorldProfile, String>{
    WorldProfile.horror:
        '深夜都市・監視・VHS\n事件ファイル・静寂・恐怖',
    WorldProfile.sport:
        'ネオン・週末・街\n駆け抜け・ポップ・解放感',
    WorldProfile.sciFi:
        '電子都市・ネオン・侵入\nグリッド・データ・サイバー',
    WorldProfile.arg:
        '夜間任務・通信管制\n迷彩・戦術・静寂',
    WorldProfile.magical:
        '羊皮紙・ルーン・禁書\n秘儀・幾何学・古代',
    WorldProfile.astronomy:
        '星海・深宇宙・静寂\n信号・軌道・希望',
    WorldProfile.japaneseLuxury:
        '墨・間・漆\n静寂・和紙・余白',
    WorldProfile.westernLuxury:
        '大理石・宮廷・アイボリー\n格式・静謐・王家',
  };
}
