import '../game/game_config.dart';
import 'room_member_view.dart';

/// ホストの presence からバックグラウンド通話中の状態を判定する。
abstract final class HostPresenceStatus {
  static Duration? backgroundDuration(
    RoomMemberView? host,
    DateTime nowUtc,
  ) {
    if (host == null || host.appLifecycle != 'background') return null;
    final since = host.backgroundSinceUtc;
    if (since == null) return Duration.zero;
    return nowUtc.difference(since.toUtc());
  }

  /// 90 秒以上バックグラウンド → 他端末に「ホスト応答待ち」を表示。
  static bool showWaitingWarning(RoomMemberView? host, DateTime nowUtc) {
    final d = backgroundDuration(host, nowUtc);
    if (d == null) return false;
    return d.inSeconds >= GameConfig.hostBackgroundWarningSeconds;
  }

  /// 時間切れ救済: ホストが background または heartbeat stale。
  static bool unavailableForMatchEnd(RoomMemberView? host, DateTime nowUtc) {
    if (host == null) return true;
    if (host.isStale(nowUtc)) return true;
    return host.appLifecycle == 'background';
  }
}
