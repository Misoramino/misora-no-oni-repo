import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/world_profile.dart';

/// 世界観別の遷移オーバーレイ（スキャンライン・フリッカー等）。
class WorldTransitionFxOverlay extends StatelessWidget {
  const WorldTransitionFxOverlay({
    required this.profile,
    required this.progress,
    super.key,
  });

  final WorldProfile? profile;
  final double progress;

  @override
  Widget build(BuildContext context) {
    if (profile == null) return const SizedBox.shrink();
    final p = progress.clamp(0.0, 1.0);
    final inv = 1 - p;

    return IgnorePointer(
      child: Stack(
        fit: StackFit.expand,
        children: [
          switch (profile!) {
            WorldProfile.sciFi => CustomPaint(
                painter: _ScanWipePainter(progress: p),
              ),
            WorldProfile.horror when p < 0.22 => ColoredBox(
                color: Colors.black.withValues(alpha: inv * 0.75),
              ),
            WorldProfile.horror => CustomPaint(
                painter: _VhsNoisePainter(seed: p),
              ),
            WorldProfile.magical => CustomPaint(
                painter: _SparklePainter(progress: p),
              ),
            WorldProfile.astronomy => CustomPaint(
                painter: _StarStreakPainter(progress: p),
              ),
            WorldProfile.arg => CustomPaint(
                painter: _HorizontalScanPainter(progress: p),
              ),
            WorldProfile.sport => ColoredBox(
                color: Colors.white.withValues(alpha: (1 - p) * 0.12),
              ),
            WorldProfile.japaneseLuxury => CustomPaint(
                painter: _ShojiWipePainter(progress: p),
              ),
            WorldProfile.westernLuxury => CustomPaint(
                painter: _CurtainGildPainter(progress: p),
              ),
          },
        ],
      ),
    );
  }
}

class _ScanWipePainter extends CustomPainter {
  _ScanWipePainter({required this.progress});

  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final x = size.width * progress;
    final paint = Paint()
      ..shader = LinearGradient(
        colors: [
          Colors.transparent,
          const Color(0xFF00E5FF).withValues(alpha: 0.35),
          Colors.transparent,
        ],
      ).createShader(Rect.fromLTWH(x - 24, 0, 48, size.height));
    canvas.drawRect(Rect.fromLTWH(x - 24, 0, 48, size.height), paint);
    final line = Paint()..color = const Color(0xFF00E5FF).withValues(alpha: 0.18);
    for (var y = 0.0; y < size.height; y += 5) {
      canvas.drawRect(Rect.fromLTWH(0, y, size.width, 1), line);
    }
  }

  @override
  bool shouldRepaint(covariant _ScanWipePainter old) => old.progress != progress;
}

class _VhsNoisePainter extends CustomPainter {
  _VhsNoisePainter({required this.seed});

  final double seed;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.white.withValues(alpha: 0.04);
    for (var i = 0; i < 40; i++) {
      final y = (seed * 997 + i * 37) % size.height;
      canvas.drawRect(Rect.fromLTWH(0, y, size.width, 1.2), paint);
    }
  }

  @override
  bool shouldRepaint(covariant _VhsNoisePainter old) => old.seed != seed;
}

class _SparklePainter extends CustomPainter {
  _SparklePainter({required this.progress});

  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = const Color(0xFFE040FB).withValues(alpha: 0.35);
    for (var i = 0; i < 8; i++) {
      final t = (progress + i * 0.11) % 1.0;
      final cx = size.width * (0.2 + i * 0.09);
      final cy = size.height * (0.25 + (i % 3) * 0.18);
      canvas.drawCircle(Offset(cx, cy), 2 + t * 4, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _SparklePainter old) => old.progress != progress;
}

class _StarStreakPainter extends CustomPainter {
  _StarStreakPainter({required this.progress});

  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final paint = Paint()
      ..color = const Color(0xFFFFD54F).withValues(alpha: 0.1)
      ..strokeWidth = 0.8;
    for (var i = 0; i < 6; i++) {
      final angle = i * 1.05 + progress * 1.2;
      final len = size.shortestSide * (0.08 + progress * 0.12);
      final end = center + Offset(math.cos(angle), math.sin(angle)) * len;
      canvas.drawLine(center, end, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _StarStreakPainter old) =>
      old.progress != progress;
}

class _HorizontalScanPainter extends CustomPainter {
  _HorizontalScanPainter({required this.progress});

  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final y = size.height * progress;
    final paint = Paint()
      ..color = const Color(0xFF78909C).withValues(alpha: 0.28);
    canvas.drawRect(Rect.fromLTWH(0, y - 1, size.width, 2), paint);
  }

  @override
  bool shouldRepaint(covariant _HorizontalScanPainter old) =>
      old.progress != progress;
}

/// 禅京都の遷移。以前は縦の障子パネル＋金の縦線で目立っていたため、
/// 縦線を排した「やわらかい墨のベール＋金の横刷毛＋金粉」に変更。
class _ShojiWipePainter extends CustomPainter {
  _ShojiWipePainter({required this.progress});

  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final inv = (1 - progress).clamp(0.0, 1.0);

    // 墨のやわらかいベール（フェードのみ・縦線なし）。
    final veil = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          const Color(0xFF1A1A14).withValues(alpha: 0.40 * inv),
          const Color(0xFF1A1A14).withValues(alpha: 0.26 * inv),
        ],
      ).createShader(rect);
    canvas.drawRect(rect, veil);

    // 中央を払う、やわらかな金の横刷毛（遷移の中盤で最も濃く）。
    final sweep = (1 - (progress - 0.5).abs() * 2).clamp(0.0, 1.0);
    final brush = Paint()
      ..color = const Color(0xFFC9A227).withValues(alpha: 0.16 * sweep)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    final y = size.height * 0.5;
    final path = Path()
      ..moveTo(0, y)
      ..quadraticBezierTo(size.width * 0.5, y - 16 * inv, size.width, y);
    canvas.drawPath(path, brush);

    // 漂う金粉。
    final dust = Paint()
      ..color = const Color(0xFFFFD54F).withValues(alpha: 0.10 * inv);
    for (var i = 0; i < 6; i++) {
      final px = size.width * ((0.12 + i * 0.16 + progress * 0.05) % 1);
      final py = size.height * (0.22 + (i % 3) * 0.24);
      canvas.drawCircle(Offset(px, py), 1.4 + i * 0.25, dust);
    }
  }

  @override
  bool shouldRepaint(covariant _ShojiWipePainter old) => old.progress != progress;
}

class _CurtainGildPainter extends CustomPainter {
  _CurtainGildPainter({required this.progress});

  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final inv = 1 - progress;
    final leftW = size.width * 0.5 * inv;
    final rightX = size.width - leftW;
    final curtain = Paint()..color = const Color(0xFF101418).withValues(alpha: 0.72);
    canvas.drawRect(Rect.fromLTWH(0, 0, leftW, size.height), curtain);
    canvas.drawRect(Rect.fromLTWH(rightX, 0, leftW, size.height), curtain);
    final gild = Paint()
      ..shader = LinearGradient(
        colors: [
          const Color(0xFFD4AF37).withValues(alpha: 0.35),
          Colors.transparent,
        ],
      ).createShader(Rect.fromLTWH(leftW - 8, 0, 16, size.height));
    canvas.drawRect(Rect.fromLTWH(leftW - 8, 0, 16, size.height), gild);
    canvas.drawRect(Rect.fromLTWH(rightX - 8, 0, 16, size.height), gild);
    final light = Paint()..color = const Color(0xFFECEFF1).withValues(alpha: 0.08 * progress);
    canvas.drawRect(Rect.fromLTWH(leftW, 0, rightX - leftW, size.height), light);
  }

  @override
  bool shouldRepaint(covariant _CurtainGildPainter old) =>
      old.progress != progress;
}
