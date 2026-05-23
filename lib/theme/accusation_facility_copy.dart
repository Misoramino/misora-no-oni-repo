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

  static AccusationFacilityCopy forProfile(WorldProfile profile) =>
      switch (profile) {
        WorldProfile.horror => const AccusationFacilityCopy(
            facilityName: '調査本部',
            unlockLines: [
              '第一被害確認',
              '調査本部 起動',
              '容疑者告発プロトコル 解禁',
            ],
            accuseActionLabel: '容疑者を告発',
            lockedHint: '告発: 未解禁（脱落 or 残り40%）',
          ),
        WorldProfile.sciFi => const AccusationFacilityCopy(
            facilityName: '制御中枢',
            unlockLines: [
              '生体信号ロスト',
              '制御中枢 接続',
              '告発プロトコル 解禁',
            ],
            accuseActionLabel: '標的を告発',
            lockedHint: '告発: 未解禁（脱落 or 残り40%）',
          ),
        WorldProfile.arg => const AccusationFacilityCopy(
            facilityName: '情報統制局',
            unlockLines: [
              '被害発生を確認',
              '情報統制ネットワーク 起動',
              '標的識別権限 解放',
            ],
            accuseActionLabel: '標的を告発',
            lockedHint: '告発: 未解禁（脱落 or 残り40%）',
          ),
        WorldProfile.sport => const AccusationFacilityCopy(
            facilityName: '交番',
            unlockLines: [
              '事件発生！',
              '交番への通報が可能になりました！',
              '犯人通報システム 解禁！',
            ],
            accuseActionLabel: '犯人を通報',
            lockedHint: '告発: 未解禁（脱落 or 残り40%）',
          ),
        WorldProfile.magical => const AccusationFacilityCopy(
            facilityName: '魔導審問局',
            unlockLines: [
              '禁術反応を検知しました',
              '魔導審問局との交信を確立',
              '真犯人告発の儀式が可能になりました',
            ],
            accuseActionLabel: '真犯人を告発',
            lockedHint: '告発: 未解禁（脱落 or 残り40%）',
          ),
        WorldProfile.astronomy => const AccusationFacilityCopy(
            facilityName: '宇宙連合・地球支部',
            unlockLines: [
              '異常天体反応を観測',
              '地球支部との通信確立',
              '対象識別プロトコル 解禁',
            ],
            accuseActionLabel: '対象を告発',
            lockedHint: '告発: 未解禁（脱落 or 残り40%）',
          ),
      };
}
