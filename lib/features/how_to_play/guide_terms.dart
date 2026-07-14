import '../../game/match_ui_terms.dart';

/// 遊び方・告発・勝敗説明で使う用語。
///
/// プレイヤー向けの共有ラベルは [MatchUiTerms] を一次ソースとし、ここから参照する。
/// [trueOni] は告発対象などルール上の「鬼」。[realOni] は人狼と区別するときだけ使う。
abstract final class GuideTerms {
  static const trueOni = MatchUiTerms.oniRoleLabel;
  static const realOni = '本物の鬼';
  static const runner = '逃走者';
  static const werewolf = '人狼';
  static const humanFaction = '人陣営';
  static const oniFaction = '鬼陣営';
  static const namedReveal = MatchUiTerms.namedReveal;
  /// 地図上のマーカー・痕跡そのもの。
  static const anonTrace = MatchUiTerms.anonTrace;

  /// 位置がばれる行為（する／される）。
  static const anonPositionReveal = MatchUiTerms.anonPositionReveal;
  static const panic = MatchUiTerms.panicMechanic;
  static const panicTrace = 'パニック痕跡';
  static const secondGame = '第二ゲーム';
  static const echoForm = '残響体';
  static const vengefulShadow = '復讐の鬼影';
  /// マップ・HUD と同じ名称（旧: 通信妨害ゾーン）。
  static const commJamZone = '通信障害地帯';
}
