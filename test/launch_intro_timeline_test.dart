import 'package:flutter_test/flutter_test.dart';
import 'package:oni_game/features/branding/launch_intro_timeline.dart';

void main() {
  test('logo hold keeps layout at title position', () {
    expect(LaunchIntroTimeline.layoutT(0), 0);
    expect(LaunchIntroTimeline.layoutT(0.5), 0);
    expect(LaunchIntroTimeline.layoutT(0.58), 0);
    expect(LaunchIntroTimeline.layoutT(1), closeTo(1, 0.001));
  });

  test('brand text appears during logo hold', () {
    expect(LaunchIntroTimeline.brandTextOpacity(0.2), 0);
    expect(LaunchIntroTimeline.brandTextOpacity(0.42), greaterThan(0.5));
    expect(LaunchIntroTimeline.brandTextOpacity(0.55), 1);
  });

  test('body fades in after handoff starts', () {
    expect(LaunchIntroTimeline.bodyOpacity(0.55), 0);
    expect(LaunchIntroTimeline.bodyOpacity(0.9), greaterThan(0.5));
  });

  test('visuals bundles values consistently', () {
    final v = LaunchIntroTimeline.visuals(0.5);
    expect(v.layoutT, LaunchIntroTimeline.layoutT(0.5));
    expect(v.effectOpacity, LaunchIntroTimeline.effectOpacity(0.5));
  });
}
