import 'package:flutter_test/flutter_test.dart';
import 'package:oni_game/features/match/match_result_hints.dart';
import 'package:oni_game/progression/player_progress.dart';

void main() {
  group('MatchResultHints', () {
    test('first win shows multiplayer hint', () {
      const before = PlayerProgress(matches: 2, wins: 0);
      final hint = MatchResultHints.afterMatch(before: before, won: true);
      expect(hint, isNotNull);
      expect(hint!, contains('初勝利'));
      expect(hint, contains('ルームロビー'));
    });

    test('first match loss shows softer hint', () {
      const before = PlayerProgress();
      final hint = MatchResultHints.afterMatch(before: before, won: false);
      expect(hint, isNotNull);
      expect(hint!, contains('オンラインルーム'));
    });

    test('veteran gets no hint', () {
      const before = PlayerProgress(matches: 5, wins: 2);
      expect(
        MatchResultHints.afterMatch(before: before, won: true),
        isNull,
      );
    });
  });
}
