import 'package:flutter/material.dart';

import '../../../game/location_reveal_event.dart';
import '../../../game/match_ui_terms.dart';
import '../../../game/match_event.dart';

/// 暴露・試合イベントを時系列で並べた簡易タイムライン。
class MatchFlowTimeline extends StatelessWidget {
  const MatchFlowTimeline({
    required this.reveals,
    required this.events,
    this.maxItems = 20,
    this.onSeekTo,
    super.key,
  });

  final List<LocationRevealEvent> reveals;
  final List<MatchEvent> events;
  final int maxItems;

  /// 行タップでその時刻へジャンプ（リプレイ用）。
  final void Function(DateTime atUtc)? onSeekTo;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final items = <_FlowItem>[];
    for (final r in reveals) {
      items.add(
        _FlowItem(
          at: r.timestamp,
          icon: Icons.location_on_outlined,
          title: r.playerLabel.isNotEmpty
              ? r.playerLabel
              : MatchUiTerms.namedReveal,
          subtitle: r.reasonSummary ?? '',
        ),
      );
    }
    for (final e in events) {
      items.add(
        _FlowItem(
          at: e.atUtc,
          icon: Icons.flag_outlined,
          title: e.message,
          subtitle: e.type,
        ),
      );
    }
    items.sort((a, b) => a.at.compareTo(b.at));
    final shown = items.length > maxItems
        ? items.sublist(items.length - maxItems)
        : items;

    if (shown.isEmpty) {
      return Text(
        '記録されたイベントはまだありません',
        style: theme.textTheme.bodySmall?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var i = 0; i < shown.length; i++) ...[
          if (i > 0)
            Divider(
              height: 12,
              color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
            ),
          _TimelineRow(item: shown[i], onSeekTo: onSeekTo),
        ],
      ],
    );
  }
}

class _FlowItem {
  const _FlowItem({
    required this.at,
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final DateTime at;
  final IconData icon;
  final String title;
  final String subtitle;
}

class _TimelineRow extends StatelessWidget {
  const _TimelineRow({required this.item, this.onSeekTo});

  final _FlowItem item;
  final void Function(DateTime atUtc)? onSeekTo;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final time =
        '${item.at.toLocal().hour.toString().padLeft(2, '0')}:'
        '${item.at.toLocal().minute.toString().padLeft(2, '0')}:'
        '${item.at.toLocal().second.toString().padLeft(2, '0')}';
    final content = Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(item.icon, size: 18, color: theme.colorScheme.primary),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                item.title,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (item.subtitle.isNotEmpty)
                Text(
                  item.subtitle,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
            ],
          ),
        ),
        Text(
          time,
          style: theme.textTheme.labelSmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
    if (onSeekTo == null) return content;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => onSeekTo!(item.at),
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: content,
        ),
      ),
    );
  }
}
