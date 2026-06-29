import 'package:flutter_test/flutter_test.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:oni_game/features/game_map/logic/gimmick_relocator.dart';

void main() {
  group('GimmickRelocator.snapCandidateToRoad', () {
    test('returns candidate when api key is empty', () async {
      const candidate = LatLng(35.0, 139.0);
      final snapped = await GimmickRelocator.snapCandidateToRoad(
        candidate: candidate,
        apiKey: '',
      );
      expect(snapped, candidate);
    });
  });
}
