import 'package:flutter_test/flutter_test.dart';
import 'package:oni_game/sync/room_phase.dart';

void main() {
  test('normalize keeps known phases', () {
    expect(RoomPhase.normalize(RoomPhase.running), RoomPhase.running);
    expect(RoomPhase.normalize(null), RoomPhase.lobby);
    expect(RoomPhase.normalize('unknown'), RoomPhase.lobby);
  });

  test('isKnown filters invalid values', () {
    expect(RoomPhase.isKnown(RoomPhase.ended), isTrue);
    expect(RoomPhase.isKnown(''), isFalse);
  });
}
