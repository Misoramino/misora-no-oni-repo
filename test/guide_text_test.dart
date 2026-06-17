import 'package:flutter_test/flutter_test.dart';
import 'package:oni_game/features/how_to_play/guide_text.dart';

void main() {
  test('keeps arrow flows on one line', () {
    const raw = 'ボタン → 地図を長押し → 離して設置';
    final out = GuideText.forDisplay(raw);
    expect(out, isNot(contains(' → ')));
    expect(out.contains('\u00A0→\u00A0'), isTrue);
  });

  test('glues circled step numbers', () {
    final out = GuideText.forDisplay('①下のボタンを押す');
    expect(out.startsWith('①\u00A0'), isTrue);
  });

  test('preserves intentional newlines', () {
    const raw = '①ボタン\n②長押し';
    final out = GuideText.forDisplay(raw);
    expect(out, contains('\n'));
    expect(out.startsWith('①\u00A0'), isTrue);
  });
}
