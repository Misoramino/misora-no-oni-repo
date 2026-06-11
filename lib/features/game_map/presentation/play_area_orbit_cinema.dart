import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../../config/google_maps_config.dart';
import '../../../game/play_area.dart';
import '../../../theme/world_launch_branding.dart';
import '../../../theme/world_profile.dart';
import '../../../theme/world_profile_tokens.dart';
import '../map/game_map_overlay_builder.dart';
import '../map/game_map_overlay_snapshot.dart';

/// プレイエリアを複数アングルから見せる L1 シネマ（円・多角形どちらも bounds 基準）。
Future<void> runPlayAreaOrbitCinema({
  required BuildContext context,
  required PlayArea area,
  required WorldProfile profile,
  required String? mapStyleJson,
  required WorldProfileTokens tokens,
  GoogleMapController? mapController,
}) async {
  if (!context.mounted) return;

  if (mapController != null) {
    await _orbitOnController(
      context: context,
      controller: mapController,
      area: area,
      profile: profile,
    );
    return;
  }

  if (!GoogleMapsConfig.isConfigured) return;

  await showGeneralDialog<void>(
    context: context,
    barrierDismissible: true,
    barrierColor: Colors.black.withValues(alpha: 0.35),
    transitionDuration: const Duration(milliseconds: 220),
    pageBuilder: (_, __, ___) => _OrbitCinemaMapDialog(
      area: area,
      profile: profile,
      mapStyleJson: mapStyleJson,
      tokens: tokens,
    ),
  );
}

Future<void> _orbitOnController({
  required BuildContext context,
  required GoogleMapController controller,
  required PlayArea area,
  required WorldProfile profile,
}) async {
  final branding = WorldLaunchBranding.of(profile);
  final overlay = Overlay.of(context);
  final entry = OverlayEntry(
    builder: (_) => _OrbitCinemaHud(
      branding: branding,
      profile: profile,
      areaLabel: area.shapeSummary(),
    ),
  );
  overlay.insert(entry);

  try {
    await _playOrbitSequence(controller, area, profile);
  } finally {
    entry.remove();
  }
}

Future<void> _playOrbitSequence(
  GoogleMapController controller,
  PlayArea area,
  WorldProfile profile,
) async {
  final shots = _buildCameraShots(area);
  HapticFeedback.mediumImpact();

  try {
    await controller.animateCamera(
      CameraUpdate.newLatLngBounds(area.bounds, 72),
    );
    await Future<void>.delayed(const Duration(milliseconds: 520));
  } catch (_) {}

  for (var i = 0; i < shots.length; i++) {
    final shot = shots[i];
    try {
      await controller.animateCamera(
        CameraUpdate.newCameraPosition(shot),
      );
    } catch (_) {}
    if (i == 0) HapticFeedback.selectionClick();
    if (i == shots.length - 1) HapticFeedback.lightImpact();
    await Future<void>.delayed(
      Duration(milliseconds: i == shots.length - 1 ? 680 : 920),
    );
  }

  try {
    await controller.animateCamera(
      CameraUpdate.newLatLngBounds(area.bounds, 56),
    );
  } catch (_) {}
  await Future<void>.delayed(const Duration(milliseconds: 360));
}

List<CameraPosition> _buildCameraShots(PlayArea area) {
  final anchor = area.anchorCenter;
  final bounds = area.bounds;
  final spanLat =
      (bounds.northeast.latitude - bounds.southwest.latitude).abs().clamp(0.0008, 0.08);
  final spanLng =
      (bounds.northeast.longitude - bounds.southwest.longitude).abs().clamp(0.0008, 0.08);
  final orbitM = math.max(spanLat, spanLng) * 111320 * 0.55;
  final zoom = _zoomForArea(area);
  final bearings = <double>[28, 118, 208, 298];

  return [
    for (final bearing in bearings)
      CameraPosition(
        target: _offsetMeters(anchor, orbitM, bearing),
        zoom: zoom + 0.6,
        tilt: 42,
        bearing: bearing,
      ),
  ];
}

double _zoomForArea(PlayArea area) {
  switch (area.type) {
    case PlayAreaType.circle:
      final r = area.radiusMeters.clamp(80, 2400);
      if (r < 200) return 17.2;
      if (r < 500) return 16.2;
      if (r < 1000) return 15.4;
      return 14.6;
    case PlayAreaType.polygon:
      final b = area.bounds;
      final diag = Geolocator.distanceBetween(
        b.southwest.latitude,
        b.southwest.longitude,
        b.northeast.latitude,
        b.northeast.longitude,
      );
      if (diag < 300) return 17.0;
      if (diag < 700) return 16.0;
      if (diag < 1400) return 15.2;
      return 14.4;
  }
}

LatLng _offsetMeters(LatLng origin, double meters, double bearingDeg) {
  final bearing = bearingDeg * math.pi / 180;
  final latRad = origin.latitude * math.pi / 180;
  final dLat = (meters * math.cos(bearing)) / 111320;
  final dLng = (meters * math.sin(bearing)) / (111320 * math.cos(latRad));
  return LatLng(origin.latitude + dLat, origin.longitude + dLng);
}

class _OrbitCinemaMapDialog extends StatefulWidget {
  const _OrbitCinemaMapDialog({
    required this.area,
    required this.profile,
    required this.mapStyleJson,
    required this.tokens,
  });

  final PlayArea area;
  final WorldProfile profile;
  final String? mapStyleJson;
  final WorldProfileTokens tokens;

  @override
  State<_OrbitCinemaMapDialog> createState() => _OrbitCinemaMapDialogState();
}

class _OrbitCinemaMapDialogState extends State<_OrbitCinemaMapDialog> {
  GoogleMapController? _controller;
  var _started = false;

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  Future<void> _onMapCreated(GoogleMapController c) async {
    _controller = c;
    if (widget.mapStyleJson != null) {
      try {
        await c.setMapStyle(widget.mapStyleJson);
      } catch (_) {}
    }
    if (_started || !mounted) return;
    _started = true;
    await _playOrbitSequence(c, widget.area, widget.profile);
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final branding = WorldLaunchBranding.of(widget.profile);
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

    return Material(
      color: Colors.black,
      child: Stack(
        fit: StackFit.expand,
        children: [
          GoogleMap(
            initialCameraPosition: CameraPosition(
              target: widget.area.anchorCenter,
              zoom: _zoomForArea(widget.area),
            ),
            onMapCreated: _onMapCreated,
            myLocationEnabled: false,
            myLocationButtonEnabled: false,
            zoomControlsEnabled: false,
            mapToolbarEnabled: false,
            compassEnabled: false,
            polygons: GameMapOverlayBuilder.buildPolygons(overlay),
            circles: GameMapOverlayBuilder.buildCircles(overlay),
          ),
          _OrbitCinemaHud(
            branding: branding,
            profile: widget.profile,
            areaLabel: widget.area.shapeSummary(),
          ),
        ],
      ),
    );
  }
}

class _OrbitCinemaHud extends StatelessWidget {
  const _OrbitCinemaHud({
    required this.branding,
    required this.profile,
    required this.areaLabel,
  });

  final WorldLaunchBranding branding;
  final WorldProfile profile;
  final String areaLabel;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Stack(
        fit: StackFit.expand,
        children: [
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withValues(alpha: 0.42),
                  Colors.transparent,
                  Colors.transparent,
                  Colors.black.withValues(alpha: 0.38),
                ],
                stops: const [0.0, 0.22, 0.78, 1.0],
              ),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'AREA SCAN',
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          color: branding.accent.withValues(alpha: 0.9),
                          letterSpacing: 2,
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    branding.profileLabel,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                        ),
                  ),
                  const Spacer(),
                  Text(
                    areaLabel,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: Colors.white.withValues(alpha: 0.88),
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _orbitTagline(profile),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.white54,
                        ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _orbitTagline(WorldProfile profile) => switch (profile) {
        WorldProfile.astronomy => 'プレイエリアを軌道からスキャン中…',
        WorldProfile.magical => '結界（プレイエリア）を確認しています…',
        WorldProfile.sciFi => 'プレイエリアをロックオン…',
        WorldProfile.horror => '暗がりの中、プレイエリアを探索…',
        WorldProfile.sport => 'みんなのプレイエリア、チェック！',
        WorldProfile.arg => 'プレイエリアを俯瞰確認…',
      };
}
