import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

import '../../../services/battery_power_mode.dart';
import '../../../services/location_service.dart';
import '../../../session/onboarding_prefs.dart';
import '../../../widgets/app_dialog.dart';

/// 試合開始前に、バックグラウンド・位置情報・低電力モードについて案内する。
Future<void> showMatchPlayabilityHintsIfNeeded(
  BuildContext context, {
  required LocationService locationService,
}) async {
  if (!context.mounted) return;

  final generalSeen = await OnboardingPrefs.matchPlayabilityHintsSeen();
  final hasAlways = await locationService.hasBackgroundLocationPermission();
  final needsAlways =
      !kIsWeb && Platform.isIOS && !hasAlways;
  final lowPower = await BatteryPowerMode.isLowPowerModeEnabled();

  if (generalSeen && !needsAlways && !lowPower) return;

  if (!context.mounted) return;

  final lines = <String>[
    if (!generalSeen) ...[
      '試合中に LINE などへ切り替えたり、通話しながら歩いても大丈夫です。',
      '戻ってきたとき、残り時間と位置は自動で追いつきます。',
      'スキルボタンの操作だけは、アプリを前面に戻してから行ってください。',
      '低電力モード中は位置更新や同期が止まりやすいです。試合中はオフを推奨します。',
    ],
    if (needsAlways)
      'iPhone では位置情報を「常に許可」にすると、画面ロック中も位置判定が安定します。',
    if (lowPower)
      '低電力モードがオンです。位置更新・同期・危機通知が遅れることがあります。可能ならオフを推奨します。',
  ];
  if (lines.isEmpty) return;

  await showAppDialog<void>(
    context: context,
    builder: (ctx) => AppDialog(
      title: '快適にプレイするために',
      icon: Icons.phone_android_rounded,
      actions: [
        if (needsAlways)
          AppDialogAction(
            label: '設定を開く',
            filled: false,
            onPressed: () async {
              Navigator.pop(ctx);
              await Geolocator.openAppSettings();
            },
          ),
        AppDialogAction(
          label: '了解',
          onPressed: () => Navigator.pop(ctx),
        ),
      ],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final line in lines) ...[
            Text(line),
            if (line != lines.last) const SizedBox(height: 10),
          ],
        ],
      ),
    ),
  );

  if (!generalSeen) {
    await OnboardingPrefs.markMatchPlayabilityHintsSeen();
  }
}
