import 'accusation_weight.dart';
import 'match_quick_preset.dart';
import 'skill_catalog.dart';

/// 準備画面・ロビー向けの設定サマリ文案。
abstract final class MatchSetupSummary {
  static const recommendedPlayers = '5〜6人';
  static const recommendedDuration = '30〜60分';

  /// ホスト向け：この設定だと何分・何人向けか。
  static String prepSummaryLine({
    required double durationMinutes,
    required double gimmickDensity,
    required int participantCount,
  }) {
    final densityLabel = gimmickDensity < 0.85
        ? 'ギミック少なめ'
        : gimmickDensity > 1.12
            ? 'ギミック多め'
            : 'ギミック標準';
    final playerHint = participantCount >= 3
        ? '現在 $participantCount 人'
        : '現在 $participantCount 人（告発は3人以上）';
    return '$recommendedPlayers · ${durationMinutes.round()}分 · $densityLabel · $playerHint';
  }

  /// 非ホスト向け：告発重み・時間・人数感の一行。
  static String rulesOverviewLine({
    required double durationMinutes,
    required AccusationWeight accusationWeight,
    required int participantCount,
    required double gimmickDensity,
  }) {
    final playerHint = participantCount >= 5
        ? '人数OK'
        : participantCount >= 3
            ? 'やや少なめ'
            : '3人未満（告発不可）';
    final densityShort = gimmickDensity < 0.85
        ? 'ギミック少なめ'
        : gimmickDensity > 1.12
            ? 'ギミック多め'
            : 'バランス';
    return '${durationMinutes.round()}分 · 告発:${accusationWeight.label} · '
        '$playerHint · $densityShort';
  }

  /// プリセット適用後のトースト用。
  static String presetAppliedLabel(MatchQuickPreset preset) =>
      '${preset.label}（${preset.durationMinutes.round()}分 · '
      '${preset.subtitle.split(' · ').skip(1).join(' · ')}）';

  static String get catalogHint => SkillCatalog.matchFlow.split('。').first;
}
