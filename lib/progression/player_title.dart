import 'player_progress.dart';

/// 戦績から解放される称号。実績兼コレクション要素。
class PlayerTitle {
  const PlayerTitle({
    required this.id,
    required this.label,
    required this.description,
    required this.icon,
    required this.test,
  });

  final String id;
  final String label;
  final String description;

  /// Material アイコンの codePoint（依存を持たないため int で保持）。
  final int icon;

  /// この称号が解放条件を満たしているか。
  final bool Function(PlayerProgress p) test;
}

/// 称号カタログ（達成順に概ね並ぶ）。
abstract final class PlayerTitles {
  static final List<PlayerTitle> all = [
    PlayerTitle(
      id: 'first_match',
      label: '初陣',
      description: '初めて試合を終えた',
      icon: 0xe5d5, // refresh
      test: (p) => p.matches >= 1,
    ),
    PlayerTitle(
      id: 'first_win',
      label: '初勝利',
      description: '初めて勝利した',
      icon: 0xea65, // emoji_events
      test: (p) => p.wins >= 1,
    ),
    PlayerTitle(
      id: 'streak3',
      label: '波に乗る者',
      description: '3 連勝を達成',
      icon: 0xe80e, // local_fire_department 近似
      test: (p) => p.bestStreak >= 3,
    ),
    PlayerTitle(
      id: 'streak5',
      label: '連勝街道',
      description: '5 連勝を達成',
      icon: 0xe80e,
      test: (p) => p.bestStreak >= 5,
    ),
    PlayerTitle(
      id: 'human5',
      label: '人類の砦',
      description: '人間陣営で 5 勝',
      icon: 0xe7ef, // groups
      test: (p) => p.winsHuman >= 5,
    ),
    PlayerTitle(
      id: 'oni5',
      label: '鬼の頭目',
      description: '鬼陣営で 5 勝',
      icon: 0xe9ba, // visibility 近似
      test: (p) => p.winsOni >= 5,
    ),
    PlayerTitle(
      id: 'win10',
      label: '常勝',
      description: '通算 10 勝',
      icon: 0xea65,
      test: (p) => p.wins >= 10,
    ),
    PlayerTitle(
      id: 'veteran',
      label: '歴戦',
      description: '通算 20 試合',
      icon: 0xe5d5,
      test: (p) => p.matches >= 20,
    ),
    PlayerTitle(
      id: 'win25',
      label: '伝説',
      description: '通算 25 勝',
      icon: 0xea65,
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
