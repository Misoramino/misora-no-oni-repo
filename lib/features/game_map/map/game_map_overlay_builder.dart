import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../../game/elimination_aftermath_rule.dart';
import '../../../game/game_config.dart';
import '../../../game/play_area.dart';
import 'game_map_overlay_snapshot.dart';
import 'map_geo_format.dart';
import 'map_marker_kind.dart';
import 'map_zoom_lod.dart';

/// GoogleMap の markers / polylines / circles / polygons を組み立てる。
abstract final class GameMapOverlayBuilder {
  static BitmapDescriptor _icon(
    GameMapOverlaySnapshot s,
    MapMarkerKind kind,
    double fallbackHue,
  ) {
    final reg = s.markerRegistry;
    if (reg != null && reg.isReady) {
      return reg.iconOrHue(kind, fallbackHue);
    }
    return BitmapDescriptor.defaultMarkerWithHue(fallbackHue);
  }

  static MapZoomLodPolicy _lod(GameMapOverlaySnapshot s) =>
      s.visualPack?.lodPolicy ?? MapZoomLodPolicy.standard;

  static Set<Marker> buildMarkers(GameMapOverlaySnapshot s) {
    final L = s.layerToggles;
    final lod = _lod(s);
    final z = s.mapZoom;
    final showGimmickIcons = lod.showGimmickIcons(z);
    final showDetail = lod.showDetailMarkers(z);

    final playerIcon = s.usePhotoPlayerPin && s.playerMarkerIcon != null
        ? s.playerMarkerIcon!
        : _icon(
            s,
            s.usePhotoPlayerPin
                ? MapMarkerKind.playerRevealed
                : MapMarkerKind.player,
            BitmapDescriptor.hueAzure,
          );

    final markers = <Marker>{
      Marker(
        markerId: const MarkerId('player'),
        position: s.playerMarkerPosition,
        infoWindow: const InfoWindow(title: 'あなた', snippet: '現在地'),
        icon: playerIcon,
      ),
      if (s.showOniMarker)
        Marker(
          markerId: const MarkerId('oni'),
          position: s.oniPosition,
          infoWindow: InfoWindow(
            title: '鬼',
            snippet: s.remoteOniKnown ? 'オンライン同期' : 'テスト／デモ',
          ),
          icon: _icon(s, MapMarkerKind.oni, BitmapDescriptor.hueRed),
        ),
    };

    if (L.remotePlayers && lod.showRemotePlayers(z)) {
      for (final e in s.remoteMembers.entries) {
        final kind = switch (e.value.role) {
          'oni' => MapMarkerKind.remoteOni,
          'spectator' => MapMarkerKind.remoteSpectator,
          _ => MapMarkerKind.remoteRunner,
        };
        markers.add(
          Marker(
            markerId: MarkerId('remote_${e.key}'),
            position: LatLng(e.value.lat, e.value.lng),
            infoWindow: InfoWindow(
              title: e.value.nickname.isEmpty ? '参加者' : e.value.nickname,
              snippet: '${e.value.role} (online)',
            ),
            icon: _icon(
              s,
              kind,
              switch (e.value.role) {
                'oni' => BitmapDescriptor.hueRose,
                'spectator' => BitmapDescriptor.hueAzure,
                _ => BitmapDescriptor.hueMagenta,
              },
            ),
          ),
        );
      }
    }

    if (s.showGimmickMarkers) {
      if (L.safeZones && showGimmickIcons) {
        for (var i = 0; i < s.safeZonePositions.length; i++) {
          markers.add(
            Marker(
              markerId: MarkerId('safe_zone_marker_$i'),
              position: s.safeZonePositions[i],
              infoWindow: InfoWindow(
                title: '安全地帯 ${i + 1}',
                snippet: s.safeZoneAvailable
                    ? 'チャージ獲得地点'
                    : '再出現まで ${MapGeoFormat.secondsUntil(s.safeZoneRespawnAt, s.now)} 秒',
              ),
              icon: _icon(s, MapMarkerKind.safeZone, BitmapDescriptor.hueGreen),
            ),
          );
        }
      }
      if (L.infoBrokers && showGimmickIcons) {
        for (var i = 0; i < s.infoBrokerPositions.length; i++) {
          markers.add(
            Marker(
              markerId: MarkerId('info_broker_marker_$i'),
              position: s.infoBrokerPositions[i],
              infoWindow: InfoWindow(
                title: '情報屋 ${i + 1}',
                snippet: s.infoBrokerAvailable
                    ? '鬼の方角ヒント'
                    : '再出現まで ${MapGeoFormat.secondsUntil(s.infoBrokerRespawnAt, s.now)} 秒',
              ),
              icon: _icon(
                s,
                MapMarkerKind.infoBroker,
                BitmapDescriptor.hueViolet,
              ),
            ),
          );
        }
      }
      if (L.commJamming && showGimmickIcons) {
        for (var i = 0; i < s.commJammingZonePositions.length; i++) {
          markers.add(
            Marker(
              markerId: MarkerId('comm_jamming_zone_marker_$i'),
              position: s.commJammingZonePositions[i],
              infoWindow: InfoWindow(
                title: '通信障害地帯 ${i + 1}',
                snippet: '情報が断片化する',
              ),
              icon: _icon(
                s,
                MapMarkerKind.commJamming,
                BitmapDescriptor.hueOrange,
              ),
            ),
          );
        }
      }
      if (L.traces && showDetail && lod.showTraceMarkers(z)) {
        for (var i = 0; i < s.tracePoints.length; i++) {
          markers.add(
            Marker(
              markerId: MarkerId('trace_$i'),
              position: s.tracePoints[i],
              infoWindow: const InfoWindow(title: '痕跡', snippet: '脱落地点の痕跡'),
              icon: _icon(s, MapMarkerKind.trace, BitmapDescriptor.hueCyan),
            ),
          );
        }
      }
      if (L.reveals && lod.showRevealMarkers(z)) {
        for (var i = 0; i < s.revealTraces.length; i++) {
          markers.add(
            Marker(
              markerId: MarkerId('reveal_trace_$i'),
              position: s.revealTraces[i].position,
              infoWindow: InfoWindow(
                title:
                    '${s.revealTraces[i].playerLabel} の位置暴露 #${s.revealTraces[i].sequence}',
                snippet:
                    '${MapGeoFormat.traceAge(s.revealTraces[i].timestamp, s.now)} / ${MapGeoFormat.latLng(s.revealTraces[i].position)}',
              ),
              icon: _icon(s, MapMarkerKind.reveal, BitmapDescriptor.hueViolet),
            ),
          );
        }
      }
      if (L.oniIntel && showDetail) {
        for (var i = 0; i < s.oniIntelTraces.length; i++) {
          markers.add(
            Marker(
              markerId: MarkerId('oni_intel_trace_$i'),
              position: s.oniIntelTraces[i].position,
              infoWindow: InfoWindow(
                title: '情報屋の鬼情報',
                snippet:
                    '${MapGeoFormat.intelTraceAge(s.oniIntelTraces[i].timestamp, s.now)} / ${s.oniIntelTraces[i].text}',
              ),
              icon: _icon(s, MapMarkerKind.oniIntel, BitmapDescriptor.hueRed),
            ),
          );
        }
      }
      if (L.cameras && showGimmickIcons) {
        for (var i = 0; i < s.cameraPositions.length; i++) {
          markers.add(
            Marker(
              markerId: MarkerId('camera_$i'),
              position: s.cameraPositions[i],
              infoWindow: InfoWindow(
                title: '監視カメラ ${i + 1}',
                snippet: s.triggeredCameras.contains(i)
                    ? '作動済み'
                    : '感知エリア ${GameConfig.cameraTriggerRadiusMeters.toStringAsFixed(0)}m（円）',
              ),
              icon: _icon(s, MapMarkerKind.camera, BitmapDescriptor.hueYellow),
            ),
          );
        }
      }
    }

    if (L.skillMarkers && s.fakePositionActive && s.fakePositionLatLng != null) {
      markers.add(
        Marker(
          markerId: const MarkerId('fake_position'),
          position: s.fakePositionLatLng!,
          infoWindow: const InfoWindow(title: '偽位置', snippet: 'デコイ発信中'),
          icon: _icon(s, MapMarkerKind.fakePosition, BitmapDescriptor.hueRose),
        ),
      );
    }
    if (L.skillMarkers && s.bodyThrowPosition != null) {
      markers.add(
        Marker(
          markerId: const MarkerId('body_throw_position'),
          position: s.bodyThrowPosition!,
          infoWindow: const InfoWindow(title: '体投げ', snippet: '判定位置'),
          icon: _icon(s, MapMarkerKind.bodyThrow, BitmapDescriptor.hueOrange),
        ),
      );
    }

    if (L.ghostRough && s.afterCatchRule != null) {
      final rule = s.afterCatchRule!;
      final hue = rule == EliminationAftermathRule.joinOni
          ? BitmapDescriptor.hueRed
          : BitmapDescriptor.hueAzure;
      final title =
          rule == EliminationAftermathRule.joinOni ? '鬼側索敵' : '幽霊視点';
      final snippet = rule == EliminationAftermathRule.joinOni
          ? 'ざっくり位置（鬼合流）'
          : 'ざっくり位置（中立）';
      for (var i = 0; i < s.ghostRoughPositions.length; i++) {
        markers.add(
          Marker(
            markerId: MarkerId('spectator_rough_$i'),
            position: s.ghostRoughPositions[i],
            infoWindow: InfoWindow(title: title, snippet: snippet),
            icon: _icon(
              s,
              rule == EliminationAftermathRule.joinOni
                  ? MapMarkerKind.remoteOni
                  : MapMarkerKind.remoteSpectator,
              hue,
            ),
          ),
        );
      }
    }

    if (s.editingArea && !s.editCircleMode) {
      for (var i = 0; i < s.polygonDraft.length; i++) {
        markers.add(
          Marker(
            markerId: MarkerId('draft_v_$i'),
            position: s.polygonDraft[i],
            infoWindow: InfoWindow(title: '頂点', snippet: '${i + 1}'),
            icon: _icon(s, MapMarkerKind.safeZone, BitmapDescriptor.hueGreen),
          ),
        );
      }
    }

    if (s.editingArea && s.editCircleMode) {
      markers.add(
        Marker(
          markerId: const MarkerId('circle_center'),
          position: s.circleDraftCenter,
          infoWindow: const InfoWindow(title: '円の中心', snippet: '編集中'),
          icon: _icon(s, MapMarkerKind.infoBroker, BitmapDescriptor.hueViolet),
        ),
      );
    }

    return markers;
  }

  static Set<Polyline> buildPolylines(GameMapOverlaySnapshot s) {
    if (!s.editingArea || s.editCircleMode || s.polygonDraft.isEmpty) {
      return {};
    }
    final pts = s.polygonDraftClosed
        ? MapGeoFormat.closedPolygonRing(s.polygonDraft)
        : s.polygonDraft;
    return {
      Polyline(
        polylineId: const PolylineId('draft_polyline'),
        points: pts,
        width: 3,
        color: s.polygonDraftClosed
            ? s.tokens.editDraftColor
            : s.tokens.editDraftColor.withValues(alpha: 0.85),
      ),
    };
  }

  static Set<Circle> buildCircles(GameMapOverlaySnapshot s) {
    final L = s.layerToggles;
    final tokens = s.tokens;
    final circles = <Circle>{};

    if (s.showGimmickMarkers) {
      if (L.safeZones) {
        for (var i = 0; i < s.safeZonePositions.length; i++) {
          circles.add(
            Circle(
              circleId: CircleId('safe-zone-$i'),
              center: s.safeZonePositions[i],
              radius: GameConfig.safeZoneRadiusMeters,
              strokeWidth: 2,
              fillColor: tokens.safeColor.withValues(
                alpha: s.safeZoneAvailable ? 0.12 : 0.04,
              ),
              strokeColor: tokens.safeColor,
              zIndex: 1,
            ),
          );
        }
      }
      if (L.infoBrokers) {
        for (var i = 0; i < s.infoBrokerPositions.length; i++) {
          circles.add(
            Circle(
              circleId: CircleId('info-broker-$i'),
              center: s.infoBrokerPositions[i],
              radius: GameConfig.infoBrokerRadiusMeters,
              strokeWidth: 2,
              fillColor: tokens.infoColor.withValues(
                alpha: s.infoBrokerAvailable ? 0.12 : 0.04,
              ),
              strokeColor: tokens.infoColor,
              zIndex: 1,
            ),
          );
        }
      }
      if (L.commJamming) {
        for (var i = 0; i < s.commJammingZonePositions.length; i++) {
          circles.add(
            Circle(
              circleId: CircleId('comm-jamming-zone-$i'),
              center: s.commJammingZonePositions[i],
              radius: GameConfig.commJammingZoneRadiusMeters,
              strokeWidth: 2,
              fillColor: tokens.commJammingColor.withValues(alpha: 0.12),
              strokeColor: tokens.commJammingColor,
              zIndex: 1,
            ),
          );
        }
      }
      if (L.cameras) {
        final pulse = s.cameraPulsePhase;
        final wave = 0.5 + 0.5 * math.sin(pulse * math.pi * 2);
        for (var i = 0; i < s.cameraPositions.length; i++) {
          final center = s.cameraPositions[i];
          final baseR = GameConfig.cameraTriggerRadiusMeters;
          final triggered = s.triggeredCameras.contains(i);
          final scanR = baseR * (0.92 + 0.18 * wave);
          if (!triggered) {
            circles.add(
              Circle(
                circleId: CircleId('camera-zone-$i'),
                center: center,
                radius: baseR,
                strokeWidth: 1,
                fillColor: tokens.cameraSenseColor.withValues(alpha: 0.07),
                strokeColor: tokens.cameraSenseColor.withValues(alpha: 0.55),
                zIndex: 1,
              ),
            );
            circles.add(
              Circle(
                circleId: CircleId('camera-scan-$i'),
                center: center,
                radius: scanR,
                strokeWidth: 2,
                fillColor: Colors.transparent,
                strokeColor: tokens.markerAccent.withValues(alpha: 0.35 + 0.25 * wave),
                zIndex: 2,
              ),
            );
          } else {
            circles.add(
              Circle(
                circleId: CircleId('camera-alert-$i'),
                center: center,
                radius: scanR * 1.05,
                strokeWidth: 3,
                fillColor: tokens.alertColor.withValues(alpha: 0.18),
                strokeColor: tokens.alertColor.withValues(alpha: 0.75),
                zIndex: 4,
              ),
            );
          }
        }
      }
      if (L.traces) {
        for (var i = 0; i < s.tracePoints.length; i++) {
          circles.add(
            Circle(
              circleId: CircleId('trace_circle_$i'),
              center: s.tracePoints[i],
              radius: 18,
              strokeWidth: 1,
              fillColor: tokens.traceColor.withValues(alpha: 0.2),
              strokeColor: tokens.traceColor,
              zIndex: 2,
            ),
          );
        }
      }
      if (L.reveals) {
        for (var i = 0; i < s.revealTraces.length; i++) {
          circles.add(
            Circle(
              circleId: CircleId('reveal_trace_circle_$i'),
              center: s.revealTraces[i].position,
              radius: 24,
              strokeWidth: 1,
              fillColor: tokens.revealRingColor.withValues(alpha: 0.16),
              strokeColor: tokens.revealRingColor,
              zIndex: 2,
            ),
          );
        }
      }
      if (L.oniIntel) {
        for (var i = 0; i < s.oniIntelTraces.length; i++) {
          circles.add(
            Circle(
              circleId: CircleId('oni_intel_trace_circle_$i'),
              center: s.oniIntelTraces[i].position,
              radius: 30,
              strokeWidth: 2,
              fillColor: tokens.alertColor.withValues(alpha: 0.12),
              strokeColor: tokens.alertColor,
              zIndex: 3,
            ),
          );
        }
      }
    }

    if (L.captureZone && s.captureZoneCenter != null) {
      circles.add(
        Circle(
          circleId: const CircleId('capture-zone'),
          center: s.captureZoneCenter!,
          radius: GameConfig.captureZoneRadiusMeters,
          strokeWidth: 3,
          fillColor: tokens.captureZoneColor.withValues(alpha: 0.16),
          strokeColor: tokens.captureZoneColor,
          zIndex: 12,
        ),
      );
    }

    if (L.playArea &&
        s.playArea.type == PlayAreaType.circle &&
        !s.editingArea) {
      circles.add(
        Circle(
          circleId: const CircleId('play-area'),
          center: s.playArea.center,
          radius: s.playArea.radiusMeters,
          strokeWidth: 4,
          fillColor: tokens.playAreaColor.withValues(alpha: 0.16),
          strokeColor: tokens.playAreaColor,
          zIndex: 10,
        ),
      );
    }

    if (s.editingArea && s.editCircleMode) {
      circles.add(
        Circle(
          circleId: const CircleId('draft-circle'),
          center: s.circleDraftCenter,
          radius: s.circleDraftRadiusMeters,
          strokeWidth: 4,
          fillColor: tokens.editDraftColor.withValues(alpha: 0.22),
          strokeColor: tokens.editDraftColor,
          zIndex: 20,
        ),
      );
    }
    return circles;
  }

  static Set<Polygon> buildPolygons(GameMapOverlaySnapshot s) {
    if (!s.editingArea &&
        s.layerToggles.playArea &&
        s.playArea.type == PlayAreaType.polygon) {
      return {
        Polygon(
          polygonId: const PolygonId('play-area-poly'),
          points: MapGeoFormat.closedPolygonRing(s.playArea.points),
          strokeWidth: 4,
          strokeColor: s.tokens.playAreaColor,
          fillColor: s.tokens.playAreaColor.withValues(alpha: 0.16),
          zIndex: 10,
        ),
      };
    }
    if (s.editingArea &&
        !s.editCircleMode &&
        s.polygonDraftClosed &&
        s.polygonDraft.length >= 3) {
      return {
        Polygon(
          polygonId: const PolygonId('draft-poly-preview'),
          points: MapGeoFormat.closedPolygonRing(s.polygonDraft),
          strokeWidth: 4,
          strokeColor: s.tokens.editDraftColor,
          fillColor: s.tokens.editDraftColor.withValues(alpha: 0.22),
          zIndex: 20,
        ),
      };
    }
    return {};
  }

  static List<LatLng> ghostRoughPositions({
    required LatLng currentPosition,
    required LatLng oniPosition,
    required List<LatLng> cameraPositions,
  }) {
    final base = [
      currentPosition,
      oniPosition,
      for (final p in cameraPositions) p,
    ];
    return base.asMap().entries.map((e) {
      final p = e.value;
      final shift = (e.key + 1) * 0.0006;
      return LatLng(p.latitude + shift, p.longitude - shift);
    }).toList();
  }
}
