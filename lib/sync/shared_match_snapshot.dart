import '../game/elimination_aftermath_rule.dart';
import '../game/game_state.dart';
import '../game/oni_intel_mode.dart';
import '../game/play_area.dart';
import '../game/player_role.dart';
import 'firestore_room_blueprint.dart';

/// 1 試合分の役職・スキル・ギミック（ホストが room doc に 1 回書く）。
class SharedMatchSnapshot {
  const SharedMatchSnapshot({
    required this.gimmickSeed,
    required this.playArea,
    required this.matchDurationSeconds,
    required this.oniIntelMode,
    required this.eliminationAftermathRule,
    required this.assignments,
    this.startedAtUtc,
  });

  final int gimmickSeed;
  final PlayArea playArea;
  final int matchDurationSeconds;
  final OniIntelMode oniIntelMode;
  final EliminationAftermathRule eliminationAftermathRule;

  /// uid → 割当
  final Map<String, SharedPlayerAssignment> assignments;
  final String? startedAtUtc;

  Map<String, dynamic> toMap() => {
        RoomDocFields.matchStartGimmickSeed: gimmickSeed,
        RoomDocFields.matchStartPlayArea: playArea.toJson(),
        RoomDocFields.matchStartDurationSec: matchDurationSeconds,
        RoomDocFields.matchStartOniIntelMode: oniIntelMode.name,
        RoomDocFields.matchStartAftermathRule: eliminationAftermathRule.name,
        RoomDocFields.matchStartAssignments: {
          for (final e in assignments.entries) e.key: e.value.toMap(),
        },
        if (startedAtUtc != null)
          RoomDocFields.matchStartStartedAtUtc: startedAtUtc,
      };

  static SharedMatchSnapshot? tryParse(Map<String, dynamic>? raw) {
    if (raw == null || raw.isEmpty) return null;
    final seed = raw[RoomDocFields.matchStartGimmickSeed];
    final areaRaw = raw[RoomDocFields.matchStartPlayArea];
    final duration = raw[RoomDocFields.matchStartDurationSec];
    final assignmentsRaw = raw[RoomDocFields.matchStartAssignments];
    if (seed is! num || areaRaw is! Map || duration is! num) return null;
    if (assignmentsRaw is! Map) return null;

    final assignments = <String, SharedPlayerAssignment>{};
    for (final e in assignmentsRaw.entries) {
      if (e.value is! Map) continue;
      final a = SharedPlayerAssignment.tryParse(
        Map<String, dynamic>.from(e.value as Map),
      );
      if (a != null) assignments[e.key.toString()] = a;
    }
    if (assignments.isEmpty) return null;

    return SharedMatchSnapshot(
      gimmickSeed: seed.toInt(),
      playArea: PlayArea.fromJson(Map<String, dynamic>.from(areaRaw)),
      matchDurationSeconds: duration.toInt(),
      oniIntelMode: _parseOniIntelMode(
        raw[RoomDocFields.matchStartOniIntelMode] as String?,
      ),
      eliminationAftermathRule: _parseAftermathRule(
            raw[RoomDocFields.matchStartAftermathRule] as String?,
          ) ??
          EliminationAftermathRule.ghostSpectator,
      assignments: assignments,
      startedAtUtc: raw[RoomDocFields.matchStartStartedAtUtc] as String?,
    );
  }

  static EliminationAftermathRule? _parseAftermathRule(String? raw) {
    if (raw == null) return null;
    for (final v in EliminationAftermathRule.values) {
      if (v.name == raw) return v;
    }
    return null;
  }

  static OniIntelMode _parseOniIntelMode(String? raw) {
    if (raw == null) return OniIntelMode.directionOnly;
    for (final v in OniIntelMode.values) {
      if (v.name == raw) return v;
    }
    return OniIntelMode.directionOnly;
  }

  SharedPlayerAssignment? assignmentFor(String? uid) =>
      uid == null ? null : assignments[uid];
}

class SharedPlayerAssignment {
  const SharedPlayerAssignment({
    required this.role,
    required this.skills,
  });

  final PlayerRole role;
  final List<String> skills;

  Map<String, dynamic> toMap() => {
        'role': role.name,
        'skills': skills,
      };

  static SharedPlayerAssignment? tryParse(Map<String, dynamic> json) {
    final roleName = json['role'] as String?;
    if (roleName == null) return null;
    PlayerRole? role;
    for (final r in assignablePlayerRoles) {
      if (r.name == roleName) {
        role = r;
        break;
      }
    }
    if (role == null) return null;
    final skillsRaw = json['skills'];
    final skills = skillsRaw is List
        ? skillsRaw.map((e) => e.toString()).toList()
        : <String>[];
    return SharedPlayerAssignment(role: role, skills: skills);
  }
}

/// 試合終了時に room doc に載せる結果。
class SharedMatchEnd {
  const SharedMatchEnd({
    required this.endReason,
    required this.outcome,
    required this.message,
    this.endedAtUtc,
  });

  final String endReason;
  final GameState outcome;
  final String message;
  final String? endedAtUtc;

  static SharedMatchEnd? tryParse(Map<String, dynamic>? roomData) {
    if (roomData == null) return null;
    final reason = roomData[RoomDocFields.endReason] as String?;
    final outcomeRaw = roomData[RoomDocFields.matchOutcome] as String?;
    if (reason == null || outcomeRaw == null) return null;
    final outcome = _parseOutcome(outcomeRaw);
    if (outcome == null) return null;
    return SharedMatchEnd(
      endReason: reason,
      outcome: outcome,
      message: roomData[RoomDocFields.endMessage] as String? ?? '',
      endedAtUtc: roomData[RoomDocFields.endedAtUtc] as String?,
    );
  }

  static GameState? _parseOutcome(String raw) {
    for (final s in [GameState.runnerWin, GameState.caughtByOni]) {
      if (s.name == raw) return s;
    }
    return null;
  }
}

/// room doc の phase + 共有試合データ。
class RoomMatchState {
  const RoomMatchState({
    required this.phase,
    this.matchStart,
    this.matchEnd,
  });

  final String phase;
  final SharedMatchSnapshot? matchStart;
  final SharedMatchEnd? matchEnd;
}
