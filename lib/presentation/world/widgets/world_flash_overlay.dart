import 'package:flutter/material.dart';

import '../world_presentation_pack.dart';

/// 世界観別フェーズフラッシュ（起動演出の再利用をやめる）。
class WorldFlashOverlay extends StatelessWidget {
  const WorldFlashOverlay({
    required this.pack,
    required this.progress,
    this.headline,
    super.key,
  });

  final WorldPresentationPack pack;
  final double progress;
  final String? headline;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      foregroundPainter: _WorldFlashPainter(
        pack: pack,
        progress: progress,
      ),
      child: headline == null
          ? null
          : Center(
              child: Opacity(
                opacity: Curves.easeOut.transform(progress),
                child: Text(
                  headline!,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        color: Colors.white.withValues(alpha: 0.92),
                        fontWeight: pack.headlineWeight,
                        letterSpacing: pack.headlineLetterSpacing,
                      ),
                ),
              ),
            ),
    );
  }
}

class _WorldFlashPainter extends CustomPainter {
  _WorldFlashPainter({required this.pack, required this.progress});

  final WorldPresentationPack pack;
  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final alpha = (1 - progress) * 0.85;
    canvas.drawRect(
      Offset.zero & size,
      Paint()..color = pack.scaffoldTop.withValues(alpha: alpha.clamp(0.0, 0.9)),
    );

    switch (pack.flashKind) {
      case WorldFlashKind.vhsFlicker:
        if (progress < 0.3) {
          canvas.drawRect(
            Rect.fromLTWH(0, size.height * 0.4, size.width, 2),
            Paint()..color = Colors.white.withValues(alpha: 0.15),
          );
        }
      case WorldFlashKind.popBurst:
        canvas.drawCircle(
          Offset(size.width / 2, size.height / 2),
          size.shortestSide * 0.4 * progress,
          Paint()..color = pack.accent.withValues(alpha: 0.25 * (1 - progress)),
        );
      case WorldFlashKind.cyberGlitch:
        for (var i = 0; i < 4; i++) {
          final y = (size.height * (0.2 + i * 0.18) + progress * 40) % size.height;
          canvas.drawRect(
            Rect.fromLTWH(0, y, size.width, 3),
            Paint()..color = pack.accent.withValues(alpha: 0.35 * (1 - progress)),
          );
        }
      case WorldFlashKind.tacticalScan:
        canvas.drawRect(
          Rect.fromLTWH(0, size.height * progress, size.width, 6),
          Paint()..color = pack.accent.withValues(alpha: 0.3),
        );
      case WorldFlashKind.sigilPulse:
        _ring(canvas, size, pack.accent, progress);
      case WorldFlashKind.cosmicWave:
        _ring(canvas, size, pack.accentMuted, progress * 1.2);
      case WorldFlashKind.inkWash:
        canvas.drawCircle(
          Offset(size.width / 2, size.height / 2),
          size.shortestSide * 0.5 * progress,
          Paint()..color = pack.dangerColor.withValues(alpha: 0.35 * (1 - progress)),
        );
      case WorldFlashKind.gildedCurtain:
        final w = size.width * progress;
        canvas.drawRect(
          Rect.fromLTWH(0, 0, w / 2, size.height),
          Paint()..color = pack.accent.withValues(alpha: 0.2 * (1 - progress)),
        );
        canvas.drawRect(
          Rect.fromLTWH(size.width - w / 2, 0, w / 2, size.height),
          Paint()..color = pack.accent.withValues(alpha: 0.2 * (1 - progress)),
        );
    }
  }

  void _ring(Canvas canvas, Size size, Color color, double t) {
    canvas.drawCircle(
      Offset(size.width / 2, size.height / 2),
      size.shortestSide * 0.35 * t,
      Paint()
        ..color = color.withValues(alpha: 0.4 * (1 - t))
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3,
    );
  }

  @override
  bool shouldRepaint(covariant _WorldFlashPainter old) =>
      old.progress != progress;
}
