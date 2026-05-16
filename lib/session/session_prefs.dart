import 'package:shared_preferences/shared_preferences.dart';

/// ルーム参加フォームの直近値を端末に保持。
abstract final class SessionPrefs {
  static const nicknameKey = 'session_nickname_v1';
  static const roomIdKey = 'session_room_id_v1';
  static const roleKey = 'session_role_v1';

  static Future<({String nickname, String roomId, String role})> loadForm() async {
    final prefs = await SharedPreferences.getInstance();
    return (
      nickname: prefs.getString(nicknameKey) ?? 'player1',
      roomId: prefs.getString(roomIdKey) ?? '',
      role: prefs.getString(roleKey) ?? 'runner',
    );
  }

  static Future<void> saveForm({
    required String nickname,
    required String roomId,
    required String role,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(nicknameKey, nickname);
    await prefs.setString(roomIdKey, roomId);
    await prefs.setString(roleKey, role);
  }
}
