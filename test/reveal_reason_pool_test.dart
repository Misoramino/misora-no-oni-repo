import 'package:flutter_test/flutter_test.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:oni_game/features/game_map/logic/reveal_reason_pool.dart';

void main() {
  test('cameraPick returns surveillance summary', () {
    expect(RevealReasonPool.cameraPick().summary, '監視カメラ');
  });

  test('pick near camera prefers camera summary', () {
    const cam = LatLng(35.0, 139.0);
    const near = LatLng(35.0002, 139.0002);
    final pick = RevealReasonPool.pick(
      revealPosition: near,
      cameraPositions: [cam],
      safeZonePositions: const [],
      actorOutsidePlayArea: false,
    );
    expect(pick.summary, '監視カメラ');
  });
}
