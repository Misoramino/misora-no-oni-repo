# プロジェクト引き継ぎハンドブック

仕様を変えずに「どこを読むか・どこを触ったら何を検証するか」を一本化した入口です。  
英語の短い設計意図だけ必要な場合は [AI_HANDOFF.md](./AI_HANDOFF.md) を先にどうぞ。

## 誰向けに何を読むか

| 読者 | 最初に読む | 次に読む |
|------|------------|----------|
| 人間（初見） | リポジトリ直下 [README.md](../README.md) | [CHANGE_MAP.md](./CHANGE_MAP.md) の該当行だけ |
| 別の AI | [AI_HANDOFF.md](./AI_HANDOFF.md)（意図）→ 本書の「検証コマンド」 | [CHANGE_MAP.md](./CHANGE_MAP.md) |
| オンライン／Firebase だけ | [OPERATIONS_CHECKLIST.md](./OPERATIONS_CHECKLIST.md) | [FIRESTORE_AND_PERFORMANCE.md](./FIRESTORE_AND_PERFORMANCE.md) |
| 実機プレイ QA | [DEVICE_VERIFICATION_CHECKLIST.md](./DEVICE_VERIFICATION_CHECKLIST.md) | 上記の Firestore 節 |

## ドキュメント一覧（役割とメンテ方針）

| ファイル | 役割 | いつ更新するか |
|----------|------|----------------|
| [FILE_STRUCTURE.md](./FILE_STRUCTURE.md) | **ディレクトリ構造の共有用**（plist/json の役割、`ios` のファイルが多い理由） | フォルダ構成や Firebase 配置を変えたら |
| [CHANGE_MAP.md](./CHANGE_MAP.md) | **変更のピンポイント地図**（領域 → 主ファイル → 走らせるテスト） | 大きめのディレクトリ移動や責務分割のたび |
| [event_pipeline.md](./event_pipeline.md) | ゲーム → Firestore → Replay パイプライン | 記録・同期・再生を変えたら |
| [sync.md](./sync.md) | `FirestoreRoomSession` 責務マップ | 同期 API を分割・追加したら |
| [ARCHITECTURE.md](./ARCHITECTURE.md) | モジュール構成・オンライン Phase・世界観パックの詳説（日本語） | 機能追加で構成が変わったら |
| [LEGIBILITY_RULES.md](./LEGIBILITY_RULES.md) | UI 可読性の設計ルール・自動チェック | ガイド/オンボーディング/世界観 UI を触ったら |
| [AI_HANDOFF.md](./AI_HANDOFF.md) | 設計優先度の英語サマリ（短い） | プロダクト方針が変わったら |
| [OPERATIONS_CHECKLIST.md](./OPERATIONS_CHECKLIST.md) | Firebase / Maps キー / 実機の**運用手順** | 配布方法や制約が変わったら |
| [DEVICE_VERIFICATION_CHECKLIST.md](./DEVICE_VERIFICATION_CHECKLIST.md) | 実機・複数端末の**目視 QA** | UI やオンライン動線を変えたら |
| [FIRESTORE_AND_PERFORMANCE.md](./FIRESTORE_AND_PERFORMANCE.md) | 書き込み頻度・課金感・トラブルシュート | 同期スキーマやルールを変えたら |
| [BLE_PROXIMITY.md](./BLE_PROXIMITY.md) | BLE 近接の挙動メモ（任意機能） | 近接スタックを変えたら |
| [GAME_EVENT_AREAS.md](./GAME_EVENT_AREAS.md) | マップ上イベントエリアの仕様メモ | `GameConfig` やギミック生成を変えたら |
| [GAME_DESIGN_SPEC.md](./GAME_DESIGN_SPEC.md) | **ゲーム性・バランス・GPT用質問テンプレ**（仕様の日本語まとめ） | ルール・スキル方針を変えたら |
| [PLAYER_REFERENCE.md](./PLAYER_REFERENCE.md) | **プレイヤー向け・リリースノート用**の現行仕様まとめ | スキル・人狼・暴露を変えたら |
| [LOCATION_REVEALS.md](./LOCATION_REVEALS.md) | 位置暴露の段階（現行仕様・`PLAYER_REFERENCE` と同期） | 暴露・スキル演出を変えたら |
| [../CHANGELOG.md](../CHANGELOG.md) | **リリース履歴**（v2.0 以降） | ユーザー向け機能追加のたび |

**削除済み・参照しない:** 旧 `FIREBASE_USER_TASKS.txt` の内容は [OPERATIONS_CHECKLIST.md](./OPERATIONS_CHECKLIST.md) に統合しました。

## 変更後に必ず回す検証（仕様非変更の安全网）

```bash
cd /path/to/oni_game
flutter pub get
flutter analyze
flutter test
```

- オンラインや地図を触ったら、[DEVICE_VERIFICATION_CHECKLIST.md](./DEVICE_VERIFICATION_CHECKLIST.md) の該当チェックを目視で足すとよいです。
- Firestore ルールや `events` クエリを変えたら、`FIRESTORE_AND_PERFORMANCE.md` のインデックス節とコンソールのエラーを確認してください。

## コードの粗いレイヤ（記憶用）

1. **`lib/game/`** — ルール・定数・ドメイン型（UI から独立してテストしやすい）
2. **`lib/features/game_map/`** — マップ画面専用 UI 部品（HUD・準備・マッチ制御の橋渡し）
3. **`lib/screens/`** — 画面エントリとオーケストレーション（`GameMapScreen` が肥大化しやすいので CHANGE_MAP を見る）
4. **`lib/sync/`** — Firestore ルーム・イベント・オフラインキュー
5. **`lib/services/`** — 位置・録画・アーカイブ・ローカル永続化
6. **`test/`** — ドメインと契約テスト（画面ウィジェットテストは未整備）

詳細な木構造は [ARCHITECTURE.md](./ARCHITECTURE.md) へ。**フォルダだけ共有したい**ときは [FILE_STRUCTURE.md](./FILE_STRUCTURE.md)。
