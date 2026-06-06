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

  test('remote snapshot parses without coordinates (avatar/role still carried)',
      () {
    final hiddenPresence = {
      MemberPresenceFields.nickname: 'oni',
      MemberPresenceFields.role: 'oni',
      MemberPresenceFields.reportedAtUtc: '2026-01-10T10:00:00.000Z',
      MemberPresenceFields.locationVisibility: 'hidden',
      MemberPresenceFields.avatarThumbB64: 'ZmFrZQ==',
    };

    final snap = RemoteMemberSnapshot.tryParse('uid-oni', hiddenPresence);
    expect(snap, isNotNull);
    expect(snap!.hasCoords, isFalse);
    expect(snap.lat, isNull);
    expect(snap.lng, isNull);
    expect(snap.role, 'oni');
    // 座標が無くても顔写真サムネは届く（暴露ピンの顔表示が成立する）。
    expect(snap.avatarThumbB64, 'ZmFrZQ==');
  });

  test('remote snapshot keeps coordinates when present', () {
    final withCoords = {
      MemberPresenceFields.nickname: 'runner',
      MemberPresenceFields.role: 'runner',
      MemberPresenceFields.reportedAtUtc: '2026-01-10T10:00:00.000Z',
      MemberPresenceFields.lastLat: 35.0,
      MemberPresenceFields.lastLng: 139.0,
    };

    final snap = RemoteMemberSnapshot.tryParse('uid-r', withCoords);
    expect(snap, isNotNull);
    expect(snap!.hasCoords, isTrue);
    expect(snap.lat, 35.0);
    expect(snap.lng, 139.0);
  });
}
