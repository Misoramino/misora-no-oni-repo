import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../widgets/skill_map_placement_layer.dart';
import 'game_map_overlay_builder.dart';
import 'game_map_overlay_snapshot.dart';
import 'game_map_overlay_visual.dart';

/// 試合中の GoogleMap オーバーレイだけを局所更新する層。
///
/// 親 [GameMapScreen] の setState では [GoogleMap] 自体を再構築せず、
/// [overlayListenable] の通知時のみマーカー等を更新する。
class GameMapInteractiveLayer extends StatefulWidget {
  const GameMapInteractiveLayer({
    required this.overlayListenable,
    required this.mapStyleJson,
    required this.initialCameraTarget,
    required this.onMapCreated,
    required this.onTap,
    required this.onCameraIdle,
    required this.mapController,
    required this.skillPlacementActive,
    required this.bodyThrowAwaitingMapTap,
    required this.skillPlacementHint,
    required this.onSkillPlacementPreview,
    required this.onSkillPlacementConfirm,
    required this.onSkillPlacementCancel,
    super.key,
  });

  final ValueListenable<GameMapOverlaySnapshot?> overlayListenable;
  final String? mapStyleJson;
  final LatLng initialCameraTarget;
  final void Function(GoogleMapController controller) onMapCreated;
  final void Function(LatLng position) onTap;
  final VoidCallback onCameraIdle;
  final GoogleMapController? mapController;
  final bool skillPlacementActive;
  final bool bodyThrowAwaitingMapTap;
  final String skillPlacementHint;
  final ValueChanged<LatLng?> onSkillPlacementPreview;
  final void Function(LatLng latLng) onSkillPlacementConfirm;
  final VoidCallback onSkillPlacementCancel;

  @override
  State<GameMapInteractiveLayer> createState() =>
      _GameMapInteractiveLayerState();
}

class _GameMapInteractiveLayerState extends State<GameMapInteractiveLayer> {
  GameMapOverlaySnapshot? _overlay;

  @override
  void initState() {
    super.initState();
    _overlay = widget.overlayListenable.value;
    widget.overlayListenable.addListener(_onOverlayChanged);
  }

  @override
  void didUpdateWidget(covariant GameMapInteractiveLayer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.overlayListenable != widget.overlayListenable) {
      oldWidget.overlayListenable.removeListener(_onOverlayChanged);
      widget.overlayListenable.addListener(_onOverlayChanged);
      _overlay = widget.overlayListenable.value;
    }
  }

  @override
  void dispose() {
    widget.overlayListenable.removeListener(_onOverlayChanged);
    super.dispose();
  }

  void _onOverlayChanged() {
    final next = widget.overlayListenable.value;
    if (next == null || identical(next, _overlay)) return;
    setState(() => _overlay = next);
  }

  @override
  Widget build(BuildContext context) {
    final overlay = _overlay;
    return Stack(
      fit: StackFit.expand,
      children: [
        if (overlay == null)
          const ColoredBox(color: Color(0xFF1A1D24))
        else
          RepaintBoundary(
            child: _GoogleMapOverlayView(
              overlay: overlay,
              mapStyleJson: widget.mapStyleJson,
              initialCameraTarget: widget.initialCameraTarget,
              onMapCreated: widget.onMapCreated,
              onTap: widget.onTap,
              onCameraIdle: widget.onCameraIdle,
              mapGesturesEnabled: !widget.skillPlacementActive,
            ),
          ),
        SkillMapPlacementLayer(
          mapController: widget.mapController,
          active: widget.skillPlacementActive,
          isBodyThrow: widget.bodyThrowAwaitingMapTap,
          hint: widget.skillPlacementHint,
          onPreview: widget.onSkillPlacementPreview,
          onConfirm: widget.onSkillPlacementConfirm,
          onCancel: widget.onSkillPlacementCancel,
        ),
      ],
    );
  }
}

/// [GoogleMap] だけを持つ子。親の build では overlay 参照を使わない。
class _GoogleMapOverlayView extends StatefulWidget {
  const _GoogleMapOverlayView({
    required this.overlay,
    required this.mapStyleJson,
    required this.initialCameraTarget,
    required this.onMapCreated,
    required this.onTap,
    required this.onCameraIdle,
    required this.mapGesturesEnabled,
  });

  final GameMapOverlaySnapshot overlay;
  final String? mapStyleJson;
  final LatLng initialCameraTarget;
  final void Function(GoogleMapController controller) onMapCreated;
  final void Function(LatLng position) onTap;
  final VoidCallback onCameraIdle;
  final bool mapGesturesEnabled;

  @override
  State<_GoogleMapOverlayView> createState() => _GoogleMapOverlayViewState();
}

class _GoogleMapOverlayViewState extends State<_GoogleMapOverlayView> {
  Set<Marker>? _cachedMarkers;
  int? _cachedMarkerFingerprint;

  @override
  void initState() {
    super.initState();
    _rebuildMarkersIfNeeded(widget.overlay, force: true);
  }

  @override
  void didUpdateWidget(covariant _GoogleMapOverlayView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(oldWidget.overlay, widget.overlay)) {
      _rebuildMarkersIfNeeded(widget.overlay);
    }
  }

  void _rebuildMarkersIfNeeded(GameMapOverlaySnapshot overlay, {bool force = false}) {
    final fp = GameMapOverlayVisual.fingerprint(overlay);
    if (!force && fp == _cachedMarkerFingerprint && _cachedMarkers != null) {
      return;
    }
    _cachedMarkerFingerprint = fp;
    _cachedMarkers = GameMapOverlayBuilder.buildMarkers(overlay);
  }

  @override
  Widget build(BuildContext context) {
    final overlay = widget.overlay;
    final gestures = widget.mapGesturesEnabled;
    return GoogleMap(
      key: const ValueKey('game_map_core'),
      style: widget.mapStyleJson,
      initialCameraPosition: CameraPosition(
        target: widget.initialCameraTarget,
        zoom: 16,
      ),
      scrollGesturesEnabled: gestures,
      zoomGesturesEnabled: gestures,
      rotateGesturesEnabled: gestures,
      tiltGesturesEnabled: gestures,
      myLocationEnabled: true,
      myLocationButtonEnabled: !gestures,
      markers: _cachedMarkers ?? GameMapOverlayBuilder.buildMarkers(overlay),
      polylines: GameMapOverlayBuilder.buildPolylines(overlay),
      circles: GameMapOverlayBuilder.buildCircles(overlay),
      polygons: GameMapOverlayBuilder.buildPolygons(overlay),
      onTap: widget.onTap,
      onMapCreated: widget.onMapCreated,
      onCameraIdle: widget.onCameraIdle,
    );
  }
}
