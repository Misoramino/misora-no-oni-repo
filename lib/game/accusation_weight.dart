/// 告発が成功・失敗したときの試合への影響（ホストが試合開始前に固定）。
enum AccusationWeight {
  /// 正解で人陣営即勝利。失敗で告発者脱落（既定）。
  instantWin,

  /// 正解で本鬼を脱落させるが試合は継続。失敗は告発権消費のみ。
  eliminateOni,

  /// 正解で告発ポイント+1（終了時集計）。失敗は告発権消費のみ。
  points;

  static AccusationWeight fromName(String? raw) {
    for (final v in AccusationWeight.values) {
      if (v.name == raw) return v;
    }
    return AccusationWeight.instantWin;
  }

  String get label => switch (this) {
        AccusationWeight.instantWin => '即勝利（標準）',
        AccusationWeight.eliminateOni => '鬼を脱落（試合継続）',
        AccusationWeight.points => 'ポイント加算（終了時集計）',
      };

  String get helperText => switch (this) {
        AccusationWeight.instantWin =>
          '正解で人陣営の即勝利。外すと告発者が脱落（残響体）。',
        AccusationWeight.eliminateOni =>
          '正解で本鬼を脱落させるが、試合は時間まで継続。外すと告発権のみ消費。',
        AccusationWeight.points =>
          '正解のたびに人陣営ポイント+1。時間切れ勝敗は通常どおり。外すと告発権のみ消費。',
      };

  /// 失敗時に告発者を即脱落させるか。
  bool get eliminatesAccuserOnFailure =>
      this == AccusationWeight.instantWin;

  String get successOutcomeLabel => switch (this) {
        AccusationWeight.instantWin => '逃走者陣営の即勝利',
        AccusationWeight.eliminateOni => '本鬼を脱落（試合は継続）',
        AccusationWeight.points => '告発ポイント +1',
      };

  String get failureOutcomeLabel => switch (this) {
        AccusationWeight.instantWin => '即脱落（残響体として第二ゲームへ）',
        _ => '告発権を消費（この試合では再告発不可）',
      };
}
