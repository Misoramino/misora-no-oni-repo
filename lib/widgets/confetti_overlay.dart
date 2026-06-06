import 'dart:math' as math;

import 'package:flutter/material.dart';

/// 勝利演出などで上から舞い散る紙吹雪。
///
/// 一度だけ降らせたいときは [loop] を false にする（既定）。
class ConfettiOverlay extends StatefulWidget {
  const ConfettiOverlay({
    super.key,
    this.pieceCount = 90,
    this.colors,
    this.duration = const Duration(milliseconds: 2600),
    this.loop = false,
  });

  final int pieceCount;
  final List<Color>? colors;
  final Duration duration;
  final bool loop;

  @override
  State<ConfettiOverlay> createState() => _ConfettiOverlayState();
}

class _ConfettiOverlayState extends State<ConfettiOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: widget.duration,
  );
  late final List<_Piece> _pieces;

  static const _defaultColors = [
    Color(0xFFFFC107),
    Color(0xFFFF5252),
    Color(0xFF40C4FF),
    Color(0xFF69F0AE),
    Color(0xFFE040FB),
    Color(0xFFFFFFFF),
  ];

  @override
  void initState() {
    super.initState();
    final rng = math.Random();
    final palette = widget.colors ?? _defaultColors;
    _pieces = List.generate(widget.pieceCount, (i) {
      return _Piece(
        x: rng.nextDouble(),
        startDelay: rng.nextDouble() * 0.25,
        fallSpan: 0.7 + rng.nextDouble() * 0.3,
        drift: (rng.nextDouble() - 0.5) * 0.35,
        rotations: 1 + rng.nextDouble() * 4,
        size: 6 + rng.nextDouble() * 8,
        color: palette[rng.nextInt(palette.length)],
        wobble: 0.02 + rng.nextDouble() * 0.05,
      );
    });
    if (widget.loop) {
      _controller.repeat();
    } else {
      _controller.forward();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: RepaintBoundary(
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, _) {
            return CustomPaint(
              painter: _ConfettiPainter(_pieces, _controller.value),
              size: Size.infinite,
            );
          },
        ),
      ),
    );
  }
}

class _Piece {
  _Piece({
    required this.x,
    required this.startDelay,
    required this.fallSpan,
    required this.drift,
    required this.rotations,
    required this.size,
    required this.color,
    required this.wobble,
  });

  final double x;
  final double startDelay;
  final double fallSpan;
  final double drift;
  final double rotations;
  final double size;
  final Color color;
  final double wobble;
}

class _ConfettiPainter extends CustomPainter {
  _ConfettiPainter(this.pieces, this.t);

  final List<_Piece> pieces;
  final double t;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint();
    for (final p in pieces) {
      final local = ((t - p.startDelay) / p.fallSpan).clamp(0.0, 1.0);
      if (local <= 0) continue;
      final fade = local > 0.85 ? (1 - (local - 0.85) / 0.15) : 1.0;
      final dx = (p.x + p.drift * local +
              math.sin(local * math.pi * 6) * p.wobble) *
          size.width;
      final dy = (local * 1.15 - 0.1) * size.height;
      final angle = local * p.rotations * math.pi * 2;

      canvas.save();
      canvas.translate(dx, dy);
      canvas.rotate(angle);
      paint.color = p.color.withValues(alpha: fade.clamp(0.0, 1.0));
      final h = p.size * (0.5 + 0.5 * math.cos(angle));
      canvas.drawRect(
        Rect.fromCenter(center: Offset.zero, width: p.size, height: h),
        paint,
      );
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(_ConfettiPainter oldDelegate) => oldDelegate.t != t;
}
