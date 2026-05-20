import 'package:flutter_test/flutter_test.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:oni_game/features/game_map/map/game_map_overlay_builder.dart';
import 'package:oni_game/features/game_map/map/game_map_overlay_snapshot.dart';
import 'package:oni_game/game/play_area.dart';
import 'package:oni_game/theme/world_profile.dart';
import 'package:oni_game/theme/world_profile_tokens.dart' show WorldProfileTokenFactory;

void main() {
  test('overlay builder produces player marker at minimum', () {
    final tokens = WorldProfileTokenFactory.of(WorldProfile.horror);
    final snap = GameMapOverlaySnapshot(
      now: DateTime.utc(2026, 5, 19),
      playerMarkerPosition: const LatLng(35.68, 139.76),
      oniPosition: const LatLng(35.68, 139.77),
      showOniMarker: false,
      remoteOniKnown: false,
      remoteMembers: const {},
      showGimmickMarkers: false,
      safeZonePositions: const [],
      infoBrokerPositions: const [],
      commJammingZonePositions: const [],
      cameraPositions: const [],
      tracePoints: const [],
      revealTraces: const [],
      oniIntelTraces: const [],
      safeZoneAvailable: true,
      infoBrokerAvailable: true,
      safeZoneRespawnAt: null,
      infoBrokerRespawnAt: null,
      triggeredCameras: const {},
      fakePositionActive: false,
      fakePositionLatLng: null,
      bodyThrowPosition: null,
      bodyThrowAwaitingMapTap: false,
      afterCatchRule: null,
      ghostRoughPositions: const [],
      editingArea: false,
      editCircleMode: true,
      polygonDraft: const [],
      polygonDraftClosed: false,
      circleDraftCenter: const LatLng(35.68, 139.76),
      circleDraftRadiusMeters: 500,
      playArea: const PlayArea.circle(
        center: LatLng(35.68, 139.76),
        radiusMeters: 500,
      ),
      captureZoneCenter: null,
      tokens: tokens,
    );

    final markers = GameMapOverlayBuilder.buildMarkers(snap);
    expect(markers.length, 1);
    expect(markers.first.markerId.value, 'player');

    final circles = GameMapOverlayBuilder.buildCircles(snap);
    expect(circles.any((c) => c.circleId.value == 'play-area'), isTrue);
  });
}
