import '../features/how_to_play/guide_terms.dart';
import 'match_ui_terms.dart';
import 'player_role.dart';
import 'skill_ids.dart';

/// 遊び方シート・設計ドキュメント用のスキル説明（一次ソースは [SkillIds] / [GameConfig]）。
abstract final class SkillCatalog {
  static const matchFlow =
      'タイトル → ルーム参加 → 準備（時間・エリア・ルール）→ 試合開始 → 結果。'
      '推奨: 5〜6人・30〜60分・やや広めのエリア（第二ゲーム・告発・心理戦向け）。';

  static const mapSkillPlacementGuide =
      '捕獲結界・体投げなど「地図に置く」スキルは、ボタンを押したあと'
      '地図を長押しして範囲を確認し、指を離して設置します。'
      'キャンセルは画面右上の×です。'
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
      switch (role) {
        PlayerRole.runner => runnerSkills,
        PlayerRole.hunter => hunterSkills,
        PlayerRole.werewolf => werewolfSkills,
      };

  static const runnerSkills = [
    SkillHelpEntry(
      id: SkillIds.fakePosition,
      title: '偽位置（逃走者）',
      iconName: 'scatter_plot',
      body:
          '【できること】約20秒、進行方向の先にデコイ位置を出し、ゆっくり移動させます。'
          '発動中は${MatchUiTerms.namedReveal}がデコイ座標に差し替わることがあります。\n'
          '【いつ使う】追われているとき、痕跡を残したくないとき。\n'
          '【リスク】露出が起きない間は効果が限定的。相手の地図に「デコイ」とは表示されません。',
    ),
    SkillHelpEntry(
      id: SkillIds.captureZone,
      title: '捕獲結界（逃走者）',
      iconName: 'trip_origin',
      body:
          '【できること】スキルで地図に拘束エリア（半径約55m）を置き、範囲内の相手をロックします。'
          '至近またはBLEで捕獲しやすくなります。\n'
          '【いつ使う】通路を塞ぐ、逆転のトラップを仕掛けるとき。'
          '地図を長押し→離して設置（右上×でキャンセル）。\n'
          '【リスク】約24秒で消えます。再使用まで約80秒。',
    ),
  ];

  static const hunterSkills = [
    SkillHelpEntry(
      id: SkillIds.fakeIntelReveal,
      title: '偽情報暴露（鬼）',
      iconName: 'psychology_alt',
      body:
          '【できること】「自分を暴露」か「逃走者をランダム暴露」を選び、'
          '${MatchUiTerms.namedReveal}のような偽情報を地図に出します（${GuideTerms.anonTrace}ではありません）。'
          '相手からは偽とは分かりません。\n'
          '【いつ使う】アリバイ・囮・読みのずらしに。選択画面はキャンセル可。\n'
          '【リスク】地点はプレイエリア内の別座標。再使用まで約75秒。',
    ),
    SkillHelpEntry(
      id: SkillIds.bodyThrow,
      title: '体投げ（鬼）',
      iconName: 'near_me',
      body:
          '【できること】自分から約90m以内の地点に人形を置き、短時間そこを捕獲判定の中心にします。'
          '逃走者から見た鬼の位置が人形へ移る「瞬間的な寄せ」です。\n'
          '【いつ使う】離れた相手を一気に追い詰めたいとき。'
          '地図を長押し→離して設置（右上×でキャンセル）。\n'
          '【リスク】未回収・期限切れで${MatchUiTerms.namedReveal}されることがあります。',
    ),
    SkillHelpEntry(
      id: SkillIds.captureZone,
      title: '捕獲結界（鬼）',
      iconName: 'trip_origin',
      body:
          '【できること】スキルで地図に拘束エリア（半径約55m）を置き、範囲内の逃走者をロックします。'
          '至近またはBLEで捕獲しやすくなります。\n'
          '【いつ使う】複数方向から圧をかけたいとき。'
          '地図を長押し→離して設置（右上×でキャンセル）。\n'
          '【リスク】約24秒。範囲外に10秒出ると相手に脱落リスク。再使用まで約80秒。',
    ),
  ];

  static const werewolfSkills = [
    SkillHelpEntry(
      id: SkillIds.werewolfTransform,
      title: '鬼化⇄人化（人狼）',
      iconName: 'nightlight',
      body:
          '【できること】「人の姿」と「鬼化中の姿」を切り替えます（ボタン表示は現在の姿に応じて「鬼化」「人化」）。'
          '鬼化中は鬼のように追跡・拘束できますが、${GuideTerms.werewolf}は${GuideTerms.trueOni}ではありません。\n'
          '【いつ使う】陣営（${GuideTerms.humanFaction}/${GuideTerms.oniFaction}）に応じて立ち回るとき。'
          '人数比で陣営が決まり、見た目とは別です（同数なら${GuideTerms.humanFaction}）。'
          '人陣営＋鬼化は捕獲可、鬼陣営＋鬼化は${GuideTerms.panic}・拘束のみ。\n'
          '【リスク】min(10分, 試合時間÷3)ごとに強制切替（通知なし）。'
          '自発切替CD=0.75×interval、強制切替CD=0.9×interval。告発不可。脱落時の陣営は固定。',
    ),
  ];

  static const gimmicks = [
    SkillHelpEntry(
      id: 'safe_zone',
      title: '安全地帯',
      iconName: 'shield',
      body:
          '【できること】ステルスチャージ（エリア外暴露を1回防ぐ）と、スキルの再使用待ち短縮。\n'
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
      title: '定期匿名痕跡',
      iconName: 'schedule',
      body:
          '【できること】試合時間に連動した間隔（おおよそ75〜180秒）で参加者から1人が選ばれ、'
          '${GuideTerms.anonTrace}が出ます（${MatchUiTerms.namedReveal}ではありません）。\n'
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
          '【リスク】脱落はしません。痕跡が残りやすくなります。',
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
          '【できること】${GuideTerms.anonTrace}に時間帯・観測源・信頼度の読み取り補助。\n'
          '【いつ使う】痕跡をつなげて${GuideTerms.trueOni}の動きを推理するとき。\n'
          '【リスク】対象者の名前は出しません。',
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

final class SkillHelpEntry {
  const SkillHelpEntry({
    required this.id,
    required this.title,
    required this.iconName,
    required this.body,
  });

  final String id;
  final String title;
  final String iconName;
  final String body;
}
