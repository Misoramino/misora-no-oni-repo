# Live 座標同期 — 設計メモ（現行最適化 / live 導入案）

> **ステータス:** 設計ドキュメント（未実装）。実装前の方針共有・見積り用。  
> **関連:** [FIRESTORE_AND_PERFORMANCE.md](./FIRESTORE_AND_PERFORMANCE.md) · [sync.md](./sync.md) · [host_light_multiplayer.md](./host_light_multiplayer.md) · [OPERATIONS_CHECKLIST.md](./OPERATIONS_CHECKLIST.md)

## 背景

オンライン試合では **常時の地図ピン共有はしない**（プライバシー・演出）が、近接・感染・拘束・捕獲などの判定には **相手の座標が一定頻度で届いている必要** がある。

2026-07 時点の課題認識:

- ゲーム判定（接触拘束 4 秒、感染 6 秒など）に対し、座標経路によっては **12 秒間隔** しか更新されない場面がある。
- `hunter_position`（events）が届かないと `oniKnown == false` のまま距離が `infinity` 扱いになり、**近接が一切動かない**。
- `hunter_position` を events に逐次 append すると、再接続時の **読み取りが膨らみやすい**。

本書は「現行方針のまま間隔・経路を最適化する案」と「live 座標（members 集約）を導入する案」の両方をまとめる。

---

## 現行アーキテクチャ（2026-07）

### 座標の二系統

| 経路 | 保存先 | 主な用途 | 間隔（実装） |
|------|--------|----------|--------------|
| **`hunter_position`** | `rooms/{id}/events`（`match_event` の innerType） | 逃走者の `_distanceToOni()`・`_lastKnownHunterPositions` | **最短 3 秒**（6 m 未満の移動はスキップ） |
| **presence `lat`/`lng`** | `rooms/{id}/members/{uid}` | 鬼の BG 捕獲補助・`_remoteMembers` | **12 秒（通常）/ 5.5 秒（緊迫）** |

定数の所在:

- `lib/game/game_config.dart` — `hunterPositionPublishIntervalSeconds`（3）
- `lib/sync/firestore_room_blueprint.dart` — `PresenceSyncBudget.calmMinIntervalMs`（12000）/ `tensionMinIntervalMs`（5500）
- `lib/game/sampling_tier.dart` — ローカル GPS（relaxed 12s / standard 5s / chase 2s）

### 近接判定の流れ（逃走者端末）

```
ローカル GPS（2〜12 秒）
    +
鬼の最後の座標（主: hunter_position → _lastKnownHunterPositions）
    ↓
_distanceToOni()  →  HybridProximityService（+ BLE 任意）
    ↓
GameMapMatchController.evaluateRunningTick()
    ↓
接触圏 / 感染 / 拘束 / 捕獲
```

**ゲート条件:** `oniKnown == false` のとき `MatchGeoHelpers.distanceToOni` は `infinity` を返し、接触拘束の `enabled` も false になる（`game_map_match_controller.dart`）。

### 鬼側の座標配信（ホスト不要）

非ホストでも、役割割当で本鬼または鬼化人狼なら `_maybePublishHunterPosition` が動く（`game_map_screen.skills.dart`）。Firestore ルール上 `match_event` は参加者全員が create 可能（`firestore.rules`）。

### 緊迫モードの鶏と卵

presence の `tension: true`（5.5 秒間隔）は、現状 **`_remoteOniKnown && 鬼までの距離 ≤ warningDistance`** のときのみ（`game_map_screen.dart` の `_acceptPosition`）。

鬼位置が未同期の間は **常に calm（12 秒）** のまま → `hunter_position` 不通時に二重に不利。

---

## 方針 A — 現行のまま間隔・経路を最適化（推奨の第一歩）

ゲーム判定ロジック（秒数・半径）は変えず、**座標の届き方だけ** 改善する案。

### A-1. presence 間隔の見直し

| モード | 現行 | 提案 | 根拠 |
|--------|------|------|------|
| 通常（鬼が遠い） | 12 s | **6 s** | 感染 6 s 判定に対し、相手座標が 1 回は届く余裕 |
| 追跡中（例: 120 m 以内） | 5.5 s | **3 s** | 接触拘束 4 s に対し 1〜2 サンプル |
| 接触圏付近 | （なし） | **2 s** | 拘束・12 m 捕獲の体感（短時間のみ） |

変更候補: `PresenceSyncBudget`（`firestore_room_blueprint.dart`）、`_acceptPosition` の tension 判定。

### A-2. tension 判定の緩和

`hunter_position` 未着でも、次のいずれかで **calm → 追跡モード** に入れる:

- members に相手の `lat`/`lng` があり、fix 年齢が `GameConfig.gpsMaxFixAgeSeconds` 以内
- BLE が `near` / `contact`
- 直近の匿名痕跡・暴露で鬼の粗い位置が分かる

→ **「鬼が分かってからやっと速くなる」循環を断つ。**

### A-3. 近接判定のフォールバック経路

`_distanceToOni()` / `_anyPerceivedOniPositionKnown` で、`hunter_position` に加え **presence の `_remoteMembers[oniUid]`** を参照する。

優先順位案:

1. `_lastKnownHunterPositions`（events・最新）
2. `_remoteMembers` の lat/lng（members・スロットル付き）
3. いずれも無し → `oniKnown = false`

### A-4. `hunter_position` の整理

- **維持:** 鬼・鬼化人狼は 3 秒間隔で継続（現行）
- **検討:** 移動閾値 6 m を 4 m に下げる（都市部の低速接近）
- **検討:** events への append 頻度を下げ、座標の正は members に寄せる（方針 B への橋渡し）

### A-5. 実装タッチポイント（実装時）

| 領域 | ファイル |
|------|----------|
| 間隔定数 | `lib/sync/firestore_room_blueprint.dart` |
| presence 送信 | `lib/screens/game_map_screen.dart`（`_acceptPosition`） |
| 鬼位置配信 | `lib/screens/game_map_screen.skills.dart`（`_maybePublishHunterPosition`） |
| 距離・oniKnown | `lib/screens/game_map_screen.skills.dart`, `game_map_screen.dart` |
| 判定本体 | `lib/features/game_map/match/game_map_match_controller.dart`, `match_geo_helpers.dart` |
| Firestore I/O | `lib/sync/firestore_room_session.dart` |

**テスト:** `test/match_geo_helpers_capture_test.dart`, `test/multiplayer_risk_audit_test.dart`, `test/firestore_presence_contract_test.dart` + 実機 [DEVICE_VERIFICATION_CHECKLIST.md](./DEVICE_VERIFICATION_CHECKLIST.md)「接近・捕獲」「オンライン」

---

## 方針 B — live 座標（members 集約）

「試合中は全員の座標を Firestore `members` に定期的に書く」案。地図ピンは従来どおり出さず `locationVisibility: hidden` のまま可能。

### B-1. 設計原則

| 項目 | 方針 |
|------|------|
| 保存先 | **`members/{uid}` の `lat`/`lng`/`reportedAtUtc` のみ**（1 ユーザー 1 ドキュメント更新） |
| 地図表示 | 原則非表示（現行どおり）。観戦者は既存の `inspectorFeed` を別途 |
| events | 捕獲・暴露・スキル等の **出来事** のみ。座標ストリームは載せない |
| ホスト | 座標配信にホスト権限は不要（現行どおり） |

### B-2. 推奨レート（4 人・45 分試合想定）

| モード | 間隔 | 条件 |
|--------|------|------|
| calm | 6 s | 鬼から遠い / 試合序盤 |
| chase | 3 s | 警告距離内 |
| contact | 2 s | 接触圏・拘束中 |

全員が同じティアで書く（逃走者だけでなく **鬼・鬼化人狼も**）。

### B-3. 読み取り側

- 既存の `members` スナップショット購読（`firestore_room_session.dart`）をそのまま利用
- `_remoteMembers` 更新 → `_applyRemoteOniPosition` / `_distanceToOni` フォールバック
- `hunter_position` は **廃止またはバックアップ**（イベント蓄積による read 爆発を防ぐ）

### B-4. メリット / デメリット

| メリット | デメリット |
|----------|------------|
| 再接続しても **読むのはメンバー 4 ドキュメント程度** | `OPERATIONS_CHECKLIST` の「members に live を書かない」文言と矛盾 → ドキュメント更新が必要 |
| 間隔を単一箇所で管理しやすい | 書き込み回数は events 逐次より **やや増える**場合あり |
| `oniKnown` を安定させやすい | ルール・プライバシー説明の見直し |

### B-5. 段階的導入

1. **Phase 1（方針 A）:** フォールバック + 間隔最適化のみ。スキーマ変更なし。
2. **Phase 2:** 試合中の presence を 6/3/2 s に。`hunter_position` は併用。
3. **Phase 3:** 座標の正を members に一本化し、`hunter_position` 頻度を下げる or 廃止。

---

## Firestore 課金（参照用）

> 料金は Google の改定で変わる。**実測は Firebase Console → Usage** を正とする。  
> 最終確認: 2026-07（[Firebase Pricing](https://firebase.google.com/pricing/) / [Firestore pricing](https://cloud.google.com/firestore/pricing)）

### 無料枠（1 プロジェクト・1 データベース・**1 日ごと**リセット、太平洋時間 0 時）

| 操作 | 無料枠 / 日 |
|------|-------------|
| ドキュメント読み取り | **50,000** |
| ドキュメント書き込み | **20,000** |
| ドキュメント削除 | 20,000 |
| 保存データ | 1 GiB |
| 外向き転送 | 10 GiB / 月 |

- **Spark（無料）プラン:** 無料枠内のみ。超過すると操作が拒否され、**請求は発生しない**（従量課金にはならない）。
- **Blaze（従量課金）プラン:** 無料枠を超えた分が課金対象。

### 無料枠超過後のおおよその単価（Standard edition・米国リージョン目安）

| 操作 | 超過分 |
|------|--------|
| 読み取り | 10 万回あたり約 **$0.06** |
| 書き込み | 10 万回あたり約 **$0.18** |
| 削除 | 10 万回あたり約 **$0.02** |

### 現行実装の設計上限（1 端末・1 時間・試合中）

[FIRESTORE_AND_PERFORMANCE.md](./FIRESTORE_AND_PERFORMANCE.md) より:

- 緊迫時 presence: 約 **715 writes/h** 未満（5.5 s 間隔 + ハートビート）
- 通常: 約 **360 writes/h** 未満（12 s 間隔 + ハートビート）

※ `hunter_position` の **events 書き込みは別カウント**（1 回 = 1 write + リスナー数 × read）。

### 試合あたりの目安（4 人・45 分）

| シナリオ | 書き込み（合計・4 端末） | 読み取り（合計・目安） |
|----------|-------------------------|------------------------|
| **現行**（3 s hunter_position + 12 s presence） | 約 2,000〜4,000 | 約 8,000〜15,000 |
| **方針 A**（6/3/2 s presence + フォールバック） | 約 3,000〜5,000 | 約 10,000〜18,000 |
| **方針 B**（members のみ 6/3/2 s、events 座標なし） | 約 2,500〜4,500 | 約 8,000〜14,000 |

**1 日 1〜2 試合（4 人）** であれば、無料枠（特に write 2 万/日）内に収まる想定。

### 読み取りが膨らみやすい要因（現行）

| 要因 | 説明 |
|------|------|
| `events` の append-only | `hunter_position` が 45 分で ~900 ドキュメント蓄積 |
| `fetchMatchEvents` | 再接続・8 s ポンプで **セッション全イベントを再読** |
| 複数購読 | 各端末が room + members + events の 3 本 |
| 初回スナップショット | リスナー接続時の一括 read |

→ live 座標を members に集約すると、**座標起因の read 爆発を抑えやすい**。

### 実測例（参考）

2026-07-05 頃、4 人テストで **読み取り + 書き込み ≈ 5,000**（試合は正常に機能せず）。無料枠の約 10% 程度。

Console で **1 日あたりのアラート**（例: reads 40k / writes 16k）を設定することを推奨（[OPERATIONS_CHECKLIST.md](./OPERATIONS_CHECKLIST.md)）。

---

## スリープ・通話中

[host_light_multiplayer.md](./host_light_multiplayer.md) のとおり:

- 逃走者 BG: `_evaluateProximityWhileBackground` で近接継続（**座標が届いていることが前提**）
- 鬼前面 + 逃走者 BG: `oni_capture_elimination`（members の `proximityBand` / 座標を参照）
- 鬼 BG: 鬼側の近接捕獲 publish はスキップ（前面復帰を想定）

live / 最適化後も **iOS「常に」位置許可** と BG location の実機確認が必須。

---

## 実装時チェックリスト

- [ ] `PresenceSyncBudget` / tension 条件の変更
- [ ] `_distanceToOni` の members フォールバック
- [ ] `hunter_position` との役割分担（併用 or 縮小）
- [ ] `firestore.rules` — members の `lat`/`lng` 更新は現行で許可済みか確認
- [ ] `OPERATIONS_CHECKLIST` の「不変条件」文言の更新（live 採用時）
- [ ] Firebase Console 使用量アラート
- [ ] 実機: 2 台以上で接近・拘束・捕獲・通話中 BG（[DEVICE_VERIFICATION_CHECKLIST.md](./DEVICE_VERIFICATION_CHECKLIST.md)）
- [ ] `flutter test`（presence 契約・capture・multiplayer audit）

---

## 決定ログ（未記入）

| 日付 | 決定 | 備考 |
|------|------|------|
| | 方針 A / B / 段階的のどれを採用するか | |

実装 PR がマージされたら、本表と [CHANGELOG.md](../CHANGELOG.md) を更新する。
