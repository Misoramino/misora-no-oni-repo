import 'package:flutter/material.dart';

/// 確認ダイアログ。確定で `true`、キャンセルで `false`。
Future<bool> showConfirmDialog(
  BuildContext context, {
  required String title,
  required String message,
  String confirmLabel = '削除',
  bool isDestructive = false,
}) async {
  final ok = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(title),
      content: Text(message),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx, false),
          child: const Text('キャンセル'),
        ),
        FilledButton(
          style: isDestructive
              ? FilledButton.styleFrom(
                  backgroundColor: Theme.of(ctx).colorScheme.error,
                  foregroundColor: Theme.of(ctx).colorScheme.onError,
                )
              : null,
          onPressed: () => Navigator.pop(ctx, true),
          child: Text(confirmLabel),
        ),
      ],
    ),
  );
  return ok == true;
}

/// テキスト入力ダイアログ。キャンセルで `null`。
Future<String?> showTextPromptDialog(
  BuildContext context, {
  required String title,
  required String labelText,
  String? hintText,
  required String defaultValue,
  String confirmLabel = 'OK',
}) async {
  final controller = TextEditingController(text: defaultValue);
  try {
    return await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: TextField(
          controller: controller,
          decoration: InputDecoration(
            labelText: labelText,
            hintText: hintText,
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('キャンセル'),
          ),
          FilledButton(
            onPressed: () {
              final t = controller.text.trim();
              Navigator.pop(ctx, t.isEmpty ? defaultValue : t);
            },
            child: Text(confirmLabel),
          ),
        ],
      ),
    );
  } finally {
    controller.dispose();
  }
}
