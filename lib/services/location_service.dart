import 'package:geolocator/geolocator.dart';

import '../game/sampling_tier.dart';

enum LocationAccessStatus {
  granted,
  serviceDisabled,
  denied,
  deniedForever,
}

class LocationAccessCheck {
  const LocationAccessCheck(this.status);

  final LocationAccessStatus status;

  bool get granted => status == LocationAccessStatus.granted;
}

class LocationService {
  Future<LocationAccessCheck> checkLocationAccess() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return const LocationAccessCheck(LocationAccessStatus.serviceDisabled);
    }

    final permission = await Geolocator.checkPermission();
    return LocationAccessCheck(_statusFromPermission(permission));
  }

  Future<bool> ensurePermission() async {
    var check = await checkLocationAccess();
    if (check.status == LocationAccessStatus.denied) {
      final permission = await Geolocator.requestPermission();
      check = LocationAccessCheck(_statusFromPermission(permission));
    }
    return check.granted;
  }

  LocationAccessStatus _statusFromPermission(LocationPermission permission) {
    return switch (permission) {
      LocationPermission.always ||
      LocationPermission.whileInUse =>
        LocationAccessStatus.granted,
      LocationPermission.deniedForever => LocationAccessStatus.deniedForever,
      LocationPermission.denied => LocationAccessStatus.denied,
      LocationPermission.unableToDetermine => LocationAccessStatus.denied,
    };
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
