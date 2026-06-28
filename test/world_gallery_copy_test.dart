import 'package:flutter_test/flutter_test.dart';

import 'package:oni_game/presentation/world/world_gallery_copy.dart';
import 'package:oni_game/theme/world_profile.dart';

void main() {
  group('WorldGalleryCopy', () {
    for (final profile in WorldProfile.values) {
      test('${profile.name} description is two keyword lines', () {
        final text = WorldGalleryCopy.description(profile);
        final lines = text.split('\n');
        expect(lines.length, 2);
        for (final line in lines) {
          expect(line.trim(), isNotEmpty);
          expect(line, contains('・'));
        }
      });
    }
  });
}
