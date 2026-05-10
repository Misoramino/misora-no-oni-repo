import 'package:geolocator/geolocator.dart';

/// GPSストリームの「荒さ」を切り替える。処理が軽い時間帯は粗く・緊迫時は細かめる。
enum LocationSamplingTier {
  relaxed,
  standard,
  chase,
}

extension LocationSamplingTierX on LocationSamplingTier {
  LocationSettings locationSettings({
    LocationAccuracy accuracy = LocationAccuracy.high,
  }) {
    return LocationSettings(
      accuracy: accuracy,
      distanceFilter: distanceFilterMeters,
    );
  }

  /// Geolocator `distanceFilter`（メートル）のおすすめ値。
  int get distanceFilterMeters {
    switch (this) {
      case LocationSamplingTier.relaxed:
        return 15;
      case LocationSamplingTier.standard:
        return 8;
      case LocationSamplingTier.chase:
        return 5;
    }
  }
}
