import 'player_role.dart';
import 'skill_ids.dart';

/// 遊び方シート・設計ドキュメント用のスキル説明（一次ソースは [SkillIds] / [GameConfig]）。
abstract final class SkillCatalog {
  static const matchFlow =
      'タイトル → ルーム参加 → 準備（時間・エリア・ルール）→ 試合開始 → 結果。'
      '推奨: 5〜6人・30〜60分・やや広めのエリア（第二ゲーム・告発・心理戦向け）。';

  static const mapSkillPlacementGuide =
      '捕獲結界・体投げなど「地図に置く」スキルは、ボタンを押したあと'
      '地図を押し続けて範囲を確認し、指を離して設置します。'
      '画面下の×へドラッグするとキャンセルできます。'
      '偽情報暴露など選択画面があるスキルは、キャンセルで取り消せます。';

  /// 遊び方シート・エリア編集の共通文案。
  static const playAreaGuide =
      'プレイエリアは準備で決める「試合の舞台」です。地図上の枠線の内側が有効範囲。'
      '外に出すぎると位置がバレやすくなり、HUD に「エリア外」と出ます。'
      'ホストはマップパネルから円・多角形で形を編集し、試合開始前に保存します。';

  static const coreRule =
      '通常は仲間のライブ位置は見えません。\n'
      '監視・情報屋・スキルなどで断片情報が出ます。\n'
      '個人の脱落と陣営の勝敗は別で、脱落後も第二ゲームに参加できます。';

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
          '約20秒間、進行方向の少し先に「偽の自分位置」を出し、デコイが進行方向へゆっくり移動します。'
          '発動中は名前付きの位置暴露（情報屋の副作用など）が出るとき、本当のGPSではなくデコイ座標に差し替わります。'
          '相手の地図に「デコイ」とは表示しません。露出が起きない間は効果は限定的です。',
    ),
    SkillHelpEntry(
      id: SkillIds.captureZone,
      title: '捕獲結界（逃走者）',
      iconName: 'trip_origin',
      body:
          '地図を押し続けて範囲（約55m）を確認し、指を離して設置。'
          '×へドラッグでキャンセル可。範囲内の相手をロックし、至近またはBLEで捕獲しやすくします。'
          '足止め・逆転トラップ向け。約24秒・再使用まで約80秒。',
    ),
  ];

  static const hunterSkills = [
    SkillHelpEntry(
      id: SkillIds.fakeIntelReveal,
      title: '偽情報暴露（鬼）',
      iconName: 'psychology_alt',
      body:
          '「自分を暴露」か「逃走者をランダム暴露」を選ぶ画面が開きます（キャンセル可）。'
          'どちらも匿名ではなく通常の位置露見として地図に出ます（相手からは偽とは分からない）。'
          '地点はプレイエリア内の別座標。アリバイ・囮・ワープ誘導向け。再使用まで約75秒。',
    ),
    SkillHelpEntry(
      id: SkillIds.bodyThrow,
      title: '体投げ（鬼）',
      iconName: 'near_me',
      body:
          '地図を押し続けて設置位置（現在地から約90m以内）を確認し、指を離して人形を置きます。'
          '×へドラッグでキャンセル可。短時間そこを捕獲判定の中心にします。'
          '逃走者から見た鬼の位置が人形へ移るので、離れた場所の相手も捕まえやすくなる「瞬間的な寄せ」です。'
          '未回収・期限切れで相手の位置が露見することもあります。',
    ),
    SkillHelpEntry(
      id: SkillIds.captureZone,
      title: '捕獲結界（鬼）',
      iconName: 'trip_origin',
      body:
          '地図を押し続けて範囲（約55m）を確認し、指を離して設置。'
          '×へドラッグでキャンセル可。範囲内の逃走者をロックし、至近またはBLEで捕獲しやすくします。'
          '約24秒。範囲外に10秒出ると相手に脱落リスク。再使用まで約80秒。',
    ),
  ];

  static const werewolfSkills = [
    SkillHelpEntry(
      id: SkillIds.werewolfTransform,
      title: '鬼化⇄人化（人狼）',
      iconName: 'nightlight',
      body:
          'ボタン表示は現在の姿に応じて「鬼化」「人化」に切り替わります。'
          '人の姿＝人ロール、鬼化中＝鬼ロール。陣営（人陣営/鬼陣営）は生存者の人数比で決まり、見た目とは別です。'
          '人陣営＋鬼化で捕獲可、鬼陣営＋鬼化はパニック・拘束のみ。'
          '自発切替CD=0.75×interval、強制切替CD=0.9×interval（interval=min(10分,試合時間÷3)）。'
          '強制は通知なしで鬼⇄人が交互に発火。告発不可。脱落時の陣営は固定。',
    ),
  ];

  static const gimmicks = [
    SkillHelpEntry(
      id: 'safe_zone',
      title: '安全地帯',
      iconName: 'shield',
      body:
          'ステルスチャージ（エリア外暴露を1回防ぐ）と、装備スキルの再使用待ち短縮。使用後は別の場所へ移動します。',
    ),
    SkillHelpEntry(
      id: 'info_broker',
      title: '情報屋（逃走者）',
      iconName: 'storefront',
      body:
          '鬼の方角・距離帯・断片テキストを1回取得。利用した地点に約10分の「手がかり」メモ（行き直し不要）。'
          '鬼の正確な座標ピンは出しません。'
          '同じ人が何度も使うとリスクが増えるため、個人の再使用まで約2分（鬼用90秒より長め）。',
    ),
    SkillHelpEntry(
      id: 'oni_info_broker',
      title: '情報屋（鬼）',
      iconName: 'storefront',
      body:
          '同じ情報屋マーカー。鬼が使うと逃走者1人がランダムに選ばれ、その端末から名前付きの位置暴露が1回入る（理由は共通プール）。'
          '再使用まで約90秒。オンライン試合のみ。常時GPS共有はしません。',
    ),
    SkillHelpEntry(
      id: 'camera',
      title: '監視カメラ',
      iconName: 'videocam',
      body:
          '小さな感知圏。通過のたびに通知と名前なしの位置痕跡（理由: 監視カメラ）。'
          '同一カメラは約90秒後に再検知できる（1台1回で止まらない）。',
    ),
    SkillHelpEntry(
      id: 'periodic_anon',
      title: '定期匿名痕跡',
      iconName: 'schedule',
      body:
          '試合時間に連動した間隔（おおよそ75〜180秒）で、参加者から1人が選ばれ、'
          'その位置に名前なしの痕跡が出ます。'
          '理由は通信混線・傍受・監視カメラなど共通プールから。情報の床として偽情報と区別しにくくします。',
    ),
    SkillHelpEntry(
      id: 'infection',
      title: 'パニック',
      iconName: 'bubble_chart',
      body:
          '鬼からの距離が「パニック圏」（プレイエリア連動・接触圏より外側になりやすい）に'
          '約6秒 → 約22秒のパニック状態。約7秒ごとに名前のない位置痕跡。脱落はしません。',
    ),
    SkillHelpEntry(
      id: 'capture',
      title: '接触・捕獲',
      iconName: 'front_hand',
      body:
          '鬼の接触圏（エリア連動）に約4秒留まると「接触拘束」。'
          '拘束円もエリア連動。持続は歩行で横断する想定時間。'
          '至近はGPS約12mまたはBLE接触。スキル結界とは別です。',
    ),
    SkillHelpEntry(
      id: 'accusation_facility',
      title: '告発施設',
      iconName: 'account_balance',
      body:
          '3人以上のみ。解禁前は有効0、解禁で有効1施設。'
          '残響体の陣取りで+1（試合2回まで）。復讐の鬼影の妨害で-1（試合3回）。'
          '脱落1人かつ試合時間の25%（最短5分・最長15分）経過、または試合60%経過で解禁。'
          '正解・失敗の重みはホストが試合前に選択（即勝利／鬼脱落継続／ポイント加算）。'
          '人狼は告発不可。'
          '生存中の本鬼が施設付近にいる間はその施設では告発不可（別施設は可）。',
    ),
    SkillHelpEntry(
      id: 'oni_delayed_trail',
      title: '鬼の遅延軌跡',
      iconName: 'timeline',
      body:
          '鬼の位置は常時共有されません。試合時間に応じた遅延のあと、過去の通過らしき線が薄く出ます。'
          '序盤は「試合開始付近」の手がかりピンが出ることもあります（遅延軌跡が育つ前の補助）。',
    ),
    SkillHelpEntry(
      id: 'trace_drop',
      title: '脱落地点の痕跡',
      iconName: 'place',
      body: '捕獲・告発失敗などで脱落した地点が、同じルームの全員の地図に共有されます。',
    ),
    SkillHelpEntry(
      id: 'runner_analyst',
      title: 'アナリスト（逃走者特化）',
      iconName: 'analytics',
      body:
          '匿名痕跡に時間帯・観測源・信頼度の読み取り補助。対象者の名前は出しません。',
    ),
    SkillHelpEntry(
      id: 'runner_hacker',
      title: 'ハッカー（逃走者特化）',
      iconName: 'terminal',
      body:
          '情報屋の距離帯が細かくなり、鬼の向いている方角（移動方向）が分かることがあります。'
          '鬼の座標ピンは出しません。',
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
