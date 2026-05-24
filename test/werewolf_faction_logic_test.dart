import 'package:flutter_test/flutter_test.dart';
import 'package:oni_game/game/player_role.dart';
import 'package:oni_game/game/werewolf_faction_logic.dart';

MatchParticipantState p(
  String uid,
  PlayerRole role, {
  bool oni = false,
  bool out = false,
}) =>
    MatchParticipantState(
      uid: uid,
      assignmentRole: role,
      werewolfInOniForm: oni,
      eliminated: out,
    );

void main() {
  test('3 players: werewolf is human faction (1 human vs 1 oni among others)', () {
    final players = [
      p('h', PlayerRole.hunter),
      p('w', PlayerRole.werewolf),
      p('r', PlayerRole.runner),
    ];
    expect(
      WerewolfFactionLogic.factionFor(
        assignmentRole: PlayerRole.werewolf,
        players: players,
        uid: 'w',
      ),
      FactionSide.humanTeam,
    );
    expect(
      WerewolfFactionLogic.werewolfCanCaptureInOniForm(FactionSide.humanTeam),
      isTrue,
    );
  });

  test('4 players: werewolf starts oni faction (2 humans > 1 oni among others)', () {
    final players = [
      p('h', PlayerRole.hunter),
      p('w', PlayerRole.werewolf),
      p('r1', PlayerRole.runner),
      p('r2', PlayerRole.runner),
    ];
    expect(
      WerewolfFactionLogic.factionFor(
        assignmentRole: PlayerRole.werewolf,
        players: players,
        uid: 'w',
      ),
      FactionSide.oniTeam,
    );
    expect(
      WerewolfFactionLogic.werewolfCanCaptureInOniForm(FactionSide.oniTeam),
      isFalse,
    );
  });

  test('werewolf human form counts as human role; oni form as oni role', () {
  final humanForm = p('w', PlayerRole.werewolf, oni: false);
  final oniForm = p('w', PlayerRole.werewolf, oni: true);
  expect(WerewolfFactionLogic.perceivedRoleFor(humanForm), PerceivedRole.human);
  expect(WerewolfFactionLogic.perceivedRoleFor(oniForm), PerceivedRole.oni);
  });

  test('faction flips when human count no longer exceeds oni count', () {
    var players = [
      p('h', PlayerRole.hunter),
      p('w', PlayerRole.werewolf),
      p('r1', PlayerRole.runner),
      p('r2', PlayerRole.runner),
    ];
    expect(
      WerewolfFactionLogic.factionFor(
        assignmentRole: PlayerRole.werewolf,
        players: players,
        uid: 'w',
      ),
      FactionSide.oniTeam,
    );
  // 1 runner eliminated → 1 human vs 1 oni (hunter) among others
    players = [
      p('h', PlayerRole.hunter),
      p('w', PlayerRole.werewolf),
      p('r1', PlayerRole.runner),
      p('r2', PlayerRole.runner, out: true),
    ];
    expect(
      WerewolfFactionLogic.factionFor(
        assignmentRole: PlayerRole.werewolf,
        players: players,
        uid: 'w',
      ),
      FactionSide.humanTeam,
    );
  });

  test('eliminated players are excluded from role counts', () {
    final players = [
      p('h', PlayerRole.hunter),
      p('w', PlayerRole.werewolf),
      p('r', PlayerRole.runner, out: true),
    ];
    final counts = WerewolfFactionLogic.countOthersPerceivedRoles(
      players: players,
      selfUid: 'w',
    );
    expect(counts.humanCount, 0);
    expect(counts.oniCount, 1);
  });

  test('proximity BLE capture when GPS far from hunter', () {
    const captureM = 12.0;
    const farGps = 100.0;

    // 3p: human-faction werewolf in oni form — allow (can capture).
    final players3 = [
      p('h', PlayerRole.hunter),
      p('w', PlayerRole.werewolf, oni: true),
      p('r', PlayerRole.runner),
    ];
    expect(
      WerewolfFactionLogic.proximityCapturePermittedForRunner(
        gpsDistanceToHunterMeters: farGps,
        captureDistanceMeters: captureM,
        bleContactBand: true,
        participants: players3,
        runnerUid: 'r',
      ),
      isTrue,
    );

    // 4p: oni-faction werewolf only — block BLE-only capture.
    final players4 = [
      p('h', PlayerRole.hunter),
      p('w', PlayerRole.werewolf, oni: true),
      p('r1', PlayerRole.runner),
      p('r2', PlayerRole.runner),
    ];
    expect(
      WerewolfFactionLogic.proximityCapturePermittedForRunner(
        gpsDistanceToHunterMeters: farGps,
        captureDistanceMeters: captureM,
        bleContactBand: true,
        participants: players4,
        runnerUid: 'r1',
      ),
      isFalse,
    );

    // GPS close — always allow.
    expect(
      WerewolfFactionLogic.proximityCapturePermittedForRunner(
        gpsDistanceToHunterMeters: 5,
        captureDistanceMeters: captureM,
        bleContactBand: true,
        participants: players4,
        runnerUid: 'r1',
      ),
      isTrue,
    );

    // No BLE contact — allow.
    expect(
      WerewolfFactionLogic.proximityCapturePermittedForRunner(
        gpsDistanceToHunterMeters: farGps,
        captureDistanceMeters: captureM,
        bleContactBand: false,
        participants: players4,
        runnerUid: 'r1',
      ),
      isTrue,
    );
  });
}
