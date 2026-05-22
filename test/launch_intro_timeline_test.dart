import 'package:flutter_test/flutter_test.dart';
import 'package:oni_game/features/branding/launch_intro_timeline.dart';

void main() {
  test('logo hold is brief before title layout', () {
    expect(LaunchIntroTimeline.layoutT(0), 0);
    expect(LaunchIntroTimeline.layoutT(0.33), 0);
    expect(LaunchIntroTimeline.layoutT(0.5), greaterThan(0.3));
    expect(LaunchIntroTimeline.layoutT(1), closeTo(1, 0.001));
  });

  test('logo-only hold window is under 250ms', () {
    final holdMs = (LaunchIntroTimeline.logoHoldEnd - LaunchIntroTimeline.effectEnd) *
        LaunchIntroTimeline.totalMs;
    expect(holdMs, lessThan(250));
  });

  test('total intro is under 4 seconds', () {
    expect(LaunchIntroTimeline.totalMs, lessThan(4000));
  });

  test('logo reveals during effect phase', () {
    expect(LaunchIntroTimeline.logoReveal(0), 0);
    expect(LaunchIntroTimeline.logoReveal(0.27), closeTo(1, 0.001));
    expect(LaunchIntroTimeline.logoReveal(0.14), greaterThan(0.4));
  });

  test('brand text appears during effect animation', () {
    expect(LaunchIntroTimeline.brandTextOpacity(0.04), 0);
    expect(LaunchIntroTimeline.brandTextOpacity(0.1), greaterThan(0.35));
    expect(LaunchIntroTimeline.brandTextOpacity(0.14), 1);
    expect(LaunchIntroTimeline.effectOpacity(0.14), 1);
  });

  test('body fades in soon after layout handoff', () {
    expect(LaunchIntroTimeline.bodyOpacity(0.34), 0);
    expect(LaunchIntroTimeline.bodyOpacity(0.85), greaterThan(0.5));
  });

  test('visuals bundles values consistently', () {
    final v = LaunchIntroTimeline.visuals(0.5);
    expect(v.layoutT, LaunchIntroTimeline.layoutT(0.5));
    expect(v.logoReveal, LaunchIntroTimeline.logoReveal(0.5));
    expect(v.effectOpacity, LaunchIntroTimeline.effectOpacity(0.5));
  });
}
