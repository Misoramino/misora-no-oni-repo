import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../../presentation/world/world_legibility.dart';

/// 地図タップスキル（捕獲結界・体投げ）の長押し→離して設置／×でキャンセル。
class SkillMapPlacementLayer extends StatefulWidget {
  const SkillMapPlacementLayer({
    required this.mapController,
    required this.active,
    required this.isBodyThrow,
    required this.hint,
    required this.onPreview,
    required this.onConfirm,
    required this.onCancel,
    super.key,
  });

  final GoogleMapController? mapController;
  final bool active;
  final bool isBodyThrow;
  final String hint;
  final ValueChanged<LatLng?> onPreview;
  final ValueChanged<LatLng> onConfirm;
  final VoidCallback onCancel;

  @override
  State<SkillMapPlacementLayer> createState() => _SkillMapPlacementLayerState();
}

class _SkillMapPlacementLayerState extends State<SkillMapPlacementLayer> {
  bool _pointerDown = false;
  int _activePointers = 0;
  Offset? _lastLocal;

  @override
  void didUpdateWidget(covariant SkillMapPlacementLayer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!widget.active && oldWidget.active) {
      _pointerDown = false;
      _lastLocal = null;
      widget.onPreview(null);
    }
  }

  Future<LatLng?> _latLngAt(Offset local) async {
    final controller = widget.mapController;
    if (controller == null) return null;
    return controller.getLatLng(
      ScreenCoordinate(x: local.dx.round(), y: local.dy.round()),
    );
  }

  void _updatePreview(Offset local) {
    _lastLocal = local;
    unawaited(_latLngAt(local).then((latLng) {
      if (!mounted || !_pointerDown) return;
      widget.onPreview(latLng);
    }));
  }

  void _finishPointer() {
    _activePointers = (_activePointers - 1).clamp(0, 8);
    if (_activePointers > 0) return;
    if (!_pointerDown) return;
    _pointerDown = false;
    if (_lastLocal != null) {
      unawaited(_latLngAt(_lastLocal!).then((latLng) {
        if (!mounted || latLng == null) return;
        widget.onPreview(null);
        widget.onConfirm(latLng);
      }));
    } else {
      widget.onPreview(null);
    }
  }

  void _cancelPlacement() {
    if (!widget.active) return;
    _pointerDown = false;
    _lastLocal = null;
    widget.onPreview(null);
    widget.onCancel();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.active) return const SizedBox.shrink();

    final theme = Theme.of(context);
    final leg = context.runningHudLegibility();
    final topInset = MediaQuery.paddingOf(context).top;
    const appBarHeight = kToolbarHeight;

    return Stack(
      fit: StackFit.expand,
      children: [
        Listener(
          behavior: HitTestBehavior.opaque,
          onPointerDown: (e) {
            _activePointers++;
            if (_activePointers > 1) return;
            _pointerDown = true;
            _updatePreview(e.localPosition);
          },
          onPointerMove: (e) {
            if (_activePointers > 1 || !_pointerDown) return;
            _updatePreview(e.localPosition);
          },
          onPointerUp: (_) => _finishPointer(),
          onPointerCancel: (_) => _finishPointer(),
        ),
        Align(
          alignment: Alignment.topCenter,
          child: Padding(
            padding: EdgeInsets.only(
              top: topInset + appBarHeight + 10,
              left: 16,
              right: 16,
            ),
            child: Material(
              color: leg.infoPanelBg,
              elevation: 6,
              borderRadius: BorderRadius.circular(12),
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        '${widget.hint}\n指を離すと設置',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: leg.body,
                          height: 1.4,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Material(
                      color: leg.skillButtonBg,
                      shape: const CircleBorder(),
                      child: InkWell(
                        customBorder: const CircleBorder(),
                        onTap: _cancelPlacement,
                        child: Padding(
                          padding: const EdgeInsets.all(8),
                          child: Icon(
                            Icons.close_rounded,
                            color: leg.skillButtonFg,
                            size: 22,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
