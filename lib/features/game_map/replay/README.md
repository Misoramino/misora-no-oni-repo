# Replay modules

タイムラプス再生専用。ゲームロジック・Firestore ルールは変更しません。

## 依存方向（上 → 下のみ）

```
match_replay_screen.dart
    ├── ReplayDirector          … 時刻・軌跡・カメラ
    ├── ReplayEventCues         … イベント→演出キュー
    ├── ReplaySfxGate           … SE デバウンス / 高速間引き
    ├── ReplayCaptureZone       … 捕獲ゾーン表示 lifecycle
    ├── ReplayRecordEnricher    … 記録補完（試合前）
    ├── ReplayTimelineUtils     … 軌跡クリップ
    └── replay_track_kind.dart  … 第二ゲーム軌跡の見た目
```

外部サービス:

- `MatchReplayLatestFetch` — `lib/services/match_replay_latest_fetch.dart`
- `RoomEventReplayMapper` — Firestore イベント → `MatchEvent`

## ファイル責務

| File | Role |
|------|------|
| `replay_director.dart` | 進捗 %、軌跡補間、trail 幅、終了ホールド |
| `replay_event_cues.dart` | イベント種別 → SFX / フラッシュ / 優先度 |
| `replay_sfx_gate.dart` | 8x/16x 時の SE 抑制、debounce |
| `replay_capture_zone.dart` | placed → ack → bound → fade |
| `replay_record_enricher.dart` | `endReason` から不足イベントを合成 |
| `replay_timeline_utils.dart` | `samplesUpTo` 等の純関数 |
| `replay_track_kind.dart` | oni / survivor / spectral 等の表示メタ |

## データ

入力は常に `SavedMatchRecord`（`effectiveWorldProfile` で世界観フォールバック）。
