/// 遊び方・告発・勝敗説明で使う用語。
///
/// [trueOni] は告発対象などルール上の「鬼」。[realOni] は人狼と区別するときだけ使う。
abstract final class GuideTerms {
  static const trueOni = '鬼';
  static const realOni = '本物の鬼';
  static const runner = '逃走者';
  static const werewolf = '人狼';
  static const humanFaction = '人陣営';
  static const oniFaction = '鬼陣営';
  static const namedReveal = '名前付き暴露';
  /// 地図上のマーカー・痕跡そのもの。
  static const anonTrace = '不明な痕跡';

  /// 位置がばれる行為（する／される）。
  static const anonPositionReveal = '匿名位置暴露';
  static const panic = 'パニック';
  static const panicTrace = 'パニック痕跡';
  static const secondGame = '第二ゲーム';
  static const echoForm = '残響体';
  static const vengefulShadow = '復讐の鬼影';
  /// マップ・HUD と同じ名称（旧: 通信妨害ゾーン）。
  static const commJamZone = '通信障害地帯';
}
