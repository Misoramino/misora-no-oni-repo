/// Google Maps / Roads API キー（ビルド時 `--dart-define=GOOGLE_MAPS_API_KEY=...`）。
abstract final class GoogleMapsConfig {
  static const String apiKey = String.fromEnvironment('GOOGLE_MAPS_API_KEY');

  static bool get isConfigured => apiKey.isNotEmpty;
}
