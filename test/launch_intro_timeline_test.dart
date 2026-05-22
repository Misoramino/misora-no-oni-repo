import 'package:flutter_test/flutter_test.dart';
import 'package:oni_game/features/branding/launch_intro_timeline.dart';

void main() {
  test('logo hold keeps layout at title position', () {
    expect(LaunchIntroTimeline.layoutT(0), 0);
    expect(LaunchIntroTimeline.layoutT(0.5), 0);
    expect(LaunchIntroTimeline.layoutT(0.50), 0);
    expect(LaunchIntroTimeline.layoutT(1), closeTo(1, 0.001));
  });

  test('logo reveals during effect phase', () {
    expect(LaunchIntroTimeline.logoReveal(0), 0);
    expect(LaunchIntroTimeline.logoReveal(0.26), closeTo(1, 0.001));
    expect(LaunchIntroTimeline.logoReveal(0.13), greaterThan(0.4));
  });

  test('brand text appears during logo hold', () {
    expect(LaunchIntroTimeline.brandTextOpacity(0.15), 0);
    expect(LaunchIntroTimeline.brandTextOpacity(0.28), greaterThan(0.5));
    expect(LaunchIntroTimeline.brandTextOpacity(0.45), 1);
  });

  test('body fades in after handoff starts', () {
    expect(LaunchIntroTimeline.bodyOpacity(0.52), 0);
    expect(LaunchIntroTimeline.bodyOpacity(0.85), greaterThan(0.5));
  });

  test('visuals bundles values consistently', () {
    final v = LaunchIntroTimeline.visuals(0.5);
    expect(v.layoutT, LaunchIntroTimeline.layoutT(0.5));
    expect(v.logoReveal, LaunchIntroTimeline.logoReveal(0.5));
    expect(v.effectOpacity, LaunchIntroTimeline.effectOpacity(0.5));
  });

  test('total duration shortened', () {
    expect(LaunchIntroTimeline.totalMs, lessThan(5500));
  });
}
