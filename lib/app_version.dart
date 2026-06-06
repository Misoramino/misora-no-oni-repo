/// アプリのリリースバージョン（`pubspec.yaml` の `version:` と揃える）。
class AppVersion {
  AppVersion._();

  static const String label = '2.0.0';
  static const int buildNumber = 2;

  /// タイトル画面などに表示する短い表記。
  static const String display = 'v$label';
}
