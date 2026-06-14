/// プレイヤー向け表示文言（内部の infection 等の識別子とは別）。
abstract final class MatchUiTerms {
  /// 役職ラベル（本名を出さない暴露用）。
  static const oniRoleLabel = '鬼';

  /// 旧「感染」メカニクスの世界観名。
  static const panicMechanic = 'パニック';

  static const panicRing = 'パニック圏';

  static const panicActive = 'パニック中';

  static const panicDanger = 'パニック危険';

  static const panicOnly = 'パニックのみ';

  static const operationsManual = '遊び方';

  static const guideHub = 'ガイド・遊び方';

  static const restraint = '拘束';

  static const capture = '捕獲';

  static const anonTrace = '不明な痕跡';

  static const anonPositionReveal = '匿名位置暴露';

  static const namedReveal = '名前付き暴露';

  static const learnMoreHint =
      'くわしいルールは「チュートリアル」か ⋮ →「$guideHub」→「$operationsManual」で見られます。';
}
