import '../../game/elimination_aftermath_rule.dart';

/// 脱落後（第二ゲーム）チュートリアルの種別。
enum SecondGameTutorialKind {
  echoForm,
  vengefulShadow,
}

/// 脱落後ルールに対応するチュートリアル（残響体・復讐の鬼影のみ）。
SecondGameTutorialKind? secondGameTutorialKindForRule(
  EliminationAftermathRule rule,
) =>
    switch (rule) {
      EliminationAftermathRule.spectralOperative =>
        SecondGameTutorialKind.echoForm,
      EliminationAftermathRule.revenantOni =>
        SecondGameTutorialKind.vengefulShadow,
      _ => null,
    };