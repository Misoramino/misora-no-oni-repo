import 'package:flutter_test/flutter_test.dart';
import 'package:oni_game/sync/firestore_room_blueprint.dart';
import 'package:oni_game/sync/remote_member_snapshot.dart';
import 'package:oni_game/sync/room_member_view.dart';

void main() {
  test('lobby presence parses without live coordinates', () {
    final view = RoomMemberView.parse(
      uid: 'uid-1',
      data: {
        MemberPresenceFields.nickname: 'player',
        MemberPresenceFields.role: 'runner',
        MemberPresenceFields.reportedAtUtc: '2026-01-10T10:00:00.000Z',
        MemberPresenceFields.locationVisibility: 'hidden',
      },
      isSelf: false,
    );

    expect(view.nickname, 'player');
    expect(view.role, 'runner');
    expect(view.hasHeartbeat, isTrue);
    expect(view.isSelf, isFalse);
    expect(view.isHost, isFalse);
  });

  test('lobby member can be marked host', () {
    final view = RoomMemberView.parse(
      uid: 'host-uid',
      data: {
        MemberPresenceFields.nickname: 'host',
        MemberPresenceFields.role: 'runner',
        MemberPresenceFields.reportedAtUtc: '2026-01-10T10:00:00.000Z',
        MemberPresenceFields.locationVisibility: 'hidden',
      },
      isSelf: false,
      isHost: true,
    );
    expect(view.isHost, isTrue);
  });

  test('remote map snapshots still require explicit coordinates', () {
    final hiddenPresence = {
      MemberPresenceFields.nickname: 'oni',
      MemberPresenceFields.role: 'oni',
      MemberPresenceFields.reportedAtUtc: '2026-01-10T10:00:00.000Z',
      MemberPresenceFields.locationVisibility: 'hidden',
    };

    expect(RemoteMemberSnapshot.tryParse('uid-oni', hiddenPresence), isNull);
  });
}
