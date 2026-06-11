import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../../game/play_area.dart';
import '../../../config/google_maps_config.dart';
import '../map/game_map_overlay_builder.dart';
import '../map/game_map_overlay_snapshot.dart';
import '../../../theme/world_profile_tokens.dart';

/// 準備画面用の読み取り専用マッププレビュー（位置・形の確認のみ）。
class PlayAreaMapPreview extends StatefulWidget {
  const PlayAreaMapPreview({
    required this.area,
    required this.mapStyleJson,
    required this.tokens,
    this.height = 168,
    super.key,
  });

  final PlayArea area;
  final String? mapStyleJson;
  final WorldProfileTokens tokens;
  final double height;

  @override
  State<PlayAreaMapPreview> createState() => _PlayAreaMapPreviewState();
}

class _PlayAreaMapPreviewState extends State<PlayAreaMapPreview> {
  GoogleMapController? _controller;

  @override
  void didUpdateWidget(covariant PlayAreaMapPreview oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.area != widget.area) {
      _fitCamera();
    }
  }

  Future<void> _fitCamera() async {
    final c = _controller;
    if (c == null) return;
    try {
      await c.animateCamera(
        CameraUpdate.newLatLngBounds(widget.area.bounds, 40),
      );
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    if (!GoogleMapsConfig.isConfigured) {
      return SizedBox(
        height: widget.height,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceContainerHigh,
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Center(
            child: Text('地図 API 未設定', style: TextStyle(fontSize: 12)),
          ),
        ),
      );
    }

    final overlay = GameMapOverlaySnapshot(
      now: DateTime.now(),
      playerMarkerPosition: widget.area.anchorCenter,
      oniPosition: widget.area.anchorCenter,
      showOniMarker: false,
      remoteOniKnown: false,
      remoteMembers: const {},
      showGimmickMarkers: false,
      safeZonePositions: const [],
      infoBrokerPositions: const [],
      accusationFacilityPositions: const [],
      activeAccusationSiteIndices: const {},
      cameraJackPositions: const [],
      commJammingZonePositions: const [],
      cameraPositions: const [],
      tracePoints: const [],
      revealTraces: const [],
      anonymousRevealTraces: const [],
      oniIntelTraces: const [],
      safeZoneAvailable: false,
      infoBrokerAvailable: false,
      safeZoneRespawnAt: null,
      infoBrokerRespawnAt: null,
      fakePositionActive: false,
      fakePositionLatLng: widget.area.anchorCenter,
      bodyThrowPosition: widget.area.anchorCenter,
      afterCatchRule: null,
      ghostRoughPositions: const [],
      editingArea: false,
      editCircleMode: false,
      polygonDraft: const [],
      polygonDraftClosed: false,
      circleDraftCenter: widget.area.anchorCenter,
      circleDraftRadiusMeters: 0,
      playArea: widget.area,
      lockZoneCenter: null,
      tokens: widget.tokens,
    );

    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: SizedBox(
        height: widget.height,
        child: GoogleMap(
          style: widget.mapStyleJson,
          initialCameraPosition: CameraPosition(
            target: widget.area.anchorCenter,
            zoom: 15,
          ),
          myLocationEnabled: false,
          myLocationButtonEnabled: false,
          zoomControlsEnabled: false,
          mapToolbarEnabled: false,
          rotateGesturesEnabled: false,
          scrollGesturesEnabled: false,
          tiltGesturesEnabled: false,
          zoomGesturesEnabled: false,
          liteModeEnabled: false,
          circles: GameMapOverlayBuilder.buildCircles(overlay),
          polygons: GameMapOverlayBuilder.buildPolygons(overlay),
          onMapCreated: (c) {
            _controller = c;
            _fitCamera();
          },
        ),
      ),
    );
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }
}
