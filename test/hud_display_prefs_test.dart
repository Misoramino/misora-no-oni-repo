import 'package:flutter_test/flutter_test.dart';
import 'package:oni_game/features/game_map/hud/hud_compact_line.dart';
import 'package:oni_game/session/hud_display_prefs.dart';

void main() {
  test('HudDisplaySettings defaults', () {
    const s = HudDisplaySettings();
    expect(s.compactLineSlot, HudCompactLineSlot.all);
    expect(s.showIntelLine, isTrue);
  });
}
