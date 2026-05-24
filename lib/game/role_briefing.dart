import 'player_role.dart';

import 'werewolf_faction_logic.dart';



/// 役職ごとの詳細説明（遊び方シート用）。

class RoleBriefing {

  const RoleBriefing({

    required this.role,

    required this.headline,

    required this.factionLine,

    required this.goals,

    required this.actions,

    this.notes = const [],

  });



  final PlayerRole role;

  final String headline;

  final String factionLine;

  final List<String> goals;

  final List<String> actions;

  final List<String> notes;

}



/// 試合開始ポップアップ用の短い説明（役職理解・最低限だけ）。

class MatchStartBriefing {

  const MatchStartBriefing({

    required this.role,

    required this.tagline,

    required this.winLine,

    required this.mustKnow,

    this.learnMoreHint =

        'くわしいルールやスキルは、メニューの「遊び方」でいつでも確認できます。',

  });



  final PlayerRole role;

  final String tagline;

  final String winLine;

  final List<String> mustKnow;

  final String learnMoreHint;

}



abstract final class RoleBriefingCatalog {

  static RoleBriefing forRole(PlayerRole role) => switch (role) {

        PlayerRole.runner => _runner,

        PlayerRole.hunter => _hunter,

        PlayerRole.werewolf => _werewolf,

      };



  /// 試合開始直後のポップアップ（短く・やさしい言葉）。

  static MatchStartBriefing matchStartBriefing(

    PlayerRole role, {

    FactionSide? werewolfFaction,

  }) =>

      switch (role) {

        PlayerRole.runner => _runnerStart,

        PlayerRole.hunter => _hunterStart,

        PlayerRole.werewolf => _werewolfStart(werewolfFaction),

      };



  /// 試合開始直後の HUD ステータス行（役職ごと）。

  static String matchStartStatusLine(PlayerRole role) => switch (role) {

        PlayerRole.runner => 'ゲーム開始。鬼から逃げてください。',

        PlayerRole.hunter => 'ゲーム開始。逃走者を捕らえてください。',

        PlayerRole.werewolf => 'ゲーム開始。陣営に応じて姿を使い分けてください。',

      };



  static const _runnerStart = MatchStartBriefing(

    role: PlayerRole.runner,

    tagline: '鬼から逃げる側です。',

    winLine: '制限時間まで生き残れば、あなたたちの勝ちです。',

    mustKnow: [

      '鬼の居場所は、ずっと見え続けるわけではありません。',

      '近づきすぎ・長く寄ると捕まります。',

      '3人以上なら、告発施設で本鬼を当てれば一発勝ちもあります。',

    ],

  );



  static const _hunterStart = MatchStartBriefing(

    role: PlayerRole.hunter,

    tagline: '逃げる人を追い、捕まえる鬼です。',

    winLine: '逃走者を捕まえれば、鬼側の勝ちです。',

    mustKnow: [

      '相手のリアルタイム位置は見えません。',

      '近くに寄り続けると拘束し、至近で捕獲できます。',

      '告発施設の近くにいると、そこでの告発を防げます。',

    ],

  );



  static MatchStartBriefing _werewolfStart(FactionSide? faction) {
    return MatchStartBriefing(
      role: PlayerRole.werewolf,
      tagline: '見た目と味方がずれる、いびつな役です。',
      winLine: '自分以外の生存者で、人と鬼の少ない方の味方です。',
      mustKnow: [
        'スキルで「人の姿」と「鬼の姿」を切り替え。同数なら人陣営。',
        '人陣営＋鬼化は捕まえ可。鬼陣営＋鬼化は直接は殺せず、本鬼に追わせる。',
        faction == null
            ? 'いまの陣営は HUD で確認できます。'
            : 'いまの人数比では${faction.label}（HUD・脱落後は固定）。',
      ],
    );
  }



  static const _runner = RoleBriefing(

    role: PlayerRole.runner,

    headline: '逃走者 — 情報を読んで勝つ',

    factionLine: '所属: 人陣営（勝利判定は常に人側）',

    goals: [

      '制限時間まで生き残り、人陣営の勝利を目指す',

      '3人以上の試合では、告発施設で本鬼を当てれば即勝利',

    ],

    actions: [

      '鬼の位置は常時見えない。匿名痕跡・監視・パニック・情報屋の断片を読んで動く',

      '鬼の接触圏に長くいると拘束→捕獲。パニックは脱落しないが匿名痕跡が出やすい',

      'スキル（偽位置・捕獲結界など）で時間を稼ぎ、仲間と情報を共有する',

      '告発は解禁後のみ。失敗すると即脱落（残響体として第二ゲームへ）',

    ],

    notes: [

      '脱落後も試合は続く。残響体なら監視ジャックや告発施設の陣取りで仲間を支援できる',

    ],

  );



  static const _hunter = RoleBriefing(

    role: PlayerRole.hunter,

    headline: '鬼 — 断片を読んで追い詰める',

    factionLine: '所属: 鬼陣営（勝利判定は常に鬼側）',

    goals: [

      '逃走者を捕獲・脱落させ、鬼陣営の勝利を目指す',

      '告発されないよう、情報暴露のタイミングを読む',

    ],

    actions: [

      'ライブ位置は共有されない。遅延軌跡・序盤の手がかり・パニック痕跡・監視カメラで追う',

      '接触圏に留まると相手を拘束。至近距離またはBLE接触で捕獲',

      '偽情報・体投げ・捕獲結界で読みをずらし、複数方向から圧をかける',

      '生存中は告発施設付近にいると、その施設での告発を阻止できる',

    ],

    notes: [

      '鬼化中の人狼とはパニック・捕獲が起きない（鬼同士）',

      '脱落した場合、脱落時点の陣営に応じた第二ゲーム（既定では復讐の鬼影）へ',

    ],

  );



  static const _werewolf = RoleBriefing(

    role: PlayerRole.werewolf,

    headline: '人狼 — 姿と陣営を使い分ける',

    factionLine: '陣営は人数比で決まり、見た目の姿とは別（下記）',

    goals: [

      '自分の陣営（人陣営 or 鬼陣営）の勝利を目指す',

      '序盤と終盤で立場が変わるのが人狼の醍醐味',

    ],

    actions: [

      'スキルで鬼化⇄人化。ボタンは「鬼化」「人化」と現在の姿に応じて切替',

      '人の姿＝人ロール、鬼化中＝鬼ロール（周囲からそう見える）',

      '自分以外の生存者で、人と鬼の少ない方の陣営（同数なら人陣営）',

      '人陣営＋鬼化: 鬼と同様に接近・捕獲可 / 鬼陣営＋鬼化: パニック・拘束はあるが捕獲不可',

      'min(10分, 試合時間÷3) ごとに強制切替（通知なし）。自発切替の方がCDが短い',

      '告発は不可',

    ],

    notes: [

      '3人戦では人陣営になりやすく、鬼化で仲間を脅かす混沌役に',

      '5〜6人では鬼陣営になりやすく、鬼化しても直接殺せないため本鬼に追わせる攪乱が鍵',

      '6人以上の試合では人狼が2人いる。陣営は人数比で個別に決まる',

      '脱落時の陣営は固定（人陣営→残響体、鬼陣営→復讐の鬼影）。その後人数が変わっても変わらない',

    ],

  );



  static const winConditions = '''

【陣営勝利】

・人陣営: 時間切れ（逃走成功）または告発成功

・鬼陣営: 逃走者の捕獲・脱落が進み、人側が勝てない展開を作る



個人の脱落と陣営勝敗は別です。脱落しても第二ゲームで試合に関与できます。

''';

}


