import 'package:flutter_test/flutter_test.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:oni_game/game/game_config.dart';
import 'package:oni_game/game/match_quick_preset.dart';

void main() {
  test('preset labels and durations', () {
    expect(MatchQuickPreset.casual.label, 'お手軽');
    expect(MatchQuickPreset.standard.durationMinutes, 45);
    expect(MatchQuickPreset.intense.gimmickDensity, greaterThan(1.0));
  });

  test('fromName roundtrips enum names', () {
    for (final preset in MatchQuickPreset.values) {
      expect(MatchQuickPreset.fromName(preset.name), preset);
    }
    expect(MatchQuickPreset.fromName('unknown'), isNull);
  });

  test('playAreaFromCenter scales radius by preset', () {
    const center = LatLng(35.68, 139.76);
    final casual = MatchQuickPreset.casual.playAreaFromCenter(center);
    final standard = MatchQuickPreset.standard.playAreaFromCenter(center);
    final intense = MatchQuickPreset.intense.playAreaFromCenter(center);

    expect(casual.radiusMeters, lessThan(standard.radiusMeters));
    expect(intense.radiusMeters, greaterThan(standard.radiusMeters));
    expect(standard.radiusMeters, GameConfig.playAreaRadiusMeters);
  });
}
