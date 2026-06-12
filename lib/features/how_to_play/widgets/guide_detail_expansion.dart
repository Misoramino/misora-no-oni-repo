import 'package:flutter/material.dart';

import '../guide_models.dart';

/// 折りたたみ詳細（秒数・距離・例外など）。
class GuideDetailExpansion extends StatelessWidget {
  const GuideDetailExpansion({
    required this.details,
    super.key,
  });

  final List<GuideDetailData> details;

  @override
  Widget build(BuildContext context) {
    if (details.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final d in details)
          Card(
            margin: const EdgeInsets.only(bottom: 6),
            clipBehavior: Clip.antiAlias,
            child: ExpansionTile(
              tilePadding: const EdgeInsets.symmetric(horizontal: 12),
              childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
              title: Text(
                d.title,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
              children: [
                Text(
                  d.body,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        height: 1.5,
                      ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
