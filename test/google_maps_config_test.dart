import 'package:flutter_test/flutter_test.dart';
import 'package:oni_game/config/google_maps_config.dart';

void main() {
  test('GoogleMapsConfig defaults to empty when not defined at build', () {
    expect(GoogleMapsConfig.apiKey, isA<String>());
    expect(GoogleMapsConfig.isConfigured, GoogleMapsConfig.apiKey.isNotEmpty);
  });
}
