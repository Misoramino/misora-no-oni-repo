/// Firestore `rooms/{id}.phase` の値。
abstract final class RoomPhase {
  static const lobby = 'lobby';
  static const running = 'running';
  static const ended = 'ended';

  static bool isKnown(String? value) =>
      value == lobby || value == running || value == ended;

  static String normalize(String? value) =>
      isKnown(value) ? value! : lobby;
}
