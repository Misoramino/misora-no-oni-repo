/// Firestore ルームイベントの冪等処理（doc id 単位）。
class RoomEventDeduper {
  final Set<String> _processed = {};

  bool get isEmpty => _processed.isEmpty;

  int get length => _processed.length;

  bool contains(String eventDocId) => _processed.contains(eventDocId);

  /// 未処理なら登録して true。既処理なら false。
  bool markIfNew(String eventDocId) {
    if (_processed.contains(eventDocId)) return false;
    _processed.add(eventDocId);
    return true;
  }

  void clear() => _processed.clear();
}
