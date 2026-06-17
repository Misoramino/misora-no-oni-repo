import 'room_member_view.dart';

/// ロビー・試合中で共通利用するメンバー接続状態ラベル。
abstract final class MemberConnectionLabel {
  /// grace 中は stale より優先。null なら通常オンライン。
  static String? statusLine(RoomMemberView member, DateTime nowUtc) {
    if (member.isInBackgroundGrace(nowUtc)) {
      if (member.isHost) return 'ホストが一時的に離れています';
      return '通話中 / 一時離脱中';
    }
    if (member.isStale(nowUtc)) return '接続不安定';
    return null;
  }
}
