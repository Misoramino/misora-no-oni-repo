import 'package:flutter/material.dart';

import '../../presentation/world/world_legibility.dart';
import '../../audio/sfx_id.dart';
import '../../widgets/juicy_tap.dart';
import '../how_to_play/guide_text.dart';
import 'tutorial_copy.dart';

/// チュートリアル上部の指示バナー。
class TutorialInstructionBanner extends StatelessWidget {
  const TutorialInstructionBanner({
    required this.text,
    required this.accent,
    required this.done,
    this.missionLabel,
    this.flash,
    this.onOpenGuide,
    super.key,
  });

  final String text;
  final Color accent;
  final bool done;
  final String? missionLabel;
  final String? flash;
  final VoidCallback? onOpenGuide;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 14),
      color: accent.withValues(alpha: 0.12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                done ? Icons.check_circle_rounded : Icons.school_rounded,
                color: done ? Colors.green.shade600 : accent,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  GuideText.forDisplay(text),
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    height: 1.3,
                  ),
                ),
              ),
              if (missionLabel != null) ...[
                const SizedBox(width: 8),
                Text(
                  missionLabel!,
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: context.worldMuted,
                  ),
                ),
              ],
            ],
          ),
          if (flash != null) ...[
            const SizedBox(height: 8),
            Text(
              flash!,
              style: theme.textTheme.labelLarge?.copyWith(
                color: accent,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
          if (onOpenGuide != null) ...[
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: onOpenGuide,
                icon: const Icon(Icons.menu_book_outlined, size: 18),
                label: const Text('遊び方でくわしく'),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// チュートリアル完了パネル。
class TutorialFinishPanel extends StatelessWidget {
  const TutorialFinishPanel({
    required this.copy,
    required this.accent,
    required this.onClose,
    required this.onRetry,
    required this.onOpenGuide,
    super.key,
  });

  final TutorialFinishCopy copy;
  final Color accent;
  final VoidCallback onClose;
  final VoidCallback onRetry;
  final void Function(String sectionId, {String? guideCardId}) onOpenGuide;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Icon(Icons.check_circle_rounded, size: 48, color: accent),
            const SizedBox(height: 12),
            Text(
              copy.title,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              GuideText.forDisplay(copy.body),
              style: theme.textTheme.bodyMedium?.copyWith(height: 1.55),
            ),
            const SizedBox(height: 20),
            Text('もっと詳しく見る', style: theme.textTheme.labelLarge),
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                for (final g in copy.relatedGuides)
                  ActionChip(
                    avatar: const Icon(Icons.menu_book_outlined, size: 16),
                    label: Text(g.title),
                    onPressed: () =>
                        onOpenGuide(g.sectionId, guideCardId: g.guideCardId),
                  ),
              ],
            ),
            const Spacer(),
            JuicyTap(
              onTap: onClose,
              sfx: SfxId.uiConfirm,
              child: IgnorePointer(
                child: FilledButton.icon(
                  style: FilledButton.styleFrom(
                    backgroundColor: accent,
                    foregroundColor: context.worldButtonLabel,
                    minimumSize: const Size.fromHeight(48),
                  ),
                  onPressed: () {},
                  icon: const Icon(Icons.check_rounded),
                  label: const Text('閉じる'),
                ),
              ),
            ),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.replay_rounded),
              label: const Text('もう一度'),
            ),
          ],
        ),
      ),
    );
  }
}
