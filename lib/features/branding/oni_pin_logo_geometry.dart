import 'dart:math' as math;

import 'package:flutter/material.dart';

/// PNG ブランド（位置ピン + 鬼の角 + 赤芯）に合わせた正規化シルエット。
abstract final class OniPinLogoGeometry {
  /// ピン外周のストロークパス（塗りつぶしなし）。
  static Path outline(Size size) {
    final w = size.width;
    final h = size.height;
    final cx = w * 0.5;
    final headY = h * 0.355;
    final headR = w * 0.265;
    final tipY = h * 0.90;

    final path = Path();
    // 左の角（外側へ張り出す）
    path.moveTo(cx - headR * 0.58, headY - headR * 0.22);
    path.cubicTo(
      cx - headR * 1.12,
      h * 0.11,
      cx - headR * 0.88,
      h * 0.09,
      cx - headR * 0.48,
      headY - headR * 0.58,
    );
    // 頭頂部アーク（左→右）
    path.arcToPoint(
      Offset(cx + headR * 0.58, headY - headR * 0.22),
      radius: Radius.circular(headR * 1.02),
      clockwise: true,
      largeArc: false,
    );
    // 右の角
    path.cubicTo(
      cx + headR * 0.88,
      h * 0.09,
      cx + headR * 1.12,
      h * 0.11,
      cx + headR * 0.48,
      headY - headR * 0.58,
    );
    // 右脇→先端
    path.quadraticBezierTo(
      cx + headR * 0.52,
      headY + headR * 0.52,
      cx + headR * 0.06,
      tipY - h * 0.015,
    );
    path.lineTo(cx, tipY);
    // 左脇へ戻る
    path.quadraticBezierTo(
      cx - headR * 0.06,
      tipY - h * 0.015,
      cx - headR * 0.52,
      headY + headR * 0.52,
    );
    path.close();
    return path;
  }

  /// 内側の赤い追跡点（頭の中心付近）。
  static Offset coreCenter(Size size) => Offset(size.width * 0.5, size.height * 0.355);

  static double coreRadius(Size size) => size.width * 0.102;

  /// ソフトグロー用の外側リング半径。
  static double coreGlowRadius(Size size, {double pulse = 0}) {
    final beat = 0.5 + 0.5 * math.sin(pulse * math.pi * 2);
    return coreRadius(size) + size.width * (0.06 + beat * 0.02);
  }
}
