import 'dart:convert';

/// 端末ローカルの累積戦績。称号アンロックの判定材料になる。
class PlayerProgress {
  const PlayerProgress({
    this.matches = 0,
    this.wins = 0,
    this.losses = 0,
    this.winsHuman = 0,
    this.winsOni = 0,
    this.currentStreak = 0,
    this.bestStreak = 0,
    this.unlockedTitleIds = const <String>{},
  });

  final int matches;
  final int wins;
  final int losses;
  final int winsHuman;
  final int winsOni;
  final int currentStreak;
  final int bestStreak;
  final Set<String> unlockedTitleIds;

  double get winRate => matches == 0 ? 0 : wins / matches;

  PlayerProgress copyWith({
    int? matches,
    int? wins,
    int? losses,
    int? winsHuman,
    int? winsOni,
    int? currentStreak,
    int? bestStreak,
    Set<String>? unlockedTitleIds,
  }) {
    return PlayerProgress(
      matches: matches ?? this.matches,
      wins: wins ?? this.wins,
      losses: losses ?? this.losses,
      winsHuman: winsHuman ?? this.winsHuman,
      winsOni: winsOni ?? this.winsOni,
      currentStreak: currentStreak ?? this.currentStreak,
      bestStreak: bestStreak ?? this.bestStreak,
      unlockedTitleIds: unlockedTitleIds ?? this.unlockedTitleIds,
    );
  }

  Map<String, dynamic> toJson() => {
        'matches': matches,
        'wins': wins,
        'losses': losses,
        'winsHuman': winsHuman,
        'winsOni': winsOni,
        'currentStreak': currentStreak,
        'bestStreak': bestStreak,
        'titles': unlockedTitleIds.toList(),
      };

  static PlayerProgress fromJson(Map<String, dynamic> json) {
    int asInt(Object? v) => (v as num?)?.toInt() ?? 0;
    return PlayerProgress(
      matches: asInt(json['matches']),
      wins: asInt(json['wins']),
      losses: asInt(json['losses']),
      winsHuman: asInt(json['winsHuman']),
      winsOni: asInt(json['winsOni']),
      currentStreak: asInt(json['currentStreak']),
      bestStreak: asInt(json['bestStreak']),
      unlockedTitleIds:
          ((json['titles'] as List?)?.cast<String>() ?? const <String>[])
              .toSet(),
    );
  }

  String encode() => jsonEncode(toJson());

  static PlayerProgress decode(String raw) {
    try {
      return fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      return const PlayerProgress();
    }
  }
}
