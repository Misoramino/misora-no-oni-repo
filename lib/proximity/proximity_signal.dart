enum ProximityBand {
  none,
  far,
  near,
  contact,
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
