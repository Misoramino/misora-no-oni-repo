import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:vibration/vibration.dart';

/// バックグラウンド中に自分が危機に陥ったときの即時通知（振動＋ローカル通知）。
enum BackgroundCrisisKind {
  panicWarning,
  panicImminent,
  panicStarted,
  panicTrace,
  captureZoneBound,
  touchLock,
  proximityDanger,
  proximityWarning,
  outsideAreaReveal,
  selfNamedReveal,
  accusationUnlocked,
  eliminated,
  matchEnded,
}

abstract final class BackgroundCrisisAlert {
  static final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  static bool _initialized = false;
  static final Map<String, DateTime> _lastByCategory = {};

  static String _category(BackgroundCrisisKind kind) => switch (kind) {
        BackgroundCrisisKind.panicWarning ||
        BackgroundCrisisKind.panicImminent ||
        BackgroundCrisisKind.panicStarted ||
        BackgroundCrisisKind.panicTrace ||
        BackgroundCrisisKind.proximityDanger ||
        BackgroundCrisisKind.proximityWarning =>
          'proximity',
        BackgroundCrisisKind.captureZoneBound ||
        BackgroundCrisisKind.touchLock ||
        BackgroundCrisisKind.eliminated =>
          'capture',
        BackgroundCrisisKind.outsideAreaReveal ||
        BackgroundCrisisKind.selfNamedReveal =>
          'reveal',
        BackgroundCrisisKind.accusationUnlocked => 'accusation',
        BackgroundCrisisKind.matchEnded => 'match',
      };

  static String categoryFor(BackgroundCrisisKind kind) => _category(kind);

  static Duration _debounceFor(BackgroundCrisisKind kind) => switch (kind) {
        BackgroundCrisisKind.matchEnded => const Duration(seconds: 30),
        BackgroundCrisisKind.accusationUnlocked => const Duration(seconds: 20),
        BackgroundCrisisKind.selfNamedReveal ||
        BackgroundCrisisKind.outsideAreaReveal =>
          const Duration(seconds: 12),
        BackgroundCrisisKind.proximityDanger ||
        BackgroundCrisisKind.panicImminent =>
          const Duration(seconds: 10),
        _ => const Duration(seconds: 8),
      };

  static Future<void> init() async {
    if (_initialized || kIsWeb) return;

    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const ios = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );
    await _notifications.initialize(
      const InitializationSettings(android: android, iOS: ios),
    );

    if (Platform.isAndroid) {
      await _notifications
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(
            const AndroidNotificationChannel(
              'match_crisis',
              '試合中の危機',
              description: 'パニック・捕獲圏・暴露などの緊急通知',
              importance: Importance.high,
              playSound: true,
              enableVibration: true,
            ),
          );
    }

    _initialized = true;
  }

  static Future<void> notify({
    required BackgroundCrisisKind kind,
    required String title,
    required String body,
    bool vibrate = true,
    bool showNotification = true,
  }) async {
    if (kIsWeb) return;
    if (!vibrate && !showNotification) return;

    final now = DateTime.now();
    final category = _category(kind);
    final last = _lastByCategory[category];
    final debounce = _debounceFor(kind);
    if (last != null && now.difference(last) < debounce) {
      return;
    }
    _lastByCategory[category] = now;

    if (vibrate) {
      await _vibrate(kind);
    }
    if (showNotification) {
      await _showNotification(kind: kind, title: title, body: body);
    }
  }

  /// 復帰後サマリー（1回だけ・SE連打防止）。
  static Future<void> notifyResumeSummary({
    required String title,
    required String body,
    bool vibrate = true,
    bool showNotification = true,
  }) async {
    if (kIsWeb) return;
    if (!vibrate && !showNotification) return;

    const category = 'resume_summary';
    final now = DateTime.now();
    final last = _lastByCategory[category];
    if (last != null && now.difference(last) < const Duration(seconds: 20)) {
      return;
    }
    _lastByCategory[category] = now;

    if (vibrate) {
      await _vibrate(BackgroundCrisisKind.matchEnded);
    }
    if (showNotification) {
      await _showNotification(
        kind: BackgroundCrisisKind.matchEnded,
        title: title,
        body: body,
      );
    }
  }

  static Future<void> _vibrate(BackgroundCrisisKind kind) async {
    final hasVibrator = await Vibration.hasVibrator();
    if (hasVibrator != true) return;

    final pattern = switch (kind) {
      BackgroundCrisisKind.panicImminent ||
      BackgroundCrisisKind.proximityDanger ||
      BackgroundCrisisKind.eliminated ||
      BackgroundCrisisKind.matchEnded =>
        [0, 450, 120, 450, 120, 450],
      BackgroundCrisisKind.panicStarted ||
      BackgroundCrisisKind.captureZoneBound ||
      BackgroundCrisisKind.selfNamedReveal ||
      BackgroundCrisisKind.accusationUnlocked =>
        [0, 350, 100, 350],
      _ => [0, 220, 80, 220],
    };

    final hasAmplitude = await Vibration.hasAmplitudeControl();
    if (hasAmplitude == true) {
      await Vibration.vibrate(
        pattern: pattern,
        intensities: [0, 200, 0, 255, 0, 255],
      );
    } else {
      await Vibration.vibrate(pattern: pattern);
    }
  }

  static Future<void> _showNotification({
    required BackgroundCrisisKind kind,
    required String title,
    required String body,
  }) async {
    if (!_initialized) return;

    if (Platform.isIOS) {
      final ios = _notifications.resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin>();
      await ios?.requestPermissions(alert: true, sound: true);
    }

    const androidDetails = AndroidNotificationDetails(
      'match_crisis',
      '試合中の危機',
      channelDescription: 'パニック・捕獲圏・暴露などの緊急通知',
      importance: Importance.high,
      priority: Priority.high,
      ticker: 'ONI PIN',
      enableVibration: true,
      playSound: true,
    );
    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentSound: true,
      presentBadge: false,
    );

    await _notifications.show(
      kind.index,
      title,
      body,
      const NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      ),
    );
  }
}
