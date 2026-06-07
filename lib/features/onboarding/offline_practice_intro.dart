import 'package:flutter/material.dart';

import '../../widgets/app_dialog.dart';

/// オフライン練習に入る前の1回説明。
Future<bool> confirmOfflinePracticeIntro(BuildContext context) {
  return showAppDialog<bool>(
    context: context,
    builder: (ctx) => AppDialog(
      title: 'オフラインで練習',
      icon: Icons.map_outlined,
      actions: [
        AppDialogAction(
          label: 'キャンセル',
          filled: false,
          onPressed: () => Navigator.pop(ctx, false),
        ),
        AppDialogAction(
          label: '始める',
          onPressed: () => Navigator.pop(ctx, true),
        ),
      ],
      child: const Text(
        'このモードでできること\n'
        '・地図・エリア編集の練習\n'
        '・スキル操作・HUD の確認\n'
        '・1人でのルール試走\n\n'
        'できないこと\n'
        '・友達とのオンライン同期\n'
        '・ルーム参加・ホスト機能\n\n'
        '友達と遊ぶときは「オンラインルーム」を選んでください。',
      ),
    ),
  ).then((v) => v ?? false);
}
