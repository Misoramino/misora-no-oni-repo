# Host-Light Multiplayer（通話中プレイ）

Discord / LINE 通話を常時つなぎながら遊べるよう、**ゲーム内通話は実装せず**、位置・近接・通知・同期に集中する設計。

- **前面が必要なもの**: スキル操作、告発 UI、ホストの通常権限処理
- **バックグラウンドでも継続（位置許可あり）**: 近接・捕獲・パニック判定、危機通知（振動・ローカル通知）、GPS presence 同期
- **復帰時**: Firestore イベントの取りこぼし反映 + 通話中サマリー

## 1. ホスト依存の棚卸し

| 処理 | 通常の権限 | 非ホスト救済 |
|------|-----------|-------------|
| **time up / match end** | ホスト `publishMatchEnd` | `match_end_rescue`（ホスト background / stale 時） |
| **陣営全滅終了** | ホスト `_maybeEndMatchForFactionElimination` | 同上 `match_end_rescue`（`all_humans_eliminated` / `oni_eliminated`） |
| **告発解禁** | ホスト `accusation_unlocked` | `accusation_unlocked_rescue` |
| **告発解決** | ホスト `_hostResolveAccusationAttempt` | ホスト不通時: 引継ぎ → 通常解決、または参加者による `match_end_rescue`（`accusation_success`）/ `accusation_failed` / `player_eliminated_rescue` |
| **捕獲結界 bound** | ホスト `capture_zone_bound` | `capture_zone_bound_rescue` |
| **切断脱落** | ホスト `player_eliminated` | `player_eliminated_rescue` |
| **安全地帯** | 各参加者 `safe_zone_pickup` | もともと分散 |
| **勝敗（近接捕獲）** | 逃走者端末のローカル判定 | 鬼前面時 `oni_capture_elimination` |
| **役割割当** | ホスト `match_start` | ロビーで `claimHostIfAbsent` |

救済はすべて **`HostPresenceStatus.unavailableForMatchEnd`**（ホスト heartbeat stale または `appLifecycle == background`）のときのみ発動。

## 2. 冪等性・二重処理防止

- ルーム終了: Firestore **transaction**（`publishMatchEndRescue`）
- その他救済: `publishHostLightRescueEvent` + payload の `idempotencyKey`
- 発行前: `hasRescueIdempotencyKey` で同一 session の既存イベントを確認
- クライアント: `_hostLightRescueEmittedKeys` で同一試合内の再送を抑制

## 3. 捕獲判定（鬼前面）

- 逃走者が background でも、members の `proximityBand` / 結界 bound（期限付き）/ 新鮮な座標があれば鬼端末が `oni_capture_elimination` を発行可能
- **拘束が有効な間だけ**、かつ GPS 約12m または BLE contact（逃走者ローカルの `isCaptureTriggered` と同じ条件）
- 逃走者は復帰時に Firestore イベントで脱落を反映（`publishOnline: false`）
- `capture_zone_bound` は設置時の `capturePermitted` を引き継ぐ（鬼陣営人狼の捕獲不可結界が viewer 側で致死化しない）

## 4. Firestore 課金

- GPS publish 頻度: **6秒/3秒のスロットル**（チェイス時のみ短縮）
- 救済イベント: **状態変化時のみ**（毎秒全員 write しない）
- `hasRescueIdempotencyKey`: 救済試行時のみ最大 200 件 read

## 5. 通話中推奨

試合開始前ヒント（`match_playability_hints.dart`）:

> 通話しながらでもOK。先に ONI PIN を起動し、通話アプリはバックグラウンドにすると安定します。  
> 画面ロック・通話中も近づき・捕獲の判定と危機通知は継続します。復帰時に試合中の出来事を反映します。  
> （位置情報の許可が必要です。iPhone は「常に」を推奨）

## 7. 鬼側の接近シグナル

- 逃走者の live GPS は **地図ピンとしては共有しない**（`locationVisibility: hidden`）。
- 試合中は members の `lat`/`lng` に **スロットル付き**（6秒/3秒）で載せ、鬼側の距離判定・バックグラウンド捕獲の補助に使う。
- 逃走者端末が **`proximityBand`**（`far` / `near` / `contact`）を publish。鬼は粗い接近情報として参照（正確な座標ピンではない）。
- パニック・匿名痕跡・名前付き暴露が地図上の主な情報源。

## 6. 実機確認チェックリスト

- [ ] Discord 通話しながら ONI PIN 前面
- [ ] LINE 通話しながら ONI PIN 前面
- [ ] 非ホストが 10 分通話（ホスト前面）
- [ ] ホストが 10 分通話（非ホスト救済）
- [ ] 鬼前面・逃走者 background で捕獲 → 復帰後に脱落反映
- [ ] ホスト background 中の時間切れ → 非ホストが `match_end_rescue`

**注意:** `firestore.rules` の救済イベント追加は **Firebase に deploy** が必要。
