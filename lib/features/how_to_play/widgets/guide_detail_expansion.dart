import 'package:flutter/material.dart';

import '../guide_models.dart';

/// 折りたたみ詳細（秒数・距離・例外など）。ExpansionTile より軽量な制御 UI。
class GuideDetailExpansion extends StatefulWidget {
  const GuideDetailExpansion({
    required this.details,
    super.key,
  });

  final List<GuideDetailData> details;

  @override
  State<GuideDetailExpansion> createState() => _GuideDetailExpansionState();
}

class _GuideDetailExpansionState extends State<GuideDetailExpansion> {
  final _open = <int>{};

  @override
  Widget build(BuildContext context) {
    if (widget.details.isEmpty) return const SizedBox.shrink();
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var i = 0; i < widget.details.length; i++)
          _DetailTile(
            data: widget.details[i],
            expanded: _open.contains(i),
            onTap: () => setState(() {
              if (_open.contains(i)) {
                _open.remove(i);
              } else {
                _open.add(i);
              }
            }),
            bodyStyle: theme.textTheme.bodySmall?.copyWith(height: 1.5),
          ),
      ],
    );
  }
}

class _DetailTile extends StatelessWidget {
  const _DetailTile({
    required this.data,
    required this.expanded,
    required this.onTap,
    required this.bodyStyle,
  });

  final GuideDetailData data;
  final bool expanded;
  final VoidCallback onTap;
  final TextStyle? bodyStyle;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 6),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          InkWell(
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      data.title,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                  ),
                  Icon(
                    expanded ? Icons.expand_less : Icons.expand_more,
                    size: 20,
                  ),
                ],
              ),
            ),
          ),
          if (expanded)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
              child: Text(data.body, style: bodyStyle),
            ),
        ],
      ),
    );
  }
}
