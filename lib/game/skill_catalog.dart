import '../features/how_to_play/guide_terms.dart';
import 'match_ui_terms.dart';
import 'player_role.dart';
import 'skill_reference.dart';

export 'skill_reference.dart' show SkillHelpEntry;

/// 遊び方シート・設計ドキュメント用のスキル説明。
///
/// 装備スキルの一次ソースは [SkillReference]（数値は [GameConfig]）。
abstract final class SkillCatalog {
  static const matchFlow =
      'タイトル → ルーム参加 → 準備（時間・エリア・ルール）→ 試合開始 → 結果。'
      '推奨: 5〜6人・30〜60分・やや広めのエリア（第二ゲーム・告発・心理戦向け）。';

  static const mapSkillPlacementGuide =
      '捕獲結界・体投げなど「地図に置く」スキルは、ボタンを押したあと'
      '地図を長押しして範囲を確認し、指を離して設置します。'
      '設置中はバナー右上の×でキャンセルできます（時間制限はありません）。'
      '偽情報暴露など選択画面があるスキルは、キャンセルで取り消せます。';

  /// 遊び方シート・エリア編集の共通文案。
  static const playAreaGuide =
      'プレイエリアは準備で決める「試合の舞台」です。地図上の枠線の内側が有効範囲。'
      '外に出すぎると${MatchUiTerms.namedReveal}されやすくなり、HUD に「エリア外」と出ます。'
      'ホストはマップパネルから円・多角形で形を編集し、試合開始前に保存します。';

  static const coreRule =
      '相手の位置は基本見えません。\n'
      '監視・情報屋・スキルなどで手がかりが出ます。\n'
      '脱落と陣営の勝敗は別で、脱落後も${GuideTerms.secondGame}に参加できます。';

  static List<SkillHelpEntry> entriesForRole(PlayerRole role) =>
      SkillReference.forRole(role).map((s) => s.toHelpEntry()).toList();

  static const gimmicks = [
    SkillHelpEntry(
      id: 'safe_zone',
      title: '安全地帯',
      iconName: 'shield',
      body:
          '【できること】安全地帯チャージ（エリア外暴露を1回防ぐ）と、スキルの再使用待ち短縮。\n'
          '【いつ使う】エリア外に出る前後、スキルを連続で使いたいとき。\n'
          '【リスク】使用後は別の場所へ移動します。',
    ),
    SkillHelpEntry(
      id: 'info_broker',
      title: '情報屋（逃走者）',
      iconName: 'storefront',
      body:
          '【できること】鬼の方角・距離帯・断片テキストを1回取得。'
          '利用地点に約10分の「手がかり」メモ（行き直し不要）。座標ピンは出しません。\n'
          '【いつ使う】${GuideTerms.trueOni}の居場所を絞りたいとき。\n'
          '【リスク】同じ人が何度も使うとリスクが増えます。再使用まで約2分。',
    ),
    SkillHelpEntry(
      id: 'oni_info_broker',
      title: '情報屋（鬼）',
      iconName: 'storefront',
      body:
          '【できること】同じ情報屋マーカー。鬼が使うと逃走者1人がランダムに選ばれ、'
          'その端末から${MatchUiTerms.namedReveal}が1回入ります（理由は共通プール）。\n'
          '【いつ使う】追跡の手がかりが欲しいとき。オンライン試合のみ。\n'
          '【リスク】再使用まで約90秒。常時GPS共有はしません。',
    ),
    SkillHelpEntry(
      id: 'camera',
      title: '監視カメラ',
      iconName: 'videocam',
      body:
          '【できること】小さな感知圏。通過のたびに通知と${GuideTerms.anonTrace}（理由: 監視カメラ）。\n'
          '【いつ使う】要所の動きを拾いたいとき。\n'
          '【リスク】同一カメラは約90秒後に再検知できます（1台1回で止まらない）。',
    ),
    SkillHelpEntry(
      id: 'periodic_anon',
      title: '定期の${GuideTerms.anonPositionReveal}',
      iconName: 'schedule',
      body:
          '【できること】試合時間に連動した間隔（おおよそ75〜180秒）で参加者から1人が選ばれ、'
          '${GuideTerms.anonPositionReveal}され${GuideTerms.anonTrace}が出ます（${MatchUiTerms.namedReveal}ではありません）。\n'
          '【偽位置との関係】逃走者の偽位置スキル発動中は、名前付き・匿名・定期暴露すべておとり近傍に出ます。\n'
          '【いつ使う】情報の床として、偽情報と区別しにくい手がかりになります。\n'
          '【リスク】理由は通信混線・傍受・監視カメラなど共通プールから。',
    ),
    SkillHelpEntry(
      id: 'infection',
      title: GuideTerms.panic,
      iconName: 'bubble_chart',
      body:
          '【できること】鬼からの距離が${MatchUiTerms.panicRing}（接触圏より外側になりやすい）に'
          '約6秒 → 約22秒の${GuideTerms.panic}状態。約7秒ごとに${GuideTerms.anonTrace}。\n'
          '【いつ使う】鬼が近いときの警戒サイン。\n'
          '【リスク】脱落はしません。痕跡が残りやすくなります。偽位置中は痕跡もおとり近傍。',
    ),
    SkillHelpEntry(
      id: 'capture',
      title: '接触・捕獲',
      iconName: 'front_hand',
      body:
          '【できること】鬼の接触圏（エリア連動）に約4秒留まると${MatchUiTerms.restraint}。'
          '至近はGPS約12mまたはBLE接触で${MatchUiTerms.capture}。\n'
          '【いつ使う】鬼が接近して相手を止めたいとき。\n'
          '【リスク】拘束円もエリア連動。持続は歩行で横断する想定時間。捕獲結界スキルとは別です。',
    ),
    SkillHelpEntry(
      id: 'accusation_facility',
      title: '告発施設',
      iconName: 'account_balance',
      body:
          '【できること】3人以上のみ。解禁後、${GuideTerms.humanFaction}が${GuideTerms.trueOni}を告発できます。'
          '正解・失敗の重みはホストが試合前に選択。\n'
          '【いつ使う】手がかりが揃ったとき。解禁条件: 脱落1人かつ試合時間25%（最短5分・最長15分）経過、または試合60%経過。\n'
          '【リスク】${GuideTerms.werewolf}は告発不可。'
          '生存中の${GuideTerms.trueOni}が施設付近にいる間はその施設では告発不可（別施設は可）。'
          '残響体の陣取りで+1（試合2回まで）、復讐の鬼影の妨害で-1（試合3回）。',
    ),
    SkillHelpEntry(
      id: 'oni_delayed_trail',
      title: '鬼の遅延軌跡',
      iconName: 'timeline',
      body:
          '【できること】鬼の位置は常時共有されません。試合時間に応じた遅延のあと、過去の通過らしき線が薄く出ます。\n'
          '【いつ使う】序盤は「試合開始付近」の手がかりピンが出ることもあります（遅延軌跡が育つ前の補助）。\n'
          '【リスク】ライブ位置の代わりにはなりません。',
    ),
    SkillHelpEntry(
      id: 'trace_drop',
      title: '脱落地点の痕跡',
      iconName: 'place',
      body:
          '【できること】捕獲・告発失敗などで脱落した地点が、同じルームの全員の地図に共有されます。\n'
          '【いつ使う】その後の追跡・推理の手がかりになります。\n'
          '【リスク】${MatchUiTerms.namedReveal}や${GuideTerms.anonTrace}とは別の情報です。',
    ),
    SkillHelpEntry(
      id: 'runner_analyst',
      title: 'アナリスト（逃走者特化）',
      iconName: 'analytics',
      body:
          '【できること】${GuideTerms.anonTrace}に時間帯・観測源・位置誤差（信頼度）の読み取り補助。\n'
          '【いつ使う】痕跡をつなげて${GuideTerms.trueOni}の動きを推理するとき。\n'
          '【リスク】対象者の名前は出しません。名前付き暴露・偽情報暴露には適用されません。',
    ),
    SkillHelpEntry(
      id: 'runner_hacker',
      title: 'ハッカー（逃走者特化）',
      iconName: 'terminal',
      body:
          '【できること】情報屋の距離帯が細かくなり、鬼の向いている方角（移動方向）が分かることがあります。\n'
          '【いつ使う】味方の判断を助けたいとき。\n'
          '【リスク】鬼の座標ピンは出しません。',
    ),
  ];
}
