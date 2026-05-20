/// ゲーム中の操作パネル表示モード。
enum ControlSheetMode { hidden, skillsOnly, expanded }

extension ControlSheetModeUi on ControlSheetMode {
  /// 試合中の操作パネル用。
  String get hint => switch (this) {
        ControlSheetMode.hidden => '非表示',
        ControlSheetMode.skillsOnly => '詳細',
        ControlSheetMode.expanded => 'スキル',
      };

  /// 準備中（地図オンのみ）。カスタム設定と名前が被らないよう分ける。
  String get prepMapHint => switch (this) {
        ControlSheetMode.hidden => '非表示',
        ControlSheetMode.skillsOnly => '地図ツール',
        ControlSheetMode.expanded => 'スキル',
      };
}
