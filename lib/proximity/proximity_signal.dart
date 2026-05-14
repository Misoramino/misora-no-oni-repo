enum ProximityBand {
  none,
  far,
  near,
  contact,
}

/// より「脅威が高い」帯を採用（GPS粗 + BLE 精密の合成に使用）。
ProximityBand mergeProximityBands(ProximityBand a, ProximityBand b) {
  int rank(ProximityBand x) => switch (x) {
        ProximityBand.none => 0,
        ProximityBand.far => 1,
        ProximityBand.near => 2,
        ProximityBand.contact => 3,
      };
  return rank(a) >= rank(b) ? a : b;
}

class ProximitySignal {
  const ProximitySignal({
    required this.band,
    required this.confidence,
    required this.updatedAtUtc,
    required this.source,
  });

  final ProximityBand band;
  final double confidence;
  final DateTime updatedAtUtc;
  final String source; // e.g. "ble_mock", "ble_scan"
}
