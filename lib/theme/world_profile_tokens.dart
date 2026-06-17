import 'package:flutter/material.dart';

import 'world_profile.dart';

/// 地図マーカー種別ごとの配色（決定案 v1）。
class WorldMapIconColors {
  const WorldMapIconColors({
    required this.player,
    required this.hunter,
    required this.runner,
    required this.werewolf,
    required this.safeZone,
    required this.infoBroker,
    required this.camera,
    required this.jamming,
    required this.accusation,
    required this.capture,
    required this.trace,
  });

  final Color player;
  final Color hunter;
  final Color runner;
  final Color werewolf;
  final Color safeZone;
  final Color infoBroker;
  final Color camera;
  final Color jamming;
  final Color accusation;
  final Color capture;
  final Color trace;
}

class WorldProfileTokens {
  const WorldProfileTokens({
    required this.safeColor,
    required this.alertColor,
    required this.infoColor,
    required this.dangerTextPrefix,
    required this.warningTextPrefix,
    required this.safeTextPrefix,
    required this.markerAccent,
    required this.playerRingColor,
    required this.playAreaColor,
    required this.traceColor,
    required this.revealRingColor,
    required this.commJammingColor,
    required this.cameraSenseColor,
    required this.captureZoneColor,
    required this.editDraftColor,
    required this.mapIcons,
  });

  final Color safeColor;
  final Color alertColor;
  final Color infoColor;
  final String dangerTextPrefix;
  final String warningTextPrefix;
  final String safeTextPrefix;

  final Color markerAccent;
  final Color playerRingColor;

  final Color playAreaColor;
  final Color traceColor;
  final Color revealRingColor;
  final Color commJammingColor;
  final Color cameraSenseColor;
  final Color captureZoneColor;
  final Color editDraftColor;

  final WorldMapIconColors mapIcons;
}

abstract final class WorldProfileTokenFactory {
  static WorldProfileTokens of(WorldProfile profile) {
    return switch (profile) {
      WorldProfile.horror => const WorldProfileTokens(
          safeColor: Color(0xFF6D7D65),
          alertColor: Color(0xFF7C2D2D),
          infoColor: Color(0xFF8FA3B5),
          dangerTextPrefix: '危険',
          warningTextPrefix: '警戒',
          safeTextPrefix: '静寂',
          markerAccent: Color(0xFF8FA3B5),
          playerRingColor: Color(0xFF8FA3B5),
          playAreaColor: Color(0xFF2C3E50),
          traceColor: Color(0xFF7B8794),
          revealRingColor: Color(0xFF7C2D2D),
          commJammingColor: Color(0xFF2C3E50),
          cameraSenseColor: Color(0xFF556270),
          captureZoneColor: Color(0xFF7C2D2D),
          editDraftColor: Color(0xFF556270),
          mapIcons: WorldMapIconColors(
            player: Color(0xFF8FA3B5),
            hunter: Color(0xFF7C2D2D),
            runner: Color(0xFF6D7D65),
            werewolf: Color(0xFF5A4D6D),
            safeZone: Color(0xFF6D7D65),
            infoBroker: Color(0xFF8FA3B5),
            camera: Color(0xFF556270),
            jamming: Color(0xFF2C3E50),
            accusation: Color(0xFFC2B280),
            capture: Color(0xFF7C2D2D),
            trace: Color(0xFF7B8794),
          ),
        ),
      WorldProfile.sport => const WorldProfileTokens(
          safeColor: Color(0xFFB8E35B),
          alertColor: Color(0xFFFF6FAE),
          infoColor: Color(0xFF6ECFFF),
          dangerTextPrefix: 'ハイリスク',
          warningTextPrefix: 'インプレー',
          safeTextPrefix: '安定',
          markerAccent: Color(0xFF6ECFFF),
          playerRingColor: Color(0xFF6ECFFF),
          playAreaColor: Color(0xFF6ECFFF),
          traceColor: Color(0xFF8FA3B5),
          revealRingColor: Color(0xFFFF9E7D),
          commJammingColor: Color(0xFF6B7280),
          cameraSenseColor: Color(0xFFFFB347),
          captureZoneColor: Color(0xFFFF6FAE),
          editDraftColor: Color(0xFFFF9E7D),
          mapIcons: WorldMapIconColors(
            player: Color(0xFF6ECFFF),
            hunter: Color(0xFFFF6FAE),
            runner: Color(0xFFB8E35B),
            werewolf: Color(0xFFA78BFA),
            safeZone: Color(0xFFB8E35B),
            infoBroker: Color(0xFF6ECFFF),
            camera: Color(0xFFFFB347),
            jamming: Color(0xFF6B7280),
            accusation: Color(0xFFFF9E7D),
            capture: Color(0xFFFF6FAE),
            trace: Color(0xFF8FA3B5),
          ),
        ),
      WorldProfile.sciFi => const WorldProfileTokens(
          safeColor: Color(0xFF00FFC6),
          alertColor: Color(0xFFFF3B5C),
          infoColor: Color(0xFF00F0FF),
          dangerTextPrefix: 'ALERT',
          warningTextPrefix: 'SCAN',
          safeTextPrefix: 'STEALTH',
          markerAccent: Color(0xFF00F0FF),
          playerRingColor: Color(0xFF00F0FF),
          playAreaColor: Color(0xFF2D5BFF),
          traceColor: Color(0xFF6C7A96),
          revealRingColor: Color(0xFF7A3CFF),
          commJammingColor: Color(0xFF7A3CFF),
          cameraSenseColor: Color(0xFF2D5BFF),
          captureZoneColor: Color(0xFFFF3B5C),
          editDraftColor: Color(0xFF00F0FF),
          mapIcons: WorldMapIconColors(
            player: Color(0xFF00F0FF),
            hunter: Color(0xFFFF3B5C),
            runner: Color(0xFF00FFC6),
            werewolf: Color(0xFF7A3CFF),
            safeZone: Color(0xFF00FFC6),
            infoBroker: Color(0xFF00F0FF),
            camera: Color(0xFF2D5BFF),
            jamming: Color(0xFF7A3CFF),
            accusation: Color(0xFFF7FDFF),
            capture: Color(0xFFFF3B5C),
            trace: Color(0xFF6C7A96),
          ),
        ),
      WorldProfile.arg => const WorldProfileTokens(
          safeColor: Color(0xFF6F7A45),
          alertColor: Color(0xFFC8A64A),
          infoColor: Color(0xFFA59B6B),
          dangerTextPrefix: '接触',
          warningTextPrefix: '監視',
          safeTextPrefix: '潜伏',
          markerAccent: Color(0xFFD9DFD0),
          playerRingColor: Color(0xFFD9DFD0),
          playAreaColor: Color(0xFF263524),
          traceColor: Color(0xFF7A8270),
          revealRingColor: Color(0xFFC8A64A),
          commJammingColor: Color(0xFF263524),
          cameraSenseColor: Color(0xFF3B4348),
          captureZoneColor: Color(0xFFA65F3D),
          editDraftColor: Color(0xFF7A8270),
          mapIcons: WorldMapIconColors(
            player: Color(0xFFD9DFD0),
            hunter: Color(0xFFC8A64A),
            runner: Color(0xFF6F7A45),
            werewolf: Color(0xFF7A8270),
            safeZone: Color(0xFF6F7A45),
            infoBroker: Color(0xFFA59B6B),
            camera: Color(0xFF3B4348),
            jamming: Color(0xFF263524),
            accusation: Color(0xFFC8A64A),
            capture: Color(0xFFA65F3D),
            trace: Color(0xFF7A8270),
          ),
        ),
      WorldProfile.magical => const WorldProfileTokens(
          safeColor: Color(0xFF3F7D67),
          alertColor: Color(0xFFC65A6A),
          infoColor: Color(0xFF6FC9D8),
          dangerTextPrefix: '呪い',
          warningTextPrefix: '予兆',
          safeTextPrefix: '結界',
          markerAccent: Color(0xFF6FC9D8),
          playerRingColor: Color(0xFF6FC9D8),
          playAreaColor: Color(0xFF3F4F88),
          traceColor: Color(0xFFA685E2),
          revealRingColor: Color(0xFFC6A45A),
          commJammingColor: Color(0xFF3F4F88),
          cameraSenseColor: Color(0xFFC6A45A),
          captureZoneColor: Color(0xFFC65A6A),
          editDraftColor: Color(0xFF5B4A8C),
          mapIcons: WorldMapIconColors(
            player: Color(0xFF6FC9D8),
            hunter: Color(0xFFC65A6A),
            runner: Color(0xFF62B87A),
            werewolf: Color(0xFFA685E2),
            safeZone: Color(0xFF4A79C7),
            infoBroker: Color(0xFF6FC9D8),
            camera: Color(0xFFC6A45A),
            jamming: Color(0xFF3F4F88),
            accusation: Color(0xFFC6A45A),
            capture: Color(0xFFC65A6A),
            trace: Color(0xFFA685E2),
          ),
        ),
      WorldProfile.astronomy => const WorldProfileTokens(
          safeColor: Color(0xFF1F6FEB),
          alertColor: Color(0xFF4C5BD5),
          infoColor: Color(0xFF77D7FF),
          dangerTextPrefix: '赤方偏移',
          warningTextPrefix: '観測',
          safeTextPrefix: '静穏',
          markerAccent: Color(0xFF77D7FF),
          playerRingColor: Color(0xFF77D7FF),
          playAreaColor: Color(0xFF0B1D3A),
          traceColor: Color(0xFF6D7890),
          revealRingColor: Color(0xFFB8E7FF),
          commJammingColor: Color(0xFF24324F),
          cameraSenseColor: Color(0xFFF4FBFF),
          captureZoneColor: Color(0xFF4C5BD5),
          editDraftColor: Color(0xFF1F6FEB),
          mapIcons: WorldMapIconColors(
            player: Color(0xFF77D7FF),
            hunter: Color(0xFF4C5BD5),
            runner: Color(0xFFB8E7FF),
            werewolf: Color(0xFF7B61FF),
            safeZone: Color(0xFF1F6FEB),
            infoBroker: Color(0xFF77D7FF),
            camera: Color(0xFFF4FBFF),
            jamming: Color(0xFF24324F),
            accusation: Color(0xFFB8E7FF),
            capture: Color(0xFF4C5BD5),
            trace: Color(0xFF6D7890),
          ),
        ),
      WorldProfile.japaneseLuxury => const WorldProfileTokens(
          safeColor: Color(0xFF8E9B65),
          alertColor: Color(0xFF5B4636),
          infoColor: Color(0xFF2E4A5F),
          dangerTextPrefix: '祟り',
          warningTextPrefix: '気配',
          safeTextPrefix: '静寂',
          markerAccent: Color(0xFF2E4A5F),
          playerRingColor: Color(0xFF2E4A5F),
          playAreaColor: Color(0xFF3F4A36),
          traceColor: Color(0xFFB8A77D),
          revealRingColor: Color(0xFFA88445),
          commJammingColor: Color(0xFF7B6042),
          cameraSenseColor: Color(0xFF4B545F),
          captureZoneColor: Color(0xFF5B4636),
          editDraftColor: Color(0xFF7B6042),
          mapIcons: WorldMapIconColors(
            player: Color(0xFF2E4A5F),
            hunter: Color(0xFF5B4636),
            runner: Color(0xFF5E6B4E),
            werewolf: Color(0xFF4B3F52),
            safeZone: Color(0xFF8E9B65),
            infoBroker: Color(0xFF2E4A5F),
            camera: Color(0xFF4B545F),
            jamming: Color(0xFF7B6042),
            accusation: Color(0xFFA88445),
            capture: Color(0xFF5B4636),
            trace: Color(0xFFB8A77D),
          ),
        ),
      WorldProfile.westernLuxury => const WorldProfileTokens(
          safeColor: Color(0xFF607D5A),
          alertColor: Color(0xFF6D2138),
          infoColor: Color(0xFFC8A75A),
          dangerTextPrefix: '危険',
          warningTextPrefix: '監視',
          safeTextPrefix: '安寧',
          markerAccent: Color(0xFFC8A75A),
          playerRingColor: Color(0xFF5C5246),
          playAreaColor: Color(0xFFAFCEDC),
          traceColor: Color(0xFF8C6A3B),
          revealRingColor: Color(0xFFC8A75A),
          commJammingColor: Color(0xFFBEB5A8),
          cameraSenseColor: Color(0xFF5C5246),
          captureZoneColor: Color(0xFF6D2138),
          editDraftColor: Color(0xFFD8C68C),
          mapIcons: WorldMapIconColors(
            player: Color(0xFF5C5246),
            hunter: Color(0xFF6D2138),
            runner: Color(0xFF607D5A),
            werewolf: Color(0xFF8C6A3B),
            safeZone: Color(0xFF607D5A),
            infoBroker: Color(0xFFC8A75A),
            camera: Color(0xFF5C5246),
            jamming: Color(0xFFBEB5A8),
            accusation: Color(0xFFC8A75A),
            capture: Color(0xFF6D2138),
            trace: Color(0xFF8C6A3B),
          ),
        ),
    };
  }
}
