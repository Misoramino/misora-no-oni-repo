import 'package:flutter_test/flutter_test.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:oni_game/game/inspector_intel_pin.dart';
import 'package:oni_game/game/location_reveal_event.dart';
import 'package:oni_game/game/player_role.dart';
import 'package:oni_game/sync/remote_member_snapshot.dart';
import 'package:oni_game/sync/shared_match_snapshot.dart';

void main() {
  test('build picks latest reveal per assignment uid', () {
    final t0 = DateTime.utc(2026, 1, 1, 12);
    final t1 = t0.add(const Duration(minutes: 2));
    final pins = InspectorIntelPinLogic.build(
      assignments: {
        'u1': const SharedPlayerAssignment(
          role: PlayerRole.runner,
          skills: [],
        ),
        'u2': const SharedPlayerAssignment(
          role: PlayerRole.hunter,
          skills: [],
        ),
      },
      remoteMembers: {
        'u1': RemoteMemberSnapshot(
          uid: 'u1',
          nickname: 'Alice',
          role: 'runner',
          reportedAtUtc: t1,
        ),
      },
      revealLog: [
        LocationRevealEvent(
          sequence: 1,
          timestamp: t0,
          position: const LatLng(35.0, 139.0),
          overflowMeters: 10,
          subjectUid: 'u1',
        ),
        LocationRevealEvent(
          sequence: 2,
          timestamp: t1,
          position: const LatLng(35.1, 139.1),
          overflowMeters: 5,
          subjectUid: 'u1',
        ),
      ],
      hunterPositions: {
        'u2': const LatLng(35.2, 139.2),
      },
      eliminatedUids: const {},
      now: t1,
    );

    expect(pins.length, 2);
    final alice = pins.firstWhere((p) => p.uid == 'u1');
    expect(alice.label, 'Alice');
    expect(alice.position.latitude, closeTo(35.1, 0.001));
    expect(alice.sourceLabel, '暴露');
  });
}
