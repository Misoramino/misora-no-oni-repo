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
  static const phase = 'phase'; // 'lobby' | 'running' | 'finale' | 'ended'
  static const endedAtUtc = 'endedAtUtc';
  static const rulesVersion = 'rulesVersion'; // アプリ側ルールセットの整数

  /// ルームホストの Firebase Auth UID。
  static const hostUid = 'hostUid';

  /// Phase A: ホストが試合開始時に 1 回だけ書く（ネスト map）。
  static const matchStart = 'matchStart';

  static const matchStartGimmickSeed = 'gimmickSeed';
  static const matchStartPlayArea = 'playArea';
  static const matchStartDurationSec = 'matchDurationSeconds';
  static const matchStartOniIntelMode = 'oniIntelMode';
  static const matchStartAftermathRule = 'eliminationAftermathRule';
  static const matchStartAssignments = 'assignments';
  static const matchStartStartedAtUtc = 'startedAtUtc';

  /// Phase A: 試合終了時（ホストのみ）。
  static const endReason = 'endReason';
  static const matchOutcome = 'matchOutcome';
  static const endMessage = 'endMessage';
}

/// [RoomDocFields.endReason] の値。
abstract final class MatchEndReason {
  static const timeUp = 'time_up';
  static const caught = 'caught';
  static const hostEnded = 'host_ended';
  static const hostAbort = 'host_abort';
}

/// メンバー文書：`members/{uid}`。live 位置は置かず、接続状態だけを軽く同期する。
abstract final class MemberPresenceFields {
  static const nickname = 'nickname';

  /// 'runner'|'oni'|'spectator'
  static const role = 'role';

  /// reveal / event 系コレクションでのみ使う予定。members には保存しない。
  static const lastLat = 'lat';
  static const lastLng = 'lng';

  /// クライアントが付けた送信時のUTCタイムスタンプ（ISOまたはms）
  static const reportedAtUtc = 'reportedAtUtc';

  /// 近傍「帯」（例: zone_0〜3）。BLE側と合わせると転送コスト最小。
  static const proximityBand = 'proximityBand'; // optional

  /// live 位置は原則 members に載せない。reveal/event 経由だけに寄せるための明示フラグ。
  static const locationVisibility = 'locationVisibility'; // 'hidden'

  /// カスタムモードの希望（試合確定前）。ホストが matchStart 作成時に参照。
  static const preferredRole = 'preferredRole';
  static const preferredSkills = 'preferredSkills';

  /// クライアントがセッション開始時のみ送る細かいログを貯めず、イベントとして送りたい場合
  static const lastEventHint = 'lastEventHint';
}

abstract final class RoomEventsFields {
  static const type = 'type';
  static const payload = 'payload';
  static const emittedAtUtc = 'emittedAtUtc';
  static const emittedAtMs = 'emittedAtMs';
  static const actorUid = 'actorUid';
  static const sessionKey = 'sessionKey';
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
