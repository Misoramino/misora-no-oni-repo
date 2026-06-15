import '../features/how_to_play/guide_terms.dart';
import 'world_profile.dart';

/// 告発施設の世界観別名称・解禁演出。
class AccusationFacilityCopy {
  const AccusationFacilityCopy({
    required this.facilityName,
    required this.unlockLines,
    required this.accuseActionLabel,
    required this.lockedHint,
  });

  final String facilityName;
  final List<String> unlockLines;
  final String accuseActionLabel;
  final String lockedHint;

  /// 選択シート・初回案内で使う、ルール上の告発対象の説明。
  static const accuseTargetLine =
      '告発対象は${GuideTerms.trueOni}です。'
      '${GuideTerms.werewolf}は${GuideTerms.realOni}ではないため選べません。';

  /// 未解禁時の共通説明（解禁条件はロジックと一致）。
  static const lockedHintBase =
      '告発: 未解禁（試合60% or 脱落+一定時間）';

  static AccusationFacilityCopy forProfile(WorldProfile profile) =>
      switch (profile) {
        WorldProfile.horror => const AccusationFacilityCopy(
            facilityName: '調査本部',
            unlockLines: [
              '第一被害確認',
              '調査本部 起動',
              '鬼告発プロトコル 解禁',
            ],
            accuseActionLabel: '鬼を告発',
            lockedHint: lockedHintBase,
          ),
        WorldProfile.sciFi => const AccusationFacilityCopy(
            facilityName: '制御中枢',
            unlockLines: [
              '生体信号ロスト',
              '制御中枢 接続',
              '鬼告発プロトコル 解禁',
            ],
            accuseActionLabel: '鬼を告発',
            lockedHint: lockedHintBase,
          ),
        WorldProfile.arg => const AccusationFacilityCopy(
            facilityName: '情報統制局',
            unlockLines: [
              '被害発生を確認',
              '情報統制ネットワーク 起動',
              '鬼識別権限 解放',
            ],
            accuseActionLabel: '鬼を告発',
            lockedHint: lockedHintBase,
          ),
        WorldProfile.sport => const AccusationFacilityCopy(
            facilityName: '交番',
            unlockLines: [
              '事件発生！',
              '交番で鬼の指名通報が可能に！',
              '鬼通報システム 解禁！',
            ],
            accuseActionLabel: '鬼を通報',
            lockedHint: lockedHintBase,
          ),
        WorldProfile.magical => const AccusationFacilityCopy(
            facilityName: '魔導審問局',
            unlockLines: [
              '禁術反応を検知しました',
              '魔導審問局との交信を確立',
              '鬼告発の儀式が可能になりました',
            ],
            accuseActionLabel: '鬼を告発',
            lockedHint: lockedHintBase,
          ),
        WorldProfile.astronomy => const AccusationFacilityCopy(
            facilityName: '宇宙連合・地球支部',
            unlockLines: [
              '異常天体反応を観測',
              '地球支部との通信確立',
              '鬼識別プロトコル 解禁',
            ],
            accuseActionLabel: '鬼を告発',
            lockedHint: lockedHintBase,
          ),
        WorldProfile.japaneseLuxury => const AccusationFacilityCopy(
            facilityName: '陰陽寮',
            unlockLines: [
              '気配を感知',
              '陰陽寮と交信',
              '本鬼告発の儀 解禁',
            ],
            accuseActionLabel: '本鬼を告発',
            lockedHint: lockedHintBase,
          ),
        WorldProfile.westernLuxury => const AccusationFacilityCopy(
            facilityName: '宮廷調査局',
            unlockLines: [
              '異常記録を検知',
              '宮廷調査局と接続',
              '本鬼告発権限 解放',
            ],
            accuseActionLabel: '本鬼を告発',
            lockedHint: lockedHintBase,
          ),
      };
}
