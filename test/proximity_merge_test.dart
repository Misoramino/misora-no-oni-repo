import 'package:flutter_test/flutter_test.dart';
import 'package:oni_game/proximity/proximity_signal.dart';

void main() {
  test('mergeProximityBands picks more severe band', () {
    expect(
      mergeProximityBands(ProximityBand.none, ProximityBand.far),
      ProximityBand.far,
    );
    expect(
      mergeProximityBands(ProximityBand.near, ProximityBand.far),
      ProximityBand.near,
    );
    expect(
      mergeProximityBands(ProximityBand.near, ProximityBand.contact),
      ProximityBand.contact,
    );
  });
}
