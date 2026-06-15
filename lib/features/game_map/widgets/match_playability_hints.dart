import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

import '../../../services/battery_power_mode.dart';
import '../../../services/location_service.dart';
import '../../../session/onboarding_prefs.dart';
import '../../../widgets/app_dialog.dart';
import '../../onboarding/guide_bullet_list.dart';

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
      '試合中に他アプリへ切り替えても、戻ったとき自動で追いつきます',
      'スキル操作だけは、アプリを前面に戻してから',
    ],
    if (needsAlways)
      'iPhone は位置情報を「常に許可」にすると、ロック中も判定が安定します',
    if (lowPower)
      '低電力モード中は位置更新・同期が遅れやすいです',
  ];
  if (lines.isEmpty) return;

  final accent = Theme.of(context).colorScheme.primary;

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
      child: GuideBulletList(lines: lines, accent: accent),
    ),
  );

  if (!generalSeen) {
    await OnboardingPrefs.markMatchPlayabilityHintsSeen();
  }
}
