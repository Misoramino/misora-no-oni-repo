import 'package:flutter_test/flutter_test.dart';
import 'package:oni_game/features/game_map/hud/hud_compact_line.dart';

void main() {
  test('auto picks first enabled line in priority order', () {
    expect(
      resolveHudCompactLineText(
        slot: HudCompactLineSlot.auto,
        showIntelLine: true,
        showStatusLine: true,
        showConditionLine: true,
        intelLine: '鬼: 北',
        statusText: '走れ',
        conditionText: '疲労',
      ),
      '鬼: 北',
    );

    expect(
      resolveHudCompactLineText(
        slot: HudCompactLineSlot.auto,
        showIntelLine: false,
        showStatusLine: true,
        showConditionLine: true,
        intelLine: '鬼: 北',
        statusText: '走れ',
        conditionText: '疲労',
      ),
      '走れ',
    );
  });

  test('fixed slot ignores other lines', () {
    expect(
      resolveHudCompactLineText(
        slot: HudCompactLineSlot.condition,
        showIntelLine: true,
        showStatusLine: true,
        showConditionLine: true,
        intelLine: '鬼',
        statusText: '走れ',
        conditionText: '疲労',
      ),
      '疲労',
    );
  });

  test('never includes area text', () {
    expect(
      resolveHudCompactLineText(
        slot: HudCompactLineSlot.auto,
        showIntelLine: false,
        showStatusLine: false,
        showConditionLine: false,
        intelLine: '',
        statusText: '',
        conditionText: '',
      ),
      isEmpty,
    );
  });
}
