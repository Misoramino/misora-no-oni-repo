import '../../game/player_role.dart';
import '../how_to_play/guide_terms.dart';
import 'second_game_tutorial_kind.dart';

/// チュートリアル1ステップ分の文案。
class TutorialStepCopy {
  const TutorialStepCopy({
    required this.text,
    this.showAnonMarker = false,
    this.showAccusationMarker = false,
    this.showOni = false,
    this.showRunner = false,
  });

  final String text;
  final bool showAnonMarker;
  final bool showAccusationMarker;
  final bool showOni;
  final bool showRunner;
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

  /// 作戦マニュアルの章 ID と表示名。
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

/// `05_Tutorial.md` ベースのチュートリアル文案。
abstract final class TutorialCopyCatalog {
  static TutorialFinishCopy finishFor(PlayerRole role) => switch (role) {
        PlayerRole.runner => const TutorialFinishCopy(
            title: '逃走者チュートリアル完了',
            body:
                '逃走者は、ただ逃げるだけではありません。\n'
                '痕跡を残しすぎず、情報を読み、${GuideTerms.trueOni}を見抜くことが大切です。',
            relatedGuides: [
              (sectionId: 'info', title: '情報戦'),
              (sectionId: 'combat', title: '鬼との戦い'),
              (sectionId: 'accusation', title: '告発'),
            ],
          ),
        PlayerRole.hunter => TutorialFinishCopy(
            title: '${GuideTerms.trueOni}チュートリアル完了',
            body:
                '${GuideTerms.trueOni}は、逃走者のライブ位置を追うのではなく、'
                '痕跡と暴露から動きを読む役職です。\n'
                '情報をつなげて、逃走者を追い詰めましょう。',
            relatedGuides: const [
              (sectionId: 'info', title: '情報戦'),
              (sectionId: 'combat', title: '鬼との戦い'),
              (sectionId: 'accusation', title: '告発'),
            ],
          ),
        PlayerRole.werewolf => TutorialFinishCopy(
            title: '${GuideTerms.werewolf}チュートリアル完了',
            body:
                '${GuideTerms.werewolf}は、${GuideTerms.trueOni}ではありません。\n'
                '鬼化で場を乱しながら、状況に応じて立ち回る特殊役職です。\n\n'
                '細かい立場の変化は、作戦マニュアルの「役職」を確認してください。',
            relatedGuides: const [
              (sectionId: 'roles', title: '役職'),
              (sectionId: 'skills', title: 'スキル'),
              (sectionId: 'accusation', title: '告発'),
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
                '${GuideTerms.echoForm}は、鬼の位置暴露と告発支援で${GuideTerms.humanFaction}を助けます。\n'
                '脱落後も勝敗に関われます。',
            relatedGuides: secondGameRelatedGuides,
          ),
        SecondGameTutorialKind.vengefulShadow => TutorialFinishCopy(
            title: '${GuideTerms.vengefulShadow}チュートリアル完了',
            body:
                '${GuideTerms.vengefulShadow}は、告発施設と監視カメラを妨害して${GuideTerms.oniFaction}を助けます。\n'
                '脱落後も試合の流れを変えられます。',
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
          'あなたは${GuideTerms.echoForm}になりました。\n\n'
          '脱落しても、まだ${GuideTerms.humanFaction}を助けられます。\n'
          '${GuideTerms.secondGame}で勝敗に貢献しましょう。',
    ),
    SecondGameTutorialStepCopy(
      text:
          '監視端子をジャックしましょう。\n\n'
          'ジャックすると、${GuideTerms.trueOni}の位置を味方に暴露できます。\n'
          '端子の近くへ移動し、下のボタンでチャージします。',
      showTerminal: true,
      successFlash: '鬼の位置が味方に暴露されました。',
    ),
    SecondGameTutorialStepCopy(
      text:
          '告発施設を陣取りましょう。\n\n'
          '陣取ると、有効な告発施設が増えます。\n'
          '${GuideTerms.humanFaction}の逆転を助けましょう。',
      showAccusationFacility: true,
      showRevealedOni: true,
      successFlash: '有効な告発施設が増えました。',
    ),
  ];

  static const _vengefulShadowSteps = [
    SecondGameTutorialStepCopy(
      text:
          'あなたは${GuideTerms.vengefulShadow}になりました。\n\n'
          '脱落しても、まだ${GuideTerms.oniFaction}を助けられます。\n'
          '${GuideTerms.secondGame}で勝敗に貢献しましょう。',
    ),
    SecondGameTutorialStepCopy(
      text:
          '告発施設を妨害しましょう。\n\n'
          '妨害すると、有効な告発施設が減ります。\n'
          '${GuideTerms.humanFaction}の告発を遅らせましょう。',
      showAccusationFacility: true,
      successFlash: '有効な告発施設が減りました。',
    ),
    SecondGameTutorialStepCopy(
      text:
          '監視カメラを停止しましょう。\n\n'
          '停止すると、${GuideTerms.echoForm}のジャックを妨害できます。',
      showCamera: true,
      successFlash: '監視カメラを停止しました。',
    ),
  ];

  static const _runnerSteps = [
    TutorialStepCopy(
      text:
          '相手のライブ位置は基本見えません。\n'
          '地図に出るのは、痕跡や暴露などの手がかりです。\n'
          'マップをタップして、少し動いてみましょう。',
    ),
    TutorialStepCopy(
      text:
          'これは${GuideTerms.anonTrace}です。\n'
          '誰の位置かは分かりませんが、「誰かがここにいた」手がかりになります。',
      showAnonMarker: true,
    ),
    TutorialStepCopy(
      text:
          '鬼に近づきすぎると、${GuideTerms.panic}になります。\n'
          '${GuideTerms.panic}は脱落ではありませんが、${GuideTerms.anonTrace}が出て追われやすくなります。\n'
          'タップで動いて、鬼から距離を取りましょう。',
      showOni: true,
    ),
    TutorialStepCopy(
      text:
          '${GuideTerms.panic}中は痕跡が残りやすいです。\n'
          '大きく動いて、鬼に読まれにくい位置へ逃げましょう。',
      showOni: true,
    ),
    TutorialStepCopy(
      text:
          '3人以上の試合では、後半に「告発」が使えるようになります。\n'
          '生存中の${GuideTerms.runner}だけが、${GuideTerms.trueOni}だと思う相手を指名できます。\n'
          '当てれば、${GuideTerms.humanFaction}の勝ちにつながります。',
    ),
    TutorialStepCopy(
      text:
          '告発は、地図上の告発施設で行います。\n'
          '解禁後は施設へ向かい、疑う相手を選びましょう。',
      showAccusationMarker: true,
    ),
  ];

  static const _hunterSteps = [
    TutorialStepCopy(
      text:
          '本番では、逃走者の現在地が常に見えるわけではありません。\n'
          '痕跡や暴露から、逃走者の動きを読みます。',
    ),
    TutorialStepCopy(
      text:
          '${GuideTerms.anonTrace}は、誰かがいた手がかりです。\n'
          '複数つなげると、逃げた方向が見えてきます。',
      showAnonMarker: true,
    ),
    TutorialStepCopy(
      text:
          '${GuideTerms.namedReveal}は強い情報です。\n'
          '「○○がここにいた」と分かりますが、今もそこにいるとは限りません。\n'
          '移動先を予測して追いましょう。',
    ),
    TutorialStepCopy(
      text:
          '逃走者が鬼の近くで${GuideTerms.panic}になると、${GuideTerms.anonTrace}が出ます。\n'
          'この痕跡は追跡の大きな手がかりになります。',
      showAnonMarker: true,
    ),
    TutorialStepCopy(
      text:
          '逃走者に近づき続けると拘束できます。\n'
          '至近距離まで追い詰めると捕獲です。\n'
          '青い印に近づいてみましょう。',
      showRunner: true,
    ),
  ];

  static const _werewolfSteps = [
    TutorialStepCopy(
      text:
          'あなたは${GuideTerms.werewolf}です。\n'
          '${GuideTerms.trueOni}でも${GuideTerms.runner}でもない、単独行動の特殊役職です。\n'
          '試合の進行で${GuideTerms.humanFaction}寄り・${GuideTerms.oniFaction}寄りに見えることがありますが、'
          '告発の対象はあくまで${GuideTerms.trueOni}です。',
    ),
    TutorialStepCopy(
      text: 'まずマップをタップして、少し動いてみましょう。',
    ),
    TutorialStepCopy(
      text:
          '「鬼化」は${GuideTerms.werewolf}専用のスキルです。\n'
          'ONの間だけ、鬼のように追跡・拘束ができます。\n'
          'ただし${GuideTerms.trueOni}そのものではなく、勝敗や告発の扱いも別です。\n'
          '下の「鬼化」ボタンを押してみましょう。',
    ),
    TutorialStepCopy(
      text:
          '${GuideTerms.humanFaction}が告発で当てるべきなのは${GuideTerms.trueOni}です。\n'
          '${GuideTerms.werewolf}は鬼のように見えることがありますが、告発の正解にはなりません。',
    ),
    TutorialStepCopy(
      text:
          '告発できるのは、生存中の${GuideTerms.runner}です。\n'
          '${GuideTerms.werewolf}は告発できません。',
    ),
  ];
}
