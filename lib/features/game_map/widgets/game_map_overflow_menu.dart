import 'package:flutter/material.dart';

import '../../../game/game_state.dart';

/// ゲーム画面 AppBar の「More」メニュー。
class GameMapOverflowMenu extends StatelessWidget {
  const GameMapOverflowMenu({
    super.key,
    required this.gameState,
    required this.editingArea,
    required this.testMode,
    required this.panelHidden,
    required this.prepControlSheetOpen,
    required this.onSelected,
  });

  final GameState gameState;
  final bool editingArea;
  final bool testMode;
  final bool panelHidden;
  final bool prepControlSheetOpen;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    final running = gameState == GameState.running;
    final ended =
        gameState == GameState.runnerWin || gameState == GameState.caughtByOni;

    return PopupMenuButton<String>(
      tooltip: 'More',
      onSelected: onSelected,
      itemBuilder: (ctx) => [
        const PopupMenuItem(
          value: 'help',
          child: ListTile(
            leading: Icon(Icons.help_outline),
            title: Text('How to play'),
            contentPadding: EdgeInsets.zero,
          ),
        ),
        const PopupMenuItem(
          value: 'oni',
          child: ListTile(
            leading: Icon(Icons.nightlight_round),
            title: Text('Oni settings'),
            contentPadding: EdgeInsets.zero,
          ),
        ),
        const PopupMenuItem(
          value: 'discord',
          child: ListTile(
            leading: Icon(Icons.chat_bubble_outline),
            title: Text('Discord用メモをコピー'),
            contentPadding: EdgeInsets.zero,
          ),
        ),
        const PopupMenuItem(
          value: 'gallery',
          child: ListTile(
            leading: Icon(Icons.movie_filter_outlined),
            title: Text('試合ギャラリー'),
            contentPadding: EdgeInsets.zero,
          ),
        ),
        const PopupMenuItem(
          value: 'history',
          child: ListTile(
            leading: Icon(Icons.history),
            title: Text('位置暴露ログ'),
            contentPadding: EdgeInsets.zero,
          ),
        ),
        if (running)
          const PopupMenuItem(
            value: 'abort_vote',
            child: ListTile(
              leading: Icon(Icons.how_to_vote_outlined),
              title: Text('試合中止の投票'),
              subtitle: Text('離脱・ホームへは同意後に'),
              contentPadding: EdgeInsets.zero,
            ),
          ),
        const PopupMenuItem(
          value: 'privacy',
          child: ListTile(
            leading: Icon(Icons.privacy_tip_outlined),
            title: Text('プライバシー管理'),
            contentPadding: EdgeInsets.zero,
          ),
        ),
        PopupMenuItem(
          value: 'test',
          child: ListTile(
            leading: Icon(
              testMode ? Icons.bug_report : Icons.bug_report_outlined,
            ),
            title: Text(testMode ? 'テストモードをOFF' : 'テストモードをON'),
            contentPadding: EdgeInsets.zero,
          ),
        ),
        if (ended)
          const PopupMenuItem(
            value: 'result',
            child: ListTile(
              leading: Icon(Icons.emoji_events_outlined),
              title: Text('リザルト画面'),
              contentPadding: EdgeInsets.zero,
            ),
          ),
        if (testMode && running) ...[
          const PopupMenuItem(
            value: 'dev_reset',
            child: ListTile(
              leading: Icon(Icons.stop_circle_outlined),
              title: Text('強制リセット（開発）'),
              contentPadding: EdgeInsets.zero,
            ),
          ),
          const PopupMenuItem(
            value: 'dev_oni_move',
            child: ListTile(
              leading: Icon(Icons.directions_run),
              title: Text('鬼移動（開発）'),
              contentPadding: EdgeInsets.zero,
            ),
          ),
        ],
        if (panelHidden || (!prepControlSheetOpen && !running))
          const PopupMenuItem(
            value: 'show_panel',
            child: ListTile(
              leading: Icon(Icons.expand_less),
              title: Text('操作パネルを表示'),
              contentPadding: EdgeInsets.zero,
            ),
          ),
        const PopupMenuDivider(),
        PopupMenuItem(
          value: 'import',
          enabled: gameState != GameState.running,
          child: const ListTile(
            leading: Icon(Icons.upload_file_outlined),
            title: Text('GeoJSON インポート'),
            contentPadding: EdgeInsets.zero,
          ),
        ),
        const PopupMenuItem(
          value: 'export',
          child: ListTile(
            leading: Icon(Icons.copy_outlined),
            title: Text('GeoJSON エクスポート'),
            contentPadding: EdgeInsets.zero,
          ),
        ),
      ],
    );
  }
}
