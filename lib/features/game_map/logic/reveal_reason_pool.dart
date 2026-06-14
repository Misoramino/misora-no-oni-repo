import 'dart:math' as math;



import 'package:google_maps_flutter/google_maps_flutter.dart';



import '../../../game/game_config.dart';



/// 本物・偽の暴露で共通の「世界観理由」（プレイヤーは fake/real を判別しない）。

class RevealReasonPick {
  const RevealReasonPick({required this.summary, required this.narrative});

  /// スキル等でジャスト位置を出すとき（理由ラベルなし）。
  static const exactLocation = RevealReasonPick(
    summary: '',
    narrative: '位置情報',
  );

  final String summary;
  final String narrative;
}



/// 地図文脈に応じてプールから選ぶ（表示タグは常に同系統）。

abstract final class RevealReasonPool {

  static const _entries = <RevealReasonPick>[

    RevealReasonPick(summary: '通信混線', narrative: '通信混線で記録された断片'),

    RevealReasonPick(summary: '傍受', narrative: '傍受された通信ログに含まれる座標'),

    RevealReasonPick(summary: '監視カメラ', narrative: '監視カメラの記録が外部に流れた'),

    RevealReasonPick(summary: '熱源検知', narrative: '熱源センサが反応した地点'),

    RevealReasonPick(summary: '不審通信', narrative: '不審な通信パケットから推定された位置'),

    RevealReasonPick(summary: 'ドローン観測', narrative: 'ドローン観測ログに残った座標'),

    RevealReasonPick(summary: '信号ノイズ', narrative: '信号ノイズから復元された地点'),

  ];



  /// 監視カメラ通過など、カメラ理由を優先したいとき。

  static RevealReasonPick cameraPick() => _entries[2];



  /// 定期暴露 — 実位置はずらして表示するため、カメラ圏内なら監視カメラ理由も可。

  static RevealReasonPick periodicPick({

    required LatLng revealPosition,

    required List<LatLng> cameraPositions,

    required List<LatLng> safeZonePositions,

    required bool actorOutsidePlayArea,

    int? seed,

  }) {

    const periodicEntries = <RevealReasonPick>[

      RevealReasonPick(summary: '通信混線', narrative: '通信混線で記録された断片'),

      RevealReasonPick(summary: '傍受', narrative: '傍受された通信ログに含まれる座標'),

      RevealReasonPick(summary: '熱源検知', narrative: '熱源センサが反応した地点'),

      RevealReasonPick(summary: '不審通信', narrative: '不審な通信パケットから推定された位置'),

      RevealReasonPick(summary: '信号ノイズ', narrative: '信号ノイズから復元された地点'),

      RevealReasonPick(summary: 'ドローン観測', narrative: 'ドローン観測ログに残った座標'),

    ];

    final rnd = math.Random(seed ?? _positionSeed(revealPosition));

    final camNear = GameConfig.cameraTriggerRadiusMeters + 25;

    for (final c in cameraPositions) {

      if (_distanceMeters(revealPosition, c) <= camNear) {

        return cameraPick();

      }

    }

    for (final s in safeZonePositions) {

      if (_distanceMeters(revealPosition, s) <=

          GameConfig.safeZoneRadiusMeters + 30) {

        return periodicEntries[4];

      }

    }

    if (actorOutsidePlayArea) {

      return periodicEntries[0];

    }

    return periodicEntries[rnd.nextInt(periodicEntries.length)];

  }



  static RevealReasonPick pick({

    required LatLng revealPosition,

    required List<LatLng> cameraPositions,

    required List<LatLng> safeZonePositions,

    required bool actorOutsidePlayArea,

    int? seed,

  }) {

    final rnd = math.Random(seed ?? _positionSeed(revealPosition));

    final camNear = GameConfig.cameraTriggerRadiusMeters + 25;

    for (final c in cameraPositions) {

      if (_distanceMeters(revealPosition, c) <= camNear) {

        return _entries[2];

      }

    }

    for (final s in safeZonePositions) {

      if (_distanceMeters(revealPosition, s) <=

          GameConfig.safeZoneRadiusMeters + 30) {

        return _entries[6];

      }

    }

    if (actorOutsidePlayArea) {

      return _entries[0];

    }

    return _entries[rnd.nextInt(_entries.length)];

  }



  static int _positionSeed(LatLng p) =>

      (p.latitude * 100000).round() ^ (p.longitude * 100000).round();



  static double _distanceMeters(LatLng a, LatLng b) {

    final dLat = (a.latitude - b.latitude) * 111320;

    final dLng = (b.longitude - a.longitude) *

        111320 *

        math.cos(a.latitude * math.pi / 180);

    return math.sqrt(dLat * dLat + dLng * dLng);

  }

}

