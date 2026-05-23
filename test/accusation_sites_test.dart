import 'package:flutter_test/flutter_test.dart';
import 'package:oni_game/game/accusation_sites.dart';
import 'package:oni_game/game/game_config.dart';

void main() {
  test('active site count scales with eliminations and time', () {
    const sites = 5;
    const duration = 600;

    expect(
      activeAccusationSiteCount(
        siteCount: sites,
        eliminationCount: 0,
        elapsedSeconds: 0,
        matchDurationSeconds: duration,
      ),
      1,
    );

    expect(
      activeAccusationSiteCount(
        siteCount: sites,
        eliminationCount: 1,
        elapsedSeconds: 100,
        matchDurationSeconds: duration,
      ),
      2,
    );

    expect(
      activeAccusationSiteCount(
        siteCount: sites,
        eliminationCount: 1,
        elapsedSeconds: 360,
        matchDurationSeconds: duration,
      ),
      3,
    );

    expect(
      activeAccusationSiteCount(
        siteCount: sites,
        eliminationCount: 2,
        elapsedSeconds: 360,
        matchDurationSeconds: duration,
      ),
      4,
    );

    expect(
      activeAccusationSiteCount(
        siteCount: sites,
        eliminationCount: 3,
        elapsedSeconds: duration,
        matchDurationSeconds: duration,
      ),
      4,
    );
  });

  test('pickActiveAccusationSiteIndices is deterministic', () {
    final a = pickActiveAccusationSiteIndices(
      gimmickSeed: 42,
      siteCount: 5,
      activeCount: 3,
    );
    final b = pickActiveAccusationSiteIndices(
      gimmickSeed: 42,
      siteCount: 5,
      activeCount: 3,
    );
    expect(a, b);
    expect(a.length, 3);
  });
}
