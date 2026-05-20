import 'package:flutter_test/flutter_test.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:oni_game/game/elimination_aftermath_rule.dart';
import 'package:oni_game/game/game_state.dart';
import 'package:oni_game/game/oni_intel_mode.dart';
import 'package:oni_game/game/play_area.dart';
import 'package:oni_game/game/player_role.dart';
import 'package:oni_game/sync/firestore_room_blueprint.dart';
import 'package:oni_game/sync/shared_match_snapshot.dart';

void main() {
  test('SharedMatchSnapshot roundtrip', () {
    const area = PlayArea.circle(
      center: LatLng(35.68, 139.76),
      radiusMeters: 400,
    );
    final original = SharedMatchSnapshot(
      gimmickSeed: 42,
      playArea: area,
      matchDurationSeconds: 180,
      oniIntelMode: OniIntelMode.fragmented,
      eliminationAftermathRule: EliminationAftermathRule.ghostSpectator,
      assignments: {
        'uid-a': const SharedPlayerAssignment(
          role: PlayerRole.runner,
          skills: ['fake_position'],
        ),
        'uid-b': const SharedPlayerAssignment(
          role: PlayerRole.hunter,
          skills: ['fake_intel_reveal', 'capture_zone'],
        ),
      },
      startedAtUtc: '2020-01-01T00:00:00.000Z',
      gimmickDensity: 1.15,
    );

    final parsed = SharedMatchSnapshot.tryParse(original.toMap());
    expect(parsed, isNotNull);
    expect(parsed!.gimmickSeed, 42);
    expect(parsed.gimmickDensity, closeTo(1.15, 0.001));
    expect(parsed.matchDurationSeconds, 180);
    expect(parsed.assignments.length, 2);
    expect(parsed.assignmentFor('uid-b')?.role, PlayerRole.hunter);
  });

  test('SharedMatchEnd parses room doc fields', () {
    final end = SharedMatchEnd.tryParse({
      RoomDocFields.endReason: MatchEndReason.timeUp,
      RoomDocFields.matchOutcome: GameState.runnerWin.name,
      RoomDocFields.endMessage: '逃走成功',
    });
    expect(end?.outcome, GameState.runnerWin);
    expect(end?.endReason, MatchEndReason.timeUp);
  });
}
