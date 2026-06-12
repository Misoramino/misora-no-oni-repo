import 'package:flutter_test/flutter_test.dart';
import 'package:oni_game/game/accusation_intro_copy.dart';
import 'package:oni_game/game/accusation_weight.dart';

void main() {
  group('AccusationIntroCopy', () {
    test('includes action label and weight helper', () {
      final body = AccusationIntroCopy.body(
        accuseActionLabel: '告発する',
        weight: AccusationWeight.points,
      );
      expect(body, contains('告発する'));
      expect(body, contains(AccusationWeight.points.helperText));
      expect(body, contains('鬼'));
      expect(body, contains('本物の鬼'));
    });

    test('instant win explains elimination on failure', () {
      final body = AccusationIntroCopy.body(
        accuseActionLabel: '告発',
        weight: AccusationWeight.instantWin,
      );
      expect(body, contains('即勝利'));
    });
  });
}
