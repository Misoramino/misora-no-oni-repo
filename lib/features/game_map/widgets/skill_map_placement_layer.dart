import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

/// 地図タップスキル（捕獲結界・体投げ）の長押し→離して設置／×へドラッグでキャンセル。
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
  bool _cancelHover = false;
  bool _deferToMap = false;
  int _activePointers = 0;
  Offset? _lastLocal;

  @override
  void didUpdateWidget(covariant SkillMapPlacementLayer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!widget.active && oldWidget.active) {
      _pointerDown = false;
      _cancelHover = false;
      _lastLocal = null;
      widget.onPreview(null);
    }
  }

  Rect get _cancelTarget {
    final size = MediaQuery.sizeOf(context);
    final bottomInset = MediaQuery.paddingOf(context).bottom;
    const box = 56.0;
    return Rect.fromCenter(
      center: Offset(size.width / 2, size.height - bottomInset - 148),
      width: box,
      height: box,
    );
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
    final hover = _cancelTarget.contains(local);
    if (hover != _cancelHover) {
      setState(() => _cancelHover = hover);
    }
  }

  void _finishPointer() {
    _activePointers = (_activePointers - 1).clamp(0, 8);
    if (_activePointers > 1) return;
    if (_activePointers == 0) {
      _deferToMap = false;
    }
    if (!_pointerDown) return;
    _pointerDown = false;
    if (_cancelHover) {
      widget.onPreview(null);
      widget.onCancel();
    } else if (_lastLocal != null) {
      unawaited(_latLngAt(_lastLocal!).then((latLng) {
        if (!mounted || latLng == null) return;
        widget.onPreview(null);
        widget.onConfirm(latLng);
      }));
    } else {
      widget.onPreview(null);
    }
    setState(() => _cancelHover = false);
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.active) return const SizedBox.shrink();
    if (_deferToMap) return const SizedBox.shrink();

    final theme = Theme.of(context);
    final cancelRect = _cancelTarget;

    return Stack(
      fit: StackFit.expand,
      children: [
        Listener(
          behavior: HitTestBehavior.translucent,
          onPointerDown: (e) {
            _activePointers++;
            if (_activePointers > 1) {
              setState(() {
                _deferToMap = true;
                _pointerDown = false;
                _cancelHover = false;
              });
              widget.onPreview(null);
              return;
            }
            _pointerDown = true;
            _updatePreview(e.localPosition);
          },
          onPointerMove: (e) {
            if (_deferToMap || !_pointerDown) return;
            _updatePreview(e.localPosition);
          },
          onPointerUp: (_) => _finishPointer(),
          onPointerCancel: (_) => _finishPointer(),
        ),
        IgnorePointer(
          child: Align(
            alignment: Alignment.topCenter,
            child: Padding(
              padding: const EdgeInsets.only(top: 96, left: 16, right: 16),
              child: Material(
                color: Colors.black.withValues(alpha: 0.72),
                borderRadius: BorderRadius.circular(12),
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  child: Text(
                    widget.hint,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: Colors.white,
                      height: 1.35,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
        Positioned(
          left: cancelRect.left,
          top: cancelRect.top,
          width: cancelRect.width,
          height: cancelRect.height,
          child: IgnorePointer(
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 120),
              decoration: BoxDecoration(
                color: (_cancelHover ? Colors.red : Colors.black)
                    .withValues(alpha: _cancelHover ? 0.88 : 0.62),
                shape: BoxShape.circle,
                border: Border.all(
                  color: _cancelHover ? Colors.white : Colors.white54,
                  width: _cancelHover ? 2.5 : 1.5,
                ),
              ),
              child: const Icon(Icons.close_rounded, color: Colors.white),
            ),
          ),
        ),
        IgnorePointer(
          child: Align(
            alignment: Alignment.bottomCenter,
            child: Padding(
              padding: EdgeInsets.only(bottom: cancelRect.height + 24),
              child: Text(
                '×へドラッグでキャンセル',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: Colors.white,
                  shadows: const [Shadow(color: Colors.black54, blurRadius: 4)],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
