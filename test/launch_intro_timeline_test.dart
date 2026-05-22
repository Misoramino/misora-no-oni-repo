import 'package:flutter_test/flutter_test.dart';
import 'package:oni_game/features/branding/launch_intro_timeline.dart';

void main() {
  test('logo hold keeps layout at title position', () {
    expect(LaunchIntroTimeline.layoutT(0), 0);
    expect(LaunchIntroTimeline.layoutT(0.48), 0);
    expect(LaunchIntroTimeline.layoutT(1), closeTo(1, 0.001));
  });

  test('logo reveals during effect phase', () {
    expect(LaunchIntroTimeline.logoReveal(0), 0);
    expect(LaunchIntroTimeline.logoReveal(0.32), closeTo(1, 0.001));
    expect(LaunchIntroTimeline.logoReveal(0.16), greaterThan(0.4));
  });

  test('brand text appears during effect animation', () {
    expect(LaunchIntroTimeline.brandTextOpacity(0.06), 0);
    expect(LaunchIntroTimeline.brandTextOpacity(0.14), greaterThan(0.35));
    expect(LaunchIntroTimeline.brandTextOpacity(0.22), 1);
    expect(
      LaunchIntroTimeline.brandTextOpacity(0.25),
      greaterThan(LaunchIntroTimeline.effectOpacity(0.25) > 0 ? 0.9 : 0),
    );
    expect(LaunchIntroTimeline.brandTextOpacity(0.25), 1);
    expect(LaunchIntroTimeline.effectOpacity(0.25), 1);
  });

  test('body fades in after handoff starts', () {
    expect(LaunchIntroTimeline.bodyOpacity(0.5), 0);
    expect(LaunchIntroTimeline.bodyOpacity(0.85), greaterThan(0.5));
  });

  test('visuals bundles values consistently', () {
    final v = LaunchIntroTimeline.visuals(0.5);
    expect(v.layoutT, LaunchIntroTimeline.layoutT(0.5));
    expect(v.logoReveal, LaunchIntroTimeline.logoReveal(0.5));
    expect(v.effectOpacity, LaunchIntroTimeline.effectOpacity(0.5));
  });
}
