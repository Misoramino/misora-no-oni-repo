import 'package:flutter_test/flutter_test.dart';
import 'package:oni_game/features/branding/launch_intro_timeline.dart';

void main() {
  test('logo-only hold is eliminated', () {
    expect(LaunchIntroTimeline.logoHoldEnd, LaunchIntroTimeline.effectEnd);
    final animMs = LaunchIntroTimeline.effectEnd * LaunchIntroTimeline.totalMs;
    expect(animMs, greaterThan(3000));
  });

  test('title layout begins when effect phase ends', () {
    expect(LaunchIntroTimeline.layoutT(0.60), 0);
    expect(LaunchIntroTimeline.layoutT(0.75), greaterThan(0.25));
    expect(LaunchIntroTimeline.layoutT(1), closeTo(1, 0.001));
  });

  test('logo reveals during effect phase', () {
    expect(LaunchIntroTimeline.logoReveal(0), 0);
    expect(LaunchIntroTimeline.logoReveal(0.60), closeTo(1, 0.001));
  });

  test('brand text appears during effect animation', () {
    expect(LaunchIntroTimeline.brandTextOpacity(0.02), 0);
    expect(LaunchIntroTimeline.brandTextOpacity(0.08), greaterThan(0.35));
    expect(LaunchIntroTimeline.brandTextOpacity(0.12), 1);
    expect(LaunchIntroTimeline.effectOpacity(0.12), 1);
  });

  test('body fades in while effect still full', () {
    expect(LaunchIntroTimeline.bodyOpacity(0.10), 0);
    expect(LaunchIntroTimeline.bodyOpacity(0.22), greaterThan(0.2));
    expect(LaunchIntroTimeline.bodyOpacity(0.35), 1);
    expect(LaunchIntroTimeline.effectOpacity(0.35), 1);
  });

  test('no dark title veil', () {
    expect(LaunchIntroTimeline.titleVeil(0.5), 0);
    expect(LaunchIntroTimeline.titleVeil(0.9), 0);
  });

  test('effect stays bright until late intro', () {
    expect(LaunchIntroTimeline.effectOpacity(0.5), 1);
    expect(LaunchIntroTimeline.effectOpacity(0.75), greaterThan(0.85));
  });

  test('visuals bundles values consistently', () {
    final v = LaunchIntroTimeline.visuals(0.5);
    expect(v.layoutT, LaunchIntroTimeline.layoutT(0.5));
    expect(v.logoReveal, LaunchIntroTimeline.logoReveal(0.5));
    expect(v.effectOpacity, LaunchIntroTimeline.effectOpacity(0.5));
  });
}
