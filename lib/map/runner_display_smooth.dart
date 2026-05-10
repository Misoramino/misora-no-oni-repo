import 'dart:ui' show lerpDouble;

import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

/// ロジックには生GPSを使い、**画面上の自分マーカーだけ**ゆっくり追従させるための平滑化。
///
/// 「1秒ごとでも見た目はぬるぬる」を狙う薄いレイヤです。
final class RunnerDisplaySmoothing {
  RunnerDisplaySmoothing({required LatLng initial})
      : _display = initial,
        _target = initial;

  LatLng _display;
  LatLng _target;

  LatLng get display => _display;

  /// 表示地点とGPS目標との距離（メートル）。小さいときは無駄な再描画を避けられる。
  double get residualMeters => Geolocator.distanceBetween(
        _display.latitude,
        _display.longitude,
        _target.latitude,
        _target.longitude,
      );

  /// フィルタ通過済みGPSを目標へ。
  void setTarget(LatLng gps) => _target = gps;

  /// 1フレーム分。係数 blend は大きいほど狙いへの追従が速い。
  void stepTowardTarget(double blend01, {double teleportSnapMeters = 95}) {
    final k = blend01.clamp(0.04, 0.55);

    final moved = Geolocator.distanceBetween(
      _display.latitude,
      _display.longitude,
      _target.latitude,
      _target.longitude,
    );
    if (moved < 2.5) {
      _display = _target;
      return;
    }

    final snap = teleportSnapMeters;
    if (moved > snap) {
      _display = _target;
      return;
    }

    final lat = lerpDouble(_display.latitude, _target.latitude, k)!;
    final lng = lerpDouble(_display.longitude, _target.longitude, k)!;
    _display = LatLng(lat, lng);
  }

  /// 初回ホームや許可復帰で突然飛んだときだけ表示を合わせる。
  void snapDisplayToTarget() {
    _display = _target;
  }

  /// 画面上ほぼ追いついているかどうかの簡易判定。
  bool get isNearlyThere => residualMeters < 1.1;
}
