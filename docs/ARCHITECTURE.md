# Oni Game — コード構成

## ディレクトリ概要

| パス | 役割 |
|------|------|
| `lib/game/` | ルール・状態・プレイエリア・スキル ID などドメイン |
| `lib/features/game_map/` | ゲーム画面専用 UI（準備パネル・HUD・操作パネル） |
| `lib/screens/` | 画面のエントリ（ルーティング・状態のオーケストレーション） |
| `lib/sync/` | Firestore ルーム・プレゼンス・オフラインキュー |
| `lib/services/` | 位置・録画・アーカイブ・エリア永続化 |
| `lib/proximity/` | BLE / ハイブリッド近接 |
| `lib/theme/` | ワールドプロファイルとテーマ |
| `lib/widgets/` | 画面横断の小さな UI（確認ダイアログ・プレビュー等） |

## ゲーム画面

`GameMapScreen`（`lib/screens/game_map_screen.dart`）は試合の**状態機械と地図**を保持します。  
見た目は `lib/features/game_map/` に分割しています。

- `prep/` — 地図オフ準備（時間・保存エリア一覧）
- `widgets/` — HUD、エリア編集カード、スキルバー、診断
- `map/` — `GameMapOverlaySnapshot` + `GameMapOverlayBuilder`（マーカー・円・多角形）
- `logic/` — `MapGeoUtils`・`OniIntelTextBuilder`（純粋関数）
- `settings/` — カスタム設定ボトムシート
- `match/` — `GameMapMatchController`・`MatchRuntimeState`・各種 Evaluator
- `logic/` — `GimmickRelocator`（ギミック再配置）
- `play_area/` — GeoJSON インポート/エクスポート UI
- `widgets/game_map_overflow_menu.dart` — AppBar の More メニュー

## オンライン同期（Phase A）

- `FirestoreRoomSession.roomMatchState` — `phase` + `matchStart` + 終了結果
- ホストが `publishMatchStart` で役職・スキル・ギミック seed・プレイエリアを 1 回共有
- ホストが `publishMatchEnd` で `endReason` / `matchOutcome` を共有
- 参加者は共有データを適用してから試合開始（ローカル乱数は使わない）
- `firestore.rules` — `rooms/{id}` はホストのみ update（members は自分のみ）

今後さらに分ける候補:

- スキル発動 UI コールバックの整理（画面から Match 層へ）
- ルーム doc に終了理由・共有ギミック座標

## 同期

- `FirestoreRoomSession` — ルーム doc・`hostUid`・メンバー購読
- `RoomSessionPort` — オンライン / ローカル単体の抽象
- `OfflineSyncQueue` — イベントの再送

ロビー UI は `room_lobby_screen.dart`、ゲーム内ホスト操作はまだ端末ローカルが多い（今後 Firestore イベント化）。

## テスト

- `test/` — ドメイン（`play_area`, `polygon_area_resolver`）と契約テスト
- 画面ウィジェットテストは未整備（分割後に追加しやすい）

## 運用・課金

- [FIRESTORE_AND_PERFORMANCE.md](FIRESTORE_AND_PERFORMANCE.md) — Firestore 書き込み頻度と端末負荷の目安
- [OPERATIONS_CHECKLIST.md](OPERATIONS_CHECKLIST.md) — 実機・Firebase 設定

## 文字コード

Dart ソースは **UTF-8（BOM なし）** で保存してください。UI の区切りには半角 `·` ではなく日本語の `・` を使います（一部環境で文字化けしやすいため）。
