// Firestore はまだ接続しない段階用の設計ファイル。
// 「スキーマの形」と「送信のクールダウン」だけ先に固定しておくと、後からFirebaseを足してもぶれません。

/// 実際のFirestoreパス組み立て用の雛形（文字列のみ・SDK不要）。
abstract final class FirestorePaths {
  static String roomDoc(String roomId) => 'rooms/$roomId';
  static String roomMembersColl(String roomId) => '${roomDoc(roomId)}/members';
  static String memberDoc(String roomId, String uid) =>
      '${roomMembersColl(roomId)}/$uid';
  static String roomEventsColl(String roomId) => '${roomDoc(roomId)}/events';
}

/// メインのルーム文書フィールドを表す名前（バックエンド実装時の契約）。
///
/// ```
/// rooms/{roomId}
/// ```
abstract final class RoomDocFields {
  static const phase = 'phase'; // 'lobby' | 'running' | 'finale' |ended'
  static const endedAtUtc = 'endedAtUtc';
  static const rulesVersion = 'rulesVersion'; // アプリ側ルールセットの整数
}

/// メンバー文書：`members/{uid}`。位置は低密度で十分。
abstract final class MemberPresenceFields {
  static const nickname = 'nickname';
  /// 'runner'|'oni'|'spectator'
  static const role = 'role';

  /// 最後にサーバへ届いた生のGPS（許容するときだけ）
  static const lastLat = 'lat';
  static const lastLng = 'lng';
  /// クライアントが付けた送信時のUTCタイムスタンプ（ISOまたはms）
  static const reportedAtUtc = 'reportedAtUtc';

  /// 近傍「帯」（例: zone_0〜3）。BLE側と合わせると転送コスト最小。
  static const proximityBand = 'proximityBand'; // optional

  /// クライアントがセッション開始時のみ送る細かいログを貯めず、イベントとして送りたい場合
  static const lastEventHint = 'lastEventHint';
}

abstract final class RoomEventsFields {
  static const type = 'type'; // reveal / capture_near / countdown / etc
  static const payload = 'payload';
  static const emittedAtUtc = 'emittedAtUtc';
}

/// **最大10人前後／懐事情的に無駄撃ちしないための送信レート目安（クライアント実装側の規律）**
///
/// 実際の課金はFirebaseコンソールの見積りが絶対。ここは「設計のアッパー」です。
abstract final class PresenceSyncBudget {
  /// 逃走者：**通常レベル**。おおよそ 2〜8 書き込み／分でも十分機能する構成を想定。
  static const int calmMinIntervalMs = 12000;

  /// 逃走者：**緊迫ゾーン**（鬼が近い等）。体感を優先するときのみ短くする。
  static const int tensionMinIntervalMs = 5500;

  /// イベント（暴露・捕獲候補等）はゲーム進行優先：**即時**。ただし同一種をループしないこと。
  static const int eventImmediateMs = 0;

  /// ルーム状態（開始・終了）も即時送信でよいが、チャタリング防止のバウンスは別途検討。
  static const bool debounceDuplicates = true;

  /// まとめ送り：**試合末尾のreplayバンドル**は1〜2書き換えに収めることが目標。
  static const bool preferSingleReplayWrite = true;
}
