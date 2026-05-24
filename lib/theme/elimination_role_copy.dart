import '../game/elimination_aftermath_rule.dart';
import 'world_profile.dart';

/// 脱落後モードの世界観別表示名（ゲームルール用語のラベル）。
class EliminationRoleCopy {
  const EliminationRoleCopy({
    required this.roleTitle,
    required this.roleSubtitle,
    required this.jackSiteLabel,
    required this.jackActionLabel,
  });

  final String roleTitle;
  final String roleSubtitle;
  final String jackSiteLabel;
  final String jackActionLabel;

  static EliminationRoleCopy forProfile(
    WorldProfile profile,
    EliminationAftermathRule rule,
  ) {
    final base = switch (profile) {
      WorldProfile.horror => (
          jackSite: '憑依端子',
          jackAct: '信号を焼く',
        ),
      WorldProfile.sciFi => (
          jackSite: '制御ノード',
          jackAct: 'ジャック実行',
        ),
      WorldProfile.arg => (
          jackSite: '傍受局',
          jackAct: '座標を焼く',
        ),
      WorldProfile.sport => (
          jackSite: '監視ポール',
          jackAct: '映像を流す',
        ),
      WorldProfile.magical => (
          jackSite: '視界の楔',
          jackAct: '真視の儀',
        ),
      WorldProfile.astronomy => (
          jackSite: '地球支部端子',
          jackAct: '軌道スキャン',
        ),
    };

    final (title, subtitle) = switch (rule) {
      EliminationAftermathRule.spectralOperative => (
          '残響体',
          '監視端子で鬼位置暴露 / 告発施設で陣取り（有効数+1）',
        ),
      EliminationAftermathRule.ghostSpectator => (
          '幽霊',
          '観戦のみ。位置のざっくり表示',
        ),
      EliminationAftermathRule.joinOni => (
          '追跡の残影',
          '鬼側索敵支援（ざっくり位置）',
        ),
      EliminationAftermathRule.revenantOni => (
          '復讐の鬼影',
          '告発妨害（3回）/ 監視カメラを停止してジャックを封じる',
        ),
    };

    return EliminationRoleCopy(
      roleTitle: title,
      roleSubtitle: subtitle,
      jackSiteLabel: base.jackSite,
      jackActionLabel: base.jackAct,
    );
  }
}
