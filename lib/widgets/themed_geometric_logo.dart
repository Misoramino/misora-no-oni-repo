import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../features/branding/oni_pin_logo_geometry.dart';
import '../theme/world_launch_branding.dart';

/// ONI PIN 図形マーク（PNG に合わせたピン + 角 + 赤芯）。テーマ別配色。
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
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _OniPinMarkPainter(
          branding: branding,
          pulse: pulse,
        ),
      ),
    );
  }
}

class _OniPinMarkPainter extends CustomPainter {
  _OniPinMarkPainter({
    required this.branding,
    required this.pulse,
  });

  final WorldLaunchBranding branding;
  final double pulse;

  @override
  void paint(Canvas canvas, Size size) {
    final beat = 0.5 + 0.5 * math.sin(pulse * math.pi * 2);
    final strokeW = size.width * 0.058;
    final outline = OniPinLogoGeometry.outline(size);
    final core = OniPinLogoGeometry.coreCenter(size);
    final coreR = OniPinLogoGeometry.coreRadius(size);
    final glowR = OniPinLogoGeometry.coreGlowRadius(size, pulse: pulse);

    _paintThemeBackdrop(canvas, size, beat);

    // ピン外周（ソフトグロー + 本体ストローク）
    canvas.drawPath(
      outline,
      Paint()
        ..color = branding.glow.withValues(alpha: 0.35)
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeW + 2.5
        ..strokeJoin = StrokeJoin.round
        ..strokeCap = StrokeCap.round,
    );
    canvas.drawPath(
      outline,
      Paint()
        ..color = branding.pinStroke
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeW
        ..strokeJoin = StrokeJoin.round
        ..strokeCap = StrokeCap.round,
    );

    // 赤い追跡芯
    canvas.drawCircle(
      core,
      glowR,
      Paint()..color = branding.coreGlow.withValues(alpha: 0.35 + beat * 0.15),
    );
    canvas.drawCircle(core, coreR, Paint()..color = branding.coreColor);

    _paintThemeForeground(canvas, size, beat);
  }

  void _paintThemeBackdrop(Canvas canvas, Size size, double beat) {
    final core = OniPinLogoGeometry.coreCenter(size);
    switch (branding.effect) {
      case LaunchEffectKind.cyber:
        canvas.drawCircle(
          core,
          size.width * 0.34,
          Paint()
            ..color = branding.secondaryAccent.withValues(alpha: 0.14)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 0.8,
        );
      case LaunchEffectKind.magical:
        canvas.drawCircle(
          core,
          size.width * 0.36 + beat * 2,
          Paint()..color = branding.glow.withValues(alpha: 0.2),
        );
      case LaunchEffectKind.astronomy:
        canvas.drawOval(
          Rect.fromCenter(
            center: core,
            width: size.width * 0.62,
            height: size.width * 0.22,
          ),
          Paint()
            ..color = branding.accent.withValues(alpha: 0.18)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 0.7,
        );
      default:
        break;
    }
  }

  void _paintThemeForeground(Canvas canvas, Size size, double beat) {
    final core = OniPinLogoGeometry.coreCenter(size);
    switch (branding.effect) {
      case LaunchEffectKind.horror:
        canvas.drawCircle(
          core,
          size.width * 0.34 + beat * 5,
          Paint()
            ..color = branding.coreGlow.withValues(alpha: 0.15 * beat)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1,
        );
      case LaunchEffectKind.pop:
        for (var i = 0; i < 3; i++) {
          final a = pulse * math.pi * 2 + i * 2.1;
          canvas.drawCircle(
            Offset(
              core.dx + math.cos(a) * size.width * 0.38,
              core.dy + math.sin(a) * size.width * 0.28,
            ),
            2.2,
            Paint()
              ..color = [
                branding.secondaryAccent,
                branding.accent,
                branding.particleColor,
              ][i]
                  .withValues(alpha: 0.55),
          );
        }
      case LaunchEffectKind.tactical:
        final mark = Paint()
          ..color = branding.accent.withValues(alpha: 0.4)
          ..strokeWidth = 0.7;
        final r = size.width * 0.22;
        canvas.drawLine(
          Offset(core.dx - r, core.dy),
          Offset(core.dx + r, core.dy),
          mark,
        );
        canvas.drawLine(
          Offset(core.dx, core.dy - r),
          Offset(core.dx, core.dy + r),
          mark,
        );
      case LaunchEffectKind.magical:
        for (var i = 0; i < 4; i++) {
          final a = pulse * math.pi * 2 + i * math.pi / 2;
          canvas.drawCircle(
            Offset(
              core.dx + math.cos(a) * size.width * 0.36,
              core.dy + math.sin(a) * size.width * 0.36,
            ),
            2,
            Paint()
              ..color = branding.particleColor.withValues(alpha: 0.55 + beat * 0.25),
          );
        }
      case LaunchEffectKind.astronomy:
        final rng = math.Random(3);
        for (var i = 0; i < 5; i++) {
          canvas.drawCircle(
            Offset(
              core.dx + (rng.nextDouble() - 0.5) * size.width * 0.5,
              core.dy + (rng.nextDouble() - 0.5) * size.width * 0.4,
            ),
            0.9,
            Paint()..color = Colors.white.withValues(alpha: 0.4),
          );
        }
      default:
        break;
    }
  }

  @override
  bool shouldRepaint(covariant _OniPinMarkPainter old) {
    return old.branding.effect != branding.effect || old.pulse != pulse;
  }
}
