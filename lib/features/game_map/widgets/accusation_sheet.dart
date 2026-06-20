import 'package:flutter/material.dart';

import '../../../audio/sfx_id.dart';
import '../../../features/how_to_play/guide_terms.dart';
import '../../../game/accusation_weight.dart';
import '../../../presentation/world/world_legibility.dart';
import '../../../presentation/world/world_presentation_context.dart';
import '../../../presentation/world/world_ui_helpers.dart';
import '../../../theme/accusation_facility_copy.dart';
import '../../../widgets/app_dialog.dart';

/// 告発先プレイヤー選択シート。
Future<String?> showAccusationPlayerSheet({
  required BuildContext context,
  required AccusationFacilityCopy copy,
  required AccusationWeight accusationWeight,
  required List<({String uid, String label, bool selectable, String? disabledReason})>
      candidates,
}) {
  final failHint = accusationWeight.eliminatesAccuserOnFailure
      ? '外すと即脱落し、残響体として監視網を操作できます。'
      : '外しても脱落しませんが、この試合では告発権を失います。';

  return showWorldSheet<String>(
    context,
    builder: (ctx) {
      final profile = context.worldProfile;
      return WorldThemed(
        profile: profile,
        child: DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.55,
          minChildSize: 0.35,
          maxChildSize: 0.9,
          builder: (sheetCtx, scrollController) {
            return SafeArea(
              child: ListView(
                controller: scrollController,
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                children: [
                  Text(
                    copy.facilityName,
                    style: Theme.of(sheetCtx).textTheme.titleLarge?.copyWith(
                          color: sheetCtx.worldBodyOnScaffold,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    copy.accuseActionLabel,
                    style: Theme.of(sheetCtx).textTheme.titleMedium?.copyWith(
                          color: sheetCtx.worldBodyOnScaffold,
                        ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    AccusationFacilityCopy.accuseTargetLine,
                    style: Theme.of(sheetCtx).textTheme.bodySmall?.copyWith(
                          color: sheetCtx.worldMutedOnScaffold,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    failHint,
                    style: Theme.of(sheetCtx).textTheme.bodySmall?.copyWith(
                          color: accusationWeight.eliminatesAccuserOnFailure
                              ? Theme.of(sheetCtx).colorScheme.error
                              : sheetCtx.worldMutedOnScaffold,
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                  const SizedBox(height: 12),
                  for (final c in candidates)
                    ListTile(
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
                    ),
                ],
              ),
            );
          },
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
  required AccusationWeight accusationWeight,
}) async {
  final ok = await showAppDialog<bool>(
    context: context,
    builder: (ctx) {
      final theme = Theme.of(ctx);
      return AppDialog(
        title: '${copy.accuseActionLabel}？',
        icon: Icons.gavel_rounded,
        accent: theme.colorScheme.error,
        actions: [
          AppDialogAction(
            label: 'やめる',
            filled: false,
            sfx: SfxId.uiBack,
            onPressed: () => Navigator.pop(ctx, false),
          ),
          AppDialogAction(
            label: copy.accuseActionLabel,
            icon: Icons.campaign_rounded,
            onPressed: () => Navigator.pop(ctx, true),
          ),
        ],
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '「$targetLabel」を${GuideTerms.trueOni}として告発します。',
              style: theme.textTheme.bodyLarge?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            _OutcomeRow(
              icon: Icons.check_circle_rounded,
              color: Colors.green.shade600,
              label: '正解',
              text: accusationWeight.successOutcomeLabel,
            ),
            const SizedBox(height: 8),
            _OutcomeRow(
              icon: Icons.dangerous_rounded,
              color: theme.colorScheme.error,
              label: '不正解',
              text: accusationWeight.failureOutcomeLabel,
            ),
          ],
        ),
      );
    },
  );
  return ok == true;
}

class _OutcomeRow extends StatelessWidget {
  const _OutcomeRow({
    required this.icon,
    required this.color,
    required this.label,
    required this.text,
  });

  final IconData icon;
  final Color color;
  final String label;
  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: color),
        const SizedBox(width: 8),
        Text(
          '$label: ',
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Expanded(child: Text(text, style: theme.textTheme.bodyMedium)),
      ],
    );
  }
}
