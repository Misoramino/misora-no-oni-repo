import 'package:flutter_test/flutter_test.dart';
import 'package:oni_game/game/match_duration_scaling.dart';

void main() {
  test('recommended 45 minute match has scaled accusation and trail', () {
    const d = MatchDurationScaling.recommendedMatchSeconds;
    final minElim = MatchDurationScaling.accusationUnlockMinElapsedSeconds(d);
    expect(minElim, greaterThanOrEqualTo(600));

    final trail = MatchDurationScaling.oniTrail(d);
    expect(trail.minAgeSeconds, lessThan(d ~/ 2));
    expect(trail.maxAgeSeconds, greaterThan(trail.minAgeSeconds));
    expect(trail.retainSeconds, greaterThanOrEqualTo(trail.maxAgeSeconds));
  });

  test('10 minute match still gets early start anchor window', () {
    expect(
      MatchDurationScaling.oniStartAnchorMaxElapsedSeconds(600),
      lessThanOrEqualTo(600),
    );
  });
}
