/// Firestore `members.role` / レコーダ表示向けの役職ワイヤ文字列。
///
/// - ドメイン enum: [PlayerRole.hunter]
/// - wire 従来値: `'oni'`（既存ルーム互換）
/// - wire 現行値: `'hunter'` も受理
/// - UI: 「鬼」
abstract final class MemberRoleWire {
  static const oni = 'oni';
  static const hunter = 'hunter';
  static const runner = 'runner';
  static const werewolf = 'werewolf';
  static const spectator = 'spectator';

  /// 本鬼として扱う members.role か。
  static bool isOniRole(String? role) => role == oni || role == hunter;

  /// レコーダ／フィード用の短い日本語ラベル。
  /// 未知の role は逃走者扱い（旧 spectator レコーダ互換）。
  static String displayLabel(String? role) => switch (role) {
        oni || hunter => '鬼',
        werewolf => '人狼',
        spectator => '観戦',
        runner => '逃走者',
        _ => '逃走者',
      };
}
