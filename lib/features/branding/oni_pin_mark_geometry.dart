import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter/material.dart';

/// 採用 SVG（viewBox 0 0 100）— 正規化パスは不変、スケール済みパスはキャッシュ。
abstract final class OniPinMarkGeometry {
  static const viewBox = 100.0;
  static const strokeWidth = 5.7;
  static const coreCx = 50.0;
  static const coreCy = 41.2;
  static const coreR = 7.15;

  static final Path pinOutlineNorm = _pinOutline();
  static final Path leftHornNorm = _leftHorn();
  static final Path rightHornNorm = _rightHorn();

  static const List<Offset> astronomySparkleNorm = [
    Offset(-0.24, -0.14),
    Offset(0.18, -0.18),
    Offset(-0.12, 0.16),
    Offset(0.26, 0.08),
    Offset(-0.28, 0.06),
    Offset(0.08, -0.22),
    Offset(0.22, 0.14),
  ];

  static const int _maxLayerCache = 32;
  static final Map<int, OniPinMarkLayers> _layerCache = {};

  static OniPinMarkLayers layersFor(Size size) {
    final key = (size.width * 4).round();
    final hit = _layerCache[key];
    if (hit != null) return hit;
    if (_layerCache.length >= _maxLayerCache) {
      _layerCache.remove(_layerCache.keys.first);
    }
    final layers = OniPinMarkLayers._(size);
    _layerCache[key] = layers;
    return layers;
  }

  static double beat(double pulse) =>
      0.5 + 0.5 * math.sin(pulse * math.pi * 2);

  static double coreGlowRadius(OniPinMarkLayers layers, double pulse) {
    final b = beat(pulse);
    return layers.coreR + layers.size.width * (0.06 + b * 0.025);
  }

  static Path _pinOutline() {
    final p = Path();
    p.moveTo(50, 86);
    p.cubicTo(42.4, 75.4, 30.6, 63.2, 25.2, 48.6);
    p.cubicTo(20.8, 36.1, 25.0, 25.0, 36.2, 18.4);
    p.cubicTo(43.0, 14.9, 57.0, 14.9, 63.8, 18.4);
    p.cubicTo(75.0, 25.0, 79.2, 36.1, 74.8, 48.6);
    p.cubicTo(69.4, 63.2, 57.6, 75.4, 50, 86);
    p.close();
    return p;
  }

  static Path _leftHorn() {
    final p = Path();
    p.moveTo(30.6, 22.2);
    p.cubicTo(26.8, 14.2, 28.8, 6.6, 37.2, 2.8);
    p.cubicTo(39.4, 11.4, 43.5, 16.4, 48.9, 18.4);
    p.cubicTo(41.9, 17.1, 35.4, 18.8, 30.6, 22.2);
    p.close();
    return p;
  }

  static Path _rightHorn() {
    final p = Path();
    p.moveTo(69.4, 22.2);
    p.cubicTo(73.2, 14.2, 71.2, 6.6, 62.8, 2.8);
    p.cubicTo(60.6, 11.4, 56.5, 16.4, 51.1, 18.4);
    p.cubicTo(58.1, 17.1, 64.6, 18.8, 69.4, 22.2);
    p.close();
    return p;
  }

  static Path _scale(Path norm, double sx, double sy) {
    return norm.transform(
      Float64List.fromList(<double>[
        sx, 0, 0, 0,
        0, sy, 0, 0,
        0, 0, 1, 0,
        0, 0, 0, 1,
      ]),
    );
  }
}

/// サイズ別にスケール済みの採用 SVG レイヤー。
final class OniPinMarkLayers {
  OniPinMarkLayers._(this.size)
      : outline = OniPinMarkGeometry._scale(
          OniPinMarkGeometry.pinOutlineNorm,
          size.width / OniPinMarkGeometry.viewBox,
          size.height / OniPinMarkGeometry.viewBox,
        ),
        leftHorn = OniPinMarkGeometry._scale(
          OniPinMarkGeometry.leftHornNorm,
          size.width / OniPinMarkGeometry.viewBox,
          size.height / OniPinMarkGeometry.viewBox,
        ),
        rightHorn = OniPinMarkGeometry._scale(
          OniPinMarkGeometry.rightHornNorm,
          size.width / OniPinMarkGeometry.viewBox,
          size.height / OniPinMarkGeometry.viewBox,
        ),
        core = Offset(
          size.width * (OniPinMarkGeometry.coreCx / OniPinMarkGeometry.viewBox),
          size.height * (OniPinMarkGeometry.coreCy / OniPinMarkGeometry.viewBox),
        ),
        coreR = OniPinMarkGeometry.coreR * size.width / OniPinMarkGeometry.viewBox,
        strokeW = OniPinMarkGeometry.strokeWidth *
            size.width /
            OniPinMarkGeometry.viewBox;

  final Size size;
  final Path outline;
  final Path leftHorn;
  final Path rightHorn;
  final Offset core;
  final double coreR;
  final double strokeW;
}
