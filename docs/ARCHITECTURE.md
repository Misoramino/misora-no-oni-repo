# Oni Game — コード構成

> **引き継ぎの入口:** [HANDBOOK.md](./HANDBOOK.md) → 変更の当たり付けは [CHANGE_MAP.md](./CHANGE_MAP.md)

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

`GameMapScreen`（`lib/screens/game_map_screen.dart` + `part` 9本、索引は `lib/features/game_map/game_map_screen_index.dart`）は試合の**状態機械と地図**を保持します。  
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

## オンライン同期（Phase B — append-only events）

- `rooms/{roomId}/events/{eventId}` — **create のみ**（update/delete 禁止）。`sessionKey` は `matchStart.gimmickSeed` と一致させ、試合中だけ購読する（ルーム doc / members に加えて **events 1 本**）。
- `FirestoreRoomSession.publishRoomEvent` / `publishHostRoomEvent` — 参加者が書ける型とホスト専用型をルールで分離。
- `GameMapScreen` — `roomMatchEvents` を受けて露出・偽情報・情報屋・捕獲結界を全員で揃える。常時 GPS は members に載せない方針は維持。

### 捕獲結界（capture_zone）の target 判定

| 段階 | 誰が決める | 内容 |
|------|-----------|------|
| 設置 | **結界を置いた端末**（スキル使用者） | 地図タップ位置を中心に、半径内の `'self'` と `_remoteMembers` の UID を `_captureZoneTargetsAt` で算出 |
| 共有 | 同上 → Firestore | `capture_zone_placed`: `targetUids`, **`fromSkill: true`**（`CaptureZoneEventPayload`） |
| 確定 | **ホスト**（2 秒バッファ後） | 設置イベントの `targetUids` をそのまま `capture_zone_bound` に載せる（再計算しない） |
| 適用 | 各端末 | `bound` で `lockZoneBoundIds` に `'self'`。`placed` で `lockZoneCenter` と **`lockZoneFromSkill`**（地図円半径・脱出判定に使用） |

接触拘束（タッチロック）は Firestore を経由せず、ローカルで `lockZoneFromSkill = false`。

後から入った参加者は設置時点の `targetUids` に含まれない（設置時スナップショットが権威）。

### ロビー・第二ゲームイベント

| イベント | sessionKey | 用途 |
|----------|------------|------|
| `lobby_play_area` | `0`（`lobbySessionKey`） | ホストが保存エリアを「適用」した形を試合前に全員へ |
| `spectral_territory` / `facility_sabotage` | `gimmickSeed` | 告発 `territoryBonus` ±1 と有効施設数の再計算 |
| `camera_shutdown` | 同上 | `disabledCameraIndices`（地図でグレー表示） |

### 地図レイヤー表示

- 試合中 HUD の「詳細」展開 → `MapLayerToggleStrip` でピン・円の種類ごとに ON/OFF（`GameMapLayerToggles`）。
- 下部パネルの「詳細」→ スキル以外（GPS 再取得・地図を現在地へ・痕跡クリア等）。ボタンラベルは「スキル ⇄ 詳細」で切替。

## World Visual Pack（世界観 UI）

| 世界観 | enum | 地図 JSON |
|--------|------|-----------|
| Urban Horror | `horror` | `urban_horror.json` |
| Pop City | `sport` | `pop_city.json` |
| Cyber Night | `sciFi` | `cyber_night.json` |
| Stealth Tactical | `arg` | `stealth_tactical.json` |
| Magical World | `magical` | `magical_world.json` |
| Astronomy | `astronomy` | `astronomy.json` |

- `WorldVisualPackFactory` — スタイルパス・LOD・レイヤー初期値・ビネット・演出フラグ
- `WorldProfileTokens` — マーカー色に加え、プレイエリア・痕跡・カメラ円など地図オーバーレイ色
- `MapVisualController` — `GoogleMap.style` / マーカーキャッシュ / 写真ピン
- `MapMarkerIconFactory` — PNG（`assets/map_markers/{assetKey}/`）優先、未配置時はプログラム生成
- `AvatarPinCompositor` + `AvatarImageStore` — 端末ローカル写真（Firestore 非送信、アプリ内に永続化）
- `WorldMapAtmosphere` — ビネット・reveal フラッシュ（プロファイル別 duration）・ノイズ・VHS・スキャン線
- `RevealFlashController` — 試合中 / 再生のフラッシュ ON/OFF を共通化
- ズーム LOD: `onCameraIdle` で `mapZoom` 更新 → ギミック Marker の出し分け
- 監視カメラ: 未作動はスキャン円パルス、作動後は赤いアラート円（`cameraPulsePhase`）
- タイトル / カスタム設定 / 軌跡再生 / ルーム→マップ: `WorldProfilePrefs` で世界観を共有

### 世界観別演出（抜粋）

| 世界観 | ビネット | reveal フラッシュ | ノイズ | VHS | スキャン線 | バウンス | 写真ピン |
|--------|----------|-------------------|--------|-----|------------|----------|----------|
| Urban Horror | 強 | 赤 | ○ | ○ | — | — | 暴露後のみ |
| Pop City | — | ピンク | — | — | — | ○ | 常時可 |
| Cyber Night | 暗 | シアン | ○ | — | ○ | — | — |
| Stealth Tactical | 弱 | 控えめ | — | — | — | — | — |
| Magical World | 紫 | マゼンタ | — | — | — | — | 常時可 |
| Astronomy | 宇宙 | 黄 | — | — | ○ | — | — |

再生画面 AppBar のパレットで世界観を切替可能（`WorldProfilePrefs` に保存）。

今後さらに分ける候補:

- スキル発動 UI コールバックの整理（画面から Match 層へ）
- ルーム doc に終了理由・共有ギミック座標

## 同期

- `FirestoreRoomSession` — ルーム doc・`hostUid`・メンバー購読
- `RoomSessionPort` — オンライン / ローカル単体の抽象
- `OfflineSyncQueue` — イベントの再送

ロビー UI は `room_lobby_screen.dart`、試合中の共有イベントは `events` サブコレクション経由（Phase B）。

## テスト

- `test/` — ドメイン（`play_area`, `polygon_area_resolver`）と契約テスト。ファイル早見は [CHANGE_MAP.md](./CHANGE_MAP.md) 末尾。
- 画面ウィジェットテストは未整備（分割後に追加しやすい）。変更後は `flutter test` 全文 + [DEVICE_VERIFICATION_CHECKLIST.md](./DEVICE_VERIFICATION_CHECKLIST.md) を推奨。

## 運用・課金

- [HANDBOOK.md](HANDBOOK.md) — 引き継ぎ入口と必須コマンド
- [CHANGE_MAP.md](CHANGE_MAP.md) — 領域別のファイルとテスト
- [FIRESTORE_AND_PERFORMANCE.md](FIRESTORE_AND_PERFORMANCE.md) — Firestore 書き込み頻度と端末負荷の目安
- [OPERATIONS_CHECKLIST.md](OPERATIONS_CHECKLIST.md) — 実機・Firebase 設定

## 文字コード

Dart ソースは **UTF-8（BOM なし）** で保存してください。UI の区切りには半角 `·` ではなく日本語の `・` を使います（一部環境で文字化けしやすいため）。
