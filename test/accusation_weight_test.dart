import 'package:flutter_test/flutter_test.dart';
import 'package:oni_game/game/accusation_weight.dart';

void main() {
  test('instantWin eliminates on failure', () {
    expect(AccusationWeight.instantWin.eliminatesAccuserOnFailure, isTrue);
  });

  test('lighter weights use soft failure', () {
    expect(AccusationWeight.eliminateOni.eliminatesAccuserOnFailure, isFalse);
    expect(AccusationWeight.points.eliminatesAccuserOnFailure, isFalse);
  });

  test('fromName defaults to instantWin', () {
    expect(AccusationWeight.fromName(null), AccusationWeight.instantWin);
    expect(AccusationWeight.fromName('points'), AccusationWeight.points);
  });
}
