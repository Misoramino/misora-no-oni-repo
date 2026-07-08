# Firestore 課金・性能の目安

> 引き継ぎの全体像: [HANDBOOK.md](./HANDBOOK.md) / 変更の当たり付け: [CHANGE_MAP.md](./CHANGE_MAP.md)

このドキュメントは現行実装（2026-05 時点）の**実測ではなく設計上の上限感**です。本番前に Firebase Console の使用量アラートを必ず設定してください。

座標同期の改善方針（現行最適化 / live 座標導入案・課金試算の詳細）は [LIVE_COORDINATE_SYNC.md](./LIVE_COORDINATE_SYNC.md) を参照。

## 課金リスク（Firestore）

| 項目 | 現状 | リスク |
|------|------|--------|
| ライブ GPS の地図公開 | **しない**（`locationVisibility: hidden`・座標は近接判定補助のみ） | 低 |
| プレゼンス書き込み | 6〜45 秒間隔 + 60 秒ハートビート（試合中のみ `publishPresence`） | 低〜中（人数×時間） |
| リアルタイム購読 | ルーム doc 1 + `members` 1 + `events` 1（試合中のみ） | 低（10 人未満想定） |
| `events` 複合インデックス | `sessionKey` + `emittedAtMs`（`firestore.indexes.json`） | 未作成だとクエリが失敗。Console のリンクから作成するか `firebase deploy --only firestore:indexes` |
| 試合イベント / リプレイ一括 | オフラインキューは**端末内シミュレート**が多い | 低 |
| ルーム `phase` | ホストの開始/終了で `running` / `ended` を 1 回ずつ | 低 |
| Google Maps | Firestore とは別課金（API キー制限必須） | 地図表示回数による |

### おおよその書き込み上限（1 端末・1 時間・試合中）

- 追跡時: 約 1,200 回/時（**3 秒**間隔）+ ハートビート 60 回 ≒ **1,260 writes/h** 未満
- 通常: 約 600 回/時（**6 秒**）+ ハートビート ≒ **660 writes/h** 未満

（2026-07 に 12s/5.5s から 6s/3s へ短縮。）

無料枠（Spark）でも小規模テストなら足りることが多いですが、**常時オンライン×多数端末**ではアラート必須です。

## 性能（端末）

| 要因 | 対策（実装済み / 推奨） |
|------|-------------------------|
| 地図の `setState` 連打 | マーカー平滑化タイマーは試合中 50ms、待機中 250ms |
| GPS | 状況で `LocationSamplingTier` を切替 |
| マーカー・円の再生成 | 試合中のみ毎フレーム再構築しうる → `MapMarkerIconRegistry` で Bitmap を warm-up 済み |
| 地図スタイル JSON | 起動時に `MapStyleLoader` がキャッシュ（プロファイル切替時のみ再読込） |
| 雰囲気 overlay | `WorldMapAtmosphere` は IgnorePointer・軽量 CustomPaint。ズームは `onCameraIdle` のみ `setState` |
| 準備画面 | 地図非表示時は GoogleMap を構築しない |

体感が重い場合: 開発者メニューの Test Mode をオフ、痕跡のクリア、端末の省電力除外を確認してください。

## トラブルシュート: 「Unknown error or an error from a different error domain」

1. **実行ターゲット**: Windows / macOS / Linux の**デスクトップ**では Android 用の `google-services.json` が読み込まれず、Firebase オプションが空のまま Firestore だけ失敗し、このメッセージだけ返ることがあります。**Android / iOS 実機またはエミュレータ**で試すか、ビルドに `FIREBASE_API_KEY` 等の **dart-define 4 項目**を付与してください（`lib/sync/firebase_bootstrap.dart` のコメント参照）。
2. **iOS 実機**: Xcode プロジェクトに **`GoogleService-Info.plist`** が入り、**Bundle ID** が Firebase コンソールのアプリと一致しているか。別プロジェクトの plist を置いていると、ルールは通っても別 DB に書いていることになります（デバッグビルドではルームロビーに `DBG: Firebase projectId` を表示）。
3. **セキュリティルール**: Firebase Console に `firestore.rules` をデプロイ済みか。拒否時は `permission-denied` になることが多いですが、端末によっては上記の曖昧な文言になる場合があります。
4. **App Check**: 本番で強制している場合、デバッグ用トークンが無いと接続できないことがあります。

## 仕様変更について

最近のリファクタは**ファイル分割と UI 共通化**が中心で、ゲームルール・Firestore スキーマ・課金モデルは意図的に変えていません。
