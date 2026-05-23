import 'player_role.dart';
import 'skill_ids.dart';

/// 遊び方シート・設計ドキュメント用のスキル説明（一次ソースは [SkillIds] / [GameConfig]）。
abstract final class SkillCatalog {
  static const matchFlow =
      'タイトル → ルーム/エリア/ルール設定 → 開始 → 役職/スキル確認 → 試合（3分） → 結果 → 軌跡再生';

  static const coreRule =
      '通常は仲間のライブ位置は見えません。位置暴露・情報屋・マップギミック・スキルで情報が出ます。';

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
          '短時間（約14秒）、進行方向の少し先に「偽の自分位置」を出し、そこへゆっくり移動させます。'
          '感染などで名前付きの位置が露見するとき、本当のGPSではなく偽位置が出ます。'
          '相手の地図に「デコイ」とは表示しません。単体では露出が起きないと効果は限定的です。',
    ),
    SkillHelpEntry(
      id: SkillIds.captureZone,
      title: '捕獲結界（逃走者）',
      iconName: 'trip_origin',
      body:
          '地図タップで結界を設置。範囲内の相手（鬼など）をロックし、至近またはBLE接触で捕獲しやすくします。'
          '鬼側は追い込み・封鎖、逃走者側は足止め・逆転トラップとして使えます。再使用まで約80秒。',
    ),
  ];

  static const hunterSkills = [
    SkillHelpEntry(
      id: SkillIds.fakeIntelReveal,
      title: '偽情報暴露（鬼）',
      iconName: 'psychology_alt',
      body:
          '自分または逃走者の名前で、プレイエリア内の別地点に「本物っぽい」位置暴露を1回追加します。'
          'アリバイ・囮・「前にワープした」ように見せる誘導向け。再使用まで約75秒。',
    ),
    SkillHelpEntry(
      id: SkillIds.bodyThrow,
      title: '体投げ（鬼）',
      iconName: 'near_me',
      body:
          '地図上（現在地から約90m以内）に人形を置き、短時間そこを判定の中心にします。'
          '鬼に近づいて接触・捕獲しやすくするための「瞬間的な寄せ」です。未回収・期限切れで相手の位置が露見することもあります。',
    ),
    SkillHelpEntry(
      id: SkillIds.captureZone,
      title: '捕獲結界（鬼）',
      iconName: 'trip_origin',
      body:
          '地図タップで結界を設置。範囲内の逃走者をロックし、至近（GPS）またはBLE接触で捕獲しやすくします。'
          '範囲外に長く出ると相手側に脱落リスク。再使用まで約80秒。',
    ),
  ];

  static const werewolfSkills = [
    SkillHelpEntry(
      id: SkillIds.werewolfTransform,
      title: '鬼化（人狼）',
      iconName: 'nightlight',
      body:
          '短時間（約20秒）、鬼と同様の近接・捕獲判定に近づきます。再使用まで約90秒。'
          '2人戦などで「対抗役」になったときの撹乱用です。',
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
          '鬼の正確な座標ピンは出しません。',
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
          '小さな感知圏。通過すると通知のほか、名前なしの位置痕跡（理由: 監視カメラ）が残ります。',
    ),
    SkillHelpEntry(
      id: 'periodic_anon',
      title: '定期匿名痕跡',
      iconName: 'schedule',
      body:
          '約40秒ごとに、試合参加者（鬼・逃走者を含む）から1人が選ばれ、その位置に名前なしの痕跡が出ます。'
          '理由は通信混線・傍受・監視カメラなど共通プールから。情報の床として偽情報と区別しにくくします。',
    ),
    SkillHelpEntry(
      id: 'infection',
      title: '感染',
      iconName: 'bubble_chart',
      body:
          '鬼の至近に約6秒 → 約22秒の感染。約7秒ごとに名前付きの位置暴露。'
          '至近に入ったら感染前に警告が出ます。',
    ),
    SkillHelpEntry(
      id: 'capture',
      title: '接触・捕獲',
      iconName: 'front_hand',
      body:
          '鬼の接触圏に一定時間でロック。ロック中はGPS至近またはBLE接触で捕獲。'
          '片方だけBLEオフでもGPSで進行できます。',
    ),
    SkillHelpEntry(
      id: 'accusation_facility',
      title: '告発施設',
      iconName: 'account_balance',
      body:
          '3人以上の試合のみ。脱落1人 or 残り時間40%で解禁。逃走者が施設で鬼を告発。'
          '正解で逃走者即勝利。外すと告発者の位置が全体暴露・再告発不可。人狼は告発不可。',
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
