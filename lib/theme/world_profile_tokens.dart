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
  });

  final Color safeColor;
  final Color alertColor;
  final Color infoColor;

  final String dangerTextPrefix;
  final String warningTextPrefix;
  final String safeTextPrefix;
}

abstract final class WorldProfileTokenFactory {
  static WorldProfileTokens of(WorldProfile profile) {
    switch (profile) {
      case WorldProfile.horror:
        return const WorldProfileTokens(
          safeColor: Color(0xFF1B5E20),
          alertColor: Color(0xFFB71C1C),
          infoColor: Color(0xFF4A148C),
          dangerTextPrefix: '危険',
          warningTextPrefix: '警戒',
          safeTextPrefix: '静寂',
        );
      case WorldProfile.sport:
        return const WorldProfileTokens(
          safeColor: Color(0xFF0D47A1),
          alertColor: Color(0xFFE65100),
          infoColor: Color(0xFF006064),
          dangerTextPrefix: 'ハイリスク',
          warningTextPrefix: 'インプレー',
          safeTextPrefix: '安定',
        );
      case WorldProfile.sciFi:
        return const WorldProfileTokens(
          safeColor: Color(0xFF004D40),
          alertColor: Color(0xFFBF360C),
          infoColor: Color(0xFF1A237E),
          dangerTextPrefix: 'ALERT',
          warningTextPrefix: 'SCAN',
          safeTextPrefix: 'STEALTH',
        );
      case WorldProfile.arg:
        return const WorldProfileTokens(
          safeColor: Color(0xFF33691E),
          alertColor: Color(0xFFD84315),
          infoColor: Color(0xFF311B92),
          dangerTextPrefix: '異常',
          warningTextPrefix: '傍受',
          safeTextPrefix: '潜伏',
        );
    }
  }
}
