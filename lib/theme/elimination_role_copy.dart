import '../features/how_to_play/guide_terms.dart';
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
      WorldProfile.japaneseLuxury => (
          jackSite: '監視結界',
          jackAct: '結界を焼く',
        ),
      WorldProfile.westernLuxury => (
          jackSite: '記録端末',
          jackAct: '記録を封印',
        ),
    };

    final (title, subtitle) = switch (rule) {
      EliminationAftermathRule.spectralOperative => (
          GuideTerms.echoForm,
          '監視端子ジャック / 告発施設陣取り（有効数+1）',
        ),
      EliminationAftermathRule.ghostSpectator => (
          '幽霊',
          '観戦のみ。位置のざっくり表示',
        ),
      EliminationAftermathRule.joinOni => (
          '鬼側合流',
          '索敵支援（ざっくり位置を共有）',
        ),
      EliminationAftermathRule.revenantOni => (
          GuideTerms.vengefulShadow,
          '告発施設妨害 / カメラ停止',
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
