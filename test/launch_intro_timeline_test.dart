import 'package:flutter_test/flutter_test.dart';
import 'package:oni_game/features/branding/launch_intro_timeline.dart';

void main() {
  test('logo-only hold is eliminated', () {
    expect(LaunchIntroTimeline.logoHoldEnd, LaunchIntroTimeline.effectEnd);
    final animMs = LaunchIntroTimeline.effectEnd * LaunchIntroTimeline.totalMs;
    expect(animMs, greaterThan(1400));
  });

  test('title layout begins when effect phase ends', () {
    expect(LaunchIntroTimeline.layoutT(0.52), 0);
    expect(LaunchIntroTimeline.layoutT(0.75), greaterThan(0.2));
    expect(LaunchIntroTimeline.layoutT(1), closeTo(1, 0.001));
  });

  test('logo reveals during effect phase', () {
    expect(LaunchIntroTimeline.logoReveal(0), 0);
    expect(LaunchIntroTimeline.logoReveal(0.52), closeTo(1, 0.001));
  });

  test('brand text appears during effect animation', () {
    expect(LaunchIntroTimeline.brandTextOpacity(0.01), 0);
    expect(LaunchIntroTimeline.brandTextOpacity(0.06), greaterThan(0.35));
    expect(LaunchIntroTimeline.effectOpacity(0.06), 1);
  });

  test('body fades in early while effect still full', () {
    expect(LaunchIntroTimeline.bodyOpacity(0.06), 0);
    expect(LaunchIntroTimeline.bodyOpacity(0.12), greaterThan(0.2));
    expect(LaunchIntroTimeline.bodyOpacity(0.20), 1);
    expect(LaunchIntroTimeline.effectOpacity(0.20), 1);
  });

  test('tagline slides up after brand', () {
    expect(LaunchIntroTimeline.taglineOpacity(0.18), 0);
    expect(LaunchIntroTimeline.taglineLayoutT(0.18), 0);
    expect(LaunchIntroTimeline.taglineOpacity(0.35), 1);
    expect(LaunchIntroTimeline.taglineLayoutT(0.35), 1);
  });

  test('no dark title veil', () {
    expect(LaunchIntroTimeline.titleVeil(0.9), 0);
  });

  test('visuals bundles values consistently', () {
    final v = LaunchIntroTimeline.visuals(0.5);
    expect(v.layoutT, LaunchIntroTimeline.layoutT(0.5));
    expect(v.taglineLayoutT, LaunchIntroTimeline.taglineLayoutT(0.5));
  });
}
