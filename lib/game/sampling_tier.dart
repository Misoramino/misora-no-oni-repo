import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';

/// GPSストリームの「荒さ」を切り替える。処理が軽い時間帯は粗く・緊迫時は細かめる。
enum LocationSamplingTier { relaxed, standard, chase }

extension LocationSamplingTierX on LocationSamplingTier {
  LocationSettings locationSettings({
    LocationAccuracy accuracy = LocationAccuracy.high,
  }) {
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return AndroidSettings(
          accuracy: accuracy,
          distanceFilter: distanceFilterMeters,
          intervalDuration: intervalDuration,
          foregroundNotificationConfig: const ForegroundNotificationConfig(
            notificationTitle: 'ONI PIN が位置情報を取得中',
            notificationText: '試合中の位置追跡',
            notificationChannelName: 'ONI PIN 位置情報',
            setOngoing: true,
          ),
        );
      case TargetPlatform.iOS:
        return AppleSettings(
          accuracy: accuracy,
          distanceFilter: distanceFilterMeters,
          activityType: ActivityType.fitness,
          pauseLocationUpdatesAutomatically: false,
          allowBackgroundLocationUpdates: true,
          showBackgroundLocationIndicator: true,
        );
      case TargetPlatform.macOS:
      case TargetPlatform.fuchsia:
      case TargetPlatform.linux:
      case TargetPlatform.windows:
        break;
    }
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

  Duration get intervalDuration {
    switch (this) {
      case LocationSamplingTier.relaxed:
        return const Duration(seconds: 12);
      case LocationSamplingTier.standard:
        return const Duration(seconds: 5);
      case LocationSamplingTier.chase:
        return const Duration(seconds: 2);
    }
  }
}
