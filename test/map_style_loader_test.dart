import 'package:flutter_test/flutter_test.dart';
import 'package:oni_game/theme/map_style_loader.dart';

void main() {
  test('withLabelsHidden appends labels-off rule', () {
    const base = '[{"elementType":"geometry","stylers":[{"color":"#000"}]}]';
    final hidden = MapStyleLoader.withLabelsHidden(base);
    expect(hidden, isNotNull);
    expect(hidden, contains('"labels"'));
    expect(hidden, contains('"off"'));
    expect(hidden, contains('#000'));
  });

  test('withLabelsHidden returns null for null input', () {
    expect(MapStyleLoader.withLabelsHidden(null), isNull);
  });
}
