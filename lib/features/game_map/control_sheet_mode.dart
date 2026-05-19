/// ゲーム中の操作パネル表示モード。
enum ControlSheetMode { hidden, skillsOnly, expanded }

extension ControlSheetModeUi on ControlSheetMode {
  /// タップで切り替わる先のモード名（現在表示中ではない方）。
  String get hint => switch (this) {
        ControlSheetMode.hidden => '非表示',
        ControlSheetMode.skillsOnly => '詳細',
        ControlSheetMode.expanded => 'スキル',
      };
}
