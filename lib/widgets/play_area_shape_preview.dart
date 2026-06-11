import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../game/play_area.dart';

/// 保存済みプレイエリアのざっくり形状プレビュー。
class PlayAreaShapePreview extends StatelessWidget {
  const PlayAreaShapePreview({
    required this.area,
    this.height = 72,
    this.width = double.infinity,
    this.preserveAspect = false,
    super.key,
  });

  final PlayArea area;
  final double height;
  final double width;

  /// true のとき縦横比を維持して中央にフィット（ギャラリー用）。
  final bool preserveAspect;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SizedBox(
      width: width,
      height: height,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerHigh,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: theme.colorScheme.outlineVariant.withValues(alpha: 0.6),
          ),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: CustomPaint(
            painter: _PlayAreaShapePainter(
              area: area,
              fill: theme.colorScheme.primary.withValues(alpha: 0.22),
              stroke: theme.colorScheme.primary,
              preserveAspect: preserveAspect,
            ),
            child: const SizedBox.expand(),
          ),
        ),
      ),
    );
  }
}

class _PlayAreaShapePainter extends CustomPainter {
  _PlayAreaShapePainter({
    required this.area,
    required this.fill,
    required this.stroke,
    required this.preserveAspect,
  });

  final PlayArea area;
  final Color fill;
  final Color stroke;
  final bool preserveAspect;

  @override
  void paint(Canvas canvas, Size size) {
    final points = _normalizedPoints(size);
    if (points.length < 2) return;

    final path = Path()..addPolygon(points, true);
    canvas.drawPath(
      path,
      Paint()
        ..color = fill
        ..style = PaintingStyle.fill,
    );
    canvas.drawPath(
      path,
      Paint()
        ..color = stroke
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );
  }

  List<Offset> _normalizedPoints(Size size) {
    const pad = 8.0;
    final w = size.width - pad * 2;
    final h = size.height - pad * 2;
    if (w <= 0 || h <= 0) return const [];

    switch (area.type) {
      case PlayAreaType.circle:
        return _circleApprox(size, pad);
      case PlayAreaType.polygon:
        if (area.points.length < 3) return const [];
        var minLat = area.points.first.latitude;
        var maxLat = minLat;
        var minLng = area.points.first.longitude;
        var maxLng = minLng;
        for (final p in area.points) {
          if (p.latitude < minLat) minLat = p.latitude;
          if (p.latitude > maxLat) maxLat = p.latitude;
          if (p.longitude < minLng) minLng = p.longitude;
          if (p.longitude > maxLng) maxLng = p.longitude;
        }
        final dLat = (maxLat - minLat).abs();
        final dLng = (maxLng - minLng).abs();
        if (dLat < 1e-12 && dLng < 1e-12) {
          return [Offset(size.width / 2, size.height / 2)];
        }
        return _mapGeoPoints(
          size: size,
          pad: pad,
          w: w,
          h: h,
          minLat: minLat,
          maxLat: maxLat,
          minLng: minLng,
          maxLng: maxLng,
          dLat: dLat,
          dLng: dLng,
          geo: area.points,
        );
    }
  }

  List<Offset> _mapGeoPoints({
    required Size size,
    required double pad,
    required double w,
    required double h,
    required double minLat,
    required double maxLat,
    required double minLng,
    required double maxLng,
    required double dLat,
    required double dLng,
    required List<LatLng> geo,
  }) {
    if (!preserveAspect) {
      return [
        for (final p in geo)
          Offset(
            pad + (p.longitude - minLng) / (dLng == 0 ? 1 : dLng) * w,
            pad + (maxLat - p.latitude) / (dLat == 0 ? 1 : dLat) * h,
          ),
      ];
    }
    final scale = math.min(w / (dLng == 0 ? 1 : dLng), h / (dLat == 0 ? 1 : dLat));
    final drawW = dLng * scale;
    final drawH = dLat * scale;
    final ox = pad + (w - drawW) / 2;
    final oy = pad + (h - drawH) / 2;
    return [
      for (final p in geo)
        Offset(
          ox + (p.longitude - minLng) * scale,
          oy + (maxLat - p.latitude) * scale,
        ),
    ];
  }

  List<Offset> _circleApprox(Size size, double pad) {
    final w = size.width - pad * 2;
    final h = size.height - pad * 2;
    final r = (w < h ? w : h) / 2 * (preserveAspect ? 0.42 : 0.45);
    final cx = size.width / 2;
    final cy = size.height / 2;
    const segments = 32;
    return List.generate(segments, (i) {
      final t = i / segments * 2 * math.pi;
      return Offset(cx + r * math.cos(t), cy + r * math.sin(t));
    });
  }

  @override
  bool shouldRepaint(covariant _PlayAreaShapePainter oldDelegate) =>
      oldDelegate.area != area ||
      oldDelegate.preserveAspect != preserveAspect;
}
