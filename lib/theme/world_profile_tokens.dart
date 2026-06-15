import 'package:flutter/material.dart';

import 'world_profile.dart';

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
  });

  final Color safeColor;
  final Color alertColor;
  final Color infoColor;
  final String dangerTextPrefix;
  final String warningTextPrefix;
  final String safeTextPrefix;

  /// マーカー生成用アクセント
  final Color markerAccent;
  final Color playerRingColor;

  /// 地図オーバーレイ（円・ポリゴン・編集ドラフト）
  final Color playAreaColor;
  final Color traceColor;
  final Color revealRingColor;
  final Color commJammingColor;
  final Color cameraSenseColor;
  final Color captureZoneColor;
  final Color editDraftColor;
}

abstract final class WorldProfileTokenFactory {
  static WorldProfileTokens of(WorldProfile profile) {
    return switch (profile) {
      WorldProfile.horror => const WorldProfileTokens(
          safeColor: Color(0xFF1B5E20),
          alertColor: Color(0xFFB71C1C),
          infoColor: Color(0xFF4A148C),
          dangerTextPrefix: '危険',
          warningTextPrefix: '警戒',
          safeTextPrefix: '静寂',
          markerAccent: Color(0xFFB71C1C),
          playerRingColor: Color(0xFF8D6E63),
          playAreaColor: Color(0xFF37474F),
          traceColor: Color(0xFF00838F),
          revealRingColor: Color(0xFF6A1B9A),
          commJammingColor: Color(0xFFE65100),
          cameraSenseColor: Color(0xFFF9A825),
          captureZoneColor: Color(0xFFC62828),
          editDraftColor: Color(0xFFBF360C),
        ),
      WorldProfile.sport => const WorldProfileTokens(
          safeColor: Color(0xFF00C853),
          alertColor: Color(0xFFFF6D00),
          infoColor: Color(0xFF00B8D4),
          dangerTextPrefix: 'ハイリスク',
          warningTextPrefix: 'インプレー',
          safeTextPrefix: '安定',
          markerAccent: Color(0xFFFF4081),
          playerRingColor: Color(0xFF2979FF),
          playAreaColor: Color(0xFF00B8D4),
          traceColor: Color(0xFF00E676),
          revealRingColor: Color(0xFFFF4081),
          commJammingColor: Color(0xFFFF9100),
          cameraSenseColor: Color(0xFFFFD600),
          captureZoneColor: Color(0xFFFF3D00),
          editDraftColor: Color(0xFFFF6D00),
        ),
      WorldProfile.sciFi => const WorldProfileTokens(
          safeColor: Color(0xFF00E5FF),
          alertColor: Color(0xFFFF1744),
          infoColor: Color(0xFF7C4DFF),
          dangerTextPrefix: 'ALERT',
          warningTextPrefix: 'SCAN',
          safeTextPrefix: 'STEALTH',
          markerAccent: Color(0xFF00E5FF),
          playerRingColor: Color(0xFF18FFFF),
          playAreaColor: Color(0xFF304FFE),
          traceColor: Color(0xFF00E5FF),
          revealRingColor: Color(0xFF7C4DFF),
          commJammingColor: Color(0xFFFF9100),
          cameraSenseColor: Color(0xFFFFEA00),
          captureZoneColor: Color(0xFFFF1744),
          editDraftColor: Color(0xFF00B0FF),
        ),
      WorldProfile.arg => const WorldProfileTokens(
          safeColor: Color(0xFF558B2F),
          alertColor: Color(0xFF6D4C41),
          infoColor: Color(0xFF455A64),
          dangerTextPrefix: '接触',
          warningTextPrefix: '監視',
          safeTextPrefix: '潜伏',
          markerAccent: Color(0xFF78909C),
          playerRingColor: Color(0xFF90A4AE),
          playAreaColor: Color(0xFF546E7A),
          traceColor: Color(0xFF607D8B),
          revealRingColor: Color(0xFF78909C),
          commJammingColor: Color(0xFF8D6E63),
          cameraSenseColor: Color(0xFF9E9E9E),
          captureZoneColor: Color(0xFF5D4037),
          editDraftColor: Color(0xFF6D4C41),
        ),
      WorldProfile.magical => const WorldProfileTokens(
          safeColor: Color(0xFFAB47BC),
          alertColor: Color(0xFFFF7043),
          infoColor: Color(0xFF5C6BC0),
          dangerTextPrefix: '呪い',
          warningTextPrefix: '予兆',
          safeTextPrefix: '結界',
          markerAccent: Color(0xFFEA80FC),
          playerRingColor: Color(0xFFFFD740),
          playAreaColor: Color(0xFF7E57C2),
          traceColor: Color(0xFF26C6DA),
          revealRingColor: Color(0xFFEA80FC),
          commJammingColor: Color(0xFFFF7043),
          cameraSenseColor: Color(0xFFFFD54F),
          captureZoneColor: Color(0xFFFF5722),
          editDraftColor: Color(0xFFAB47BC),
        ),
      WorldProfile.astronomy => const WorldProfileTokens(
          safeColor: Color(0xFF5C6BC0),
          alertColor: Color(0xFFFFB300),
          infoColor: Color(0xFF26C6DA),
          dangerTextPrefix: '赤方偏移',
          warningTextPrefix: '観測',
          safeTextPrefix: '静穏',
          markerAccent: Color(0xFFFFD54F),
          playerRingColor: Color(0xFFE1F5FE),
          playAreaColor: Color(0xFF283593),
          traceColor: Color(0xFF4DD0E1),
          revealRingColor: Color(0xFFFFD54F),
          commJammingColor: Color(0xFFFF8F00),
          cameraSenseColor: Color(0xFFFFEE58),
          captureZoneColor: Color(0xFFFF6F00),
          editDraftColor: Color(0xFF5C6BC0),
        ),
      WorldProfile.japaneseLuxury => const WorldProfileTokens(
          safeColor: Color(0xFF1B5E20),
          alertColor: Color(0xFFB71C1C),
          infoColor: Color(0xFF1A237E),
          dangerTextPrefix: '祟り',
          warningTextPrefix: '気配',
          safeTextPrefix: '静寂',
          markerAccent: Color(0xFFC9A227),
          playerRingColor: Color(0xFFE8D5A3),
          playAreaColor: Color(0xFF263238),
          traceColor: Color(0xFF5C6BC0),
          revealRingColor: Color(0xFFC9A227),
          commJammingColor: Color(0xFF8D6E63),
          cameraSenseColor: Color(0xFFFFD54F),
          captureZoneColor: Color(0xFFB71C1C),
          editDraftColor: Color(0xFF6D4C41),
        ),
      WorldProfile.westernLuxury => const WorldProfileTokens(
          safeColor: Color(0xFF2E7D32),
          alertColor: Color(0xFF722F37),
          infoColor: Color(0xFF5D4037),
          dangerTextPrefix: '危険',
          warningTextPrefix: '監視',
          safeTextPrefix: '安寧',
          markerAccent: Color(0xFFD4AF37),
          playerRingColor: Color(0xFFECEFF1),
          playAreaColor: Color(0xFF455A64),
          traceColor: Color(0xFF90A4AE),
          revealRingColor: Color(0xFFD4AF37),
          commJammingColor: Color(0xFF8D6E63),
          cameraSenseColor: Color(0xFFFFD54F),
          captureZoneColor: Color(0xFF722F37),
          editDraftColor: Color(0xFF6D4C41),
        ),
    };
  }
}
