import 'package:flutter_test/flutter_test.dart';
import 'package:oni_game/features/branding/launch_intro_timeline.dart';

void main() {
  test('logo-only hold is eliminated', () {
    expect(LaunchIntroTimeline.logoHoldEnd, LaunchIntroTimeline.effectEnd);
    final animMs = LaunchIntroTimeline.effectEnd * LaunchIntroTimeline.totalMs;
    expect(animMs, greaterThan(1200));
  });

  test('title layout begins when effect phase ends', () {
    expect(LaunchIntroTimeline.layoutT(0.38), 0);
    expect(LaunchIntroTimeline.layoutT(0.55), greaterThan(0.25));
    expect(LaunchIntroTimeline.layoutT(1), closeTo(1, 0.001));
  });

  test('logo reveals during effect phase', () {
    expect(LaunchIntroTimeline.logoReveal(0), 0);
    expect(LaunchIntroTimeline.logoReveal(0.38), closeTo(1, 0.001));
  });

  test('brand text appears during effect animation', () {
    expect(LaunchIntroTimeline.brandTextOpacity(0.05), 0);
    expect(LaunchIntroTimeline.brandTextOpacity(0.11), greaterThan(0.35));
    expect(LaunchIntroTimeline.brandTextOpacity(0.16), 1);
    expect(LaunchIntroTimeline.effectOpacity(0.16), 1);
  });

  test('body fades in soon after effect phase', () {
    expect(LaunchIntroTimeline.bodyOpacity(0.39), 0);
    expect(LaunchIntroTimeline.bodyOpacity(0.85), greaterThan(0.5));
  });

  test('visuals bundles values consistently', () {
    final v = LaunchIntroTimeline.visuals(0.5);
    expect(v.layoutT, LaunchIntroTimeline.layoutT(0.5));
    expect(v.logoReveal, LaunchIntroTimeline.logoReveal(0.5));
    expect(v.effectOpacity, LaunchIntroTimeline.effectOpacity(0.5));
  });
}
