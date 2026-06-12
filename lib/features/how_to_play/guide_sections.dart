import 'package:flutter/material.dart';

import 'guide_diagram_type.dart';
import 'guide_models.dart';
import 'guide_terms.dart';

/// 作戦マニュアルのヘッダー。
const guideHeader = GuideHeaderData(
  title: 'ONI PIN 作戦マニュアル',
  subtitle: '位置は見えない。痕跡を読み、鬼を出し抜け。',
  body:
      'ONI PINは、屋外GPSタッグに人狼と情報戦を組み合わせた対戦ゲームです。\n\n'
      '相手のライブ位置は基本見えません。\n\n'
      '名前付き暴露、匿名痕跡、監視カメラ、情報屋などの断片情報を読みながら、'
      '逃げる・追う・告発する判断を行います。',
  hint: '全部を最初から読む必要はありません。\n試合中に困ったら、必要な章だけ開いてください。',
  indexPrompt: '知りたい項目を選んでください。',
);

/// 12章の作戦マニュアル本文。
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

const _detail = GuideDetailData.new;

// --- sections ---

final _introSection = GuideSectionData(
  id: 'intro',
  title: 'はじめに',
  icon: Icons.info_outline,
  oneLine: 'ONI PINは、位置を読む情報戦です。',
  initiallyExpanded: true,
  sectionDiagram: GuideDiagramData(
    type: GuideDiagramType.introClues,
    title: '相手のライブ位置は基本見えない',
    caption: '見えるのは手がかり（暴露・痕跡・施設）です。',
  ),
  cards: [
    _card(
      id: 'about',
      title: 'このゲームについて',
      icon: Icons.sports_esports_outlined,
      oneLine: '鬼ごっこに、推理と情報戦を組み合わせたゲームです。',
      body:
          '人側は、鬼から逃げながら情報を集めます。\n\n'
          '鬼側は、痕跡や暴露を読んで逃走者を追い詰めます。\n\n'
          '相手の位置は常に見えるわけではありません。\n\n'
          '断片的な情報をどう読むかが、勝敗を左右します。',
    ),
    _card(
      id: 'first_things',
      title: 'まず覚えること',
      icon: Icons.lightbulb_outline,
      oneLine: 'ライブ位置ではなく、痕跡を読むゲームです。',
      body:
          'ONI PINで最初に覚えることは3つです。\n\n'
          '・相手のライブ位置は基本見えない\n'
          '・情報には「${GuideTerms.namedReveal}」と「${GuideTerms.anonTrace}」がある\n'
          '・鬼に近づくほど、${GuideTerms.panic}・拘束・捕獲の危険が高まる\n\n'
          '細かい秒数や距離は、あとから詳細ルールで確認できます。',
    ),
  ],
  details: [
    _detail(
      title: 'おすすめの遊び方',
      body:
          'おすすめは、5〜6人、30〜60分、やや広めのエリアです。\n\n'
          '人数が少ないと鬼ごっこ寄りになり、人数が増えると人狼・情報戦の要素が強くなります。',
    ),
  ],
  relatedSectionIds: ['win', 'info', 'combat'],
);

final _winSection = GuideSectionData(
  id: 'win',
  title: '勝ち方',
  icon: Icons.emoji_events_outlined,
  oneLine:
      '人側は生き残るか${GuideTerms.trueOni}を当てる。鬼側は人側を全員捕まえます。',
  initiallyExpanded: true,
  sectionDiagram: GuideDiagramData(
    type: GuideDiagramType.factionWin,
    title: '陣営ごとの勝利条件',
    caption: '個人の脱落と陣営の勝敗は別です。',
  ),
  cards: [
    _card(
      id: 'human_win',
      title: '${GuideTerms.humanFaction}の勝ち',
      icon: Icons.directions_run_rounded,
      oneLine: '逃げ切る・当てる・${GuideTerms.trueOni}を消す、のどれかで勝ちです。',
      body:
          '${GuideTerms.humanFaction}は、次のどれかを達成すると勝ちです。\n\n'
          '・制限時間まで人側の生存者が1人以上残る\n'
          '・告発施設で${GuideTerms.trueOni}を当てる\n'
          '・${GuideTerms.trueOni}が全員脱落する\n\n'
          '${GuideTerms.werewolf}が${GuideTerms.oniFaction}に残っていても、'
          '${GuideTerms.trueOni}がいなければ${GuideTerms.humanFaction}の勝ちです。',
    ),
    _card(
      id: 'oni_win',
      title: '${GuideTerms.oniFaction}の勝ち',
      icon: Icons.nightlight_round,
      oneLine: '人側の生存者を0人にすれば勝ちです。',
      body:
          '${GuideTerms.oniFaction}は、逃走者を捕獲し、人側の生存者を0人にすると勝ちです。\n\n'
          '告発に成功される前に、人側を追い詰めましょう。',
    ),
    _card(
      id: 'elim_not_end',
      title: '脱落しても終わりではありません',
      icon: Icons.replay_circle_filled_outlined,
      oneLine: '個人の脱落と、陣営の勝敗は別です。',
      body:
          '捕獲・告発失敗・エリア外などで脱落しても、試合にはまだ関われます。\n\n'
          '脱落後は、陣営に応じて${GuideTerms.secondGame}に入り、'
          '味方を助けたり、相手を妨害したりできます。',
    ),
  ],
  details: [
    _detail(
      title: '試合中止',
      body:
          '試合中止は、参加者の過半数投票またはホスト操作で行われます。\n\n'
          '中止時は勝敗・戦績・トロフィーは付与されません。\n\n'
          '軌跡保存に同意している場合、ギャラリーには「試合中止」として保存されることがあります。',
    ),
  ],
  relatedSectionIds: ['info', 'accusation', 'second_game'],
);

final _infoSection = GuideSectionData(
  id: 'info',
  title: '情報戦',
  icon: Icons.radar_outlined,
  oneLine: 'ライブ位置は見えません。痕跡と暴露から相手を読みます。',
  sectionDiagram: GuideDiagramData(
    type: GuideDiagramType.informationTypes,
    title: '情報は「現在地」ではなく「手がかり」',
    caption: 'ライブ位置は基本見えません。',
  ),
  cards: [
    _card(
      id: 'no_live',
      title: 'ライブ位置は基本見えません',
      icon: Icons.visibility_off_outlined,
      oneLine: '地図に出るのは、現在地ではなく手がかりです。',
      body:
          'ONI PINでは、仲間や敵のライブ位置が常に表示されるわけではありません。\n\n'
          '地図に出るのは、監視カメラ、${GuideTerms.panic}、情報屋、エリア外などで発生した手がかりです。\n\n'
          '「今ここにいる」と決めつけず、「少し前にここにいたかもしれない」と読んでください。',
    ),
    _card(
      id: 'named_reveal',
      title: GuideTerms.namedReveal,
      icon: Icons.person_pin_circle_outlined,
      oneLine: '「○○がここにいた」と分かる強い情報です。',
      body:
          '${GuideTerms.namedReveal}は、プレイヤー名が付いた位置情報です。\n\n'
          'エリア外に長くいる、告発に失敗する、情報屋に見つかる、偽情報暴露を受けるなどで発生します。\n\n'
          '名前が出るため強い情報ですが、暴露されたあとに移動している可能性があります。',
      details: [
        _detail(
          title: '主な発生源',
          body:
              '・エリア外の初回暴露\n'
              '・エリア外の再暴露\n'
              '・告発失敗\n'
              '・${GuideTerms.trueOni}の情報屋使用\n'
              '・偽情報暴露\n'
              '・体投げ失敗\n'
              '・拘束円や結界からの脱出失敗',
        ),
      ],
    ),
    _card(
      id: 'anon_trace',
      title: GuideTerms.anonTrace,
      icon: Icons.help_outline,
      oneLine: '「誰かがここにいた」とだけ分かる情報です。',
      body:
          '${GuideTerms.anonTrace}は、名前が出ない位置情報です。\n\n'
          '誰の痕跡かは分かりません。\n\n'
          '1つだけでは弱い情報ですが、複数の痕跡をつなぐと、移動方向や待ち伏せ場所を推理できます。',
      details: [
        _detail(
          title: '主な発生源',
          body:
              '・定期匿名痕跡\n'
              '・${GuideTerms.panic}中の痕跡\n'
              '・監視カメラ通過\n'
              '・一部の通信混線や傍受',
        ),
      ],
    ),
    _card(
      id: 'periodic_anon',
      title: '定期匿名痕跡',
      icon: Icons.schedule_outlined,
      oneLine: '試合中、ときどき誰か1人の位置が名前なしで漏れます。',
      body:
          '試合中、全員の中からランダムで1人が選ばれ、その人の近くに${GuideTerms.anonTrace}が出ることがあります。\n\n'
          '動き続けていると、移動ルートの近くに痕跡が残りやすくなります。\n\n'
          '同じ場所に留まり続けると、痕跡が重なって「誰かがここにいる」と読まれやすくなります。',
      details: [
        _detail(
          title: '間隔の目安',
          body:
              '定期匿名痕跡は、試合時間に応じておおよそ75〜180秒間隔で発生します。\n\n'
              '45分試合では、おおよそ108秒に1回が目安です。\n\n'
              '対象者はランダムです。発生するのは名前なしの${GuideTerms.anonTrace}です。',
        ),
      ],
    ),
    _card(
      id: 'read_flow',
      title: '情報は点ではなく流れで読む',
      icon: Icons.timeline_outlined,
      oneLine: '痕跡をつなぐと、相手の動きが見えてきます。',
      body:
          '${GuideTerms.anonTrace}が1つ出ただけでは、誰の情報か分かりません。\n\n'
          'しかし、複数の痕跡、監視カメラ、${GuideTerms.namedReveal}を組み合わせると、相手の移動方向が見えてきます。\n\n'
          '鬼は痕跡を追い、人側は痕跡を残しすぎないように動くことが大切です。',
    ),
  ],
  details: [
    _detail(
      title: 'よくある誤解',
      body:
          'Q. 地図に出た点は現在地ですか？\n'
          'A. いいえ。多くの場合、現在地ではなく「一度バレた場所」や「痕跡」です。\n\n'
          'Q. ${GuideTerms.anonTrace}は誰のものか分かりますか？\n'
          'A. 基本的には分かりません。アナリストなど、一部の役職は読み取り補助がありますが、名前が直接出るわけではありません。\n\n'
          'Q. ${GuideTerms.namedReveal}は確定情報ですか？\n'
          'A. その人がその場所で暴露されたことは強い情報です。ただし、今もそこにいるとは限りません。',
    ),
  ],
  relatedSectionIds: ['combat', 'facilities', 'roles'],
);

final _combatSection = GuideSectionData(
  id: 'combat',
  title: '鬼との戦い',
  icon: Icons.front_hand_outlined,
  oneLine: '鬼に近づくほど、${GuideTerms.panic}・拘束・捕獲の危険が高まります。',
  sectionDiagram: GuideDiagramData(
    type: GuideDiagramType.combatDanger,
    title: '鬼に近いほど危険',
    caption: '安全 → パニック → 拘束 → 捕獲',
  ),
  cards: [
    _card(
      id: 'danger_flow',
      title: '近づくほど危険になります',
      icon: Icons.trending_up,
      oneLine: '${GuideTerms.panic}は警告、拘束はピンチ、捕獲は脱落です。',
      body:
          '鬼に近づくと、まず${GuideTerms.panic}になりやすくなります。\n\n'
          'さらに近づくと接触され、拘束状態になります。\n\n'
          '拘束から逃げ切れない、または鬼が至近距離まで近づくと捕獲されます。',
    ),
    _card(
      id: 'panic',
      title: GuideTerms.panic,
      icon: Icons.bubble_chart_outlined,
      oneLine: '脱落ではありませんが、${GuideTerms.anonTrace}が出て追われやすくなります。',
      body:
          '${GuideTerms.panic}は、鬼の近くにしばらくいると起きる状態です。\n\n'
          '${GuideTerms.panic}中は脱落しません。\n\n'
          'ただし、名前なしの痕跡が定期的に残るため、鬼に位置を読まれやすくなります。\n\n'
          '「足がすくんで、手がかりを残してしまう」状態だと考えてください。',
      details: [
        _detail(
          title: 'パニックの目安',
          body:
              '${GuideTerms.panic}は、鬼の${GuideTerms.panic}圏に約6秒いると発生します。\n\n'
              '持続時間は約22秒です。\n\n'
              '${GuideTerms.panic}中は約7秒ごとに${GuideTerms.anonTrace}が出ます。\n\n'
              '偽位置スキル中は、痕跡がデコイ側に出ることがあります。',
        ),
      ],
    ),
    _card(
      id: 'restraint',
      title: '接触・拘束',
      icon: Icons.lock_outline,
      oneLine: '鬼に近づかれ続けると、拘束されます。',
      body:
          '鬼の接触圏に留まり続けると、接触拘束が始まります。\n\n'
          '拘束されても、すぐに脱落するわけではありません。\n\n'
          '拘束円の外へ逃げ、一定時間逃げ切れれば助かります。\n\n'
          'ただし、逃げ切れない場合は位置が暴露され、捕獲されます。',
      details: [
        _detail(
          title: '拘束の目安',
          body:
              '拘束円の外に出ても、約10秒以内に戻れば即捕獲にはなりません。\n\n'
              '約10秒を超えると、位置暴露後に捕獲されます。\n\n'
              '拘束時間はエリア規模に応じて変わります。',
        ),
      ],
    ),
    _card(
      id: 'capture',
      title: '捕獲',
      icon: Icons.front_hand,
      oneLine: '捕獲されると脱落します。',
      body:
          '鬼が至近距離まで近づくと捕獲されます。\n\n'
          'GPSでかなり近い場合や、BLE接触がある場合は特に危険です。\n\n'
          '捕獲された後も、${GuideTerms.secondGame}で試合に関与できます。',
      details: [
        _detail(
          title: '捕獲の目安',
          body:
              '直接捕獲の目安はGPS約12m以内です。\n\n'
              'BLE接触がある場合、GPSより強い接近情報として扱われることがあります。\n\n'
              '細かい判定は端末や通信状況の影響を受ける場合があります。',
        ),
      ],
    ),
    _card(
      id: 'capture_zone',
      title: '捕獲結界',
      icon: Icons.trip_origin,
      oneLine: '地図上に置かれる危険エリアです。',
      body:
          '捕獲結界は、スキルで地図上に置く拘束エリアです。\n\n'
          '範囲に入ると拘束され、逃げ切れなければ捕獲につながります。\n\n'
          '逃走者も鬼も、装備によって使うことがあります。',
      details: [
        _detail(
          title: '捕獲結界の目安',
          body:
              '捕獲結界の半径は約55mです。\n\n'
              '持続時間は約24秒です。\n\n'
              'クールダウンは約80秒です。\n\n'
              '拘束円の外へ出た場合、約10秒の猶予があります。',
        ),
      ],
    ),
  ],
  details: [
    _detail(
      title: '距離の目安',
      body:
          '鬼との危険範囲は、プレイエリアの広さに応じて変わります。\n\n'
          '接触圏、拘束円、${GuideTerms.panic}圏は、広いエリアほど大きくなります。\n\n'
          '直接捕獲のGPS距離は約12mが目安です。\n\n'
          '正確な範囲は試合設定やエリア規模によって変わるため、画面上の警告を優先してください。',
    ),
  ],
  relatedSectionIds: ['info', 'skills', 'second_game'],
);

final _outsideSection = GuideSectionData(
  id: 'outside',
  title: 'エリア外',
  icon: Icons.warning_amber_outlined,
  oneLine: '外に出ても即脱落ではありませんが、長くいるほど危険です。',
  sectionDiagram: GuideDiagramData(
    type: GuideDiagramType.outsideAreaFlow,
    title: 'エリア外は段階的に危険',
    caption: '猶予 → 暴露 → 再暴露 → 脱落',
  ),
  cards: [
    _card(
      id: 'outside_basic',
      title: 'エリア外は段階的に危険になります',
      icon: Icons.map_outlined,
      oneLine: '外に出た瞬間ではなく、外に居続けることが危険です。',
      body:
          'プレイエリアの外に出ても、すぐに脱落するわけではありません。\n\n'
          'ただし、外に居続けると、${GuideTerms.namedReveal}が発生します。\n\n'
          'さらに外に居続けると、一定間隔で再び暴露されます。\n\n'
          '最終的に、長時間外にいると脱落します。',
    ),
    _card(
      id: 'outside_named',
      title: '外にいると名前付きでバレます',
      icon: Icons.person_off_outlined,
      oneLine: 'エリア外は、逃げ道であると同時に大きなリスクです。',
      body:
          'エリア外に長くいると、自分の${GuideTerms.namedReveal}が発生します。\n\n'
          'つまり、「誰がどこでエリア外にいたか」が相手に伝わります。\n\n'
          'エリア端を使って逃げることはできますが、使いすぎると位置を読まれやすくなります。',
    ),
    _card(
      id: 'oni_outside',
      title: '鬼もエリア外で脱落します',
      icon: Icons.nightlight_outlined,
      oneLine: '鬼だけが特別に許されるわけではありません。',
      body:
          '${GuideTerms.trueOni}も、エリア外に居続けると脱落します。\n\n'
          'ただし、鬼がエリア外に出た瞬間に${GuideTerms.humanFaction}の勝ちになるわけではありません。\n\n'
          '${GuideTerms.trueOni}が全員いなくなったとき、${GuideTerms.humanFaction}の勝ちになります。',
    ),
    _card(
      id: 'safe_zone_charge',
      title: '安全地帯チャージで暴露を防ぐ',
      icon: Icons.shield_outlined,
      oneLine: 'チャージがあれば、エリア外暴露を1回防げることがあります。',
      body:
          '安全地帯でチャージを得ていると、エリア外による${GuideTerms.namedReveal}を1回防げる場合があります。\n\n'
          'エリア端を使って逃げるときの保険になります。\n\n'
          'ただし、エリア外脱落そのものを無限に防げるわけではありません。',
    ),
  ],
  details: [
    _detail(
      title: 'エリア外の詳細',
      body:
          '・境界から約25m以内なら、エリア外タイマーは進みにくくなります。\n'
          '・エリア外が約8秒続くと、警告段階を超えます。\n'
          '・安全地帯チャージがない場合、${GuideTerms.namedReveal}が発生します。\n'
          '・外に居続けると、約25秒ごとに再暴露されます。\n'
          '・約90秒続くと脱落します。\n'
          '・鬼も同じようにエリア外脱落します。\n'
          '・鬼のエリア外は即${GuideTerms.humanFaction}勝利ではなく、鬼の脱落として処理されます。',
    ),
  ],
  relatedSectionIds: ['facilities', 'win', 'spec'],
);

final _facilitiesSection = GuideSectionData(
  id: 'facilities',
  title: 'マップ施設',
  icon: Icons.place_outlined,
  oneLine: '施設は、逃走・索敵・告発を大きく動かします。',
  sectionDiagram: GuideDiagramData(
    type: GuideDiagramType.facilityRoles,
    title: '施設の役割',
    caption: '安全地帯・情報屋・監視カメラ・告発施設など',
  ),
  cards: [
    _card(
      id: 'safe_zone',
      title: '安全地帯',
      icon: Icons.shield_outlined,
      oneLine: 'エリア外暴露を防ぐチャージを得られます。',
      body:
          '安全地帯では、エリア外暴露を防ぐためのチャージを得られます。\n\n'
          'エリア端を使って逃げたいときや、危険な境界付近を通るときの保険になります。\n\n'
          'ただし、チャージには上限があります。',
      details: [
        _detail(
          title: '安全地帯の目安',
          body:
              '安全地帯の半径は約40mです。\n\n'
              '最大チャージは2です。\n\n'
              '同じ地点でのチャージには約25秒のクールダウンがあります。\n\n'
              '安全地帯は一定時間後に再出現します。',
        ),
      ],
    ),
    _card(
      id: 'info_house',
      title: '情報屋',
      icon: Icons.storefront_outlined,
      oneLine: '相手の手がかりを得られる施設です。',
      body:
          '情報屋は、相手陣営の情報を得るための施設です。\n\n'
          '逃走者は、鬼の方角や距離帯などの手がかりを得られます。\n\n'
          '${GuideTerms.trueOni}は、逃走者1人の位置を名前付きで暴露できます。',
      details: [
        _detail(
          title: '情報屋の目安',
          body:
              '情報屋の半径は約30mです。\n\n'
              '逃走者の使用クールダウンは約120秒です。\n\n'
              '${GuideTerms.trueOni}の使用クールダウンは約90秒です。\n\n'
              '情報屋の効果は、ホスト設定や情報屋モードによって変わることがあります。',
        ),
      ],
    ),
    _card(
      id: 'camera',
      title: '監視カメラ',
      icon: Icons.videocam_outlined,
      oneLine: '通ると${GuideTerms.anonTrace}が残ります。',
      body:
          '監視カメラの近くを通ると、${GuideTerms.anonTrace}が残ります。\n\n'
          '誰が通ったかは基本的に分かりません。\n\n'
          '通る側にはリスクですが、追う側には重要な手がかりになります。',
      details: [
        _detail(
          title: '監視カメラの目安',
          body:
              '監視カメラの検知半径は約18mです。\n\n'
              '同じカメラの再検知には約90秒のクールダウンがあります。\n\n'
              '${GuideTerms.vengefulShadow}によって停止されることがあります。',
        ),
      ],
    ),
    _card(
      id: 'jam_zone',
      title: '通信妨害ゾーン',
      icon: Icons.wifi_off_outlined,
      oneLine: '情報戦をかき乱すエリアです。',
      body:
          '通信妨害ゾーンは、一定周期で通信が乱れるエリアです。\n\n'
          '情報の読み合いを複雑にする場所として使われます。\n\n'
          '逃げる側も追う側も、周囲の痕跡や暴露と合わせて判断してください。',
    ),
    _card(
      id: 'accusation_site',
      title: '告発施設',
      icon: Icons.account_balance_outlined,
      oneLine: '${GuideTerms.trueOni}を当てるための施設です。',
      body:
          '告発施設では、${GuideTerms.trueOni}だと思う相手を選んで告発できます。\n\n'
          '標準設定では、告発に成功すると${GuideTerms.humanFaction}の勝利です。\n\n'
          'ただし、告発は試合開始直後から使えるわけではありません。',
    ),
  ],
  relatedSectionIds: ['info', 'accusation'],
);

final _accusationSection = GuideSectionData(
  id: 'accusation',
  title: '告発',
  icon: Icons.gavel_outlined,
  oneLine: '${GuideTerms.trueOni}を見抜けば、${GuideTerms.humanFaction}の大きな勝ち筋になります。',
  sectionDiagram: GuideDiagramData(
    type: GuideDiagramType.accusationFlow,
    title: '告発の流れ',
    caption: '推理 → 施設へ → 正解なら勝利',
  ),
  cards: [
    _card(
      id: 'what',
      title: '告発とは',
      icon: Icons.help_outline,
      oneLine: '${GuideTerms.trueOni}を推理して当てる仕組みです。',
      body:
          '告発は、${GuideTerms.humanFaction}が${GuideTerms.trueOni}を見抜くための仕組みです。\n\n'
          '情報戦で得た痕跡や暴露をもとに、${GuideTerms.trueOni}だと思う相手を選びます。\n\n'
          '標準設定では、正解すると${GuideTerms.humanFaction}の勝利です。',
    ),
    _card(
      id: 'who',
      title: '告発できる人',
      icon: Icons.person_outline,
      oneLine: '告発できるのは、生存中の逃走者です。',
      body:
          '告発できるのは、生存中の逃走者です。\n\n'
          '${GuideTerms.werewolf}、鬼、脱落者は告発できません。\n\n'
          '${GuideTerms.werewolf}は${GuideTerms.trueOni}ではないため、告発の扱いも${GuideTerms.trueOni}とは異なります。',
    ),
    _card(
      id: 'unlock',
      title: '告発は後半に解禁されます',
      icon: Icons.lock_clock_outlined,
      oneLine: '試合開始直後からは使えません。',
      body:
          '告発施設は、試合がある程度進むまで無効です。\n\n'
          '試合時間が進むか、脱落者が出て一定時間が経過すると解禁されます。\n\n'
          '解禁後、有効な告発施設で告発できます。',
      details: [
        _detail(
          title: '解禁条件',
          body:
              '告発は、次のどちらか早い方で解禁されます。\n\n'
              '・試合時間の60%が経過\n'
              '・脱落者が1人以上出て、試合時間の25%が経過\n\n'
              'ただし、脱落者による早期解禁には最短5分、最長15分の範囲があります。',
        ),
      ],
    ),
    _card(
      id: 'facility_fight',
      title: '告発施設は奪い合いになります',
      icon: Icons.groups_outlined,
      oneLine: '${GuideTerms.echoForm}は増やし、鬼影は減らし、${GuideTerms.trueOni}は守ります。',
      body:
          '告発施設の有効数は、${GuideTerms.secondGame}の影響を受けます。\n\n'
          '${GuideTerms.echoForm}は、告発施設を陣取って有効施設を増やせます。\n\n'
          '${GuideTerms.vengefulShadow}は、告発施設を妨害して有効施設を減らせます。\n\n'
          '生存中の${GuideTerms.trueOni}が施設付近にいる間、その施設では告発できません。',
      details: [
        _detail(
          title: '施設数の目安',
          body:
              '告発解禁時の有効施設数は基本1です。\n\n'
              '${GuideTerms.echoForm}の陣取りで有効施設が+1されます。試合中2回までです。\n\n'
              '${GuideTerms.vengefulShadow}の妨害で有効施設が-1されます。試合中3回までです。\n\n'
              '${GuideTerms.trueOni}が告発施設の半径内にいる間、その施設では告発できません。',
        ),
      ],
    ),
    _card(
      id: 'fail',
      title: '告発失敗',
      icon: Icons.close_rounded,
      oneLine: '外すと大きなリスクがあります。',
      body:
          '標準設定では、告発に失敗すると告発者が脱落します。\n\n'
          'また、告発失敗によって位置が暴露されることがあります。\n\n'
          '確信がない告発は、試合の流れを大きく変えるリスクがあります。',
    ),
  ],
  details: [
    _detail(
      title: 'ホスト設定による違い',
      body:
          '告発の効果は、ホスト設定によって変わる場合があります。\n\n'
          '標準設定:\n正解すると${GuideTerms.humanFaction}勝利。失敗すると告発者が脱落します。\n\n'
          '鬼を脱落モード:\n正解すると${GuideTerms.trueOni}が脱落し、試合は続きます。失敗時は告発権消費のみです。\n\n'
          'ポイントモード:\n正解すると${GuideTerms.humanFaction}にポイントが入り、終了時に集計されます。失敗時は告発権消費のみです。',
    ),
  ],
  relatedSectionIds: ['info', 'roles', 'second_game'],
);

final _rolesSection = GuideSectionData(
  id: 'roles',
  title: '役職',
  icon: Icons.groups_outlined,
  oneLine: '逃走者・${GuideTerms.trueOni}・${GuideTerms.werewolf}で、目的と見え方が変わります。',
  sectionDiagram: GuideDiagramData(
    type: GuideDiagramType.roleOverview,
    title: '役職の全体像',
    caption: '人陣営・鬼陣営・特殊（人狼）',
  ),
  cards: [
    _card(
      id: 'runner',
      title: GuideTerms.runner,
      icon: Icons.directions_run_rounded,
      oneLine: '生き残り、情報を集め、${GuideTerms.trueOni}を見抜きます。',
      body:
          '${GuideTerms.runner}は、${GuideTerms.humanFaction}の基本役職です。\n\n'
          '鬼から逃げながら、痕跡や暴露を読んで${GuideTerms.trueOni}を推理します。\n\n'
          '告発施設が解禁されたら、${GuideTerms.trueOni}を告発できます。',
    ),
    _card(
      id: 'true_oni',
      title: GuideTerms.trueOni,
      icon: Icons.nightlight_round,
      oneLine: '逃走者を捕獲する鬼側の中心役職です。',
      body:
          '${GuideTerms.trueOni}は、${GuideTerms.oniFaction}の中心となる役職です。\n\n'
          '痕跡や暴露を読み、逃走者を追い詰めて捕獲します。\n\n'
          '${GuideTerms.trueOni}が全員いなくなると、${GuideTerms.humanFaction}の勝ちになります。',
    ),
    _card(
      id: 'werewolf',
      title: GuideTerms.werewolf,
      icon: Icons.psychology_alt_rounded,
      oneLine: '鬼のように動けますが、${GuideTerms.trueOni}ではありません。',
      body:
          '${GuideTerms.werewolf}は、状況によって鬼のようにふるまえる特殊な役職です。\n\n'
          '鬼化すると、相手を追ったり、拘束したりできます。\n\n'
          'ただし、${GuideTerms.werewolf}は${GuideTerms.trueOni}ではありません。\n\n'
          '${GuideTerms.humanFaction}が告発で当てるべきなのは${GuideTerms.trueOni}です。\n\n'
          '${GuideTerms.trueOni}が全員いなくなった場合、${GuideTerms.werewolf}が残っていても${GuideTerms.humanFaction}の勝ちになります。',
      details: [
        _detail(
          title: '人狼の立場',
          body:
              '${GuideTerms.werewolf}は、状況によって${GuideTerms.humanFaction}側・${GuideTerms.oniFaction}側の扱いが変わります。\n\n'
              '鬼化中でも、${GuideTerms.trueOni}とは異なる扱いになる場合があります。\n\n'
              '${GuideTerms.werewolf}は告発できません。\n\n'
              '${GuideTerms.werewolf}の詳細な立場は試合状況によって変わるため、役職開示と画面表示を確認してください。',
        ),
      ],
      diagram: const GuideDiagramData(
        type: GuideDiagramType.werewolfNotOni,
        title: '${GuideTerms.werewolf} ≠ ${GuideTerms.trueOni}',
        caption: '告発の対象は${GuideTerms.trueOni}です。',
      ),
    ),
    _card(
      id: 'analyst',
      title: 'アナリスト',
      icon: Icons.analytics_outlined,
      oneLine: '${GuideTerms.anonTrace}を読みやすくする逃走者特化です。',
      body:
          'アナリストは、${GuideTerms.anonTrace}の読み取りに強い逃走者です。\n\n'
          '痕跡の時間帯、発生源、信頼度などを読む補助があります。\n\n'
          'ただし、${GuideTerms.anonTrace}に名前が直接出るわけではありません。',
    ),
    _card(
      id: 'hacker',
      title: 'ハッカー',
      icon: Icons.terminal_outlined,
      oneLine: '情報屋から、より精密な手がかりを得やすい逃走者特化です。',
      body:
          'ハッカーは、情報屋の手がかりをより精密に扱える逃走者です。\n\n'
          '鬼の方角や距離帯の情報を読みやすくなります。\n\n'
          'ただし、座標ピンが常に出るわけではありません。',
    ),
  ],
  details: [
    _detail(
      title: 'オンラインの役職配分',
      body:
          '2人以下では、最低1人の逃走者と1人の対立役が配置されます。\n\n'
          '3人以上のランダム設定では、基本的に鬼1人・人狼1人・残り逃走者になります。\n\n'
          '6人以上では、人狼が2人になる場合があります。\n\n'
          '人数指定モードでは、ホストが鬼や人狼の人数を指定できます。',
    ),
  ],
  relatedSectionIds: ['skills', 'accusation', 'win'],
);

final _skillsSection = GuideSectionData(
  id: 'skills',
  title: 'スキル',
  icon: Icons.bolt_outlined,
  oneLine: 'スキルは、逃げる・惑わせる・捕まえるための切り札です。',
  sectionDiagram: GuideDiagramData(
    type: GuideDiagramType.skillOverview,
    title: '役職ごとのスキル',
    caption: '逃走者・本鬼・人狼で装備が異なります。',
  ),
  cards: [
    _card(
      id: 'skill_basic',
      title: 'スキルの基本',
      icon: Icons.info_outline,
      oneLine: '役職ごとに使えるスキルが違います。',
      body:
          'スキルは、役職ごとに装備されます。\n\n'
          '逃走者は逃げる・惑わせるためのスキルを持ちます。\n\n'
          '${GuideTerms.trueOni}は追跡・拘束・偽情報のためのスキルを持ちます。\n\n'
          '${GuideTerms.werewolf}は鬼化を使います。',
      details: [
        _detail(
          title: '装備数',
          body:
              '逃走者は、候補スキルから1つを装備します。\n\n'
              '${GuideTerms.trueOni}は、候補スキルから2つを装備します。\n\n'
              '${GuideTerms.werewolf}は、鬼化を装備します。',
        ),
      ],
    ),
    _card(
      id: 'map_place',
      title: '地図に置くスキル',
      icon: Icons.touch_app_outlined,
      oneLine: '長押しで範囲を確認し、指を離して設置します。',
      body:
          '捕獲結界や体投げなど、一部のスキルは地図上に置いて使います。\n\n'
          'スキルボタンを押したあと、地図を押し続けると範囲を確認できます。\n\n'
          '指を離すと設置します。\n\n'
          'キャンセルしたいときは、画面下の×へドラッグしてください。',
      footnote: '設置中も、2本指で地図を動かせます。',
      diagram: const GuideDiagramData(
        type: GuideDiagramType.skillPlacement,
        title: '地図に置くスキルの流れ',
        caption: 'スキル → 長押し → 離して設置',
      ),
    ),
    _card(
      id: 'fake_position',
      title: '偽位置',
      icon: Icons.scatter_plot_outlined,
      oneLine: '自分の暴露位置をずらして、鬼の判断を惑わせます。',
      body:
          '偽位置は、一定時間、自分の暴露位置をずらすスキルです。\n\n'
          '鬼の注意をそらしたいときや、痕跡から逃げ道を読まれたくないときに使います。\n\n'
          'ただし、定期匿名痕跡そのものを止めるわけではありません。',
      details: [
        _detail(
          title: '偽位置の目安',
          body:
              '偽位置は約20秒間続きます。\n\n'
              'クールダウンは約72秒です。\n\n'
              '暴露位置は進行方向側にずれ、デコイのように表示されることがあります。',
        ),
      ],
    ),
    _card(
      id: 'capture_zone_skill',
      title: '捕獲結界',
      icon: Icons.trip_origin,
      oneLine: '地図上に拘束エリアを置きます。',
      body:
          '捕獲結界は、地図上に置く危険エリアです。\n\n'
          '範囲内に入った相手を拘束し、逃げ切れなければ捕獲につながります。\n\n'
          '逃走者も${GuideTerms.trueOni}も、装備によって使うことがあります。',
    ),
    _card(
      id: 'fake_intel',
      title: '偽情報暴露',
      icon: Icons.psychology_alt_outlined,
      oneLine: '${GuideTerms.namedReveal}のような偽情報を出します。',
      body:
          '偽情報暴露は、${GuideTerms.trueOni}側のスキルです。\n\n'
          '相手に本物の暴露のような情報を見せ、判断を迷わせます。\n\n'
          '情報戦をかき乱すために使います。',
      details: [
        _detail(title: 'クールダウン', body: 'クールダウンは約75秒です。'),
      ],
    ),
    _card(
      id: 'body_throw',
      title: '体投げ',
      icon: Icons.near_me_outlined,
      oneLine: '離れた場所に人形を投げるように設置します。',
      body:
          '体投げは、${GuideTerms.trueOni}側のスキルです。\n\n'
          '離れた場所に人形を投げるように配置し、相手の動きを乱します。\n\n'
          '配置に失敗したり、時間内に置けなかったりすると、自分の位置が暴露されることがあります。',
      details: [
        _detail(
          title: '体投げの目安',
          body:
              '射程は約90mです。\n\n'
              '人形の持続は約12秒です。\n\n'
              'クールダウンは約75秒です。\n\n'
              '地図タップの猶予は約22秒です。',
        ),
      ],
    ),
    _card(
      id: 'werewolf_transform',
      title: '鬼化',
      icon: Icons.auto_fix_high_outlined,
      oneLine: '${GuideTerms.werewolf}が一時的に鬼のように動けるスキルです。',
      body:
          '鬼化は、${GuideTerms.werewolf}のスキルです。\n\n'
          '鬼化中は、鬼のように相手を追ったり、拘束したりできます。\n\n'
          'ただし、${GuideTerms.werewolf}は${GuideTerms.trueOni}ではありません。\n\n'
          '勝敗や告発では、${GuideTerms.trueOni}とは別に扱われます。',
      details: [
        _detail(
          title: '鬼化の目安',
          body:
              '${GuideTerms.werewolf}の強制切替間隔は、試合時間に応じて変わります。\n\n'
              '目安は、試合時間の3分の1、最大約10分です。\n\n'
              '任意切替にはクールダウンがあります。',
        ),
      ],
    ),
  ],
  relatedSectionIds: ['combat', 'roles'],
);

final _secondGameSection = GuideSectionData(
  id: 'second_game',
  title: GuideTerms.secondGame,
  icon: Icons.replay_circle_filled_outlined,
  oneLine: '脱落しても、試合にはまだ関われます。',
  sectionDiagram: GuideDiagramData(
    type: GuideDiagramType.secondGameBranch,
    title: '脱落後の分岐',
    caption: '人側 → 残響体 / 鬼側 → 復讐の鬼影',
  ),
  cards: [
    _card(
      id: 'not_over',
      title: '脱落後も終わりではありません',
      icon: Icons.hourglass_bottom_outlined,
      oneLine: '${GuideTerms.secondGame}で、味方を助けたり相手を妨害したりできます。',
      body:
          'ONI PINでは、捕獲・告発失敗・エリア外などで脱落しても、試合から完全に外れるわけではありません。\n\n'
          '脱落後は、陣営に応じて${GuideTerms.secondGame}に入ります。\n\n'
          '最後まで陣営の勝敗に関わることができます。',
    ),
    _card(
      id: 'echo',
      title: GuideTerms.echoForm,
      icon: Icons.sensors_outlined,
      oneLine: '人側として脱落した後の姿です。',
      body:
          '人側として脱落すると、${GuideTerms.echoForm}になります。\n\n'
          '${GuideTerms.echoForm}は、監視端子をジャックして鬼の位置を味方に暴露できます。\n\n'
          'また、告発施設の近くで陣取りを行い、有効な告発施設を増やせます。',
      details: [
        _detail(
          title: '${GuideTerms.echoForm}の行動',
          body:
              '監視端子ジャック:\n・チャージ約15秒\n・個人クールダウン約100秒\n・試合上限5回\n\n'
              '告発施設陣取り:\n・チャージ約16秒\n・個人クールダウン約90秒\n・試合上限2回\n・告発解禁後に有効',
        ),
      ],
    ),
    _card(
      id: 'shadow',
      title: GuideTerms.vengefulShadow,
      icon: Icons.blur_on_outlined,
      oneLine: '鬼側として脱落した後の姿です。',
      body:
          '鬼側として脱落すると、${GuideTerms.vengefulShadow}になります。\n\n'
          '${GuideTerms.vengefulShadow}は、告発施設を妨害して有効な施設を減らせます。\n\n'
          'また、監視カメラを停止して、${GuideTerms.echoForm}のジャックを妨害できます。',
      details: [
        _detail(
          title: '${GuideTerms.vengefulShadow}の行動',
          body:
              '告発施設妨害:\n・チャージ約18秒\n・個人クールダウン約90秒\n・試合上限3回\n\n'
              'カメラ停止:\n・チャージ約14秒\n・個人クールダウン約25秒\n・各カメラ1回まで',
        ),
      ],
    ),
    _card(
      id: 'impact',
      title: '${GuideTerms.secondGame}は勝敗に影響します',
      icon: Icons.trending_up,
      oneLine: '脱落者の行動で、告発や情報戦が変わります。',
      body:
          '${GuideTerms.secondGame}は、ただの観戦ではありません。\n\n'
          '${GuideTerms.echoForm}は${GuideTerms.humanFaction}の告発を助けます。\n\n'
          '${GuideTerms.vengefulShadow}は、告発や監視カメラを妨害します。\n\n'
          '脱落後の動きが、終盤の勝敗を変えることがあります。',
    ),
  ],
  details: [
    _detail(
      title: '脱落後モードの違い',
      body:
          'ホスト設定によって、脱落後の扱いが変わる場合があります。\n\n'
          '既定では、陣営に応じて${GuideTerms.echoForm}または${GuideTerms.vengefulShadow}になります。\n\n'
          '設定によっては、幽霊として観戦したり、鬼側に合流したりする場合があります。',
    ),
  ],
  relatedSectionIds: ['accusation', 'facilities', 'online'],
);

final _onlineSection = GuideSectionData(
  id: 'online',
  title: 'オンライン・記録',
  icon: Icons.cloud_sync_outlined,
  oneLine: '試合開始・中止・再接続・ギャラリー保存に関するルールです。',
  cards: [
    _card(
      id: 'sync',
      title: 'オンライン同期',
      icon: Icons.sync_outlined,
      oneLine: 'ホストが開始すると、試合情報が全員に同期されます。',
      body:
          'ホストが試合を開始すると、役職、エリア、ギミック、試合状態が参加者に同期されます。\n\n'
          '試合中に再接続した場合も、経過時間や脱落後の状態が復元されます。',
    ),
    _card(
      id: 'abort',
      title: '試合中止',
      icon: Icons.stop_circle_outlined,
      oneLine: '中止時は勝敗・戦績・トロフィーは付与されません。',
      body:
          '試合中止は、参加者の過半数投票またはホスト操作で行われます。\n\n'
          '中止された試合では、勝敗や戦績は記録されません。\n\n'
          '軌跡保存に同意している場合、ギャラリーには「試合中止」として保存されることがあります。',
      details: [
        _detail(
          title: '中止の詳細',
          body:
              '中止投票の回答期限は約60秒です。\n\n'
              '試合中止の終了理由は、host_abortとして扱われます。',
        ),
      ],
    ),
    _card(
      id: 'gallery',
      title: 'ギャラリー保存',
      icon: Icons.photo_library_outlined,
      oneLine: '軌跡保存にはユーザー同意が必要です。',
      body:
          '試合の軌跡やイベントを保存するには、ユーザーの同意が必要です。\n\n'
          '保存される内容には、プレイヤー軌跡、暴露ログ、イベント、プレイエリア、ギミック配置などが含まれます。',
      details: [
        _detail(
          title: '保存の注意',
          body:
              '単独逃走では鬼軌跡は記録されません。\n\n'
              '軌跡サンプルは一定間隔で記録され、簡略化される場合があります。',
        ),
      ],
    ),
  ],
  relatedSectionIds: ['win', 'second_game'],
);

final _specSection = GuideSectionData(
  id: 'spec',
  title: '詳細ルール',
  icon: Icons.table_chart_outlined,
  oneLine: '秒数・距離・クールダウンを確認したい人向けです。',
  cards: [
    _card(
      id: 'spec_outside',
      title: 'エリア外',
      icon: Icons.map_outlined,
      oneLine: 'エリア外の秒数・距離',
      body:
          '・境界から約25m以内: エリア外タイマーは進みにくい\n'
          '・エリア外約8秒: 警告段階を超える\n'
          '・初回暴露: ${GuideTerms.namedReveal}\n'
          '・再暴露: 約25秒ごと\n'
          '・脱落: 約90秒継続\n'
          '・鬼も同様に脱落対象',
    ),
    _card(
      id: 'spec_panic',
      title: GuideTerms.panic,
      icon: Icons.bubble_chart_outlined,
      oneLine: 'パニックの秒数',
      body:
          '・発動: 鬼の${GuideTerms.panic}圏に約6秒\n'
          '・持続: 約22秒\n'
          '・痕跡: 約7秒ごと\n'
          '・痕跡種別: ${GuideTerms.anonTrace}\n'
          '・脱落: しない\n'
          '・偽位置中: デコイ側に出ることがある',
    ),
    _card(
      id: 'spec_capture',
      title: '接触・拘束・捕獲',
      icon: Icons.front_hand_outlined,
      oneLine: '至近・拘束の目安',
      body:
          '・接触圏: エリア規模に連動\n'
          '・接触拘束: 鬼の近くに留まると発生\n'
          '・拘束円外猶予: 約10秒\n'
          '・直接捕獲GPS: 約12m\n'
          '・BLE接触: 強い接近情報として扱われる',
    ),
    _card(
      id: 'spec_zone',
      title: '捕獲結界',
      icon: Icons.trip_origin,
      oneLine: '結界の数値',
      body:
          '・半径: 約55m\n'
          '・持続: 約24秒\n'
          '・クールダウン: 約80秒\n'
          '・拘束円外猶予: 約10秒',
    ),
    _card(
      id: 'spec_info',
      title: '情報・痕跡',
      icon: Icons.radar_outlined,
      oneLine: '定期匿名・施設の数値',
      body:
          '・定期匿名痕跡: 試合時間の約4%\n'
          '・間隔: 約75〜180秒\n'
          '・45分試合の目安: 約108秒\n'
          '・監視カメラ半径: 約18m\n'
          '・監視カメラ再検知: 約90秒\n'
          '・情報屋半径: 約30m',
    ),
    _card(
      id: 'spec_accusation',
      title: '告発',
      icon: Icons.gavel_outlined,
      oneLine: '告発の数値',
      body:
          '・使用可能人数: 3人以上\n'
          '・解禁1: 試合時間60%経過\n'
          '・解禁2: 脱落1人以上 + 試合時間25%経過\n'
          '・早期解禁の範囲: 最短5分、最長15分\n'
          '・解禁時有効施設: 基本1\n'
          '・${GuideTerms.echoForm}陣取り: +1、試合2回まで\n'
          '・${GuideTerms.vengefulShadow}妨害: -1、試合3回まで\n'
          '・${GuideTerms.trueOni}が施設付近にいる間、その施設では告発不可',
    ),
    _card(
      id: 'spec_second',
      title: GuideTerms.secondGame,
      icon: Icons.replay_circle_filled_outlined,
      oneLine: '第二ゲームの数値',
      body:
          '${GuideTerms.echoForm}:\n'
          '・監視端子ジャック: チャージ約15秒、CD約100秒、試合5回まで\n'
          '・告発施設陣取り: チャージ約16秒、CD約90秒、試合2回まで\n\n'
          '${GuideTerms.vengefulShadow}:\n'
          '・告発施設妨害: チャージ約18秒、CD約90秒、試合3回まで\n'
          '・カメラ停止: チャージ約14秒、CD約25秒、各カメラ1回まで',
    ),
    _card(
      id: 'spec_skills',
      title: 'スキル',
      icon: Icons.bolt_outlined,
      oneLine: 'スキルの数値',
      body:
          '偽位置:\n・持続約20秒\n・CD約72秒\n\n'
          '偽情報暴露:\n・CD約75秒\n\n'
          '体投げ:\n・射程約90m\n・人形約12秒\n・CD約75秒\n・地図タップ猶予約22秒\n\n'
          '${GuideTerms.werewolf}の鬼化:\n・強制切替は試合時間に連動\n・目安は試合時間の3分の1、最大約10分',
    ),
  ],
  relatedSectionIds: ['outside', 'combat', 'accusation'],
);
