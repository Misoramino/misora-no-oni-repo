import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../theme/world_profile.dart';
import '../world_presentation_catalog.dart';
import '../world_presentation_pack.dart';

/// 世界観別ローディング（接続・同期・読み込み）。
class WorldLoading extends StatefulWidget {
  const WorldLoading({
    required this.profile,
    this.label,
    this.size = 48,
    super.key,
  });

  final WorldProfile profile;
  final String? label;
  final double size;

  @override
  State<WorldLoading> createState() => _WorldLoadingState();
}

class _WorldLoadingState extends State<WorldLoading>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1400),
  )..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final pack = WorldPresentationCatalog.of(widget.profile);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: widget.size,
          height: widget.size,
          child: AnimatedBuilder(
            animation: _c,
            builder: (context, child) => CustomPaint(
              painter: _WorldLoadingPainter(
                pack: pack,
                progress: _c.value,
              ),
            ),
          ),
        ),
        if (widget.label != null) ...[
          const SizedBox(height: 12),
          Text(
            widget.label!,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: pack.accent.withValues(alpha: 0.85),
                ),
          ),
        ],
      ],
    );
  }
}

class _WorldLoadingPainter extends CustomPainter {
  _WorldLoadingPainter({required this.pack, required this.progress});

  final WorldPresentationPack pack;
  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final c = Offset(size.width / 2, size.height / 2);
    final r = size.shortestSide / 2 - 2;
    switch (pack.loadingKind) {
      case WorldLoadingKind.horrorTape:
        _tape(canvas, size);
      case WorldLoadingKind.popBounce:
        canvas.drawCircle(
          c + Offset(0, -8 * math.sin(progress * math.pi * 2)),
          r * 0.35,
          Paint()..color = pack.accent,
        );
      case WorldLoadingKind.cyberPulse:
        canvas.drawCircle(
          c,
          r * (0.5 + 0.2 * math.sin(progress * math.pi * 2)),
          Paint()
            ..color = pack.accent.withValues(alpha: 0.5)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2,
        );
      case WorldLoadingKind.tacticalGrid:
        _grid(canvas, size);
      case WorldLoadingKind.magicalSigil:
        _sigil(canvas, c, r);
      case WorldLoadingKind.astronomyOrbit:
        _orbit(canvas, c, r);
      case WorldLoadingKind.zenBrush:
        _brush(canvas, size);
      case WorldLoadingKind.royalSeal:
        _seal(canvas, c, r);
    }
  }

  void _tape(Canvas canvas, Size size) {
    final barH = size.height * 0.12;
    final y = size.height * progress;
    canvas.drawRect(
      Rect.fromLTWH(0, y, size.width, barH),
      Paint()..color = pack.accent.withValues(alpha: 0.25),
    );
  }

  void _grid(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = pack.accent.withValues(alpha: 0.2)
      ..strokeWidth = 0.8;
    final step = size.width / 4;
    for (var i = 0; i <= 4; i++) {
      canvas.drawLine(Offset(i * step, 0), Offset(i * step, size.height), paint);
      canvas.drawLine(Offset(0, i * step), Offset(size.width, i * step), paint);
    }
  }

  void _sigil(Canvas canvas, Offset c, double r) {
    final paint = Paint()
      ..color = pack.accent.withValues(alpha: 0.7)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    for (var i = 0; i < 3; i++) {
      final a = progress * math.pi * 2 + i * math.pi * 2 / 3;
      canvas.drawCircle(
        c + Offset(math.cos(a) * r * 0.3, math.sin(a) * r * 0.3),
        r * 0.55,
        paint,
      );
    }
  }

  void _orbit(Canvas canvas, Offset c, double r) {
    final a = progress * math.pi * 2;
    canvas.drawCircle(
      c,
      r * 0.7,
      Paint()
        ..color = pack.accentMuted.withValues(alpha: 0.4)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1,
    );
    canvas.drawCircle(
      c + Offset(math.cos(a) * r * 0.7, math.sin(a) * r * 0.7),
      3,
      Paint()..color = pack.accent,
    );
  }

  void _brush(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = pack.accent.withValues(alpha: 0.5)
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;
    final w = size.width * (0.2 + progress * 0.6);
    canvas.drawLine(
      Offset(size.width * 0.15, size.height * 0.55),
      Offset(size.width * 0.15 + w, size.height * 0.55),
      paint,
    );
  }

  void _seal(Canvas canvas, Offset c, double r) {
    canvas.drawCircle(
      c,
      r * 0.65,
      Paint()
        ..color = pack.accent.withValues(alpha: 0.35)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
    final a = progress * math.pi * 2;
    canvas.drawArc(
      Rect.fromCircle(center: c, radius: r * 0.65),
      a,
      math.pi / 3,
      false,
      Paint()
        ..color = pack.accent
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5,
    );
  }

  @override
  bool shouldRepaint(covariant _WorldLoadingPainter old) =>
      old.progress != progress;
}
