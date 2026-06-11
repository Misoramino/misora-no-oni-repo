import 'player_role.dart';

/// 周囲から見た現在のロール（人狼は鬼化状態で鬼ロール）。
enum PerceivedRole {
  human,
  oni,
}

/// 勝敗判定用の陣営（脱落後の第二ゲームもこの所属で分岐）。
enum FactionSide {
  humanTeam,
  oniTeam,
}

/// 陣営計算に使う生存プレイヤー1人分。
class MatchParticipantState {
  const MatchParticipantState({
    required this.uid,
    required this.assignmentRole,
    required this.werewolfInOniForm,
    required this.eliminated,
  });

  final String uid;
  final PlayerRole assignmentRole;
  final bool werewolfInOniForm;
  final bool eliminated;
}

abstract final class WerewolfFactionLogic {
  /// 現在の見え方ロール。
  static PerceivedRole perceivedRoleFor(MatchParticipantState player) {
    return switch (player.assignmentRole) {
      PlayerRole.hunter => PerceivedRole.oni,
      PlayerRole.runner => PerceivedRole.human,
      PlayerRole.werewolf =>
        player.werewolfInOniForm ? PerceivedRole.oni : PerceivedRole.human,
    };
  }

  /// 脱落していない参加者の陣営別人数（勝敗判定用）。
  static ({int humanAlive, int oniAlive}) countAliveFactions({
    required List<MatchParticipantState> players,
  }) {
    var human = 0;
    var oni = 0;
    for (final p in players) {
      if (p.eliminated) continue;
      switch (factionFor(
        assignmentRole: p.assignmentRole,
        players: players,
        uid: p.uid,
      )) {
        case FactionSide.humanTeam:
          human++;
        case FactionSide.oniTeam:
          oni++;
      }
    }
    return (humanAlive: human, oniAlive: oni);
  }

  /// 自分以外の生存者について人ロール／鬼ロール数を数える。
  static ({int humanCount, int oniCount}) countOthersPerceivedRoles({
    required List<MatchParticipantState> players,
    required String selfUid,
  }) {
    var human = 0;
    var oni = 0;
    for (final p in players) {
      if (p.uid == selfUid || p.eliminated) continue;
      switch (perceivedRoleFor(p)) {
        case PerceivedRole.human:
          human++;
        case PerceivedRole.oni:
          oni++;
      }
    }
    return (humanCount: human, oniCount: oni);
  }

  /// 人狼の陣営（状態に依らず固定。人数比で決まる）。
  static FactionSide werewolfFaction({
    required List<MatchParticipantState> players,
    required String werewolfUid,
  }) {
    final counts = countOthersPerceivedRoles(
      players: players,
      selfUid: werewolfUid,
    );
    return counts.humanCount <= counts.oniCount
        ? FactionSide.humanTeam
        : FactionSide.oniTeam;
  }

  static FactionSide factionFor({
    required PlayerRole assignmentRole,
    required List<MatchParticipantState> players,
    required String uid,
  }) {
    return switch (assignmentRole) {
      PlayerRole.runner => FactionSide.humanTeam,
      PlayerRole.hunter => FactionSide.oniTeam,
      PlayerRole.werewolf => werewolfFaction(players: players, werewolfUid: uid),
    };
  }

  /// 鬼化中の人狼が捕獲（殺害）できるか。鬼陣営のときは感染のみ。
  static bool werewolfCanCaptureInOniForm(FactionSide faction) =>
      faction == FactionSide.humanTeam;

  /// 周囲から鬼と認識されるか（BLE 広告・鬼同士免疫など）。
  static bool isPerceivedOni({
    required PlayerRole assignmentRole,
    required bool werewolfInOniForm,
  }) =>
      assignmentRole == PlayerRole.hunter ||
      (assignmentRole == PlayerRole.werewolf && werewolfInOniForm);

  /// 鬼の接近・感染・拘束の対象になるか。
  static bool subjectToOniProximityRules({
    required PlayerRole assignmentRole,
    required bool werewolfInOniForm,
  }) =>
      !isPerceivedOni(
        assignmentRole: assignmentRole,
        werewolfInOniForm: werewolfInOniForm,
      );

  /// GPS 上は本鬼から遠いが BLE 接触帯だけ捕獲可能なとき、
  /// 鬼陣営人狼（感染のみ）だけが鬼化中なら BLE 単独捕獲をブロックする。
  ///
  /// 人陣営人狼が鬼化中にいれば捕獲可として許可（本鬼接触と区別できない限界あり）。
  static bool proximityCapturePermittedForRunner({
    required double gpsDistanceToHunterMeters,
    required double captureDistanceMeters,
    required bool bleContactBand,
    required List<MatchParticipantState> participants,
    required String runnerUid,
  }) {
    if (gpsDistanceToHunterMeters <= captureDistanceMeters) return true;
    if (!bleContactBand) return true;

    var anyCapturingOniWolf = false;
    var anyNonCapturingOniWolf = false;
    for (final p in participants) {
      if (p.uid == runnerUid || p.eliminated) continue;
      if (p.assignmentRole != PlayerRole.werewolf || !p.werewolfInOniForm) {
        continue;
      }
      final faction = factionFor(
        assignmentRole: PlayerRole.werewolf,
        players: participants,
        uid: p.uid,
      );
      if (werewolfCanCaptureInOniForm(faction)) {
        anyCapturingOniWolf = true;
      } else {
        anyNonCapturingOniWolf = true;
      }
    }
    if (anyNonCapturingOniWolf && !anyCapturingOniWolf) return false;
    return true;
  }
}

extension FactionSideUi on FactionSide {
  String get label => switch (this) {
        FactionSide.humanTeam => '人陣営',
        FactionSide.oniTeam => '鬼陣営',
      };
}

extension PerceivedRoleUi on PerceivedRole {
  String get label => switch (this) {
        PerceivedRole.human => '人ロール',
        PerceivedRole.oni => '鬼ロール',
      };
}
