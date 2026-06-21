import 'package:flutter/material.dart';

import '../how_to_play/guide_text.dart';
import '../../presentation/world/world_legibility.dart';

/// オンボーディング／構造説明用の読みやすい箇条書き。
class GuideBulletList extends StatelessWidget {
  const GuideBulletList({
    super.key,
    required this.lines,
    required this.accent,
    this.leading,
  });

  final List<String> lines;
  final Color accent;
  final Widget? leading;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (leading != null) ...[
          leading!,
          const SizedBox(height: 12),
        ],
        for (var i = 0; i < lines.length; i++) ...[
          if (i > 0) const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: accent.withValues(alpha: 0.18)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Icon(
                    Icons.circle,
                    size: 8,
                    color: accent,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    GuideText.forDisplay(lines[i]),
                    style: theme.textTheme.bodyLarge?.copyWith(
                      height: 1.45,
                      color: context.worldBody,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}
