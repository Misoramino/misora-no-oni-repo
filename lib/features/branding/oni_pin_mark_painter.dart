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
      ..color = branding.glow.withValues(alpha: 0.34 + beat * 0.12)
      ..style = PaintingStyle.fill;
    canvas.drawPath(layers.leftHorn, glowFill);
    canvas.drawPath(layers.rightHorn, glowFill);

    final fill = Paint()..color = branding.hornFill;
    canvas.drawPath(layers.leftHorn, fill);
    canvas.drawPath(layers.rightHorn, fill);
    canvas.drawPath(
      layers.leftHorn,
      Paint()
        ..color = branding.pinStroke.withValues(alpha: 0.35)
        ..style = PaintingStyle.stroke
        ..strokeWidth = layers.strokeW * 0.35,
    );
    canvas.drawPath(
      layers.rightHorn,
      Paint()
        ..color = branding.pinStroke.withValues(alpha: 0.35)
        ..style = PaintingStyle.stroke
        ..strokeWidth = layers.strokeW * 0.35,
    );

    switch (branding.effect) {
      case LaunchEffectKind.cyber:
        final edge = Paint()
          ..color = branding.accent.withValues(alpha: 0.45 + beat * 0.25)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1;
        canvas.drawPath(layers.leftHorn, edge);
        canvas.drawPath(layers.rightHorn, edge);
      case LaunchEffectKind.horror:
        final bleed = Paint()
          ..color = branding.coreColor.withValues(alpha: 0.12 * beat)
          ..style = PaintingStyle.fill
          ..blendMode = BlendMode.plus;
        canvas.drawPath(layers.leftHorn, bleed);
        canvas.drawPath(layers.rightHorn, bleed);
      case LaunchEffectKind.pop:
        _sparkleHornTips(canvas, layers, beat);
      case LaunchEffectKind.magical:
        _sparkleHornTips(canvas, layers, beat, gold: true);
      case LaunchEffectKind.tactical:
      case LaunchEffectKind.astronomy:
        break;
    }
  }

  void _sparkleHornTips(
    Canvas canvas,
    OniPinMarkLayers layers,
    double beat, {
    bool gold = false,
  }) {
    final w = layers.size.width;
    final h = layers.size.height;
    final c1 = gold ? branding.particleColor : branding.secondaryAccent;
    final c2 = gold ? branding.accent : branding.accent;
    canvas.drawCircle(
      Offset(w * 0.26, h * 0.1),
      2.2 + beat,
      Paint()..color = c1.withValues(alpha: 0.75),
    );
    canvas.drawCircle(
      Offset(w * 0.74, h * 0.1),
      2 + beat * 0.8,
      Paint()..color = c2.withValues(alpha: 0.7),
    );
  }

  void _paintPinOutline(Canvas canvas, OniPinMarkLayers layers, double beat) {
    final sw = layers.strokeW;
    canvas.drawPath(
      layers.outline,
      Paint()
        ..color = branding.glow.withValues(alpha: 0.42 + beat * 0.18)
        ..style = PaintingStyle.stroke
        ..strokeWidth = sw + 3.2
        ..strokeJoin = StrokeJoin.round
        ..strokeCap = StrokeCap.round,
    );
    if (branding.effect == LaunchEffectKind.cyber && beat > 0.85) {
      canvas.drawPath(
        layers.outline,
        Paint()
          ..color = branding.accent.withValues(alpha: 0.35)
          ..style = PaintingStyle.stroke
          ..strokeWidth = sw * 0.6
          ..strokeJoin = StrokeJoin.round,
      );
    }
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
    final core = layers.core;
    final r = layers.coreR;

    switch (branding.effect) {
      case LaunchEffectKind.astronomy:
        for (var i = 0; i < 4; i++) {
          final scale = 1.45 + i * 0.28 + beat * 0.08;
          _strokeCircle(
            canvas,
            core,
            r * scale,
            branding.accent.withValues(alpha: 0.32 - i * 0.04 + beat * 0.1),
            0.9,
          );
        }
      case LaunchEffectKind.cyber:
        _strokeCircle(
          canvas,
          core,
          r * 1.4,
          branding.secondaryAccent.withValues(alpha: 0.28 + beat * 0.15),
          0.75,
        );
        _strokeCircle(
          canvas,
          core,
          r * 1.75,
          branding.accent.withValues(alpha: 0.12 + beat * 0.08),
          0.5,
        );
      case LaunchEffectKind.magical:
        canvas.drawCircle(
          core,
          r * (1.3 + beat * 0.15),
          Paint()..color = branding.glow.withValues(alpha: 0.28 + beat * 0.2),
        );
      case LaunchEffectKind.horror:
        _strokeCircle(
          canvas,
          core,
          r * 1.5,
          branding.coreGlow.withValues(alpha: 0.15 * beat),
          1,
        );
      case LaunchEffectKind.pop:
        canvas.drawCircle(
          core,
          r * 1.2,
          Paint()..color = branding.secondaryAccent.withValues(alpha: 0.2 + beat * 0.15),
        );
      case LaunchEffectKind.tactical:
        _strokeCircle(
          canvas,
          core,
          r * 1.25,
          branding.accent.withValues(alpha: 0.25),
          0.55,
        );
    }

    canvas.drawCircle(
      core,
      glowR,
      Paint()..color = branding.coreGlow.withValues(alpha: 0.42 + beat * 0.2),
    );
    canvas.drawCircle(core, r, Paint()..color = branding.coreColor);
    canvas.drawCircle(
      core,
      r * 0.42,
      Paint()
        ..color = Colors.white.withValues(alpha: 0.35 + beat * 0.25),
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
            ..color = branding.accent.withValues(alpha: 0.28)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 0.9,
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
          w * 0.45,
          w * 0.32,
          6,
          1.05,
          2.6,
          [
            branding.secondaryAccent,
            branding.accent,
            branding.particleColor,
            branding.pulseColor,
          ],
          0.55 + beat * 0.4,
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
          w * 0.42,
          w * 0.42,
          7,
          0.9,
          2.4,
          [branding.particleColor, branding.accent, branding.secondaryAccent],
          0.55 + beat * 0.4,
        );
      case LaunchEffectKind.astronomy:
        final tw = 0.4 + beat * 0.55;
        for (var i = 0; i < OniPinMarkGeometry.astronomySparkleNorm.length; i++) {
          final n = OniPinMarkGeometry.astronomySparkleNorm[i];
          final phase = pulse * math.pi * 2 + i;
          canvas.drawCircle(
            Offset(
              core.dx + n.dx * w + math.cos(phase) * 1.5,
              core.dy + n.dy * w + math.sin(phase) * 1.5,
            ),
            0.9 + (i.isEven ? 0.5 : 0),
            Paint()
              ..color = (i.isEven ? branding.pulseColor : Colors.white)
                  .withValues(alpha: 0.4 * tw),
          );
        }
      case LaunchEffectKind.cyber:
        final scanY = core.dy + (beat - 0.5) * w * 0.9;
        canvas.drawLine(
          Offset(0, scanY),
          Offset(w, scanY),
          Paint()
            ..color = branding.accent.withValues(alpha: 0.45)
            ..strokeWidth = 1.4,
        );
        canvas.drawLine(
          Offset(0, scanY + 3),
          Offset(w, scanY + 3),
          Paint()
            ..color = branding.scanLineColor.withValues(alpha: 0.25)
            ..strokeWidth = 0.8,
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
