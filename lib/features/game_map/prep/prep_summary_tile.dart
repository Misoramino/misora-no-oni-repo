import 'package:flutter/material.dart';

class PrepSummaryTile extends StatelessWidget {
  const PrepSummaryTile({
    required this.icon,
    required this.title,
    required this.value,
    required this.expanded,
    required this.canEdit,
    this.onTap,
    this.preview,
    this.child,
    super.key,
  });

  final IconData icon;
  final String title;
  final String value;
  final bool expanded;
  final bool canEdit;
  final VoidCallback? onTap;
  final Widget? preview;
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: theme.colorScheme.surface,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 10, 8, 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Icon(icon, size: 22, color: theme.colorScheme.primary),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(title, style: theme.textTheme.labelMedium),
                        Text(
                          value,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (canEdit)
                    Icon(
                      expanded ? Icons.expand_less : Icons.expand_more,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                ],
              ),
              if (preview != null && !expanded) ...[
                const SizedBox(height: 8),
                preview!,
              ],
              if (child != null && expanded) ...[
                const SizedBox(height: 8),
                child!,
              ],
            ],
          ),
        ),
      ),
    );
  }
}
