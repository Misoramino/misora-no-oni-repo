import '../game/player_role.dart';
import '../game/skill_ids.dart';
import 'firestore_room_blueprint.dart';
import 'shared_match_snapshot.dart';

/// ロビー一覧用（自分／他プレイヤーを UI で区別）。
class RoomMemberView {
  const RoomMemberView({
    required this.uid,
    required this.nickname,
    required this.role,
    required this.isSelf,
    this.isHost = false,
    this.reportedAtUtc,
    this.proximityBand,
    this.preferredRole,
    this.preferredSkills = const [],
  });

  final String uid;
  final String nickname;
  final String role;
  final bool isSelf;
  final bool isHost;
  final DateTime? reportedAtUtc;
  final String? proximityBand;
  final PlayerRole? preferredRole;
  final List<String> preferredSkills;

  bool get hasHeartbeat => reportedAtUtc != null;

  /// カスタム希望から試合用割当を組み立てる（無効なら null）。
  SharedPlayerAssignment? get preferredAssignment {
    final role = preferredRole;
    if (role == null) return null;
    final allowed = skillCandidatesForRole(role).toSet();
    final skills = preferredSkills.where(allowed.contains).toList();
    if (skills.isEmpty) {
      return SharedPlayerAssignment(
        role: role,
        skills: allowed.take(role == PlayerRole.hunter ? 2 : 1).toList(),
      );
    }
    final max = role == PlayerRole.hunter ? 2 : 1;
    return SharedPlayerAssignment(
      role: role,
      skills: skills.take(max).toList(),
    );
  }

  bool isStale(DateTime nowUtc) {
    final at = reportedAtUtc;
    if (at == null) return false;
    return nowUtc.difference(at.toUtc()) > const Duration(minutes: 3);
  }

  static RoomMemberView parse({
    required String uid,
    required Map<String, dynamic> data,
    required bool isSelf,
    bool isHost = false,
  }) {
    final rawTime = data[MemberPresenceFields.reportedAtUtc];
    DateTime? at;
    if (rawTime is String) {
      at = DateTime.tryParse(rawTime);
    }
    return RoomMemberView(
      uid: uid,
      nickname: (data[MemberPresenceFields.nickname] as String?) ?? '',
      role: (data[MemberPresenceFields.role] as String?) ?? 'runner',
      isSelf: isSelf,
      isHost: isHost,
      reportedAtUtc: at,
      proximityBand: data[MemberPresenceFields.proximityBand] as String?,
      preferredRole: _parsePreferredRole(
        data[MemberPresenceFields.preferredRole] as String?,
      ),
      preferredSkills: _parsePreferredSkills(
        data[MemberPresenceFields.preferredSkills],
      ),
    );
  }

  static PlayerRole? _parsePreferredRole(String? raw) {
    if (raw == null) return null;
    for (final r in assignablePlayerRoles) {
      if (r.name == raw) return r;
    }
    return null;
  }

  static List<String> _parsePreferredSkills(Object? raw) {
    if (raw is! List) return const [];
    return raw.map((e) => e.toString()).toList();
  }
}
