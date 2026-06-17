import '../../game/player_role.dart';
import '../how_to_play/guide_terms.dart';
import 'second_game_tutorial_kind.dart';

/// チュートリアル1ステップでプレイヤーに求める操作。
enum TutorialStepInteraction {
  /// 「次へ」ボタンで進む（読むだけのステップ）。
  tapNext,

  /// アリーナをタップして移動。
  moveArena,

  /// 鬼から逃げる（移動しながら距離を取る）。
  fleeOni,

  /// 逃走者に近づいて捕獲圏へ。
  chaseRunner,

  /// スキルボタン1回（鬼化・偽位置など即時発動）。
  skillInstant,

  /// スキルボタン → 地図長押し → 離して設置（本番と同じ流れ）。
  skillMapPlace,
}

/// チュートリアル1ステップ分の文案。
class TutorialStepCopy {
  const TutorialStepCopy({
    required this.text,
    this.interaction = TutorialStepInteraction.tapNext,
    this.showAnonMarker = false,
    this.showAccusationMarker = false,
    this.showOni = false,
    this.showRunner = false,
    this.guideSectionId,
  });

  final String text;
  final TutorialStepInteraction interaction;
  final bool showAnonMarker;
  final bool showAccusationMarker;
  final bool showOni;
  final bool showRunner;

  /// 指定時、ステップ中に「遊び方」へジャンプできる。
  final String? guideSectionId;
}

/// チュートリアル完了画面の文案。
class TutorialFinishCopy {
  const TutorialFinishCopy({
    required this.title,
    required this.body,
    required this.relatedGuides,
  });

  final String title;
  final String body;

  /// 遊び方の章 ID と表示名。
  final List<({String sectionId, String title})> relatedGuides;
}

/// 脱落後チュートリアル1ステップ分の文案。
class SecondGameTutorialStepCopy {
  const SecondGameTutorialStepCopy({
    required this.text,
    this.showTerminal = false,
    this.showAccusationFacility = false,
    this.showCamera = false,
    this.showRevealedOni = false,
    this.successFlash,
  });

  final String text;
  final bool showTerminal;
  final bool showAccusationFacility;
  final bool showCamera;

  /// 監視端子ジャック成功後に鬼位置を見せる（残響体のみ）。
  final bool showRevealedOni;
  final String? successFlash;
}

/// チュートリアル文案（短く・実践中心）。
abstract final class TutorialCopyCatalog {
  static TutorialFinishCopy finishFor(PlayerRole role) => switch (role) {
        PlayerRole.runner => const TutorialFinishCopy(
            title: '逃走者チュートリアル完了',
            body: '生き残るか、手がかりから鬼を当てるか — どちらも勝ち筋です。\nくわしくは「遊び方」を見てください。',
            relatedGuides: [
              (sectionId: 'info', title: '情報戦'),
              (sectionId: 'combat', title: '鬼との距離'),
              (sectionId: 'accusation', title: '告発'),
            ],
          ),
        PlayerRole.hunter => TutorialFinishCopy(
            title: '${GuideTerms.trueOni}チュートリアル完了',
            body:
                '追うのは痕跡と暴露です。\n'
                '点は「いまここ」ではなく、動いた手がかりと読みましょう。',
            relatedGuides: const [
              (sectionId: 'info', title: '情報戦'),
              (sectionId: 'combat', title: '鬼との距離'),
              (sectionId: 'accusation', title: '告発'),
            ],
          ),
        PlayerRole.werewolf => TutorialFinishCopy(
            title: '${GuideTerms.werewolf}チュートリアル完了',
            body:
                '${GuideTerms.werewolf}は${GuideTerms.realOni}ではありません。\n'
                '人数で味方が決まり、試合の流れで前半鬼側・後半人側になりやすいです。\n'
                '見た目の切替や自動切替は「遊び方」の${GuideTerms.werewolf}を参照。',
            relatedGuides: const [
              (sectionId: 'roles', title: '役職'),
              (sectionId: 'skills', title: 'スキル'),
              (sectionId: 'online', title: 'オンライン'),
            ],
          ),
      };

  static String roleTutorialTitle(PlayerRole role) => switch (role) {
        PlayerRole.runner => GuideTerms.runner,
        PlayerRole.hunter => GuideTerms.trueOni,
        PlayerRole.werewolf => GuideTerms.werewolf,
      };

  static List<TutorialStepCopy> stepsFor(PlayerRole role) => switch (role) {
        PlayerRole.runner => _runnerSteps,
        PlayerRole.hunter => _hunterSteps,
        PlayerRole.werewolf => _werewolfSteps,
      };

  static const secondGameRelatedGuides = [
    (sectionId: 'second_game', title: GuideTerms.secondGame),
    (sectionId: 'accusation', title: '告発'),
    (sectionId: 'facilities', title: 'マップ施設'),
  ];

  static String secondGameTutorialTitle(SecondGameTutorialKind kind) =>
      switch (kind) {
        SecondGameTutorialKind.echoForm => GuideTerms.echoForm,
        SecondGameTutorialKind.vengefulShadow => GuideTerms.vengefulShadow,
      };

  static TutorialFinishCopy finishForSecondGame(SecondGameTutorialKind kind) =>
      switch (kind) {
        SecondGameTutorialKind.echoForm => TutorialFinishCopy(
            title: '${GuideTerms.echoForm}チュートリアル完了',
            body:
                '脱落後も観戦ではありません。\n'
                '端子ジャックと告発施設で、生き残っている味方を助けられます。',
            relatedGuides: secondGameRelatedGuides,
          ),
        SecondGameTutorialKind.vengefulShadow => TutorialFinishCopy(
            title: '${GuideTerms.vengefulShadow}チュートリアル完了',
            body:
                '脱落後も観戦ではありません。\n'
                '告発施設とカメラを妨害して、鬼側の味方を助けられます。',
            relatedGuides: secondGameRelatedGuides,
          ),
      };

  static List<SecondGameTutorialStepCopy> stepsForSecondGame(
    SecondGameTutorialKind kind,
  ) =>
      switch (kind) {
        SecondGameTutorialKind.echoForm => _echoFormSteps,
        SecondGameTutorialKind.vengefulShadow => _vengefulShadowSteps,
      };

  static const _echoFormSteps = [
    SecondGameTutorialStepCopy(
      text:
          '${GuideTerms.echoForm}になりました（人側・脱落後の姿）。\n'
          'まだ試合に関われます。味方を助けましょう。',
    ),
    SecondGameTutorialStepCopy(
      text:
          'マップの監視端子に近づきます。\n'
          'ボタンでジャックすると、鬼の位置を味方に教えられます。',
      showTerminal: true,
      successFlash: '鬼の位置が味方に暴露されました。',
    ),
    SecondGameTutorialStepCopy(
      text:
          '告発施設（旗マーク）のそばにとどまります。\n'
          '味方が使える告発施設が1つ増えます。',
      showAccusationFacility: true,
      showRevealedOni: true,
      successFlash: '有効な告発施設が増えました。',
    ),
  ];

  static const _vengefulShadowSteps = [
    SecondGameTutorialStepCopy(
      text:
          '${GuideTerms.vengefulShadow}になりました（鬼側・脱落後の姿）。\n'
          'まだ試合に関われます。鬼側を助けましょう。',
    ),
    SecondGameTutorialStepCopy(
      text:
          '告発施設（旗マーク）に近づきます。\n'
          'ボタンで妨害すると、味方が使える施設が減ります。',
      showAccusationFacility: true,
      successFlash: '有効な告発施設が減りました。',
    ),
    SecondGameTutorialStepCopy(
      text:
          '監視カメラに近づきます。\n'
          'ボタンで停止すると、残響体のジャックを妨げられます。',
      showCamera: true,
      successFlash: '監視カメラを停止しました。',
    ),
  ];

  static const _runnerSteps = [
    TutorialStepCopy(
      text:
          '相手の今いる場所は、地図には出ません。\n'
          'マーカーは「手がかり」です。タップして少し動きましょう。',
      interaction: TutorialStepInteraction.moveArena,
      guideSectionId: 'info',
    ),
    TutorialStepCopy(
      text:
          'マップの「?」が${GuideTerms.anonTrace}です。\n'
          '「誰かがここにいた」だけ分かり、誰かは不明です。',
      showAnonMarker: true,
      guideSectionId: 'info',
    ),
    TutorialStepCopy(
      text:
          '赤い鬼に近づきすぎると${GuideTerms.panic}です。\n'
          'すぐ脱落はしません。タップして距離を取りましょう。',
      interaction: TutorialStepInteraction.fleeOni,
      showOni: true,
      guideSectionId: 'combat',
    ),
    TutorialStepCopy(
      text:
          '「偽位置」で、他人に見える位置をずらせます。\n'
          '下のボタンを押して、もう一つの点を確認しましょう。',
      interaction: TutorialStepInteraction.skillInstant,
      guideSectionId: 'skills',
    ),
    TutorialStepCopy(
      text:
          '3人以上の試合では、後半に「告発」が解禁されます。\n'
          '生き残っている逃走者だけが、${GuideTerms.realOni}を指名できます。',
      guideSectionId: 'accusation',
    ),
    TutorialStepCopy(
      text:
          '告発は地図の告発施設で行います（旗マーク）。\n'
          '解禁されたら、施設へ向かいましょう。',
      showAccusationMarker: true,
      guideSectionId: 'accusation',
    ),
  ];

  static const _hunterSteps = [
    TutorialStepCopy(
      text:
          '逃走者の今いる場所は、地図には出ません。\n'
          'マップの痕跡と暴露から、動いた方向を読みます。',
      guideSectionId: 'info',
    ),
    TutorialStepCopy(
      text:
          '「?」の${GuideTerms.anonTrace}は「誰かがいた」手がかり。\n'
          '複数つなげると、逃げた方向が見えます。',
      showAnonMarker: true,
      guideSectionId: 'info',
    ),
    TutorialStepCopy(
      text:
          '${GuideTerms.namedReveal}は「○○がここにいた」と分かります。\n'
          '強い手がかりですが、今もそこにいるとは限りません。',
      guideSectionId: 'info',
    ),
    TutorialStepCopy(
      text:
          '逃走者が${GuideTerms.panic}になると、痕跡（?）が出やすくなります。\n'
          '追跡の大きな手がかりです。',
      showAnonMarker: true,
      guideSectionId: 'combat',
    ),
    TutorialStepCopy(
      text:
          '捕獲結界で、逃走者をその場に留められます。\n'
          '①下のボタンを押す\n'
          '②地図を長押し\n'
          '③離して設置',
      interaction: TutorialStepInteraction.skillMapPlace,
      guideSectionId: 'skills',
    ),
    TutorialStepCopy(
      text:
          '青い「逃」に十分近づくと捕獲です。\n'
          'タップして近づいてみましょう。',
      interaction: TutorialStepInteraction.chaseRunner,
      showRunner: true,
      guideSectionId: 'combat',
    ),
  ];

  static const _werewolfSteps = [
    TutorialStepCopy(
      text:
          'あなたは${GuideTerms.werewolf}（第三の役職）です。\n'
          '${GuideTerms.realOni}でも${GuideTerms.runner}でもありません。',
      guideSectionId: 'roles',
    ),
    TutorialStepCopy(
      text: 'マップをタップして、少し動いてみましょう。',
      interaction: TutorialStepInteraction.moveArena,
    ),
    TutorialStepCopy(
      text:
          '「鬼化」で見た目を鬼に近づけられます（ボタン1回）。\n'
          '地図に置くスキルとは別です。下のボタンを試しましょう。',
      interaction: TutorialStepInteraction.skillInstant,
      guideSectionId: 'skills',
    ),
    TutorialStepCopy(
      text:
          '告発で当てるのは${GuideTerms.realOni}だけです。\n'
          '${GuideTerms.werewolf}を選んでも正解にはなりません。',
      guideSectionId: 'accusation',
    ),
    TutorialStepCopy(
      text:
          'あなた（人狼）は告発できません。\n'
          '告発できるのは、生き残っている逃走者だけです。',
      guideSectionId: 'accusation',
    ),
  ];
}
