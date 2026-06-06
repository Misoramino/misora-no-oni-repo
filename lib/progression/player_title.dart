import 'package:flutter/material.dart';

import 'player_progress.dart';

/// 戦績から解放される称号。実績兼コレクション要素。
class PlayerTitle {
  const PlayerTitle({
    required this.id,
    required this.label,
    required this.description,
    required this.test,
  });

  final String id;
  final String label;
  final String description;

  /// この称号が解放条件を満たしているか。
  final bool Function(PlayerProgress p) test;

  /// release ビルドの icon font tree shake 用に const [Icons] のみ返す。
  IconData get iconData => switch (id) {
        'first_match' || 'veteran' => Icons.refresh_rounded,
        'first_win' || 'win10' || 'win25' => Icons.emoji_events_rounded,
        'streak3' || 'streak5' => Icons.local_fire_department_rounded,
        'human5' => Icons.groups_rounded,
        'oni5' => Icons.visibility_rounded,
        _ => Icons.help_outline_rounded,
      };
}

/// 称号カタログ（達成順に概ね並ぶ）。
abstract final class PlayerTitles {
  static final List<PlayerTitle> all = [
    PlayerTitle(
      id: 'first_match',
      label: '初陣',
      description: '初めて試合を終えた',
      test: (p) => p.matches >= 1,
    ),
    PlayerTitle(
      id: 'first_win',
      label: '初勝利',
      description: '初めて勝利した',
      test: (p) => p.wins >= 1,
    ),
    PlayerTitle(
      id: 'streak3',
      label: '波に乗る者',
      description: '3 連勝を達成',
      test: (p) => p.bestStreak >= 3,
    ),
    PlayerTitle(
      id: 'streak5',
      label: '連勝街道',
      description: '5 連勝を達成',
      test: (p) => p.bestStreak >= 5,
    ),
    PlayerTitle(
      id: 'human5',
      label: '人類の砦',
      description: '人間陣営で 5 勝',
      test: (p) => p.winsHuman >= 5,
    ),
    PlayerTitle(
      id: 'oni5',
      label: '鬼の頭目',
      description: '鬼陣営で 5 勝',
      test: (p) => p.winsOni >= 5,
    ),
    PlayerTitle(
      id: 'win10',
      label: '常勝',
      description: '通算 10 勝',
      test: (p) => p.wins >= 10,
    ),
    PlayerTitle(
      id: 'veteran',
      label: '歴戦',
      description: '通算 20 試合',
      test: (p) => p.matches >= 20,
    ),
    PlayerTitle(
      id: 'win25',
      label: '伝説',
      description: '通算 25 勝',
      test: (p) => p.wins >= 25,
    ),
  ];

  static Set<String> unlockedIds(PlayerProgress p) =>
      all.where((t) => t.test(p)).map((t) => t.id).toSet();

  static List<PlayerTitle> byIds(Iterable<String> ids) {
    final set = ids.toSet();
    return all.where((t) => set.contains(t.id)).toList();
  }
}
