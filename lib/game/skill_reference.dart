import '../features/how_to_play/guide_models.dart';
import '../features/how_to_play/guide_terms.dart';
import 'game_config.dart';
import 'match_ui_terms.dart';
import 'player_role.dart';
import 'skill_ids.dart';

/// 装備スキルの一次ソース（数値は [GameConfig]、文案はここ）。
///
/// 遊び方・チュートリアル・役職ダイアログ・HUD はこの定義に揃える。
abstract final class SkillReference {
  static List<SkillSpec> get all => [
        fakePosition,
        fakeIntelReveal,
        bodyThrow,
        captureZone,
        werewolfTransform,
      ];

  static SkillSpec? byId(String id) {
    for (final s in all) {
      if (s.id == id) return s;
    }
    return null;
  }

  static List<SkillSpec> forRole(PlayerRole role) => switch (role) {
        PlayerRole.runner => [fakePosition, captureZone],
        PlayerRole.hunter => [fakeIntelReveal, bodyThrow, captureZone],
        PlayerRole.werewolf => [werewolfTransform],
      };

  /// 詳細ルール章 `spec_skills` の表。
  static List<GuideSpecGroup> specSkillGroups() => [
        GuideSpecGroup(title: fakePosition.title, rows: fakePosition.specRows),
        GuideSpecGroup(title: fakeIntelReveal.title, rows: fakeIntelReveal.specRows),
        GuideSpecGroup(title: bodyThrow.title, rows: bodyThrow.specRows),
        GuideSpecGroup(title: captureZone.title, rows: captureZone.specRows),
        GuideSpecGroup(title: werewolfTransform.title, rows: werewolfTransform.specRows),
      ];

  static SkillSpec get fakePosition => SkillSpec(
        id: SkillIds.fakePosition,
        guideCardId: 'fake_position',
        title: '偽位置（逃走者）',
        shortTitle: '偽位置',
        iconName: 'scatter_plot',
        roles: const [PlayerRole.runner],
        trigger: SkillTrigger.instant,
        oneLine: '約20秒、すべての暴露がおとりの位置に出る。',
        summary:
            '進行方向の先（約${GameConfig.fakePositionSpawnOffsetMeters.toStringAsFixed(0)}m）に'
            'おとり（偽の自分）を出し、ゆっくり移動させます。',
        effect:
            '効果中の名前付き暴露・匿名暴露・定期暴露はすべておとりの近くに出ます。'
            '体投げの人形が稼働中は人形側が優先されます。',
        operation: 'ボタン1回で即発動（地図操作なし）。',
        whenToUse: '追われているとき、位置情報をずらしたいとき。',
        risks:
            '露出が起きない間は効果が限定的。相手の地図に「おとり」とは表示されません。'
            '発動と同時に再使用待ちが始まります。',
        specRows: [
          GuideSpecRow('持続', '約${GameConfig.fakeSkillDurationSeconds}秒'),
          GuideSpecRow('再使用', '発動から約${GameConfig.fakeSkillCooldownSeconds}秒'),
          GuideSpecRow(
            'おとり距離',
            '進行方向の先 約${GameConfig.fakePositionSpawnOffsetMeters.toStringAsFixed(0)}m',
          ),
          GuideSpecRow('暴露', '名前付き・匿名・定期すべておとり近傍'),
        ],
        guideDetails: const [
          (
            title: 'ずれる暴露',
            body:
                '名前付き（エリア外・パニック・結界離脱・カメラ等）\n'
                '匿名（パニック痕跡・監視カメラ・定期暴露）',
          ),
          (
            title: '体投げとの関係',
            body: '鬼の体投げ人形が稼働中は、暴露の基準は人形の位置が優先されます。',
          ),
        ],
      );

  static SkillSpec get fakeIntelReveal => SkillSpec(
        id: SkillIds.fakeIntelReveal,
        guideCardId: 'fake_intel',
        title: '偽情報暴露（鬼）',
        shortTitle: '偽情報暴露',
        iconName: 'psychology_alt',
        roles: const [PlayerRole.hunter],
        trigger: SkillTrigger.dialogThenMapPlace,
        oneLine: '本物そっくりの名前付き暴露を地図に置く。',
        summary:
            '「自分（鬼）」か「逃走者を1人ランダム」を選び、'
            '${MatchUiTerms.namedReveal}をプレイエリア内の任意地点に出します。',
        effect:
            '相手からは偽とは分かりません（理由タグは出ず「位置情報」表示）。'
            '${GuideTerms.anonTrace}ではありません。',
        operation:
            '①ボタン → ②自分／ランダムを選択 → ③地図を長押し→離して設置。'
            '選択画面・地図設置は×でキャンセル可（キャンセル時は再使用待ちなし）。',
        whenToUse: 'アリバイ・図・読みのずらしに。',
        risks:
            '配置を${GameConfig.fakeIntelMapTapWindowSeconds}秒以内に完了しないとキャンセル（再使用待ちなし）。'
            '成功後の再使用まで約${GameConfig.fakeIntelRevealCooldownSeconds}秒。',
        specRows: [
          GuideSpecRow('配置期限', '選択後 約${GameConfig.fakeIntelMapTapWindowSeconds}秒'),
          GuideSpecRow('再使用', '設置成功後 約${GameConfig.fakeIntelRevealCooldownSeconds}秒'),
          GuideSpecRow('地点', 'プレイエリア内・距離制限なし'),
          GuideSpecRow('表示', '${MatchUiTerms.namedReveal}（理由タグなし）'),
        ],
        guideDetails: const [
          (
            title: 'アナリストで見たとき',
            body:
                '通常の名前付き暴露と同じ見え方です。'
                'アナリスト特化の追加読み取りは匿名痕跡向けで、偽情報暴露には適用されません。',
          ),
        ],
      );

  static SkillSpec get bodyThrow => SkillSpec(
        id: SkillIds.bodyThrow,
        guideCardId: 'body_throw',
        title: '体投げ（鬼）',
        shortTitle: '体投げ',
        iconName: 'near_me',
        roles: const [PlayerRole.hunter],
        trigger: SkillTrigger.mapPlaceThenRecover,
        oneLine: '人形の位置を基準に捕獲・暴露が動く。',
        summary:
            '自分から約${GameConfig.bodyThrowDistanceMeters.toStringAsFixed(0)}m以内に人形を置き、'
            '回収するまで捕獲・暴露の判定中心を人形にずらします。',
        effect:
            '逃走者から見た鬼の位置も人形側に寄ります。'
            '人形稼働中は他のスキルが使えません。',
        operation:
            '①ボタン → ②地図を長押し→離して設置（×でキャンセル・時間制限なし）\n'
            '③人形から約${GameConfig.bodyThrowRecoveryDistanceMeters.toStringAsFixed(0)}m以内で「回収」ボタン',
        whenToUse: '自分の現在地を隠しつつ追跡・接触したいとき。',
        risks:
            '約${GameConfig.bodyThrowDurationSeconds}秒以内に回収しないと人形の位置が${MatchUiTerms.namedReveal}。'
            '暴露後も回収するまで人形は残ります。回収後の再使用まで約${GameConfig.bodyThrowCooldownSeconds}秒。',
        specRows: [
          GuideSpecRow('設置射程', '約${GameConfig.bodyThrowDistanceMeters.toStringAsFixed(0)}m'),
          GuideSpecRow('回収距離', '約${GameConfig.bodyThrowRecoveryDistanceMeters.toStringAsFixed(0)}m'),
          GuideSpecRow(
            '回収期限',
            '約${GameConfig.bodyThrowDurationSeconds}秒（過ぎると人形位置が名前付き暴露）',
          ),
          GuideSpecRow('再使用', '回収後 約${GameConfig.bodyThrowCooldownSeconds}秒'),
          GuideSpecRow('他スキル', '人形稼働中・設置待ち中は不可'),
        ],
        guideDetails: [
          (
            title: '回収ボタン',
            body:
                '人形稼働中はボタンが「回収」に変わります。'
                '約${GameConfig.bodyThrowRecoveryDistanceMeters.toStringAsFixed(0)}m以内に入ると押せる状態になります。',
          ),
        ],
      );

  static SkillSpec get captureZone => SkillSpec(
        id: SkillIds.captureZone,
        guideCardId: 'capture_zone_skill',
        title: '捕獲結界',
        shortTitle: '捕獲結界',
        iconName: 'trip_origin',
        roles: const [
          PlayerRole.runner,
          PlayerRole.hunter,
        ],
        trigger: SkillTrigger.mapPlace,
        oneLine: '範囲内の全員を拘束。効果中のみ離脱リスク。',
        summary:
            '現在地から約${GameConfig.bodyThrowDistanceMeters.toStringAsFixed(0)}m以内に、'
            '半径約${GameConfig.captureZoneSkillRadiusMeters.toStringAsFixed(0)}mの拘束エリアを置きます。',
        effect:
            '発動時に範囲内にいた全員（自分・味方・敵）の画面に結界が表示され、拘束されます。'
            '効果中に円の外へ出ると名前付き暴露。猶予後、捕獲可能な結界なら脱落のリスクがあります。'
            '約${GameConfig.captureZoneDurationSeconds}秒で結界は消え、拘束も解除されます（終了後にその場所を離れても暴露されません）。',
        operation:
            '①ボタン → ②地図を長押し→離して設置（×でキャンセル・時間制限なし）。',
        whenToUse: '通路を塞ぐ、複数方向から圧をかける、逆転のトラップに。',
        risks:
            '効果中の円外離脱で名前付き暴露。捕獲可能な結界では猶予${GameConfig.bindZoneEscapeGraceSeconds}秒後に脱落。'
            '再使用まで約${GameConfig.captureZoneCooldownSeconds}秒。',
        specRows: [
          GuideSpecRow('設置射程', '約${GameConfig.bodyThrowDistanceMeters.toStringAsFixed(0)}m'),
          GuideSpecRow('半径', '約${GameConfig.captureZoneSkillRadiusMeters.toStringAsFixed(0)}m'),
          GuideSpecRow('持続', '約${GameConfig.captureZoneDurationSeconds}秒'),
          GuideSpecRow('再使用', '設置から約${GameConfig.captureZoneCooldownSeconds}秒'),
          GuideSpecRow('離脱時', '効果中のみ名前付き暴露'),
          GuideSpecRow('終了後', '結界消滅・拘束解除。旧位置から離れても暴露なし'),
          GuideSpecRow('円外猶予', '約${GameConfig.bindZoneEscapeGraceSeconds}秒'),
        ],
        guideDetails: [
          (
            title: '人狼が置いた場合',
            body:
                '人狼は通常、捕獲結界を装備しません。'
                'カスタム等で持っている場合、鬼陣営＋鬼化中は捕獲不可（拘束・${GuideTerms.panic}のみ）。'
                '逃走者・鬼・人陣営人狼の結界は捕獲可能です。',
          ),
          (
            title: '接触拘束との違い',
            body:
                '鬼の至近接触による拘束（接触圏）とは別物です。'
                'スキル結界は地図に置く円で、持続は約${GameConfig.captureZoneDurationSeconds}秒です。',
          ),
        ],
      );

  static SkillSpec get werewolfTransform => SkillSpec(
        id: SkillIds.werewolfTransform,
        guideCardId: 'werewolf_transform',
        title: '鬼化・人化（人狼）',
        shortTitle: '鬼化・人化',
        iconName: 'nightlight',
        roles: const [PlayerRole.werewolf],
        trigger: SkillTrigger.instant,
        oneLine: '姿を切り替えて陣営に応じた追跡・拘束。',
        summary:
            '「人の姿」と「鬼化中の姿」をボタンで切り替えます（表示は「鬼化」「人化」）。'
            '${GuideTerms.werewolf}は${GuideTerms.trueOni}ではなく、告発の正解にもなりません。',
        effect:
            '鬼化中は鬼のように追跡・拘束できます。'
            '人陣営＋鬼化は捕獲可、鬼陣営＋鬼化は${GuideTerms.panic}・拘束のみ（捕獲結界も攪乱タイプ）。',
        operation: 'ボタン1回で即切替。長く放置すると強制で反対の姿に（通知なし）。',
        whenToUse:
            '陣営（${GuideTerms.humanFaction}/${GuideTerms.oniFaction}）に応じて立ち回るとき。'
            '人数比で陣営が決まり、同数なら${GuideTerms.humanFaction}。',
        risks:
            '任意切替の再使用待ち＝強制間隔÷3（HUDの「切替」）。'
            '強制切替の直後は「切替」がやや長くなります。'
            '「自動切替」と「切替」は別タイマーです。告発不可。',
        specRows: const [
          GuideSpecRow('自動切替まで', '前回切替から min(15分, 試合÷2)'),
          GuideSpecRow('任意切替の再使用', '強制間隔÷3'),
          GuideSpecRow('強制直後の再使用', '任意の再使用 + その半分'),
          GuideSpecRow('人陣営＋鬼化', '捕獲可'),
          GuideSpecRow('鬼陣営＋鬼化', '${GuideTerms.panic}・拘束のみ'),
        ],
        guideDetails: const [
          (
            title: 'HUDの見方',
            body:
                '「自動切替」＝放置すると自動で反対の姿になるまでの秒数。'
                '「切替」＝ボタンで任意に切り替えられるまでの秒数。別表示です。',
          ),
          (
            title: '強制切替',
            body:
                '前回の切替から一定時間、任意に切り替えないと反対の姿になります（プッシュ通知なし）。'
                '任意に切り替えた場合もタイマーはリセットされます。',
          ),
        ],
      );
}

enum SkillTrigger {
  instant,
  mapPlace,
  dialogThenMapPlace,
  mapPlaceThenRecover,
}

/// 装備スキル1件分の仕様と文案。
final class SkillSpec {
  const SkillSpec({
    required this.id,
    required this.guideCardId,
    required this.title,
    required this.shortTitle,
    required this.iconName,
    required this.roles,
    required this.trigger,
    required this.oneLine,
    required this.summary,
    required this.effect,
    required this.operation,
    required this.whenToUse,
    required this.risks,
    required this.specRows,
    this.guideDetails = const [],
  });

  final String id;
  final String guideCardId;
  final String title;
  final String shortTitle;
  final String iconName;
  final List<PlayerRole> roles;
  final SkillTrigger trigger;
  final String oneLine;
  final String summary;
  final String effect;
  final String operation;
  final String whenToUse;
  final String risks;
  final List<GuideSpecRow> specRows;
  final List<({String title, String body})> guideDetails;

  /// 遊び方シート・役職ダイアログ用（【】形式）。
  String get catalogBody =>
      '【できること】$summary$effect\n'
      '【操作】$operation\n'
      '【いつ使う】$whenToUse\n'
      '【リスク】$risks';

  /// 遊び方カード本文（章内カード）。
  String get guideBody => '$summary$effect';

  SkillHelpEntry toHelpEntry() => SkillHelpEntry(
        id: id,
        title: title,
        iconName: iconName,
        body: catalogBody,
      );
}

/// [SkillCatalog] 互換のエントリ型（skill_reference から生成）。
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
