import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../../game/game_config.dart';
import '../../../game/oni_intel_mode.dart';
import 'map_geo_utils.dart';

/// 情報屋が返す鬼情報テキストを組み立てる。
abstract final class OniIntelTextBuilder {
  static String build({
    required OniIntelMode mode,
    required int elapsedSeconds,
    required bool oniInCommJammingZone,
    required LatLng playerPosition,
    required List<LatLng> commJammingZoneCenters,
    required String direction,
    required String distanceBand,
    required double bearingDegrees,
  }) {
    if (oniInCommJammingZone) {
      final coarse = MapGeoUtils.fragmentedCoarseCardinal(bearingDegrees);
      return '通信障害（鬼がゾーン内）: 情報屋の手がかりはほぼ解読不能 — $coarse 付近にノイズのみ';
    }
    if (!MapGeoUtils.isCommJammingWindowOpen(
      playerPosition: playerPosition,
      jammingZoneCenters: commJammingZoneCenters,
      elapsedSeconds: elapsedSeconds,
    )) {
      return '通信障害: ノイズ混入（方角・距離が大きく歪む）';
    }

    switch (mode) {
      case OniIntelMode.directionOnly:
        return '鬼は $direction 方向';
      case OniIntelMode.distanceBandOnly:
        return '鬼の距離帯: $distanceBand';
      case OniIntelMode.fragmented:
        final phase =
            (elapsedSeconds ~/ GameConfig.fragmentedPhaseSeconds) % 5;
        final coarse = MapGeoUtils.fragmentedCoarseCardinal(bearingDegrees);
        switch (phase) {
          case 0:
            return '断片: 信号途切れ — 方角・距離とも取得不能';
          case 1:
            return '断片: 粗い方角のみ — $coarse（精密方位は非表示）';
          case 2:
            return '断片: ノイズ帯 — このウィンドウは情報ロック';
          case 3:
            return '断片: 距離帯のみ — $distanceBand（方角は伏せられています）';
          case 4:
          default:
            return '断片: 同期ズレ — 次のウィンドウまで欠落';
        }
    }
  }
}
