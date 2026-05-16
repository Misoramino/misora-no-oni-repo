import 'remote_member_snapshot.dart';

/// ロビー一覧用（自分／他プレイヤーを UI で区別）。
class RoomMemberView {
  const RoomMemberView({
    required this.member,
    required this.isSelf,
  });

  final RemoteMemberSnapshot member;
  final bool isSelf;
}
