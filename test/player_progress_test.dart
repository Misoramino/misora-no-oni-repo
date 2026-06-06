import 'package:flutter_test/flutter_test.dart';
import 'package:oni_game/progression/player_progress.dart';
import 'package:oni_game/progression/player_title.dart';

void main() {
  test('PlayerProgress encode/decode roundtrip', () {
    const p = PlayerProgress(
      matches: 12,
      wins: 7,
      losses: 5,
      winsHuman: 4,
      winsOni: 3,
      currentStreak: 2,
      bestStreak: 5,
      unlockedTitleIds: {'first_win', 'streak3'},
    );
    final decoded = PlayerProgress.decode(p.encode());
    expect(decoded.matches, 12);
    expect(decoded.wins, 7);
    expect(decoded.winsHuman, 4);
    expect(decoded.bestStreak, 5);
    expect(decoded.unlockedTitleIds, {'first_win', 'streak3'});
  });

  test('decode tolerates malformed input', () {
    expect(PlayerProgress.decode('not json').matches, 0);
  });

  test('winRate is zero with no matches', () {
    expect(const PlayerProgress().winRate, 0);
  });

  test('titles unlock by thresholds', () {
    const fresh = PlayerProgress();
    expect(PlayerTitles.unlockedIds(fresh), isEmpty);

    const oneWin = PlayerProgress(matches: 1, wins: 1, bestStreak: 1);
    final ids = PlayerTitles.unlockedIds(oneWin);
    expect(ids, contains('first_match'));
    expect(ids, contains('first_win'));
    expect(ids, isNot(contains('streak3')));

    const streaky = PlayerProgress(matches: 3, wins: 3, bestStreak: 3);
    expect(PlayerTitles.unlockedIds(streaky), contains('streak3'));
  });

  test('byIds returns matching titles only', () {
    final titles = PlayerTitles.byIds(['first_win', 'nonexistent']);
    expect(titles, hasLength(1));
    expect(titles.first.id, 'first_win');
  });
}
