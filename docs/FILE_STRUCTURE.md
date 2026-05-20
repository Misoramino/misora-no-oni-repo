# リポジトリのファイル構造（共有用）

自動生成ではなく **2026-05 時点のスナップショット**です。  
**最新の一覧**は次で再取得できます（`build/`・`.dart_tool/` は Git に含まれません）。

```bash
git ls-files | sort
```

---

## ディレクトリツリー（要約）

`lib/` の細部は省略し、プラットフォーム・設定・ドキュメントを中心に示します。

```text
oni_game/
├── README.md
├── pubspec.yaml
├── analysis_options.yaml
├── firebase.json
├── firestore.rules
├── firestore.indexes.json
├── .firebaserc
├── .github/workflows/ios-build.yml
│
├── lib/                          # Dart アプリ本体（画面・ゲーム・同期・テーマ）
│   ├── main.dart
│   ├── app.dart
│   ├── game/                     # ルール・定数・ドメイン型
│   ├── screens/                  # 画面エントリ
│   ├── features/game_map/        # マップ画面専用 UI・マッチ橋渡し
│   ├── sync/                     # Firestore ルーム・イベント
│   ├── services/                 # 位置・録画・ローカル永続化
│   ├── session/                  # 端末内プリファレンス等
│   ├── theme/                    # 世界観・テーマ・地図スタイル
│   ├── proximity/                # BLE / 近接
│   ├── map/                      # マーカー平滑など
│   ├── widgets/                  # 共通ウィジェット
│   └── ...
│
├── test/                         # ユニットテスト（*.dart）
├── assets/
│   ├── map_styles/*.json         # 地図スタイル（世界観ごと）
│   └── map_markers/README.md
│
├── docs/                         # 引き継ぎ・運用ドキュメント
│   ├── HANDBOOK.md
│   ├── CHANGE_MAP.md
│   ├── ARCHITECTURE.md
│   ├── AI_HANDOFF.md
│   ├── OPERATIONS_CHECKLIST.md
│   ├── DEVICE_VERIFICATION_CHECKLIST.md
│   ├── FIRESTORE_AND_PERFORMANCE.md
│   ├── BLE_PROXIMITY.md
│   ├── GAME_EVENT_AREAS.md
│   └── FILE_STRUCTURE.md         # 本ファイル
│
├── android/                      # Android ネイティブシェル
│   └── app/
│       ├── build.gradle.kts
│       ├── google-services.json  # Firebase（秘密情報・通常は Git 外推奨）
│       └── src/main/...
│
├── ios/                          # iOS ネイティブシェル
│   ├── Podfile
│   ├── Flutter/
│   │   ├── AppFrameworkInfo.plist   # Flutter エンジン用（Firebase ではない）
│   │   ├── Debug.xcconfig / Release.xcconfig
│   │   └── ...
│   └── Runner/
│       ├── Info.plist               # アプリの権限・表示名など
│       ├── GoogleService-Info.plist # Firebase（秘密情報・通常は Git 外推奨）
│       ├── AppDelegate.swift / SceneDelegate.swift
│       └── Assets.xcassets/         # アイコン・起動画像（多数 PNG）
│
├── web/                          # Web ターゲット用
├── windows/ / linux/ / macos/    # デスクトップターゲット用
│
└── temp_ios_fix/                 # 別ミニ Flutter プロジェクト（実験用スナップショット）
    └── ios/Runner/...            # 本プロジェクトの ios と似た構成
```

---

## plist / json でよくある取り違え

| ファイル | 置き場所（主） | 役割 |
|----------|----------------|------|
| **GoogleService-Info.plist** | `ios/Runner/` | **Firebase**（プロジェクト ID・API キー等）。Xcode の Runner に含める。 |
| **google-services.json** | `android/app/` | **Firebase**（Android 用）。 |
| **Info.plist** | `ios/Runner/` | **アプリのメタデータ**（Bundle ID、位置情報用途の説明、Maps キー `GMSApiKey` 等）。Firebase 用ではない。 |
| **AppFrameworkInfo.plist** | `ios/Flutter/` | **Flutter フレームワーク**のバンドル情報。Firebase 用ではない。 |
| **firestore.rules** | リポジトリ直下 | Firestore **セキュリティルール**（Console / CLI でデプロイ）。 |

---

## `ios/Runner/` 直下の plist（名前が似ているもの）

- **GoogleService-Info.plist** … Firebase（1 本で足りる想定）
- **Info.plist** … アプリ本体の設定
- **Runner-Bridging-Header.h** … ObjC ブリッジ（ヘッダ）

`ios/Flutter/*.plist` は Flutter ビルド用で、Firebase の設定ファイルとは別物です。

---

## 追跡ファイル数の目安（トップレベル）

`git ls-files` の先頭ディレクトリごとの件数イメージです。

- `lib/` … Dart 本体（画面・ゲーム・同期が大半）
- `ios/` … Xcode プロジェクト・`Runner`・アセット（**ファイル数が多い**のは主に `Assets.xcassets` の PNG）
- `android/` … Gradle・Kotlin・リソース
- `test/` … ユニットテスト
- `docs/` … Markdown
- `temp_ios_fix/` … 実験用の別プロジェクト一式（本アプリと混同しないこと）

---

## 関連ドキュメント

- 引き継ぎの読み順: [HANDBOOK.md](./HANDBOOK.md)
- 変更箇所とテスト: [CHANGE_MAP.md](./CHANGE_MAP.md)
- Firebase 運用: [OPERATIONS_CHECKLIST.md](./OPERATIONS_CHECKLIST.md)
