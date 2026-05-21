import 'package:flutter_test/flutter_test.dart';
import 'package:oni_game/features/game_map/hud/hud_compact_line.dart';

void main() {
  test('all joins enabled lines in order', () {
    expect(
      resolveHudCompactLineText(
        slot: HudCompactLineSlot.all,
        showIntelLine: true,
        showStatusLine: true,
        showConditionLine: true,
        intelLine: '鬼: 北',
        statusText: '走れ',
        conditionText: '疲労',
      ),
      '鬼: 北  ·  走れ  ·  疲労',
    );

    expect(
      resolveHudCompactLineText(
        slot: HudCompactLineSlot.all,
        showIntelLine: false,
        showStatusLine: true,
        showConditionLine: true,
        intelLine: '鬼: 北',
        statusText: '走れ',
        conditionText: '疲労',
      ),
      '走れ  ·  疲労',
    );
  });

  test('fixed slot shows only that line', () {
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

  test('storage migrates auto to all', () {
    expect(HudCompactLineSlotLabel.fromStorage('auto'), HudCompactLineSlot.all);
    expect(HudCompactLineSlotLabel.fromStorage('all'), HudCompactLineSlot.all);
  });

  test('never includes area text', () {
    expect(
      resolveHudCompactLineText(
        slot: HudCompactLineSlot.all,
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
