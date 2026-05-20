# Oni Game Operations Checklist

このプロジェクトは App Store 公開ではなく、GitHub Actions で IPA を作り Sideloadly で配布する前提。
実機で「ちゃんと動く」ことを優先し、設定確認は以下の順で行う。

## Firebase / Firestore

- `android/app/google-services.json` を手元に配置する。
- `ios/Runner/GoogleService-Info.plist` を手元に配置し、Xcode の Runner target resources に入っていることを確認する（**iPhone 実機テストでは必須**。別プロジェクトの plist だと別 DB に接続する）。
- Firestore Rules を Firebase Console または Firebase CLI で deploy する。
- Anonymous Auth を有効にする。
- Firestore 使用量アラートを設定する。

### デスクトップ（Windows / macOS / Linux）で `google-services.json` が無い場合

`lib/sync/firebase_bootstrap.dart` のとおり、**dart-define 4 項目**（`FIREBASE_API_KEY`, `FIREBASE_APP_ID`, `FIREBASE_SENDER_ID`, `FIREBASE_PROJECT_ID`）を付けないと初期化をスキップします。実機検証は **Android / iOS ターゲット**推奨。

```text
flutter run -d <device> ^
  --dart-define=FIREBASE_API_KEY=... ^
  --dart-define=FIREBASE_APP_ID=... ^
  --dart-define=FIREBASE_SENDER_ID=... ^
  --dart-define=FIREBASE_PROJECT_ID=...
```

（値は Firebase Console のアプリ構成から。リポジトリやチャットに貼らないこと。）

### アプリ内のルーム参加導線

- **タイトル「オンラインルーム」** またはマップの **Lobby** から参加する（実装: `RoomLobbyScreen` / `FirestoreRoomSession.join`）。

## Google Maps API Key

- Android key は Android app 制限をかける。
  - package name: `com.example.oni_game`
  - SHA-1: 実機/CI で使う署名証明書の SHA-1
- iOS key は iOS app 制限をかける。
  - bundle id: `com.example.oniGame`
- 許可 API は Maps SDK for Android / Maps SDK for iOS に絞る。

## iOS 実機確認

- 位置情報権限で「常に許可」または実運用に近い設定を試す。
- アプリをスリープ、復帰、ロック解除して GPS 更新が止まらないか見る。
- Sideloadly で入れた端末でも Firebase 接続、ルーム参加、地図表示を確認する。
- IPA 更新後は一度アプリを削除して再インストールし、古い設定の影響を避ける。

## Android 実機確認

- 位置情報権限、バックグラウンド位置、通知権限を許可する。
- 省電力モードやバッテリー最適化の影響を確認する。
- スリープ復帰後に GPS と Firestore heartbeat が戻るか確認する。
- Google Play 開発者サービスがない端末は後回しにする。

## ゲーム設計の不変条件

- `rooms/{roomId}/members/{uid}` に live 座標を保存しない。
- live 座標は原則秘匿し、暴露・捕獲・情報屋・スキルなどのイベントだけで限定公開する。
- 試合リプレイは端末ローカル保存を基本とし、クラウド同期は同意と明示イベントを前提にする。
- 新ロールやスキルは、先に「誰に見えるか」を決めてから Firestore path / rules を追加する。

---

関連: [HANDBOOK.md](./HANDBOOK.md)（引き継ぎ入口） · [CHANGE_MAP.md](./CHANGE_MAP.md)（変更とテストの対応）
