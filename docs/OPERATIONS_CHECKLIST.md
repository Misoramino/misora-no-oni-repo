# Oni Game Operations Checklist

このプロジェクトは App Store 公開ではなく、GitHub Actions で IPA を作り Sideloadly で配布する前提。
実機で「ちゃんと動く」ことを優先し、設定確認は以下の順で行う。

## Firebase / Firestore

- `android/app/google-services.json` を手元に配置する。
- `ios/Runner/GoogleService-Info.plist` を手元に配置し、Xcode の Runner target resources に入っていることを確認する。
- Firestore Rules を Firebase Console または Firebase CLI で deploy する。
- Anonymous Auth を有効にする。
- Firestore 使用量アラートを設定する。

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
