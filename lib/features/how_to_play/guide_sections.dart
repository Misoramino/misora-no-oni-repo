import 'package:flutter/material.dart';

import 'guide_diagram_type.dart';
import 'guide_models.dart';
import 'guide_terms.dart';

/// 遊び方のヘッダー。
const guideHeader = GuideHeaderData(
  title: 'ONI PIN の遊び方',
  subtitle: '地図に隠れた相手を、手がかりだけで追いかける。',
  body: '屋外で走り回る鬼ごっこに、推理と駆け引きが加わったゲームです。\n'
      '知らない用語は章を開けば図つきで説明しています。',
  hint: '全部読まなくて大丈夫。困ったところだけ見てください。',
  indexPrompt: 'よく見る章',
);

/// 12章の遊び方本文。
final howToPlaySections = <GuideSectionData>[
  _introSection,
  _winSection,
  _infoSection,
  _combatSection,
  _outsideSection,
  _facilitiesSection,
  _accusationSection,
  _rolesSection,
  _skillsSection,
  _secondGameSection,
  _onlineSection,
  _specSection,
];

GuideSectionData? guideSectionById(String id) {
  for (final s in howToPlaySections) {
    if (s.id == id) return s;
  }
  return null;
}

/// 詳細ルール章のカード ID 一覧（ジャンプ先検証用）。
Iterable<String> get guideSpecCardIds sync* {
  final spec = guideSectionById('spec');
  if (spec == null) return;
  for (final c in spec.cards) {
    yield c.id;
  }
}

// --- helpers ---

GuideCardData _card({
  required String id,
  required String title,
  required IconData icon,
  required String oneLine,
  required String body,
  List<String> bullets = const [],
  GuideDiagramType? diagramType,
  String? diagramCaption,
  GuideDiagramData? diagram,
  List<GuideDetailData> details = const [],
  String? footnote,
}) {
  return GuideCardData(
    id: id,
    title: title,
    icon: icon,
    oneLine: oneLine,
    body: body,
    bullets: bullets,
    diagram: diagram ??
        (diagramType == null
            ? null
            : GuideDiagramData(
                type: diagramType,
                title: oneLine,
                caption: diagramCaption,
              )),
    details: details,
    footnote: footnote,
  );
}

GuideDetailData _detail({
  required String title,
  required String body,
  String? specCardId,
}) =>
    GuideDetailData(title: title, body: body, specCardId: specCardId);

GuideCardData _specCard({
  required String id,
  required String title,
  required IconData icon,
  required String oneLine,
  List<GuideSpecRow> rows = const [],
  List<GuideSpecGroup> groups = const [],
}) =>
    GuideCardData(
      id: id,
      title: title,
      icon: icon,
      oneLine: oneLine,
      body: '',
      specRows: rows,
      specGroups: groups,
    );

// --- sections ---

final _introSection = GuideSectionData(
  id: 'intro',
  title: 'はじめに',
  icon: Icons.info_outline,
  oneLine: '屋外で遊ぶ、鬼ごっこ＋推理です。',
  initiallyExpanded: true,
  sectionDiagram: GuideDiagramData(
    type: GuideDiagramType.introClues,
    title: '相手の位置は基本見えない',
    caption: '見えるのは手がかりだけ',
  ),
  cards: [
    _card(
      id: 'about',
      title: '何をするゲーム？',
      icon: Icons.sports_esports_outlined,
      oneLine: '逃げる・追う・当てる。',
      body: '鬼は追い、逃走者は耐えます。人狼は人数で味方が変わる第三の顔。'
          '地図の点は「いまここ」ではなく、読み解く手がかりです。',
      diagramType: GuideDiagramType.mapConcept,
      diagramCaption: 'GPSで走りながら、情報戦を楽しむ',
    ),
    _card(
      id: 'first_things',
      title: 'まず3つ',
      icon: Icons.lightbulb_outline,
      oneLine: 'これだけ覚えれば始められます。',
      body:
          '① 相手の位置は基本見えない\n'
          '② 手がかりを読む（${GuideTerms.namedReveal}・${GuideTerms.anonTrace}）\n'
          '③ 鬼に近づきすぎると危ない',
      details: [
        _detail(
          title: 'おすすめの人数・時間',
          body: '5〜6人、30〜60分、やや広めのエリアが目安です。',
        ),
      ],
    ),
  ],
  relatedSectionIds: ['win', 'info', 'combat'],
);

final _winSection = GuideSectionData(
  id: 'win',
  title: '勝ち方',
  icon: Icons.emoji_events_outlined,
  oneLine: '人は逃げ切るか鬼を当てる。鬼は全員捕まえる。',
  initiallyExpanded: true,
  sectionDiagram: GuideDiagramData(
    type: GuideDiagramType.factionWin,
    title: '陣営ごとの勝利条件',
    caption: '個人の脱落と陣営の勝敗は別',
  ),
  cards: [
    _card(
      id: 'human_win',
      title: '${GuideTerms.humanFaction}の勝ち',
      icon: Icons.directions_run_rounded,
      oneLine: '時間切れで生き残る／告発で鬼を当てる／鬼が全員いなくなる。',
      body: 'どれか1つで勝ちです。${GuideTerms.werewolf}だけ残っても、${GuideTerms.realOni}がいなければ人側の勝ちです。',
      details: [
        _detail(
          title: '人側の勝ち条件（一覧）',
          body:
              '・制限時間まで生存者が1人以上\n'
              '・告発で${GuideTerms.realOni}を当てる（標準設定）\n'
              '・${GuideTerms.realOni}が全員脱落',
        ),
      ],
    ),
    _card(
      id: 'oni_win',
      title: '${GuideTerms.oniFaction}の勝ち',
      icon: Icons.nightlight_round,
      oneLine: '人側の生存者を0人にする。',
      body: '逃走者を捕獲して追い詰めます。告発される前に決着をつけましょう。',
    ),
    _card(
      id: 'elim_not_end',
      title: '脱落≠終了',
      icon: Icons.replay_circle_filled_outlined,
      oneLine: '落ちても${GuideTerms.secondGame}で味方を助けられます。',
      body: '捕獲・告発失敗・エリア外などで脱落しても、陣営の勝敗にはまだ関われます。',
    ),
  ],
  relatedSectionIds: ['info', 'accusation', 'second_game'],
);

final _infoSection = GuideSectionData(
  id: 'info',
  title: '情報戦',
  icon: Icons.radar_outlined,
  oneLine: '相手の位置は見えない。手がかりを読む。',
  sectionDiagram: GuideDiagramData(
    type: GuideDiagramType.informationTypes,
    title: '地図の点は手がかり',
    caption: '「いまここ」と決めつけない',
  ),
  cards: [
    _card(
      id: 'no_live',
      title: '基本ルール',
      icon: Icons.visibility_off_outlined,
      oneLine: '地図の点＝手がかり。現在地とは限りません。',
      body: 'カメラ・${GuideTerms.panic}・施設などで点が出ます。「少し前にここにいたかも」と読みましょう。',
    ),
    _card(
      id: 'named_reveal',
      title: GuideTerms.namedReveal,
      icon: Icons.person_pin_circle_outlined,
      oneLine: '「○○がここにいた」と分かる。強い手がかり。',
      body: '名前付きなので信頼度は高いです。ただし暴露後に動いていることもあります。',
      details: [
        _detail(
          title: '出やすい場面',
          body: 'エリア外・告発失敗・情報屋・偽情報・体投げ失敗・拘束失敗など',
        ),
      ],
    ),
    _card(
      id: 'anon_trace',
      title: GuideTerms.anonTrace,
      icon: Icons.help_outline,
      oneLine: '「誰かがいた」だけ分かる。複数で方向が読める。',
      diagram: const GuideDiagramData(
        type: GuideDiagramType.infoTraceChain,
        title: '痕跡をつなぐ',
        caption: '？を並べると移動が見える',
      ),
      body: '誰の痕跡かは基本わかりません。点をつなげると逃げた方向の推理につながります。',
      details: [
        _detail(
          title: '出やすい場面',
          body: '定期匿名・${GuideTerms.panic}中・監視カメラ・通信混線など',
        ),
        _detail(
          title: '定期匿名の間隔',
          body: '試合中、ランダムに1人の近くへ名前なしの痕跡。間隔の目安は75〜180秒（詳細ルール参照）。',
        ),
      ],
    ),
    _card(
      id: 'info_strength',
      title: '強さの目安',
      icon: Icons.signal_cellular_alt_rounded,
      oneLine: '名前付き＞匿名。匿名は量で補う。',
      body: '${GuideTerms.namedReveal}は強い。${GuideTerms.anonTrace}は1つより複数の方が読みやすいです。',
      diagram: const GuideDiagramData(
        type: GuideDiagramType.infoStrength,
        title: '情報の強さ',
        caption: '匿名は量で補える',
      ),
    ),
  ],
  details: [
    _detail(
      title: 'よくある誤解',
      body:
          '・地図の点＝現在地？ → 多くは違います\n'
          '・${GuideTerms.anonTrace}の本人は？ → 基本わかりません\n'
          '・名前付き＝今もそこ？ → 必ずしもそうではありません',
    ),
  ],
  relatedSectionIds: ['combat', 'facilities', 'roles'],
);

final _combatSection = GuideSectionData(
  id: 'combat',
  title: '鬼との距離',
  icon: Icons.front_hand_outlined,
  oneLine: '近いほど危ない。円は3段階。',
  sectionDiagram: GuideDiagramData(
    type: GuideDiagramType.combatDanger,
    title: '遠い → 近い → ごく近い',
    caption: 'パニック → 止められる → 捕まる',
  ),
  cards: [
    _card(
      id: 'danger_flow',
      title: '3段階',
      icon: Icons.trending_up,
      oneLine: '①パニック ②止められる ③捕まる',
      body:
          '① やや遠い円：長くいると${GuideTerms.panic}（脱落しない・痕跡が出やすい）\n'
          '② 近い円：しばらくいると動きを止められる\n'
          '③ ごく近い：止められ中に鬼が来ると捕獲',
    ),
    _card(
      id: 'panic',
      title: GuideTerms.panic,
      icon: Icons.bubble_chart_outlined,
      oneLine: '脱落しない。離れれば落ち着く。',
      body: '鬼の外側の円に長くいると不安定になり、動くと${GuideTerms.anonTrace}が残りやすくなります。',
      details: [
        _detail(
          title: '数値を見る',
          body: '約6秒で発生・約22秒続く・約7秒ごとに痕跡が出ます。',
          specCardId: 'spec_panic',
        ),
      ],
    ),
    _card(
      id: 'restraint',
      title: '止められる',
      icon: Icons.lock_outline,
      oneLine: '近い円から外に出れば解除。',
      body: '止められてもすぐ脱落しません。大きな円の外へ逃げましょう。',
      details: [
        _detail(
          title: '数値を見る',
          body: '近い円に約4秒で止められる。大きな円の外に約10秒で解除の目安。',
          specCardId: 'spec_capture',
        ),
      ],
    ),
    _card(
      id: 'capture',
      title: '捕獲',
      icon: Icons.front_hand,
      oneLine: '至近まで来られると脱落。',
      body: '捕獲後も${GuideTerms.secondGame}で関われます。',
      details: [
        _detail(
          title: '数値を見る',
          body: '直接捕獲の目安はGPS約12m。BLE接触はより強い接近情報として扱われます。',
          specCardId: 'spec_capture',
        ),
      ],
    ),
  ],
  relatedSectionIds: ['info', 'skills', 'spec'],
);

final _outsideSection = GuideSectionData(
  id: 'outside',
  title: 'エリア外',
  icon: Icons.warning_amber_outlined,
  oneLine: '外は逃げ道だが、長くいるほどバレる。',
  sectionDiagram: GuideDiagramData(
    type: GuideDiagramType.outsideAreaFlow,
    title: 'エリア外は危険',
    caption: '行けば行くほどバレやすい',
  ),
  cards: [
    _card(
      id: 'outside_basic',
      title: '基本',
      icon: Icons.map_outlined,
      oneLine: 'すぐ脱落しない。長くいると名前付き暴露→脱落。',
      body: '枠の外はリスクです。端を使う逃げは有効ですが、使いすぎ注意。',
    ),
    _card(
      id: 'oni_outside',
      title: '鬼も同じ',
      icon: Icons.nightlight_outlined,
      oneLine: '鬼も外に長くいると脱落。即人側勝利にはならない。',
      body: '${GuideTerms.realOni}が全員いなくなったとき、人側の勝ちです。',
    ),
    _card(
      id: 'safe_zone_charge',
      title: '保険',
      icon: Icons.shield_outlined,
      oneLine: '安全地帯のチャージで、暴露を1回防げる。',
      body: 'エリア端逃げの保険になります。脱落そのものは防げません。',
    ),
  ],
  details: [
    _detail(
      title: 'くわしく',
      body:
          '境界付近（約25m）はタイマーが進みにくい。\n'
          '約8秒で警告、名前付き暴露、約25秒ごとに再暴露、約90秒で脱落。',
      specCardId: 'spec_outside',
    ),
  ],
  relatedSectionIds: ['facilities', 'win', 'spec'],
);

final _facilitiesSection = GuideSectionData(
  id: 'facilities',
  title: 'マップ施設',
  icon: Icons.place_outlined,
  oneLine: '地図上のポイント。逃げ・追う・告発に効く。',
  sectionDiagram: const GuideDiagramData(
    type: GuideDiagramType.mapConcept,
    title: 'マップの見方',
    caption: 'エリア・手がかり・施設',
  ),
  cards: [
    _card(
      id: 'safe_zone',
      title: '安全地帯',
      icon: Icons.shield_outlined,
      oneLine: 'チャージ取得。エリア外暴露を1回防げる。',
      diagram: const GuideDiagramData(
        type: GuideDiagramType.facilityRoles,
        title: '施設の種類',
        caption: '安全地帯・情報屋・カメラ・告発など',
      ),
      body: 'チャージで一定時間追跡されにくくなり、エリア外暴露を1回防げます。使うと別の場所へ移動します。',
      details: [
        _detail(
          title: '数値を見る',
          body: '半径約40m・最大チャージ2・使用後は別の場所へ移動。',
          specCardId: 'spec_info',
        ),
      ],
    ),
    _card(
      id: 'info_house',
      title: '情報屋',
      icon: Icons.storefront_outlined,
      oneLine: '人は鬼の手がかり、鬼は逃走者を名前付き暴露。',
      body: '陣営ごとに得られる情報が違います。ホスト設定で変わることがあります。',
      details: [
        _detail(
          title: '数値を見る',
          body: '半径約30m。逃走者CD約120秒、鬼CD約90秒。',
          specCardId: 'spec_info',
        ),
      ],
    ),
    _card(
      id: 'camera',
      title: '監視カメラ',
      icon: Icons.videocam_outlined,
      oneLine: '通過で${GuideTerms.anonTrace}。誰かは基本わからない。',
      body: '追う側には重要な手がかりです。',
      details: [
        _detail(
          title: '数値を見る',
          body: '検知半径約18m。同じカメラの再検知は約90秒。',
          specCardId: 'spec_info',
        ),
      ],
    ),
    _card(
      id: 'jam_zone',
      title: GuideTerms.commJamZone,
      icon: Icons.wifi_off_outlined,
      oneLine: '通信が乱れるエリア。',
      body: '情報の読み合いが複雑になります。周囲の痕跡と合わせて判断しましょう。',
    ),
    _card(
      id: 'accusation_site',
      title: '告発施設',
      icon: Icons.account_balance_outlined,
      oneLine: '後半に解禁。${GuideTerms.realOni}を当てる場所。',
      body: '標準設定では当てれば人側の勝ち。開始直後は使えません。',
    ),
  ],
  relatedSectionIds: ['info', 'accusation'],
);

final _accusationSection = GuideSectionData(
  id: 'accusation',
  title: '告発',
  icon: Icons.gavel_outlined,
  oneLine: '生存中の逃走者が、${GuideTerms.realOni}を当てる。',
  sectionDiagram: GuideDiagramData(
    type: GuideDiagramType.accusationFlow,
    title: '告発の流れ',
    caption: '推理 → 施設 → 正解なら勝利',
  ),
  cards: [
    _card(
      id: 'what',
      title: '告発とは',
      icon: Icons.help_outline,
      oneLine: '手がかりから${GuideTerms.realOni}を指名する。',
      body: '標準設定では当てれば人側の勝ち。${GuideTerms.werewolf}は正解になりません。',
    ),
    _card(
      id: 'who',
      title: '誰ができる？',
      icon: Icons.person_outline,
      oneLine: '生存中の逃走者だけ。3人以上の試合で使えます。',
      body: '鬼・人狼・脱落者は告発できません。',
    ),
    _card(
      id: 'unlock',
      title: 'いつ使える？',
      icon: Icons.lock_clock_outlined,
      oneLine: '試合の後半に解禁されます。',
      body:
          '時間が経つか、誰かが脱落すると使えるようになります。\n'
          '生き残っている逃走者だけが、告発施設で指名できます。',
      details: [
        _detail(
          title: '数値を見る',
          body: '試合時間60%経過、または脱落1人＋時間25%経過（早期解禁は5〜15分）。',
          specCardId: 'spec_accusation',
        ),
      ],
    ),
    _card(
      id: 'fail',
      title: '外したら？',
      icon: Icons.close_rounded,
      oneLine: '標準設定では告発者が脱落。位置がバレることも。',
      body: '確信がない告発はリスク大です。',
      details: [
        _detail(
          title: 'くわしく',
          body:
              '標準: 正解で人側勝利、失敗で告発者脱落。\n'
              '脱落モード: 正解で鬼脱落・試合続行、失敗は告発権のみ消費。\n'
              'ポイント: 正解でポイント加算、失敗は告発権のみ消費。',
        ),
      ],
    ),
    _card(
      id: 'facility_fight',
      title: '施設の奪い合い',
      icon: Icons.groups_outlined,
      oneLine: '残響体は施設を増やす／鬼影は減らす（鬼が近い施設は使えない）。',
      body:
          '${GuideTerms.secondGame}の行動で、味方が使える告発施設の数が変わります。',
      details: [
        _detail(
          title: '数値を見る',
          body: '解禁時は基本1施設。残響体+1（2回まで）、鬼影-1（3回まで）。',
          specCardId: 'spec_accusation',
        ),
      ],
    ),
  ],
  relatedSectionIds: ['info', 'roles', 'second_game'],
);

final _rolesSection = GuideSectionData(
  id: 'roles',
  title: '役職',
  icon: Icons.groups_outlined,
  oneLine: '逃走者・鬼・人狼。目的が違います。',
  sectionDiagram: GuideDiagramData(
    type: GuideDiagramType.roleOverview,
    title: '役職の全体像',
    caption: '人陣営・鬼陣営・人狼',
  ),
  cards: [
    _card(
      id: 'runner',
      title: GuideTerms.runner,
      icon: Icons.directions_run_rounded,
      oneLine: '逃げて、手がかりを読み、鬼を当てる。',
      body: '人陣営の基本。告発が解禁されたら${GuideTerms.realOni}を指名できます。',
    ),
    _card(
      id: 'true_oni',
      title: GuideTerms.trueOni,
      icon: Icons.nightlight_round,
      oneLine: '追って、捕まえる。鬼陣営の中心。',
      body: '逃走者を全員捕まえれば鬼側の勝ち。手がかりを読んで追い詰めます。',
    ),
    _card(
      id: 'werewolf',
      title: GuideTerms.werewolf,
      icon: Icons.psychology_alt_rounded,
      oneLine: '鬼のようには動けるが、${GuideTerms.realOni}ではない。',
      body: '「鬼化」中だけ追跡・拘束可能。告発の正解にはなりません。',
      diagram: const GuideDiagramData(
        type: GuideDiagramType.werewolfNotOni,
        title: '${GuideTerms.werewolf} ≠ ${GuideTerms.realOni}',
        caption: '告発の対象は${GuideTerms.realOni}',
      ),
      details: [
        _detail(
          title: '陣営の決まり方',
          body:
              '生存者のうち、人側と鬼側のどちらか少ない方の陣営が味方です（脱落時に固定）。',
        ),
        _detail(
          title: 'つまりどういうこと？',
          body:
              '試合が進むと人は捕まって減っていきます。'
              'だから多くの試合では前半は鬼側・後半は人側の味方になりやすい、'
              'と覚えるとラクです。',
        ),
      ],
    ),
    _card(
      id: 'analyst',
      title: 'アナリスト',
      icon: Icons.analytics_outlined,
      oneLine: '逃走者特化。${GuideTerms.anonTrace}を読みやすい。',
      body: '名前は直接は出ません。痕跡の補助情報が得られます。',
    ),
    _card(
      id: 'hacker',
      title: 'ハッカー',
      icon: Icons.terminal_outlined,
      oneLine: '逃走者特化。情報屋の手がかりが精密。',
      body: '鬼の方角・距離帯を読みやすくなります。',
    ),
  ],
  details: [
    _detail(
      title: '人数と配分',
      body: '3人以上は基本「鬼1・人狼1・残り逃走者」。6人以上で人狼2のことも。ホストが人数指定も可能。',
    ),
  ],
  relatedSectionIds: ['skills', 'accusation', 'win'],
);

final _skillsSection = GuideSectionData(
  id: 'skills',
  title: 'スキル',
  icon: Icons.bolt_outlined,
  oneLine: '試合前に装備。役職ごとに違う。',
  sectionDiagram: GuideDiagramData(
    type: GuideDiagramType.skillOverview,
    title: '役職ごとのスキル',
    caption: '逃走者・鬼・人狼',
  ),
  cards: [
    _card(
      id: 'skill_basic',
      title: '基本',
      icon: Icons.info_outline,
      oneLine: '役職ごとに1〜2個。目的を決めてから使う。',
      body:
          '逃走者：候補から1つ／鬼：候補から2つ／人狼：鬼化。\n'
          '「1分チュートリアル」で操作の感覚を体験できます。',
      details: [
        _detail(
          title: '即時 vs 地図設置',
          body:
              '鬼化・偽位置はボタン1回。\n'
              '捕獲結界・体投げは\n'
              '①ボタン\n'
              '②地図を長押し\n'
              '③離して設置',
        ),
        _detail(
          title: '数値を見る',
          body: '各スキルの持続・射程・クールダウンは詳細ルールに一覧があります。',
          specCardId: 'spec_skills',
        ),
      ],
    ),
    _card(
      id: 'map_place',
      title: '地図に置く',
      icon: Icons.touch_app_outlined,
      oneLine: 'ボタン／長押し／離して設置。',
      body: '捕獲結界・体投げなど。キャンセルは画面右上の×。',
      diagram: const GuideDiagramData(
        type: GuideDiagramType.skillPlacement,
        title: '設置の流れ',
        caption: '長押しで範囲確認',
      ),
    ),
    _card(
      id: 'fake_position',
      title: '偽位置',
      icon: Icons.scatter_plot_outlined,
      oneLine: '暴露位置をずらす（逃走者）。',
      body: '鬼の読みを乱します。定期匿名は止まりません。',
    ),
    _card(
      id: 'capture_zone_skill',
      title: '捕獲結界',
      icon: Icons.trip_origin,
      oneLine: '地図に危険エリアを置く（人・鬼どちらも可）。',
      body: '範囲内の相手を拘束。逃げ切れなければ捕獲につながります。',
    ),
    _card(
      id: 'fake_intel',
      title: '偽情報暴露',
      icon: Icons.psychology_alt_outlined,
      oneLine: '本物っぽい偽の暴露（鬼）。',
      body: '相手の判断を迷わせます。',
    ),
    _card(
      id: 'body_throw',
      title: '体投げ',
      icon: Icons.near_me_outlined,
      oneLine: '離れた場所に人形を置く（鬼）。',
      body: '置けない・時間切れだと自分がバレることがあります。',
    ),
    _card(
      id: 'werewolf_transform',
      title: '鬼化',
      icon: Icons.auto_fix_high_outlined,
      oneLine: '一時的に鬼のように追える（人狼）。',
      body: '${GuideTerms.realOni}ではなく、告発の正解にもなりません。見た目の切替・自動切替は詳細ルールを参照。',
    ),
  ],
  relatedSectionIds: ['combat', 'roles'],
);

final _secondGameSection = GuideSectionData(
  id: 'second_game',
  title: GuideTerms.secondGame,
  icon: Icons.replay_circle_filled_outlined,
  oneLine: '脱落後も勝敗に関われる。',
  sectionDiagram: GuideDiagramData(
    type: GuideDiagramType.secondGameBranch,
    title: '脱落後の分岐',
    caption: '人側→残響体 / 鬼側→鬼影',
  ),
  cards: [
    _card(
      id: 'not_over',
      title: '脱落≠観戦',
      icon: Icons.hourglass_bottom_outlined,
      oneLine: '陣営に応じて、まだ動ける。',
      body: '捕獲・告発失敗・エリア外などで落ちても、${GuideTerms.secondGame}に入ります。',
    ),
    _card(
      id: 'echo',
      title: GuideTerms.echoForm,
      icon: Icons.sensors_outlined,
      oneLine: '人側脱落後：端子で鬼位置を暴露／旗のそばで施設を増やす',
      body: '鬼の位置を味方に暴露したり、使える告発施設を増やせます。',
      details: [
        _detail(
          title: '数値を見る',
          body: '端子ジャック・告発施設の陣取りのチャージ時間と回数上限があります。',
          specCardId: 'spec_second',
        ),
      ],
    ),
    _card(
      id: 'shadow',
      title: GuideTerms.vengefulShadow,
      icon: Icons.blur_on_outlined,
      oneLine: '鬼側脱落後：旗のそばで施設を減らす／カメラを止める',
      body: '人側の告発を遅らせたり、残響体のジャックを妨げられます。',
    ),
  ],
  details: [
    _detail(
      title: 'ホスト設定',
      body: '観戦のみ・鬼側合流など、脱落後の扱いが変わる設定があります。',
    ),
  ],
  relatedSectionIds: ['accusation', 'facilities', 'online'],
);

final _onlineSection = GuideSectionData(
  id: 'online',
  title: 'オンライン・記録',
  icon: Icons.cloud_sync_outlined,
  oneLine: '同期・再接続・中止・保存について。',
  sectionDiagram: const GuideDiagramData(
    type: GuideDiagramType.onlineMatch,
    title: '通話しながら遊ぶ',
    caption: '近接判定は背面でも／スキル操作は前面',
  ),
  cards: [
    _card(
      id: 'call_play',
      title: '通話しながら遊ぶ',
      icon: Icons.phone_in_talk_outlined,
      oneLine: 'Discord / LINE 通話はそのまま。スキルだけ前面に。',
      body: 'ゲーム内通話はありません。通話アプリを前面にしたままでも、'
          '位置情報の許可があれば近接・捕獲・パニックの判定と危機通知は継続します。'
          'スキルや告発の操作は ONI PIN を前面に戻してから行ってください。',
      bullets: const [
        '試合前に一度 ONI PIN を開いて位置・通知の許可を確認',
        'iPhone は位置情報「常に」を推奨（ロック中も判定が安定）',
        '復帰時に通話中の出来事（捕獲・暴露など）をまとめて反映',
      ],
    ),
    _card(
      id: 'sync',
      title: '同期',
      icon: Icons.sync_outlined,
      oneLine: 'ホスト開始で全員に同じ試合状態。',
      body: '再接続しても、経過時間や脱落後の状態は復元されます。',
    ),
    _card(
      id: 'abort',
      title: '試合中止',
      icon: Icons.stop_circle_outlined,
      oneLine: '過半数投票かホスト操作。勝敗・戦績は付かない。',
      body: '同意していればギャラリーに「試合中止」として残ることがあります。',
    ),
    _card(
      id: 'gallery',
      title: 'ギャラリー',
      icon: Icons.photo_library_outlined,
      oneLine: '軌跡保存は同意が必要。',
      body: '軌跡・暴露ログ・エリアなどが含まれます。',
    ),
  ],
  relatedSectionIds: ['win', 'second_game'],
);

final _specSection = GuideSectionData(
  id: 'spec',
  title: '詳細ルール',
  icon: Icons.table_chart_outlined,
  oneLine: '秒数・距離・クールダウンの一覧です。',
  cards: [
    _specCard(
      id: 'spec_outside',
      title: 'エリア外',
      icon: Icons.map_outlined,
      oneLine: '外に出たときのタイマー',
      rows: [
        const GuideSpecRow('境界付近', '約25m以内はタイマーが進みにくい'),
        const GuideSpecRow('警告', 'エリア外 約8秒'),
        const GuideSpecRow('初回暴露', GuideTerms.namedReveal),
        const GuideSpecRow('再暴露', '約25秒ごと'),
        const GuideSpecRow('脱落', '約90秒継続'),
        const GuideSpecRow('鬼', '人側と同様に脱落対象'),
      ],
    ),
    _specCard(
      id: 'spec_panic',
      title: GuideTerms.panic,
      icon: Icons.bubble_chart_outlined,
      oneLine: '近づきすぎ圏',
      rows: [
        const GuideSpecRow('発動', '圏内に約6秒'),
        const GuideSpecRow('持続', '約22秒'),
        const GuideSpecRow('痕跡', '約7秒ごと'),
        const GuideSpecRow('種別', GuideTerms.anonTrace),
        const GuideSpecRow('脱落', 'しない'),
        const GuideSpecRow('偽位置中', 'デコイ側に出ることがある'),
      ],
    ),
    _specCard(
      id: 'spec_capture',
      title: '接触・拘束・捕獲',
      icon: Icons.front_hand_outlined,
      oneLine: '鬼との距離',
      rows: [
        GuideSpecRow('${GuideTerms.panic}圏', '約58〜115m（エリア規模に連動）'),
        const GuideSpecRow('接触圏', '約35〜95m'),
        const GuideSpecRow('拘束開始', '接触圏内 約4秒'),
        const GuideSpecRow('拘束円', '約45〜110m'),
        const GuideSpecRow('円外猶予', '約10秒'),
        const GuideSpecRow('直接捕獲', 'GPS 約12m'),
        const GuideSpecRow('BLE接触', '強い接近情報として扱う'),
      ],
    ),
    _specCard(
      id: 'spec_zone',
      title: '捕獲結界',
      icon: Icons.trip_origin,
      oneLine: 'スキルで置く拘束エリア',
      rows: const [
        GuideSpecRow('半径', '約55m'),
        GuideSpecRow('持続', '約24秒'),
        GuideSpecRow('クールダウン', '約80秒'),
        GuideSpecRow('円外猶予', '約10秒'),
      ],
    ),
    _specCard(
      id: 'spec_info',
      title: '情報・施設',
      icon: Icons.radar_outlined,
      oneLine: '痕跡とマップ施設',
      rows: const [
        GuideSpecRow('定期匿名', '試合時間の約4%'),
        GuideSpecRow('匿名間隔', '約75〜180秒'),
        GuideSpecRow('45分試合目安', '約108秒に1回'),
        GuideSpecRow('監視カメラ半径', '約18m'),
        GuideSpecRow('カメラ再検知', '約90秒'),
        GuideSpecRow('情報屋半径', '約30m'),
        GuideSpecRow('逃走者 情報屋CD', '約120秒'),
        GuideSpecRow('鬼 情報屋CD', '約90秒'),
        GuideSpecRow('安全地帯半径', '約40m'),
        GuideSpecRow('安全地帯チャージ', '最大2'),
      ],
    ),
    _specCard(
      id: 'spec_accusation',
      title: '告発',
      icon: Icons.gavel_outlined,
      oneLine: '解禁と施設数',
      rows: [
        const GuideSpecRow('使用人数', '3人以上'),
        const GuideSpecRow('解禁A', '試合時間 60%経過'),
        const GuideSpecRow('解禁B', '脱落1人＋時間25%経過'),
        const GuideSpecRow('早期解禁', '5〜15分の範囲'),
        const GuideSpecRow('解禁時の施設', '基本1'),
        GuideSpecRow('${GuideTerms.echoForm}陣取り', '+1（試合2回まで）'),
        GuideSpecRow('${GuideTerms.vengefulShadow}妨害', '-1（試合3回まで）'),
        GuideSpecRow('${GuideTerms.trueOni}が近く', 'その施設では告発不可'),
      ],
    ),
    _specCard(
      id: 'spec_second',
      title: GuideTerms.secondGame,
      icon: Icons.replay_circle_filled_outlined,
      oneLine: '脱落後のチャージと回数',
      groups: [
        GuideSpecGroup(
          title: GuideTerms.echoForm,
          rows: const [
            GuideSpecRow('端子ジャック', 'チャージ約15秒 / CD約100秒 / 5回'),
            GuideSpecRow('告発施設陣取り', 'チャージ約16秒 / CD約90秒 / 2回'),
          ],
        ),
        GuideSpecGroup(
          title: GuideTerms.vengefulShadow,
          rows: const [
            GuideSpecRow('告発施設妨害', 'チャージ約18秒 / CD約90秒 / 3回'),
            GuideSpecRow('カメラ停止', 'チャージ約14秒 / CD約25秒 / 各1回'),
          ],
        ),
      ],
    ),
    _specCard(
      id: 'spec_skills',
      title: 'スキル',
      icon: Icons.bolt_outlined,
      oneLine: '装備スキルの数値',
      groups: const [
        GuideSpecGroup(
          title: '偽位置（逃走者）',
          rows: [
            GuideSpecRow('持続', '約20秒'),
            GuideSpecRow('CD', '約72秒'),
          ],
        ),
        GuideSpecGroup(
          title: '偽情報暴露（鬼）',
          rows: [GuideSpecRow('CD', '約75秒')],
        ),
        GuideSpecGroup(
          title: '体投げ（鬼）',
          rows: [
            GuideSpecRow('射程', '約90m'),
            GuideSpecRow('人形', '約12秒'),
            GuideSpecRow('設置猶予', '約22秒'),
            GuideSpecRow('CD', '約75秒'),
          ],
        ),
        GuideSpecGroup(
          title: '鬼化（人狼）',
          rows: [
            GuideSpecRow('強制切替', '試合時間÷3（最大約10分）'),
          ],
        ),
      ],
    ),
  ],
  relatedSectionIds: ['outside', 'combat', 'accusation'],
);
