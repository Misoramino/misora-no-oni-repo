# Event Pipeline — ゲーム中からリプレイまで

ONI PIN のイベントは **3 系統** が最終的に [SavedMatchRecord] に合流し、リプレイで再生されます。

```
ゲーム中 (GameMapScreen)
    │  MatchRecorder / ローカル判定
    ▼
Firestore (rooms/{id}/events)     ← ホスト権限イベント + 参加者 presence
    │  RoomMatchEvent
    ▼
MatchRecorder (端末)              ← 軌跡・MatchEvent・Reveal を蓄積
    │  SavedMatchRecord
    ▼
MatchArchiveStore (ローカル)      ← 同意済みのみ端末保存
    │  optional: matchArchives サブコレクション
    ▼
FirestoreRoomSession.fetchMergedMatchArchive
    │  RoomEventReplayMapper
    ▼
ReplayRecordEnricher              ← 旧記録の endReason 補完
    ▼
MatchReplayScreen + ReplayDirector
```

## 1. ゲーム中（ローカル）

| 種類 | 型 | 生成元 |
|------|-----|--------|
| 位置・捕獲・スキル | `MatchEvent` | `MatchRecorder`, 各スキル / 判定 |
| 暴露 | `LocationRevealEvent` | Reveal ロジック |
| 軌跡 | `TrajectorySample` | GPS / 補間 (`TrajectoryGapFill`) |
| ルーム共有 | `RoomMatchEvent` | `FirestoreRoomSession.publish*` |

ロジック変更は `lib/game/` と `game_map_screen.*.dart` に閉じます。

## 2. Firestore

- **`rooms/{roomId}/events`** — セッションキー付き試合イベント（開始・終了・告発など）
- **`rooms/{roomId}/members`** — presence・prepReady・background 状態
- **`rooms/{roomId}/matchArchives`** — 試合終了後の軌跡アップロード（full / chunk / meta）

マッピング: `lib/services/room_event_replay_mapper.dart`

## 3. Recorder → Archive

- `MatchRecorder` が試合中にバッファ
- 終了時 `_finalizeMatchRecording` → `SavedMatchRecord`（`worldProfile`, `trackKinds`, `onlineRoomId` 等）
- 設定 ON 時 `MatchArchiveStore` へ保存
- オンライン時 `publishMatchArchive*` で Firestore へ（挙動は既存のまま）

## 4. Replay

| モジュール | 責務 |
|------------|------|
| `ReplayDirector` | 時刻→進捗、軌跡幅、カメラ |
| `ReplayEventCues` | SE / フラッシュトリガ |
| `ReplaySfxGate` | 高速再生時の SE 間引き |
| `ReplayCaptureZone` | 捕獲ゾーン lifecycle |
| `ReplayRecordEnricher` | 欠落イベントの合成 |
| `ReplayTimelineUtils` | サンプルクリップ |
| `MatchReplayLatestFetch` | ギャラリー「最新取得」 |

詳細: `lib/features/game_map/replay/README.md`

## 型の対応

| レイヤ | 主な型 |
|--------|--------|
| 同期 | `RoomMatchEvent` |
| 記録 | `MatchEvent`, `LocationRevealEvent`, `SavedMatchRecord` |
| 再生 | 上記を `ReplayDirector` が時系列で消費 |

---

[SavedMatchRecord]: ../lib/game/match_record.dart
