import 'package:flutter/material.dart';

import '../features/branding/oni_pin_mark_painter.dart';
import '../theme/world_launch_branding.dart';

/// ONI PIN 採用 SVG マーク。世界観ごとに色・装飾・パルスを変える。
class ThemedGeometricLogo extends StatelessWidget {
  const ThemedGeometricLogo({
    required this.branding,
    this.size = 88,
    this.pulse = 0,
    super.key,
  });

  final WorldLaunchBranding branding;
  final double size;
  final double pulse;

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: SizedBox(
        width: size,
        height: size,
        child: CustomPaint(
          painter: OniPinMarkPainter(
            branding: branding,
            pulse: pulse,
          ),
        ),
      ),
    );
  }
}
