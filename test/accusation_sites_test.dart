import 'package:flutter_test/flutter_test.dart';
import 'package:oni_game/game/accusation_sites.dart';

void main() {
  test('active site count is 0 until unlock then 1', () {
    const sites = 5;

    expect(
      activeAccusationSiteCount(
        accusationUnlocked: false,
        siteCount: sites,
      ),
      0,
    );

    expect(
      activeAccusationSiteCount(
        accusationUnlocked: true,
        siteCount: sites,
      ),
      1,
    );

    expect(
      activeAccusationSiteCount(
        accusationUnlocked: true,
        siteCount: sites,
        territoryBonus: 2,
      ),
      3,
    );

    expect(
      activeAccusationSiteCount(
        accusationUnlocked: true,
        siteCount: 2,
        territoryBonus: 5,
      ),
      2,
    );
  });

  test('unlock publish must treatAsUnlocked for non-empty sites', () {
    // Mirrors _computeActiveAccusationIndices(treatAsUnlocked: true).
    expect(
      activeAccusationSiteCount(
        accusationUnlocked: false,
        siteCount: 4,
      ),
      0,
    );
    expect(
      pickActiveAccusationSiteIndices(
        gimmickSeed: 1,
        siteCount: 4,
        activeCount: activeAccusationSiteCount(
          accusationUnlocked: true,
          siteCount: 4,
        ),
      ),
      isNotEmpty,
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
