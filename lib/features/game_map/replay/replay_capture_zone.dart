import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../../game/game_config.dart';
import '../../../game/match_event.dart';

/// 捕獲圏 1 件のライフサイクル（記録イベントから復元）。
class ReplayCaptureZone {
  ReplayCaptureZone({
    required this.id,
    required this.center,
    required this.placedAt,
    this.boundAt,
    this.durationSec = GameConfig.captureZoneDurationSeconds,
    this.ackTimes = const [],
  });

  final String id;
  final LatLng center;
  final DateTime placedAt;
  final DateTime? boundAt;
  final int durationSec;
  final List<DateTime> ackTimes;

  DateTime get activeUntil {
    final end = boundAt ?? placedAt;
    return end.add(Duration(seconds: durationSec));
  }

  DateTime get fadeEnd => activeUntil.add(const Duration(milliseconds: 800));
}

/// placed → ack(s) → bound → fade の視覚パラメータ。
class ReplayCaptureZoneVisual {
  const ReplayCaptureZoneVisual({
    required this.visible,
    required this.strokeWidth,
    required this.fillAlpha,
    required this.strokeAlpha,
    required this.pulseAck,
    required this.boundFlash,
  });

  final bool visible;
  final double strokeWidth;
  final double fillAlpha;
  final double strokeAlpha;
  final bool pulseAck;
  final bool boundFlash;
}

abstract final class ReplayCaptureZoneCatalog {
  static List<ReplayCaptureZone> fromEvents(List<MatchEvent> events) {
    final zones = <String, ReplayCaptureZone>{};
    final acks = <String, List<DateTime>>{};

    for (final e in events) {
      final type = e.type;
      if (type == 'capture_zone_ack') {
        final zoneId = _zoneIdFromAck(e);
        acks.putIfAbsent(zoneId, () => []).add(e.atUtc);
        continue;
      }
      if (!type.startsWith('capture_zone') && type != 'capture_zone_start') {
        continue;
      }
      if (type == 'capture_zone_bound') {
        final id = _zoneIdFromEvent(e);
        final existing = zones[id];
        if (existing != null) {
          zones[id] = ReplayCaptureZone(
            id: id,
            center: existing.center,
            placedAt: existing.placedAt,
            boundAt: e.atUtc,
            durationSec: existing.durationSec,
            ackTimes: existing.ackTimes,
          );
        } else {
          zones[id] = ReplayCaptureZone(
            id: id,
            center: e.position,
            placedAt: e.atUtc.subtract(const Duration(seconds: 6)),
            boundAt: e.atUtc,
            ackTimes: acks[id] ?? const [],
          );
        }
        continue;
      }
      // placed / start
      final id = _zoneIdFromEvent(e);
      zones[id] = ReplayCaptureZone(
        id: id,
        center: e.position,
        placedAt: e.atUtc,
        boundAt: zones[id]?.boundAt,
        ackTimes: acks[id] ?? zones[id]?.ackTimes ?? const [],
      );
    }

    for (final entry in acks.entries) {
      final z = zones[entry.key];
      if (z != null) {
        zones[entry.key] = ReplayCaptureZone(
          id: z.id,
          center: z.center,
          placedAt: z.placedAt,
          boundAt: z.boundAt,
          durationSec: z.durationSec,
          ackTimes: entry.value,
        );
      }
    }

    return zones.values.toList()
      ..sort((a, b) => a.placedAt.compareTo(b.placedAt));
  }

  static String _zoneIdFromEvent(MatchEvent e) {
    final fromMsg = _placeIdFromMessage(e.message);
    if (fromMsg != null) return fromMsg;
    return 'cz_${e.atUtc.microsecondsSinceEpoch}_${e.position.latitude.toStringAsFixed(5)}';
  }

  static String? _placeIdFromMessage(String message) {
    final idx = message.indexOf('place:');
    if (idx < 0) return null;
    final id = message.substring(idx + 6).trim();
    return id.isEmpty ? null : id;
  }

  static String _zoneIdFromAck(MatchEvent e) {
    return _placeIdFromMessage(e.message) ??
        'cz_ack_${e.atUtc.microsecondsSinceEpoch}';
  }

  static ReplayCaptureZoneVisual visualAt(ReplayCaptureZone zone, DateTime tNow) {
    if (tNow.isBefore(zone.placedAt) || tNow.isAfter(zone.fadeEnd)) {
      return const ReplayCaptureZoneVisual(
        visible: false,
        strokeWidth: 1,
        fillAlpha: 0,
        strokeAlpha: 0,
        pulseAck: false,
        boundFlash: false,
      );
    }

    final bound = zone.boundAt;
    final inFade = tNow.isAfter(zone.activeUntil);
    final fadeT = inFade
        ? (tNow.difference(zone.activeUntil).inMilliseconds / 800).clamp(0.0, 1.0)
        : 0.0;
    final fadeMul = 1.0 - fadeT;

    var stroke = 1.2;
    var fillA = 0.1;
    var strokeA = 0.55;
    var boundFlash = false;

    if (bound != null && !tNow.isBefore(bound)) {
      stroke = 2.8;
      fillA = 0.22;
      strokeA = 0.92;
      if (tNow.difference(bound).inMilliseconds < 600) {
        boundFlash = true;
      }
    } else if (tNow.difference(zone.placedAt).inMilliseconds < 4000) {
      stroke = 1.6;
      fillA = 0.14;
      strokeA = 0.72;
    }

    final pulseAck = zone.ackTimes.any(
      (a) => tNow.difference(a).inMilliseconds.abs() < 450,
    );
    if (pulseAck && bound == null) {
      stroke += 0.4;
      fillA += 0.06;
    }

    return ReplayCaptureZoneVisual(
      visible: fadeMul > 0.02,
      strokeWidth: stroke,
      fillAlpha: fillA * fadeMul,
      strokeAlpha: strokeA * fadeMul,
      pulseAck: pulseAck,
      boundFlash: boundFlash,
    );
  }
}
