import 'package:flutter/material.dart';

import '../../../theme/accusation_facility_copy.dart';

/// 告発先プレイヤー選択シート。
Future<String?> showAccusationPlayerSheet({
  required BuildContext context,
  required AccusationFacilityCopy copy,
  required List<({String uid, String label, bool selectable, String? disabledReason})>
      candidates,
}) {
  return showModalBottomSheet<String>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (ctx) {
      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                copy.facilityName,
                style: Theme.of(ctx).textTheme.titleLarge,
              ),
              const SizedBox(height: 4),
              Text(
                copy.accuseActionLabel,
                style: Theme.of(ctx).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              Text(
                '外すと即脱落し、残響体として監視網を操作できます。',
                style: Theme.of(ctx).textTheme.bodySmall?.copyWith(
                      color: Theme.of(ctx).colorScheme.error,
                      fontWeight: FontWeight.w600,
                    ),
              ),
              const SizedBox(height: 16),
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: candidates.length,
                  itemBuilder: (context, i) {
                    final c = candidates[i];
                    return ListTile(
                      enabled: c.selectable,
                      title: Text(c.label),
                      subtitle: c.disabledReason != null
                          ? Text(c.disabledReason!)
                          : null,
                      trailing: c.selectable
                          ? const Icon(Icons.chevron_right)
                          : null,
                      onTap: c.selectable
                          ? () => Navigator.pop(ctx, c.uid)
                          : null,
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}

/// 告発確定前の最終確認。
Future<bool> showAccusationConfirmDialog({
  required BuildContext context,
  required String targetLabel,
  required AccusationFacilityCopy copy,
}) async {
  final ok = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text('${copy.accuseActionLabel}？'),
      content: Text(
        '「$targetLabel」を鬼として告発します。\n\n'
        '正解: 逃走者陣営の即勝利\n'
        '不正解: 即脱落（残響体として第二ゲームへ）',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx, false),
          child: const Text('やめる'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(ctx, true),
          child: Text(copy.accuseActionLabel),
        ),
      ],
    ),
  );
  return ok == true;
}
