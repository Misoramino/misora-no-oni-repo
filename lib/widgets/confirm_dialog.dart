import 'package:flutter/material.dart';

import '../presentation/world/world_ui_layout.dart';

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
    builder: (ctx) {
      final theme = Theme.of(ctx);
      final width = MediaQuery.sizeOf(ctx).width;
      final stackActions = width < 300;
      return AlertDialog(
        insetPadding: WorldUILayout.dialogInsets(ctx),
        title: Text(title),
        content: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: SingleChildScrollView(
            child: Text(
              message,
              style: theme.textTheme.bodyMedium?.copyWith(height: 1.45),
            ),
          ),
        ),
        actionsAlignment:
            stackActions ? MainAxisAlignment.center : MainAxisAlignment.end,
        actionsOverflowAlignment: OverflowBarAlignment.center,
        actionsOverflowDirection: VerticalDirection.down,
        actions: stackActions
            ? [
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    style: isDestructive
                        ? FilledButton.styleFrom(
                            backgroundColor: theme.colorScheme.error,
                            foregroundColor: theme.colorScheme.onError,
                          )
                        : null,
                    onPressed: () => Navigator.pop(ctx, true),
                    child: Text(confirmLabel),
                  ),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(ctx, false),
                  child: const Text('キャンセル'),
                ),
              ]
            : [
                TextButton(
                  onPressed: () => Navigator.pop(ctx, false),
                  child: const Text('キャンセル'),
                ),
                FilledButton(
                  style: isDestructive
                      ? FilledButton.styleFrom(
                          backgroundColor: theme.colorScheme.error,
                          foregroundColor: theme.colorScheme.onError,
                        )
                      : null,
                  onPressed: () => Navigator.pop(ctx, true),
                  child: Text(confirmLabel),
                ),
              ],
      );
    },
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
        insetPadding: WorldUILayout.dialogInsets(ctx),
        title: Text(title),
        content: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: SingleChildScrollView(
            child: TextField(
              controller: controller,
              decoration: InputDecoration(
                labelText: labelText,
                hintText: hintText,
              ),
              autofocus: true,
            ),
          ),
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
