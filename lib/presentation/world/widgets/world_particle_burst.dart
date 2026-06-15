import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../world_presentation_pack.dart';

/// モーメント（リビール・捕獲等）用の短いパーティクルバースト。
class WorldParticleBurst extends StatefulWidget {
  const WorldParticleBurst({
    required this.pack,
    required this.trigger,
    this.duration = const Duration(milliseconds: 720),
    super.key,
  });

  final WorldPresentationPack pack;
  final int trigger;
  final Duration duration;

  @override
  State<WorldParticleBurst> createState() => _WorldParticleBurstState();
}

class _WorldParticleBurstState extends State<WorldParticleBurst>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: widget.duration,
  );

  @override
  void didUpdateWidget(covariant WorldParticleBurst oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.trigger != widget.trigger) {
      _c.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: AnimatedBuilder(
        animation: _c,
        builder: (_, __) {
          if (_c.value == 0 && !_c.isAnimating) {
            return const SizedBox.shrink();
          }
          return CustomPaint(
            painter: _BurstPainter(
              pack: widget.pack,
              t: Curves.easeOut.transform(_c.value),
            ),
            child: const SizedBox.expand(),
          );
        },
      ),
    );
  }
}

class _BurstPainter extends CustomPainter {
  _BurstPainter({required this.pack, required this.t});

  final WorldPresentationPack pack;
  final double t;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height * 0.42);
    const count = 18;
    for (var i = 0; i < count; i++) {
      final a = (i / count) * math.pi * 2;
      final dist = size.shortestSide * 0.35 * t;
      final p = center + Offset(math.cos(a) * dist, math.sin(a) * dist);
      final alpha = (1 - t).clamp(0.0, 1.0);
      final color = switch (pack.momentParticle) {
        WorldParticleKind.neonPop => i.isEven ? pack.accent : pack.accentMuted,
        WorldParticleKind.dataBits => pack.accent,
        WorldParticleKind.goldInk => pack.accent,
        WorldParticleKind.lightRays => pack.accentMuted,
        _ => pack.accent,
      };
      final radius = switch (pack.momentParticle) {
        WorldParticleKind.dataBits => 2.0,
        WorldParticleKind.goldInk => 1.5 + (i % 2),
        WorldParticleKind.neonPop => 4.0,
        _ => 2.5,
      };
      canvas.drawCircle(
        p,
        radius * (1 - t * 0.5),
        Paint()..color = color.withValues(alpha: alpha * 0.65),
      );
    }
    if (pack.momentParticle == WorldParticleKind.smokeRain) {
      canvas.drawRect(
        Rect.fromCenter(
          center: center,
          width: size.width * t,
          height: 4,
        ),
        Paint()..color = pack.accentMuted.withValues(alpha: 0.2 * (1 - t)),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _BurstPainter old) => old.t != t;
}
