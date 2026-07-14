import 'package:flutter_test/flutter_test.dart';
import 'package:oni_game/game/accusation_outcome.dart';
import 'package:oni_game/game/accusation_weight.dart';

void main() {
  test('resolveAccusationOutcome maps success weights', () {
    expect(
      resolveAccusationOutcome(
        targetIsHunter: true,
        weight: AccusationWeight.instantWin,
      ),
      AccusationResolutionKind.successInstantWin,
    );
    expect(
      resolveAccusationOutcome(
        targetIsHunter: true,
        weight: AccusationWeight.eliminateOni,
      ),
      AccusationResolutionKind.successEliminateOni,
    );
    expect(
      resolveAccusationOutcome(
        targetIsHunter: true,
        weight: AccusationWeight.points,
      ),
      AccusationResolutionKind.successPoints,
    );
  });

  test('resolveAccusationOutcome failure when not hunter', () {
    for (final w in AccusationWeight.values) {
      expect(
        resolveAccusationOutcome(targetIsHunter: false, weight: w),
        AccusationResolutionKind.failure,
      );
    }
  });
}
