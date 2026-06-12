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
    this.guideSectionId,
  });

  final String text;
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
            body: '手がかりを読んで、鬼を当てるのが勝ち筋です。\nくわしくは「遊び方」を見てください。',
            relatedGuides: [
              (sectionId: 'info', title: '情報戦'),
              (sectionId: 'combat', title: '鬼との距離'),
              (sectionId: 'accusation', title: '告発'),
            ],
          ),
        PlayerRole.hunter => TutorialFinishCopy(
            title: '${GuideTerms.trueOni}チュートリアル完了',
            body: '追うのは痕跡と暴露です。現在地がずっと見えるわけではありません。',
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
                '告発の正解にもなりません。役職は「遊び方」を参照。',
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
            body: '脱落後も、端子ジャックと告発施設で人側を助けられます。',
            relatedGuides: secondGameRelatedGuides,
          ),
        SecondGameTutorialKind.vengefulShadow => TutorialFinishCopy(
            title: '${GuideTerms.vengefulShadow}チュートリアル完了',
            body: '脱落後も、告発とカメラを妨害して鬼側を助けられます。',
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
          '${GuideTerms.echoForm}になりました。\n'
          '脱落しても、まだ味方を助けられます。',
    ),
    SecondGameTutorialStepCopy(
      text:
          '監視端子をジャックしましょう。\n'
          '鬼の位置を味方に暴露できます。近づいてボタンを押します。',
      showTerminal: true,
      successFlash: '鬼の位置が味方に暴露されました。',
    ),
    SecondGameTutorialStepCopy(
      text:
          '告発施設の近くで陣取りしましょう。\n'
          '使える告発施設が増えます。',
      showAccusationFacility: true,
      showRevealedOni: true,
      successFlash: '有効な告発施設が増えました。',
    ),
  ];

  static const _vengefulShadowSteps = [
    SecondGameTutorialStepCopy(
      text:
          '${GuideTerms.vengefulShadow}になりました。\n'
          '脱落しても、まだ鬼側を助けられます。',
    ),
    SecondGameTutorialStepCopy(
      text:
          '告発施設を妨害しましょう。\n'
          '使える告発施設が減ります。',
      showAccusationFacility: true,
      successFlash: '有効な告発施設が減りました。',
    ),
    SecondGameTutorialStepCopy(
      text:
          '監視カメラを停止しましょう。\n'
          '残響体のジャックを妨げられます。',
      showCamera: true,
      successFlash: '監視カメラを停止しました。',
    ),
  ];

  static const _runnerSteps = [
    TutorialStepCopy(
      text:
          '相手の位置は基本見えません。\n'
          '地図の点は手がかりです。タップして少し動いてみましょう。',
      guideSectionId: 'info',
    ),
    TutorialStepCopy(
      text:
          'これは${GuideTerms.anonTrace}です。\n'
          '「誰かがいた」手がかり。誰かは分かりません。',
      showAnonMarker: true,
      guideSectionId: 'info',
    ),
    TutorialStepCopy(
      text:
          '鬼に近づきすぎると${GuideTerms.panic}です。\n'
          '脱落しませんが、痕跡が出やすくなります。離れてみましょう。',
      showOni: true,
      guideSectionId: 'combat',
    ),
    TutorialStepCopy(
      text:
          '${GuideTerms.panic}中は動くと痕跡が残りやすいです。\n'
          '鬼から距離を取りましょう。',
      showOni: true,
      guideSectionId: 'combat',
    ),
    TutorialStepCopy(
      text:
          '3人以上の試合では、後半に告発が使えます。\n'
          '生存中の逃走者だけが、${GuideTerms.realOni}を指名できます。',
      guideSectionId: 'accusation',
    ),
    TutorialStepCopy(
      text: '告発は告発施設で行います。解禁後、施設へ向かいましょう。',
      showAccusationMarker: true,
      guideSectionId: 'accusation',
    ),
  ];

  static const _hunterSteps = [
    TutorialStepCopy(
      text:
          '逃走者の位置は常に見えるわけではありません。\n'
          '痕跡と暴露から動きを読みます。',
      guideSectionId: 'info',
    ),
    TutorialStepCopy(
      text:
          '${GuideTerms.anonTrace}は「誰かがいた」手がかりです。\n'
          '複数つなげると方向が見えます。',
      showAnonMarker: true,
      guideSectionId: 'info',
    ),
    TutorialStepCopy(
      text:
          '${GuideTerms.namedReveal}は「○○がここにいた」と分かります。\n'
          '今もそこにいるとは限りません。',
      guideSectionId: 'info',
    ),
    TutorialStepCopy(
      text:
          '逃走者が${GuideTerms.panic}になると痕跡が出ます。\n'
          '追跡の大きな手がかりです。',
      showAnonMarker: true,
      guideSectionId: 'combat',
    ),
    TutorialStepCopy(
      text:
          '捕獲結界は地図を長押しで置きます。\n'
          '指を離して設置、右上の×でキャンセルです。',
      guideSectionId: 'skills',
    ),
    TutorialStepCopy(
      text: '至近まで追い詰めると捕獲です。青い印に近づいてみましょう。',
      showRunner: true,
      guideSectionId: 'combat',
    ),
  ];

  static const _werewolfSteps = [
    TutorialStepCopy(
      text:
          'あなたは${GuideTerms.werewolf}です。\n'
          '${GuideTerms.realOni}でも逃走者でもありません。',
      guideSectionId: 'roles',
    ),
    TutorialStepCopy(
      text: 'マップをタップして、少し動いてみましょう。',
    ),
    TutorialStepCopy(
      text:
          '「鬼化」で一時的に鬼のように追えます。\n'
          '下のボタンを押してみましょう。',
      guideSectionId: 'skills',
    ),
    TutorialStepCopy(
      text:
          '告発の正解は${GuideTerms.realOni}だけです。\n'
          '人狼は正解になりません。',
      guideSectionId: 'accusation',
    ),
    TutorialStepCopy(
      text: '告発できるのは生存中の逃走者だけです。',
      guideSectionId: 'accusation',
    ),
  ];
}
