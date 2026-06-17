# ONI PIN

**GPS × 鬼ごっこ** — 都市型・緊張感重視のマルチプレイ原型。8 世界観・オンラインルーム・タイムラプスリプレイ・バックグラウンド通話対応。

## できること

| 領域 | 概要 |
|------|------|
| **世界観** | 8 profiles（Horror, Pop, Cyber, Stealth, Magical, Astronomy, Zen, Royal）— 地図・BGM・UI・Presentation morph |
| **マルチ** | Firestore ルーム、ホスト権威、presence、イベント同期 |
| **Replay** | 試合後の軌跡タイムラプス（端末保存 + 任意クラウド archive） |
| **Background** | 通話・一時離脱中も可能な範囲で同期；復帰時にイベント追いつき |
| **Audio** | 4 レイヤー BGM + 世界観 SE（`WorldAudioDirector`） |

遠距離は粗い追跡でよい／近距離はプレッシャー優先。位置の常時共有はせず、スキル・イベントで開示。

## ビルド・実行

```bash
flutter pub get
flutter run
```

実機テスト（位置・バックグラウンド）:

1. 位置情報「常に許可」（iOS 推奨）
2. 2 台以上で同一ルーム ID
3. `docs/DEVICE_VERIFICATION_CHECKLIST.md`

Firebase（オンライン機能）:

1. `google-services.json` / `GoogleService-Info.plist` を配置
2. `firebase deploy --only firestore:rules` — **ルール変更後は必須**

品質チェック:

```bash
flutter analyze
flutter test
```

## ドキュメント（入口）

| ドキュメント | 内容 |
|--------------|------|
| [docs/HANDBOOK.md](docs/HANDBOOK.md) | 引き継ぎ・検証コマンド |
| [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md) | 全体構成（30 分で把握） |
| [docs/event_pipeline.md](docs/event_pipeline.md) | ゲーム → Firestore → Replay |
| [docs/sync.md](docs/sync.md) | `FirestoreRoomSession` 責務マップ |
| [lib/audio/README.md](lib/audio/README.md) | `WorldAudioState` 遷移 |
| [lib/features/game_map/replay/README.md](lib/features/game_map/replay/README.md) | リプレイモジュール |
| [lib/presentation/world/README.md](lib/presentation/world/README.md) | Theme → Pack → Widget |

## 主要パス

- `lib/screens/game_map_screen.dart` + `part` — 試合オーケストレータ
- `lib/features/game_map/game_map_screen_index.dart` — part 索引
- `lib/sync/firestore_room_session.dart` — ルーム同期
- `lib/screens/match_replay_screen.dart` — タイムラプス
- `lib/presentation/world/` — 世界観 UI

## Brand assets (`assets/branding/`)

| File | Use |
|------|-----|
| `app_icon.png` | Launcher — `dart run flutter_launcher_icons` |
| `brand_logo.png` | Title / README |
| `splash_logo.png` | Launcher source |

タイトル画面の音量アイコンで起動 SE ON/OFF（ローカル保存）。

変更履歴: [CHANGELOG.md](CHANGELOG.md)
