import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

/// Firebase 初期化。
///
/// 優先順位:
/// 1. すべて揃っている **dart-define**（CI やキーをビルドに埋めない運用向け）
/// 2. **Android / iOS** では **`Firebase.initializeApp()` 引数なし**  
///    → `google-services.json` / `GoogleService-Info.plist` から読む標準経路
/// 3. **Windows / macOS / Linux** では dart-define が無い **`initializeApp()` 引数なしは使わない**  
///    （Firestore が「Unknown error…」だけ返す原因になりやすい）
///
/// 失敗後も **[tryInit] を再度呼べる**（`google-services.json` を後から置いた場合など）。
abstract final class FirebaseBootstrap {
  static bool _ready = false;
  static bool _inProgress = false;

  /// 直近の初期化失敗（UI に短く出す用。本番ではログのみでも可）
  static String? lastErrorBrief;

  static bool get isReady => _ready;

  /// デスクトップは `google-services.json` が効かないため、明示オプション無しの初期化を避ける。
  static bool get _needsExplicitFirebaseOptions {
    if (kIsWeb) return false;
    return switch (defaultTargetPlatform) {
      TargetPlatform.windows ||
      TargetPlatform.linux ||
      TargetPlatform.macOS => true,
      _ => false,
    };
  }

  static Future<void> tryInit() async {
    if (_ready) return;
    if (Firebase.apps.isNotEmpty) {
      _ready = true;
      lastErrorBrief = null;
      if (kDebugMode) {
        debugPrint('FirebaseBootstrap: already initialized (${Firebase.apps.length} app(s))');
      }
      return;
    }
    if (_inProgress) return;
    _inProgress = true;
    lastErrorBrief = null;

    const apiKey = String.fromEnvironment('FIREBASE_API_KEY');
    const appId = String.fromEnvironment('FIREBASE_APP_ID');
    const senderId = String.fromEnvironment('FIREBASE_SENDER_ID');
    const projectId = String.fromEnvironment('FIREBASE_PROJECT_ID');
    const storageBucket =
        String.fromEnvironment('FIREBASE_STORAGE_BUCKET', defaultValue: '');

    final hasEnv = apiKey.isNotEmpty &&
        appId.isNotEmpty &&
        senderId.isNotEmpty &&
        projectId.isNotEmpty;

    if (!hasEnv && _needsExplicitFirebaseOptions) {
      _ready = false;
      lastErrorBrief =
          'Windows / macOS / Linux では Firebase に dart-define（FIREBASE_API_KEY / '
          'FIREBASE_APP_ID / FIREBASE_SENDER_ID / FIREBASE_PROJECT_ID）が必要です。'
          '実機の Android / iOS では google-services.json 等で自動設定されます。'
          '（Firestore の「Unknown error…」は未設定デスクトップで起きがちです）';
      if (kDebugMode) {
        debugPrint('FirebaseBootstrap: skipped default init on desktop (no dart-define)');
      }
      _inProgress = false;
      return;
    }

    try {
      if (hasEnv) {
        await Firebase.initializeApp(
          options: FirebaseOptions(
            apiKey: apiKey,
            appId: appId,
            messagingSenderId: senderId,
            projectId: projectId,
            storageBucket: storageBucket.isEmpty ? null : storageBucket,
          ),
        );
        if (kDebugMode) {
          debugPrint('FirebaseBootstrap: initialized via dart-define ($projectId)');
        }
      } else {
        await Firebase.initializeApp();
        if (kDebugMode) {
          debugPrint(
            'FirebaseBootstrap: initialized via platform default (e.g. google-services.json)',
          );
        }
      }
      _ready = true;
      lastErrorBrief = null;
    } catch (e, st) {
      _ready = false;
      final msg = e.toString();
      lastErrorBrief = msg.length > 160 ? '${msg.substring(0, 157)}...' : msg;
      if (kDebugMode) {
        debugPrint(
          'FirebaseBootstrap: init failed (google-services.json または dart-define を確認): $e\n$st',
        );
      }
    } finally {
      _inProgress = false;
    }
  }
}
