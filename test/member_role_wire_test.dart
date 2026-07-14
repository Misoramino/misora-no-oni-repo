import 'package:flutter_test/flutter_test.dart';
import 'package:oni_game/sync/member_role_wire.dart';

void main() {
  test('isOniRole accepts oni and hunter', () {
    expect(MemberRoleWire.isOniRole('oni'), isTrue);
    expect(MemberRoleWire.isOniRole('hunter'), isTrue);
    expect(MemberRoleWire.isOniRole('runner'), isFalse);
    expect(MemberRoleWire.isOniRole(null), isFalse);
  });

  test('displayLabel covers common roles', () {
    expect(MemberRoleWire.displayLabel('oni'), '鬼');
    expect(MemberRoleWire.displayLabel('hunter'), '鬼');
    expect(MemberRoleWire.displayLabel('werewolf'), '人狼');
    expect(MemberRoleWire.displayLabel('spectator'), '観戦');
    expect(MemberRoleWire.displayLabel('runner'), '逃走者');
    expect(MemberRoleWire.displayLabel(''), '逃走者');
  });
}
