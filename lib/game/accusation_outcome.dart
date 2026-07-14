import 'accusation_weight.dart';

/// 告発解決の分岐結果（画面はこれだけ見て publish / UI 副作用を選ぶ）。
enum AccusationResolutionKind {
  /// 正解 → 人陣営即勝利。
  successInstantWin,

  /// 正解 → 本鬼脱落（試合継続）。
  successEliminateOni,

  /// 正解 → 告発ポイント +1。
  successPoints,

  /// 不正解 → 失敗処理（脱落または権消費は [AccusationWeight]）。
  failure,
}

/// 告発の正解／不正解と重みから、副作用の種類だけを決める。
AccusationResolutionKind resolveAccusationOutcome({
  required bool targetIsHunter,
  required AccusationWeight weight,
}) {
  if (!targetIsHunter) return AccusationResolutionKind.failure;
  return switch (weight) {
    AccusationWeight.instantWin => AccusationResolutionKind.successInstantWin,
    AccusationWeight.eliminateOni => AccusationResolutionKind.successEliminateOni,
    AccusationWeight.points => AccusationResolutionKind.successPoints,
  };
}
