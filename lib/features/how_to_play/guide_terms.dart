/// 作戦マニュアル・告発・勝敗説明で使う用語。
///
/// ゲーム全体の表示名（[PlayerRole.displayName] 等）は「鬼」のまま。
/// ルール上の正式説明では [trueOni] を使う。
abstract final class GuideTerms {
  static const trueOni = '本鬼';
  static const runner = '逃走者';
  static const werewolf = '人狼';
  static const humanFaction = '人陣営';
  static const oniFaction = '鬼陣営';
  static const namedReveal = '名前付き暴露';
  static const anonTrace = '匿名痕跡';
  static const panic = 'パニック';
  static const panicTrace = 'パニック痕跡';
  static const secondGame = '第二ゲーム';
  static const echoForm = '残響体';
  static const vengefulShadow = '復讐の鬼影';
}
