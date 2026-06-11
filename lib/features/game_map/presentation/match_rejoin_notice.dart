import 'package:flutter/material.dart';

/// 途中参加・再参加時の短い案内（カウントダウン省略時など）。
Future<void> showMatchRejoinNotice({
  required BuildContext context,
  required int remainingSeconds,
  required String roleLabel,
}) async {
  if (!context.mounted) return;
  final minutes = (remainingSeconds / 60).ceil().clamp(1, 999);
  await showDialog<void>(
    context: context,
    barrierDismissible: true,
    builder: (ctx) => AlertDialog(
      title: const Text('試合は開始済み'),
      content: Text(
        '残りおよそ $minutes 分です。\n'
        'あなたの役職: $roleLabel\n\n'
        '位置の更新とタイマーはすでに動いています。',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx),
          child: const Text('了解'),
        ),
      ],
    ),
  );
}
