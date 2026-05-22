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
          ..color = branding.accent.withValues(alpha: 0.22 + beat * 0.1)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 0.8;
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
    final outlineGlow = branding.effect == LaunchEffectKind.tactical
        ? 0.26 + beat * 0.06
        : branding.effect == LaunchEffectKind.cyber
            ? 0.32 + beat * 0.1
            : 0.4 + beat * 0.16;
    canvas.drawPath(
      layers.outline,
      Paint()
        ..color = branding.glow.withValues(alpha: outlineGlow)
        ..style = PaintingStyle.stroke
        ..strokeWidth = sw + 3.2
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
    final core = layers.core;
    final r = layers.coreR;

    switch (branding.effect) {
      case LaunchEffectKind.astronomy:
        for (var i = 0; i < 3; i++) {
          final scale = 1.5 + i * 0.32 + beat * 0.06;
          _strokeCircle(
            canvas,
            core,
            r * scale,
            branding.coreGlow.withValues(alpha: 0.28 - i * 0.06 + beat * 0.08),
            0.75,
          );
        }
      case LaunchEffectKind.cyber:
        _strokeCircle(
          canvas,
          core,
          r * 1.4,
          branding.accent.withValues(alpha: 0.22 + beat * 0.1),
          0.65,
        );
        _strokeCircle(
          canvas,
          core,
          r * 1.65,
          branding.secondaryAccent.withValues(alpha: 0.1 + beat * 0.06),
          0.45,
        );
      case LaunchEffectKind.magical:
        canvas.save();
        canvas.translate(core.dx, core.dy);
        canvas.rotate(pulse * math.pi * 0.25);
        _strokePolygon(
          canvas,
          _logoStar(Offset.zero, r * 2.2, 5),
          branding.accent.withValues(alpha: 0.35 + beat * 0.15),
          0.7,
        );
        canvas.restore();
        canvas.drawCircle(
          core,
          r * (1.35 + beat * 0.12),
          Paint()..color = branding.glow.withValues(alpha: 0.3 + beat * 0.18),
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
          r * 1.25,
          Paint()..color = branding.coreGlow.withValues(alpha: 0.35 + beat * 0.15),
        );
      case LaunchEffectKind.tactical:
        break;
    }

    final glowAlpha = branding.effect == LaunchEffectKind.tactical
        ? 0.2 + beat * 0.08
        : 0.38 + beat * 0.16;
    canvas.drawCircle(
      core,
      glowR,
      Paint()..color = branding.coreGlow.withValues(alpha: glowAlpha),
    );
    canvas.drawCircle(core, r, Paint()..color = branding.coreColor);
    final highlight = branding.effect == LaunchEffectKind.tactical
        ? branding.pinStroke.withValues(alpha: 0.22 + beat * 0.08)
        : Colors.white.withValues(alpha: 0.32 + beat * 0.2);
    canvas.drawCircle(core, r * 0.42, Paint()..color = highlight);
  }

  void _paintBackdrop(Canvas canvas, OniPinMarkLayers layers, double beat) {
    final core = layers.core;
    final w = layers.size.width;
    switch (branding.effect) {
      case LaunchEffectKind.cyber:
        _strokeCircle(
          canvas,
          core,
          w * 0.34,
          branding.accent.withValues(alpha: 0.12),
          0.55,
        );
      case LaunchEffectKind.magical:
        _strokeCircle(
          canvas,
          core,
          w * 0.4,
          branding.accent.withValues(alpha: 0.18),
          0.7,
        );
      case LaunchEffectKind.astronomy:
        _paintWarpStreaks(canvas, core, w, beat);
      case LaunchEffectKind.horror:
        canvas.drawCircle(
          core,
          w * 0.42,
          Paint()..color = branding.coreGlow.withValues(alpha: 0.06),
        );
      case LaunchEffectKind.pop:
        canvas.drawCircle(
          core,
          w * 0.32,
          Paint()..color = branding.accent.withValues(alpha: 0.12),
        );
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
        break;
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
        final tw = 0.35 + beat * 0.5;
        for (var i = 0; i < OniPinMarkGeometry.astronomySparkleNorm.length; i++) {
          final n = OniPinMarkGeometry.astronomySparkleNorm[i];
          final phase = pulse * math.pi * 2 + i;
          canvas.drawCircle(
            Offset(
              core.dx + n.dx * w + math.cos(phase) * 1.2,
              core.dy + n.dy * w + math.sin(phase) * 1.2,
            ),
            0.7 + (i.isEven ? 0.4 : 0),
            Paint()
              ..color = branding.particleColor.withValues(alpha: 0.45 * tw),
          );
        }
      case LaunchEffectKind.cyber:
        final scanY = core.dy + (beat - 0.5) * w * 0.5;
        canvas.drawLine(
          Offset(0, scanY),
          Offset(w, scanY),
          Paint()
            ..color = branding.accent.withValues(alpha: 0.18)
            ..strokeWidth = 0.9,
        );
    }
  }

  Path _logoStar(Offset c, double r, int points) {
    final p = Path();
    for (var i = 0; i < points * 2; i++) {
      final rad = i.isEven ? r : r * 0.45;
      final a = -math.pi / 2 + i * math.pi / points;
      final pt = Offset(c.dx + math.cos(a) * rad, c.dy + math.sin(a) * rad);
      if (i == 0) {
        p.moveTo(pt.dx, pt.dy);
      } else {
        p.lineTo(pt.dx, pt.dy);
      }
    }
    p.close();
    return p;
  }

  void _strokePolygon(Canvas canvas, Path path, Color color, double width) {
    canvas.drawPath(
      path,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = width
        ..strokeJoin = StrokeJoin.round,
    );
  }

  void _paintWarpStreaks(Canvas canvas, Offset core, double w, double beat) {
    for (var i = 0; i < 8; i++) {
      final ang = i * math.pi / 4 + pulse * 0.5;
      final len = w * (0.22 + beat * 0.08);
      final start = core;
      final end = Offset(core.dx + math.cos(ang) * len, core.dy + math.sin(ang) * len * 0.5);
      canvas.drawLine(
        start,
        end,
        Paint()
          ..color = branding.accent.withValues(alpha: 0.2 + beat * 0.15)
          ..strokeWidth = 0.7
          ..strokeCap = StrokeCap.round,
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
