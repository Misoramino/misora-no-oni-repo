import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/world_launch_branding.dart';

/// ONI PIN 図形マーク（位置ピン + 角 + 赤芯）。テーマごとに色・装飾のみ変化。
class ThemedGeometricLogo extends StatelessWidget {
  const ThemedGeometricLogo({
    required this.branding,
    this.size = 88,
    this.pulse = 0,
    super.key,
  });

  final WorldLaunchBranding branding;
  final double size;
  /// 0–1。心拍・明滅など（起動アニメ用）。
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
    final cx = size.width / 2;
    final cy = size.height / 2;
    final r = size.width * 0.34;
    final beat = 0.5 + 0.5 * math.sin(pulse * math.pi * 2);

    _paintThemeBackdrop(canvas, size, cx, cy, r, beat);

    // 外環（ピン輪郭）
    canvas.drawCircle(
      Offset(cx, cy),
      r,
      Paint()
        ..color = branding.logoRingColor(branding.accent)
        ..style = PaintingStyle.stroke
        ..strokeWidth = size.width * 0.028,
    );

    // 角（鬼）
    final horn = Paint()
      ..color = branding.accent.withValues(alpha: 0.92)
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.width * 0.022
      ..strokeCap = StrokeCap.round;
    final hornY = cy - r * 0.72;
    canvas.drawArc(
      Rect.fromCenter(
        center: Offset(cx - r * 0.38, hornY),
        width: r * 0.5,
        height: r * 0.42,
      ),
      math.pi * 0.15,
      math.pi * 0.55,
      false,
      horn,
    );
    canvas.drawArc(
      Rect.fromCenter(
        center: Offset(cx + r * 0.38, hornY),
        width: r * 0.5,
        height: r * 0.42,
      ),
      math.pi * 0.7,
      math.pi * 0.55,
      false,
      horn,
    );

    // 赤い追跡芯
    final coreR = size.width * (0.09 + beat * 0.015);
    canvas.drawCircle(
      Offset(cx, cy),
      coreR + 4,
      Paint()..color = branding.pulseColor.withValues(alpha: 0.18 + beat * 0.12),
    );
    canvas.drawCircle(
      Offset(cx, cy),
      coreR,
      Paint()..color = const Color(0xFFE53935),
    );

    _paintThemeForeground(canvas, size, cx, cy, r, beat);
  }

  void _paintThemeBackdrop(
    Canvas canvas,
    Size size,
    double cx,
    double cy,
    double r,
    double beat,
  ) {
    switch (branding.effect) {
      case LaunchEffectKind.cyber:
        canvas.drawCircle(
          Offset(cx, cy),
          r + 10,
          Paint()
            ..color = branding.secondaryAccent.withValues(alpha: 0.12)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 0.8,
        );
      case LaunchEffectKind.magical:
        canvas.drawCircle(
          Offset(cx, cy),
          r + 14 + beat * 3,
          Paint()..color = branding.glow.withValues(alpha: 0.22),
        );
      case LaunchEffectKind.astronomy:
        canvas.drawOval(
          Rect.fromCenter(
            center: Offset(cx, cy),
            width: r * 2.4,
            height: r * 0.85,
          ),
          Paint()
            ..color = branding.accent.withValues(alpha: 0.15)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 0.7,
        );
      default:
        break;
    }
  }

  void _paintThemeForeground(
    Canvas canvas,
    Size size,
    double cx,
    double cy,
    double r,
    double beat,
  ) {
    switch (branding.effect) {
      case LaunchEffectKind.horror:
        canvas.drawCircle(
          Offset(cx, cy),
          r + 8 + beat * 6,
          Paint()
            ..color = branding.pulseColor.withValues(alpha: 0.12 * beat)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1,
        );
      case LaunchEffectKind.pop:
        canvas.drawCircle(
          Offset(cx, cy),
          r + 6,
          Paint()
            ..color = branding.secondaryAccent.withValues(alpha: 0.25)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.2,
        );
      case LaunchEffectKind.tactical:
        final mark = Paint()
          ..color = branding.accent.withValues(alpha: 0.45)
          ..strokeWidth = 0.8;
        canvas.drawLine(
          Offset(cx - r * 0.35, cy),
          Offset(cx + r * 0.35, cy),
          mark,
        );
        canvas.drawLine(
          Offset(cx, cy - r * 0.35),
          Offset(cx, cy + r * 0.35),
          mark,
        );
      case LaunchEffectKind.magical:
        for (var i = 0; i < 4; i++) {
          final a = pulse * math.pi * 2 + i * math.pi / 2;
          canvas.drawCircle(
            Offset(cx + math.cos(a) * (r + 10), cy + math.sin(a) * (r + 10)),
            1.8,
            Paint()
              ..color = branding.particleColor.withValues(alpha: 0.5 + beat * 0.3),
          );
        }
      case LaunchEffectKind.astronomy:
        final rng = math.Random(3);
        for (var i = 0; i < 6; i++) {
          canvas.drawCircle(
            Offset(
              cx + (rng.nextDouble() - 0.5) * r * 1.6,
              cy + (rng.nextDouble() - 0.5) * r * 1.6,
            ),
            0.9,
            Paint()..color = Colors.white.withValues(alpha: 0.35 + beat * 0.2),
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

extension on WorldLaunchBranding {
  Color logoRingColor(Color fallback) {
    return switch (effect) {
      LaunchEffectKind.cyber => accent.withValues(alpha: 0.95),
      LaunchEffectKind.horror => Colors.white.withValues(alpha: 0.88),
      LaunchEffectKind.pop => accent.withValues(alpha: 0.85),
      LaunchEffectKind.tactical => accent,
      LaunchEffectKind.magical => const Color(0xFFF3E5AB),
      LaunchEffectKind.astronomy => accent.withValues(alpha: 0.9),
    };
  }
}
