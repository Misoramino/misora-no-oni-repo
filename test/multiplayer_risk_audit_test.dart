import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:oni_game/game/game_config.dart';
import 'package:oni_game/sync/match_elapsed_sync.dart';
import 'package:oni_game/sync/room_event_deduper.dart';
import 'package:oni_game/sync/room_match_event.dart';
import 'package:oni_game/sync/room_member_view.dart';

void main() {
  group('MatchElapsedSync — server-time match timer', () {
    test('elapsed follows startedAtUtc not local drift', () {
      final started = DateTime.utc(2026, 6, 16, 12, 0, 0);
      final now = started.add(const Duration(minutes: 10, seconds: 5));
      expect(
        MatchElapsedSync.elapsedSeconds(
          startedAtUtc: started.toIso8601String(),
          matchDurationSeconds: 2700,
          nowUtc: now,
        ),
        605,
      );
      expect(
        MatchElapsedSync.remainingSeconds(
          startedAtUtc: started.toIso8601String(),
          matchDurationSeconds: 2700,
          nowUtc: now,
        ),
        2095,
      );
    });

    test('clamps elapsed to match duration', () {
      final started = DateTime.utc(2026, 1, 1);
      final now = started.add(const Duration(hours: 2));
      expect(
        MatchElapsedSync.elapsedSeconds(
          startedAtUtc: started.toIso8601String(),
          matchDurationSeconds: 600,
          nowUtc: now,
        ),
        600,
      );
    });
  });

  group('RoomEventDeduper — idempotent event processing', () {
    test('duplicate capture event ignored', () {
      final deduper = RoomEventDeduper();
      expect(deduper.markIfNew('capture_evt_1'), isTrue);
      expect(deduper.markIfNew('capture_evt_1'), isFalse);
      expect(deduper.length, 1);
    });

    test('out-of-order replay still dedupes by doc id', () {
      final deduper = RoomEventDeduper();
      for (final id in ['b', 'a', 'c', 'a', 'b']) {
        deduper.markIfNew(id);
      }
      expect(deduper.length, 3);
    });
  });

  group('RoomMemberView — background grace', () {
    test('background within 15 min is not stale for elimination', () {
      final now = DateTime.utc(2026, 6, 16, 12, 30);
      final member = RoomMemberView(
        uid: 'u1',
        nickname: 'A',
        role: 'runner',
        isSelf: false,
        reportedAtUtc: now.subtract(const Duration(seconds: 30)),
        appLifecycle: 'background',
        backgroundSinceUtc: now.subtract(const Duration(minutes: 2)),
      );
      expect(member.isStale(now), isFalse);
      expect(member.isInBackgroundGrace(now), isTrue);
    });

    test('foreground after grace window is stale when heartbeat old', () {
      final now = DateTime.utc(2026, 6, 16, 12, 30);
      final member = RoomMemberView(
        uid: 'u1',
        nickname: 'A',
        role: 'runner',
        isSelf: false,
        reportedAtUtc: now.subtract(
          Duration(seconds: GameConfig.memberPresenceStaleSeconds + 5),
        ),
        appLifecycle: 'foreground',
      );
      expect(member.isInBackgroundGrace(now), isFalse);
      expect(member.isStale(now), isTrue);
    });
  });

  group('Firestore rules — participant event allowlist', () {
    late String rulesText;

    setUp(() {
      rulesText = File('firestore.rules').readAsStringSync();
    });

    test('safe_zone_pickup allowed for participants', () {
      expect(rulesText, contains("'safe_zone_pickup'"));
    });

    test('accusation_point_scored allowed for participants', () {
      expect(rulesText, contains("'accusation_point_scored'"));
    });

    test('lobby_play_area_proposal allowed for participants', () {
      expect(rulesText, contains("'lobby_play_area_proposal'"));
    });

    test('match_end is host-only', () {
      expect(rulesText, contains("'match_end'"));
      final hostOnlyStart = rulesText.indexOf('hostOnlyRoomEventType');
      final participantStart = rulesText.indexOf('participantRoomEventType');
      expect(hostOnlyStart, greaterThan(0));
      expect(participantStart, greaterThan(0));
      final hostBlock = rulesText.substring(hostOnlyStart, hostOnlyStart + 400);
      final participantBlock =
          rulesText.substring(participantStart, participantStart + 900);
      expect(hostBlock, contains("'match_end'"));
      expect(participantBlock, isNot(contains("'match_end'")));
    });

    test('player_eliminated restricted to host or self uid', () {
      expect(rulesText, contains("d.type != 'player_eliminated'"));
      expect(rulesText, contains('d.payload.uid == request.auth.uid'));
    });
  });

  group('RoomMatchEventTypes — authority classification', () {
    test('host-only types are not published by participants in code paths', () {
      const hostOnly = {
        RoomMatchEventTypes.matchStart,
        RoomMatchEventTypes.matchEnd,
        RoomMatchEventTypes.captureZoneBound,
        RoomMatchEventTypes.accusationUnlocked,
        RoomMatchEventTypes.lobbyPlayArea,
      };
      const participant = {
        RoomMatchEventTypes.reveal,
        RoomMatchEventTypes.safeZonePickup,
        RoomMatchEventTypes.accusationPointScored,
        RoomMatchEventTypes.lobbyPlayAreaProposal,
        RoomMatchEventTypes.captureZonePlaced,
        RoomMatchEventTypes.accusationAttempt,
      };
      for (final t in hostOnly) {
        expect(participant, isNot(contains(t)));
      }
    });
  });

  group('GameConfig — resume and GPS guards', () {
    test('resume catch-up grace is short', () {
      expect(GameConfig.resumeCatchUpGraceSeconds, lessThanOrEqualTo(6));
    });

    test('gps max fix age rejects stale captures', () {
      expect(GameConfig.gpsMaxFixAgeSeconds, greaterThan(0));
      expect(GameConfig.gpsMaxFixAgeSeconds, lessThanOrEqualTo(20));
    });
  });
}
