import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../../game/analyst_trace_format.dart';
import '../../../game/elimination_aftermath_rule.dart';
import '../../../game/game_config.dart';
import '../../../game/player_role.dart';
import '../../../game/play_area.dart';
import 'game_map_overlay_snapshot.dart';
import 'map_geo_format.dart';
import 'map_marker_kind.dart';
import 'map_zoom_lod.dart';

/// GoogleMap の markers / polylines / circles / polygons を組み立てる。
abstract final class GameMapOverlayBuilder {
  static double _gimmickMarkerAlpha(
    GameMapOverlaySnapshot s, {
    required bool usable,
    double baseAlpha = 1.0,
  }) {
    if (!s.secondGameIntroHighlight) return baseAlpha;
    return usable ? 1.0 : 0.28;
  }

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

    final lowZoomPlayer = z < 14;
    final playerIcon = lowZoomPlayer
        ? BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure)
        : (s.usePhotoPlayerPin && s.playerMarkerIcon != null
            ? s.playerMarkerIcon!
            : _icon(
                s,
                s.usePhotoPlayerPin
                    ? MapMarkerKind.playerRevealed
                    : MapMarkerKind.player,
                BitmapDescriptor.hueAzure,
              ));

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
        final lat = e.value.lat;
        final lng = e.value.lng;
        // members には生 GPS を載せない設計のため、座標が無いメンバーはマーカー化しない。
        if (lat == null || lng == null) continue;
        final kind = switch (e.value.role) {
          'oni' => MapMarkerKind.remoteOni,
          'spectator' => MapMarkerKind.remoteSpectator,
          _ => MapMarkerKind.remoteRunner,
        };
        markers.add(
          Marker(
            markerId: MarkerId('remote_${e.key}'),
            position: LatLng(lat, lng),
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

    if (L.inspectorIntel && s.showInspectorIntelPins && showDetail) {
      final liveUids = s.inspectorLiveFeed.keys.toSet();
      for (final e in s.inspectorLiveFeed.entries) {
        final pin = e.value;
        final kind = switch (pin.role) {
          'oni' => MapMarkerKind.remoteOni,
          'spectator' => MapMarkerKind.remoteSpectator,
          _ => MapMarkerKind.remoteRunner,
        };
        final hue = switch (pin.role) {
          'oni' => BitmapDescriptor.hueRed,
          'spectator' => BitmapDescriptor.hueAzure,
          _ => BitmapDescriptor.hueGreen,
        };
        final ageSec = s.now.difference(pin.reportedAtUtc).inSeconds;
        markers.add(
          Marker(
            markerId: MarkerId('inspector_live_${pin.uid}'),
            position: LatLng(pin.lat, pin.lng),
            alpha: 0.92,
            infoWindow: InfoWindow(
              title: pin.nickname.isEmpty ? '参加者' : pin.nickname,
              snippet: 'ライブ GPS · ${ageSec}s前',
            ),
            icon: _icon(s, kind, hue),
          ),
        );
      }
      for (final pin in s.inspectorIntelPins) {
        if (liveUids.contains(pin.uid)) continue;
        final kind = switch (pin.role) {
          PlayerRole.hunter => MapMarkerKind.remoteOni,
          PlayerRole.werewolf => MapMarkerKind.remoteOni,
          _ => MapMarkerKind.remoteRunner,
        };
        final hue = pin.eliminated
            ? BitmapDescriptor.hueOrange
            : switch (pin.role) {
                PlayerRole.hunter => BitmapDescriptor.hueRed,
                PlayerRole.werewolf => BitmapDescriptor.hueRose,
                _ => BitmapDescriptor.hueGreen,
              };
        final ageSec = s.now.difference(pin.updatedAt).inSeconds;
        markers.add(
          Marker(
            markerId: MarkerId('inspector_intel_${pin.uid}'),
            position: pin.position,
            alpha: pin.eliminated ? 0.55 : 0.82,
            infoWindow: InfoWindow(
              title: pin.label,
              snippet: '${pin.role.displayName} · ${pin.sourceLabel} · ${ageSec}s前',
            ),
            icon: _icon(s, kind, hue),
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
      if (L.infoBrokers && showGimmickIcons) {
        for (var i = 0; i < s.accusationFacilityPositions.length; i++) {
          final active = s.activeAccusationSiteIndices.contains(i);
          final usable = active &&
              (s.secondGameCanUseAccusationTerritory ||
                  s.secondGameCanUseFacilitySabotage);
          final alpha = s.secondGameIntroHighlight
              ? _gimmickMarkerAlpha(s, usable: usable)
              : (active ? 1.0 : 0.45);
          markers.add(
            Marker(
              markerId: MarkerId('accusation_facility_$i'),
              position: s.accusationFacilityPositions[i],
              infoWindow: InfoWindow(
                title: active
                    ? '${s.accusationFacilityTitle}（有効）'
                    : '${s.accusationFacilityTitle}（無効）',
                snippet: active
                    ? (s.secondGameIntroHighlight && usable
                        ? '第二ゲーム — ここで操作可能'
                        : '告発可能（解禁後・逃走者）')
                    : '現在は無効',
              ),
              icon: _icon(
                s,
                MapMarkerKind.accusationFacility,
                active
                    ? BitmapDescriptor.hueRose
                    : BitmapDescriptor.hueOrange,
              ),
              alpha: alpha,
            ),
          );
        }
      }
      if (s.showCameraJackSites && showGimmickIcons) {
        for (var i = 0; i < s.cameraJackPositions.length; i++) {
          final usable = s.secondGameCanUseCameraJack;
          markers.add(
            Marker(
              markerId: MarkerId('camera_jack_$i'),
              position: s.cameraJackPositions[i],
              infoWindow: InfoWindow(
                title: 'ジャック端子',
                snippet: s.secondGameIntroHighlight
                    ? (usable ? '第二ゲーム — 監視ジャック可' : 'ここでは使えません')
                    : '残響体のみチャージ可',
              ),
              icon: _icon(
                s,
                MapMarkerKind.camera,
                BitmapDescriptor.hueYellow,
              ),
              alpha: _gimmickMarkerAlpha(s, usable: usable),
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
        final anchor = s.oniMatchStartAnchor;
        if (anchor != null) {
          markers.add(
            Marker(
              markerId: const MarkerId('oni_match_start_anchor'),
              position: anchor,
              infoWindow: const InfoWindow(
                title: '鬼の試合開始付近',
                snippet: '序盤の手がかり（遅延軌跡が出る前）',
              ),
              icon: _icon(s, MapMarkerKind.oniIntel, BitmapDescriptor.hueRed),
            ),
          );
        }
      }
      if (L.traces && lod.showTraceMarkers(z)) {
        for (var i = 0; i < s.anonymousRevealTraces.length; i++) {
          final t = s.anonymousRevealTraces[i];
          markers.add(
            Marker(
              markerId: MarkerId('anon_reveal_$i'),
              position: t.position,
              infoWindow: InfoWindow(
                title: '不明な痕跡',
                snippet: s.analystTraceDetail
                    ? AnalystTraceFormat.summaryLine(t, s.now)
                    : '${MapGeoFormat.traceAge(t.timestamp, s.now)} / ${t.reasonSummary}',
              ),
              icon: _icon(
                s,
                MapMarkerKind.anonymousReveal,
                BitmapDescriptor.hueAzure,
              ),
            ),
          );
        }
      }
      if (L.reveals && lod.showRevealMarkers(z)) {
        for (var i = 0; i < s.revealTraces.length; i++) {
          final trace = s.revealTraces[i];
          final photoIcon = trace.subjectUid != null
              ? s.revealAvatarIconsByUid[trace.subjectUid]
              : null;
          markers.add(
            Marker(
              markerId: MarkerId('reveal_trace_$i'),
              position: trace.position,
              infoWindow: InfoWindow(
                title: '${trace.playerLabel} の位置暴露 #${trace.sequence}',
                snippet:
                    '${MapGeoFormat.traceAge(trace.timestamp, s.now)} / ${MapGeoFormat.latLng(trace.position)}',
              ),
              icon: photoIcon ??
                  _icon(s, MapMarkerKind.reveal, BitmapDescriptor.hueViolet),
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
                title: '情報屋の手がかり',
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
          final disabled = s.disabledCameraIndices.contains(i);
          final usable = s.secondGameCanUseCameraShutdown && !disabled;
          markers.add(
            Marker(
              markerId: MarkerId('camera_$i'),
              position: s.cameraPositions[i],
              infoWindow: InfoWindow(
                title: disabled
                    ? '監視カメラ ${i + 1}（停止）'
                    : '監視カメラ ${i + 1}',
                snippet: s.secondGameIntroHighlight
                    ? (usable
                        ? '第二ゲーム — 停止可能'
                        : disabled
                            ? 'すでに停止済み'
                            : 'ここでは使えません')
                    : disabled
                        ? '復讐の鬼影により無効化'
                        : '感知 ${GameConfig.cameraTriggerRadiusMeters.toStringAsFixed(0)}m · '
                            '再検知 ${GameConfig.cameraRetriggerCooldownSeconds}秒',
              ),
              icon: _icon(
                s,
                MapMarkerKind.camera,
                disabled
                    ? BitmapDescriptor.hueOrange
                    : BitmapDescriptor.hueYellow,
              ),
              alpha: s.secondGameIntroHighlight
                  ? _gimmickMarkerAlpha(s, usable: usable, baseAlpha: 1.0)
                  : 1.0,
            ),
          );
        }
      }
    }

    if (L.skillMarkers && s.fakePositionActive && s.fakePositionLatLng != null) {
      markers.add(
        Marker(
          markerId: const MarkerId('fake_position_local'),
          position: s.fakePositionLatLng!,
          infoWindow: const InfoWindow(
            title: '偽位置（あなたのみ）',
            snippet: '露出イベントではここが名前付きで出ます',
          ),
          icon: _icon(
            s,
            MapMarkerKind.fakePosition,
            BitmapDescriptor.hueViolet,
          ),
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


    return markers;
  }

  static Set<Polyline> buildPolylines(GameMapOverlaySnapshot s) {
    final out = <Polyline>{};
    if (s.oniTrailPoints.length >= 2) {
      out.add(
        Polyline(
          polylineId: const PolylineId('oni_delayed_trail'),
          points: s.oniTrailPoints,
          width: 3,
          color: s.tokens.traceColor.withValues(alpha: 0.55),
        ),
      );
    }
    if (!s.editingArea || s.editCircleMode || s.polygonDraft.isEmpty) {
      return out;
    }
    final pts = s.polygonDraftClosed
        ? MapGeoFormat.closedPolygonRing(s.polygonDraft)
        : s.polygonDraft;
    out.add(
      Polyline(
        polylineId: const PolylineId('draft_polyline'),
        points: pts,
        width: 3,
        color: s.polygonDraftClosed
            ? s.tokens.editDraftColor
            : s.tokens.editDraftColor.withValues(alpha: 0.85),
      ),
    );
    return out;
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
          final disabled = s.disabledCameraIndices.contains(i);
          final scanR = baseR * (0.92 + 0.18 * wave);
          if (disabled) {
            circles.add(
              Circle(
                circleId: CircleId('camera-disabled-$i'),
                center: center,
                radius: baseR * 0.85,
                strokeWidth: 2,
                fillColor: Colors.grey.withValues(alpha: 0.12),
                strokeColor: Colors.grey.withValues(alpha: 0.55),
                zIndex: 1,
              ),
            );
          } else {
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

    if (s.skillMapPlacementMaxRangeMeters > 0) {
      circles.add(
        Circle(
          circleId: const CircleId('skill-map-placement-range'),
          center: s.playerMarkerPosition,
          radius: s.skillMapPlacementMaxRangeMeters,
          strokeWidth: 1,
          fillColor: tokens.traceColor.withValues(alpha: 0.05),
          strokeColor: tokens.traceColor.withValues(alpha: 0.38),
          zIndex: 7,
        ),
      );
    }

    if (L.captureZone &&
        s.skillPlacementPreviewLatLng != null &&
        s.skillPlacementPreviewRadiusMeters > 0) {
      circles.add(
        Circle(
          circleId: const CircleId('skill-placement-preview'),
          center: s.skillPlacementPreviewLatLng!,
          radius: s.skillPlacementPreviewRadiusMeters,
          strokeWidth: 2,
          fillColor: tokens.captureZoneColor.withValues(alpha: 0.14),
          strokeColor: tokens.captureZoneColor.withValues(alpha: 0.72),
          zIndex: 11,
        ),
      );
    }

    if (L.captureZone &&
        s.lockZoneCenter != null &&
        s.lockZoneDisplayRadiusMeters > 0) {
      circles.add(
        Circle(
          circleId: const CircleId('lock-zone'),
          center: s.lockZoneCenter!,
          radius: s.lockZoneDisplayRadiusMeters,
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
      circles.add(
        Circle(
          circleId: const CircleId('draft-circle-center-dot'),
          center: s.circleDraftCenter,
          radius: 5,
          strokeWidth: 2,
          fillColor: tokens.editDraftColor.withValues(alpha: 0.9),
          strokeColor: Colors.white.withValues(alpha: 0.85),
          zIndex: 25,
        ),
      );
    }

    if (s.editingArea && !s.editCircleMode) {
      for (var i = 0; i < s.polygonDraft.length; i++) {
        circles.add(
          Circle(
            circleId: CircleId('draft_v_$i'),
            center: s.polygonDraft[i],
            radius: 5,
            strokeWidth: 2,
            fillColor: tokens.safeColor.withValues(alpha: 0.85),
            strokeColor: Colors.white.withValues(alpha: 0.8),
            zIndex: 25,
          ),
        );
      }
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
