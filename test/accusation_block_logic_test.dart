import 'package:flutter_test/flutter_test.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:oni_game/game/accusation_block_logic.dart';

void main() {
  const facility = LatLng(35.0, 139.0);
  const hunterNear = LatLng(35.0002, 139.0002);
  const hunterFar = LatLng(35.01, 139.01);

  test('blocks when hunter within facility radius', () {
    expect(
      AccusationBlockLogic.isHunterBlockingSite(
        facilityPosition: facility,
        hunterPosition: hunterNear,
        hunterPositionKnown: true,
      ),
      isTrue,
    );
  });

  test('does not block when hunter far or unknown', () {
    expect(
      AccusationBlockLogic.isHunterBlockingSite(
        facilityPosition: facility,
        hunterPosition: hunterFar,
        hunterPositionKnown: true,
      ),
      isFalse,
    );
    expect(
      AccusationBlockLogic.isHunterBlockingSite(
        facilityPosition: facility,
        hunterPosition: null,
        hunterPositionKnown: false,
      ),
      isFalse,
    );
  });
}
