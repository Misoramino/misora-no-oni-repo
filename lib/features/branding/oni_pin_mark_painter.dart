import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../theme/world_launch_branding.dart';
import 'oni_pin_mark_geometry.dart';

/// 採用 SVG マークの CustomPainter（世界観装飾つき）。
class OniPinMarkPainter extends CustomPainter {
  OniPinMarkPainter({
    required this.branding,
    required this.pulse,
  });

  final WorldLaunchBranding branding;
  final double pulse;

  @override
  void paint(Canvas canvas, Size size) {
    final layers = OniPinMarkGeometry.layersFor(size);
    final beat = OniPinMarkGeometry.beat(pulse);
    final glowR = OniPinMarkGeometry.coreGlowRadius(layers, pulse);

    _paintBackdrop(canvas, layers, beat);
    _paintHorns(canvas, layers, beat);
    _paintPinOutline(canvas, layers, beat);
    _paintCore(canvas, layers, glowR, beat);
    _paintForeground(canvas, layers, beat);
  }

  void _paintHorns(Canvas canvas, OniPinMarkLayers layers, double beat) {
    final glowFill = Paint()
      ..color = branding.glow.withValues(alpha: 0.28 + beat * 0.1)
      ..style = PaintingStyle.fill;
    canvas.drawPath(layers.leftHorn, glowFill);
    canvas.drawPath(layers.rightHorn, glowFill);

    final fill = Paint()..color = branding.pinStroke;
    canvas.drawPath(layers.leftHorn, fill);
    canvas.drawPath(layers.rightHorn, fill);

    switch (branding.effect) {
      case LaunchEffectKind.cyber:
        final edge = Paint()
          ..color = branding.accent.withValues(alpha: 0.35 + beat * 0.2)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 0.9;
        canvas.drawPath(layers.leftHorn, edge);
        canvas.drawPath(layers.rightHorn, edge);
      case LaunchEffectKind.horror:
        final bleed = Paint()
          ..color = branding.coreGlow.withValues(alpha: 0.08 * beat)
          ..style = PaintingStyle.fill
          ..blendMode = BlendMode.plus;
        canvas.drawPath(layers.leftHorn, bleed);
        canvas.drawPath(layers.rightHorn, bleed);
      case LaunchEffectKind.pop:
        final w = layers.size.width;
        final h = layers.size.height;
        canvas.drawCircle(
          Offset(w * 0.28, h * 0.12),
          2.5,
          Paint()..color = branding.secondaryAccent.withValues(alpha: 0.7),
        );
        canvas.drawCircle(
          Offset(w * 0.72, h * 0.1),
          2,
          Paint()..color = branding.accent.withValues(alpha: 0.65),
        );
      case LaunchEffectKind.tactical:
      case LaunchEffectKind.magical:
      case LaunchEffectKind.astronomy:
        break;
    }
  }

  void _paintPinOutline(Canvas canvas, OniPinMarkLayers layers, double beat) {
    final sw = layers.strokeW;
    canvas.drawPath(
      layers.outline,
      Paint()
        ..color = branding.glow.withValues(alpha: 0.38 + beat * 0.12)
        ..style = PaintingStyle.stroke
        ..strokeWidth = sw + 2.8
        ..strokeJoin = StrokeJoin.round
        ..strokeCap = StrokeCap.round,
    );
    canvas.drawPath(
      layers.outline,
      Paint()
        ..color = branding.pinStroke
        ..style = PaintingStyle.stroke
        ..strokeWidth = sw
        ..strokeJoin = StrokeJoin.round
        ..strokeCap = StrokeCap.round,
    );
  }

  void _paintCore(
    Canvas canvas,
    OniPinMarkLayers layers,
    double glowR,
    double beat,
  ) {
    canvas.drawCircle(
      layers.core,
      glowR,
      Paint()..color = branding.coreGlow.withValues(alpha: 0.38 + beat * 0.18),
    );
    canvas.drawCircle(
      layers.core,
      layers.coreR,
      Paint()..color = branding.coreColor,
    );
  }

  void _paintBackdrop(Canvas canvas, OniPinMarkLayers layers, double beat) {
    final core = layers.core;
    final w = layers.size.width;
    switch (branding.effect) {
      case LaunchEffectKind.cyber:
        _strokeCircle(
          canvas,
          core,
          w * (0.34 + beat * 0.02),
          branding.secondaryAccent.withValues(alpha: 0.16),
          1,
        );
        _strokeCircle(
          canvas,
          core,
          w * 0.46,
          branding.accent.withValues(alpha: 0.1),
          0.6,
        );
      case LaunchEffectKind.magical:
        canvas.drawCircle(
          core,
          w * (0.36 + beat * 3),
          Paint()..color = branding.glow.withValues(alpha: 0.22),
        );
      case LaunchEffectKind.astronomy:
        canvas.drawOval(
          Rect.fromCenter(center: core, width: w * 0.64, height: w * 0.24),
          Paint()
            ..color = branding.accent.withValues(alpha: 0.2)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 0.8,
        );
      case LaunchEffectKind.horror:
        canvas.drawCircle(
          core,
          w * 0.42,
          Paint()..color = branding.coreGlow.withValues(alpha: 0.06),
        );
      case LaunchEffectKind.pop:
      case LaunchEffectKind.tactical:
        break;
    }
  }

  void _paintForeground(Canvas canvas, OniPinMarkLayers layers, double beat) {
    final core = layers.core;
    final w = layers.size.width;
    switch (branding.effect) {
      case LaunchEffectKind.horror:
        _strokeCircle(
          canvas,
          core,
          w * (0.34 + beat * 6),
          branding.coreGlow.withValues(alpha: 0.18 * beat),
          1.2,
        );
      case LaunchEffectKind.pop:
        _orbitParticles(
          canvas,
          core,
          w,
          w * 0.4,
          w * 0.3,
          4,
          1.57,
          2.4,
          [
            branding.secondaryAccent,
            branding.accent,
            branding.particleColor,
            branding.pulseColor,
          ],
          0.5 + beat * 0.35,
        );
      case LaunchEffectKind.tactical:
        final mark = Paint()
          ..color = branding.accent.withValues(alpha: 0.45 + beat * 0.15)
          ..strokeWidth = 0.85;
        final r = w * 0.24;
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
        _strokeCircle(
          canvas,
          core,
          r * 0.55,
          branding.accent.withValues(alpha: 0.2),
          0.6,
        );
      case LaunchEffectKind.magical:
        _orbitParticles(
          canvas,
          core,
          w,
          w * 0.38,
          w * 0.38,
          5,
          1.26,
          2.2,
          [branding.particleColor],
          0.5 + beat * 0.35,
        );
      case LaunchEffectKind.astronomy:
        final tw = 0.35 + beat * 0.5;
        for (var i = 0; i < OniPinMarkGeometry.astronomySparkleNorm.length; i++) {
          final n = OniPinMarkGeometry.astronomySparkleNorm[i];
          canvas.drawCircle(
            Offset(core.dx + n.dx * w, core.dy + n.dy * w),
            0.8 + (i.isEven ? 0.4 : 0),
            Paint()..color = Colors.white.withValues(alpha: 0.35 * tw),
          );
        }
      case LaunchEffectKind.cyber:
        final scanY = core.dy + (beat - 0.5) * w * 0.85;
        canvas.drawLine(
          Offset(0, scanY),
          Offset(w, scanY),
          Paint()
            ..color = branding.scanLineColor.withValues(alpha: 0.35)
            ..strokeWidth = 1.2,
        );
    }
  }

  void _strokeCircle(
    Canvas canvas,
    Offset center,
    double radius,
    Color color,
    double width,
  ) {
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = width,
    );
  }

  void _orbitParticles(
    Canvas canvas,
    Offset core,
    double w,
    double rx,
    double ry,
    int count,
    double phaseStep,
    double dotR,
    List<Color> colors,
    double alpha,
  ) {
    final base = pulse * math.pi * 2;
    for (var i = 0; i < count; i++) {
      final a = base + i * phaseStep;
      canvas.drawCircle(
        Offset(core.dx + math.cos(a) * rx, core.dy + math.sin(a) * ry),
        dotR,
        Paint()
          ..color = colors[i % colors.length].withValues(alpha: alpha),
      );
    }
  }

  @override
  bool shouldRepaint(covariant OniPinMarkPainter old) {
    return old.branding.effect != branding.effect ||
        (old.pulse - pulse).abs() > 0.004;
  }
}
