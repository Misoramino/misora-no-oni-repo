import 'package:geolocator/geolocator.dart';

import '../game/sampling_tier.dart';

class LocationService {
  Future<bool> ensurePermission() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return false;
    }

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      return false;
    }

    return true;
  }

  Future<Position> getCurrentPosition() {
    return Geolocator.getCurrentPosition();
  }

  Stream<Position> watchPosition(LocationSamplingTier tier) {
    return Geolocator.getPositionStream(
      locationSettings: tier.locationSettings(),
    );
  }
}
