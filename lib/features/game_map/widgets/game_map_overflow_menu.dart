import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter/material.dart';

import '../../../game/game_state.dart';
import '../../../game/match_hud_copy.dart';

/// ゲーム画面 AppBar の「More」メニュー。
class GameMapOverflowMenu extends StatelessWidget {
  const GameMapOverflowMenu({
    super.key,
    this.menuKey,
    required this.gameState,
    required this.editingArea,
    required this.testMode,
    required this.onSelected,
  });

  /// コーチマーク用。PopupMenuButton 本体に付与する。
  final GlobalKey? menuKey;

  final GameState gameState;
  final bool editingArea;
  final bool testMode;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    final running = gameState == GameState.running;

    return PopupMenuButton<String>(
      key: menuKey,
      tooltip: 'その他',
      onSelected: onSelected,
      itemBuilder: (ctx) => [
        PopupMenuItem(
          value: 'settings',
          child: ListTile(
            leading: const Icon(Icons.settings_outlined),
            title: const Text('設定'),
            subtitle: Text(
              running
                  ? '個人・サウンド・データ・HUD'
                  : '個人・サウンド・データ',
            ),
            contentPadding: EdgeInsets.zero,
            dense: true,
          ),
        ),
        const PopupMenuItem(
          value: 'help',
          child: ListTile(
            leading: Icon(Icons.menu_book_outlined),
            title: Text('ガイド・遊び方'),
            contentPadding: EdgeInsets.zero,
            dense: true,
          ),
        ),
        if (!running)
          const PopupMenuItem(
            value: 'area_gallery',
            child: ListTile(
              leading: Icon(Icons.photo_library_outlined),
              title: Text('保存エリア一覧'),
              subtitle: Text('保存・ファイル読込'),
              contentPadding: EdgeInsets.zero,
              dense: true,
            ),
          ),
        if (!running)
          const PopupMenuItem(
            value: 'gallery',
            child: ListTile(
              leading: Icon(Icons.movie_filter_outlined),
              title: Text('試合ギャラリー'),
              contentPadding: EdgeInsets.zero,
              dense: true,
            ),
          ),
        if (running)
          const PopupMenuItem(
            value: 'role_briefing',
            child: ListTile(
              leading: Icon(Icons.badge_outlined),
              title: Text('役職を確認'),
              contentPadding: EdgeInsets.zero,
              dense: true,
            ),
          ),
        if (running)
          const PopupMenuItem(
            value: 'history',
            child: ListTile(
              leading: Icon(Icons.history),
              title: Text(MatchHudCopy.revealLogTitle),
              contentPadding: EdgeInsets.zero,
              dense: true,
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
        if (kDebugMode)
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
      ],
    );
  }
}
