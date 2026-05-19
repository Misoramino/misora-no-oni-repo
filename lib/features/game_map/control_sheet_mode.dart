/// ゲーム中の操作パネル表示モード。
enum ControlSheetMode { hidden, skillsOnly, expanded }

extension ControlSheetModeUi on ControlSheetMode {
  String get hint => switch (this) {
        ControlSheetMode.hidden => '非表示',
        ControlSheetMode.skillsOnly => 'スキル',
        ControlSheetMode.expanded => '詳細',
      };
}
