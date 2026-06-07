import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

import '../../../services/location_service.dart';
import '../../../widgets/app_dialog.dart';

/// 位置情報が使えないときに設定へ誘導する。
Future<void> showLocationPermissionPrompt(
  BuildContext context, {
  required LocationAccessStatus status,
}) {
  final (title, body, settingsLabel) = switch (status) {
    LocationAccessStatus.serviceDisabled => (
        '位置情報サービスがオフです',
        '端末の設定で位置情報（GPS）をオンにしてください。\n'
            'このゲームは GPS でフィールドを表示します。',
        '位置情報の設定を開く',
      ),
    LocationAccessStatus.deniedForever => (
        '位置情報の許可が必要です',
        'アプリの設定から位置情報を「許可」に変更してください。',
        'アプリの設定を開く',
      ),
    LocationAccessStatus.denied => (
        '位置情報の許可が必要です',
        'プレイエリアや自分の位置を地図に表示するために許可が必要です。',
        'もう一度許可を求める',
      ),
    LocationAccessStatus.granted => ('', '', ''),
  };

  return showAppDialog<void>(
    context: context,
    builder: (ctx) => AppDialog(
      title: title,
      icon: Icons.location_off_rounded,
      actions: [
        AppDialogAction(
          label: 'あとで',
          filled: false,
          onPressed: () => Navigator.pop(ctx),
        ),
        AppDialogAction(
          label: settingsLabel,
          onPressed: () async {
            Navigator.pop(ctx);
            if (status == LocationAccessStatus.denied) {
              await Geolocator.requestPermission();
            } else {
              await Geolocator.openAppSettings();
            }
          },
        ),
      ],
      child: Text(body),
    ),
  );
}
