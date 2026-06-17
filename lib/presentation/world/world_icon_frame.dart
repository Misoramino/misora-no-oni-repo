import 'package:flutter/material.dart';

import '../../theme/world_profile.dart';

/// 世界観アイコンの枠・影・光（ほんの少しだけ差を付ける）。
class WorldIconFrame {
  const WorldIconFrame({
    this.borderWidth = 0,
    this.borderColor,
    this.shadowBlur = 6,
    this.shadowOpacity = 0.18,
    this.glowColor,
    this.glowOpacity = 0,
    this.fillColor,
  });

  final double borderWidth;
  final Color? borderColor;
  final double shadowBlur;
  final double shadowOpacity;
  final Color? glowColor;
  final double glowOpacity;
  final Color? fillColor;

  static WorldIconFrame of(WorldProfile profile) => switch (profile) {
        WorldProfile.horror => const WorldIconFrame(
            borderWidth: 1.2,
            borderColor: Color(0x668FA3B5),
            shadowBlur: 10,
            shadowOpacity: 0.32,
            fillColor: Color(0xFF1A1A22),
          ),
        WorldProfile.sport => const WorldIconFrame(
            borderWidth: 0,
            shadowBlur: 12,
            shadowOpacity: 0.22,
            glowColor: Color(0x44FF6FAE),
            glowOpacity: 0.35,
            fillColor: Color(0xFFFFF8FC),
          ),
        WorldProfile.sciFi => const WorldIconFrame(
            borderWidth: 1.2,
            borderColor: Color(0x8800E5FF),
            shadowBlur: 6,
            shadowOpacity: 0.22,
            glowColor: Color(0x5500E5FF),
            glowOpacity: 0.38,
            fillColor: Color(0xFF0A1420),
          ),
        WorldProfile.arg => const WorldIconFrame(
            borderWidth: 1.2,
            borderColor: Color(0x774CAF50),
            shadowBlur: 5,
            shadowOpacity: 0.24,
            fillColor: Color(0xFF1C241C),
          ),
        WorldProfile.magical => const WorldIconFrame(
            borderWidth: 1.2,
            borderColor: Color(0x77C6A45A),
            shadowBlur: 12,
            shadowOpacity: 0.22,
            glowColor: Color(0x336FC9D8),
            glowOpacity: 0.28,
            fillColor: Color(0xFF2B2438),
          ),
        WorldProfile.astronomy => const WorldIconFrame(
            borderWidth: 0.9,
            borderColor: Color(0x6677D7FF),
            shadowBlur: 16,
            shadowOpacity: 0.28,
            glowColor: Color(0x334488FF),
            glowOpacity: 0.38,
            fillColor: Color(0xFF050A14),
          ),
        WorldProfile.japaneseLuxury => const WorldIconFrame(
            borderWidth: 1.2,
            borderColor: Color(0x663D2914),
            shadowBlur: 4,
            shadowOpacity: 0.14,
            fillColor: Color(0xFFF5F0E6),
          ),
        WorldProfile.westernLuxury => const WorldIconFrame(
            borderWidth: 1.6,
            borderColor: Color(0x99C8A75A),
            shadowBlur: 8,
            shadowOpacity: 0.18,
            glowColor: Color(0x33F5F0E6),
            glowOpacity: 0.22,
            fillColor: Color(0xFFFFFDFC),
          ),
      };

  Widget wrap({
    required Widget child,
    required Color accent,
  }) {
    return DecoratedBox(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: fillColor,
        border: borderWidth > 0
            ? Border.all(
                color: borderColor ?? accent.withValues(alpha: 0.45),
                width: borderWidth,
              )
            : null,
        boxShadow: [
          if (shadowOpacity > 0)
            BoxShadow(
              color: Colors.black.withValues(alpha: shadowOpacity),
              blurRadius: shadowBlur,
              offset: const Offset(0, 2),
            ),
          if (glowOpacity > 0 && glowColor != null)
            BoxShadow(
              color: glowColor!.withValues(alpha: glowOpacity),
              blurRadius: shadowBlur + 4,
            ),
        ],
      ),
      child: child,
    );
  }

  /// ギャラリーヒーロー / 世界カード用の大きいアイコン。
  Widget heroIcon({
    required WorldProfile profile,
    required IconData icon,
    required Color iconColor,
    double size = 72,
  }) {
    return wrap(
      accent: iconColor,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Icon(icon, size: size, color: iconColor),
      ),
    );
  }
}
