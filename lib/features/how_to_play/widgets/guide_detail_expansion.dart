import 'package:flutter/material.dart';

import '../../../audio/game_audio.dart';
import '../../../audio/sfx_id.dart';
import '../guide_text.dart';
import '../guide_models.dart';

/// 折りたたみ詳細（秒数・距離・例外など）。
class GuideDetailExpansion extends StatefulWidget {
  const GuideDetailExpansion({
    required this.details,
    this.onOpenSpecCard,
    super.key,
  });

  final List<GuideDetailData> details;
  final ValueChanged<String>? onOpenSpecCard;

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
            onTap: () {
              final opening = !_open.contains(i);
              setState(() {
                if (opening) {
                  _open.add(i);
                } else {
                  _open.remove(i);
                }
              });
              if (opening) GameAudio.instance.playSfx(SfxId.uiTap);
            },
            bodyStyle: theme.textTheme.bodySmall?.copyWith(height: 1.5),
            onOpenSpecCard: widget.onOpenSpecCard,
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
    this.onOpenSpecCard,
  });

  final GuideDetailData data;
  final bool expanded;
  final VoidCallback onTap;
  final TextStyle? bodyStyle;
  final ValueChanged<String>? onOpenSpecCard;

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
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(GuideText.forDisplay(data.body), style: bodyStyle),
                  if (data.specCardId != null && onOpenSpecCard != null) ...[
                    const SizedBox(height: 10),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: TextButton.icon(
                        onPressed: () {
                          GameAudio.instance.playSfx(SfxId.uiTap);
                          onOpenSpecCard!(data.specCardId!);
                        },
                        icon: const Icon(Icons.table_chart_outlined, size: 18),
                        label: const Text('詳細ルールで数値を見る'),
                      ),
                    ),
                  ],
                ],
              ),
            ),
        ],
      ),
    );
  }
}
