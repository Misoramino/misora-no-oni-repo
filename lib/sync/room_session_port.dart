/// 将来の Firestore ルーム実装と差し替えるための薄いポート。
/// 現状はローカルのみ（オフライン想定）。
abstract class RoomSessionPort {
  /// UI 表示用（例: offline / lobby）
  String get modeLabel;

  /// 接続済みルームID。未接続は null。
  String? get roomId;

  Future<void> connectLocalDemo();
  Future<void> disconnect();
}

/// ネットワークなしのプレースホルダ。Firebase 接続時は別クラスに置き換え。
class LocalOnlyRoomSession implements RoomSessionPort {
  @override
  String get modeLabel => 'offline（ローカル専用）';

  @override
  String? get roomId => null;

  @override
  Future<void> connectLocalDemo() async {}

  @override
  Future<void> disconnect() async {}
}
