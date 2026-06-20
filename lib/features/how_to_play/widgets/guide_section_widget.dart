import 'package:flutter/material.dart';

import '../../../presentation/world/world_legibility.dart';
import '../guide_text.dart';
import '../../../game/player_role.dart';
import '../../game_map/widgets/role_briefing_dialog.dart';
import '../guide_models.dart';
import 'guide_card.dart';
import 'guide_detail_expansion.dart';
import 'guide_diagram_slot.dart';
import 'guide_related_links.dart';

/// 章1つ分の UI（将来の専用画面でも再利用可能）。
class GuideSectionWidget extends StatelessWidget {
  const GuideSectionWidget({
    required this.section,
    required this.expanded,
    required this.onExpansionChanged,
    required this.onRelatedSectionTap,
    this.onOpenSpecCard,
    this.cardKeys,
    this.yourRole,
    super.key,
  });

  final GuideSectionData section;
  final bool expanded;
  final ValueChanged<bool> onExpansionChanged;
  final ValueChanged<String> onRelatedSectionTap;
  final ValueChanged<String>? onOpenSpecCard;
  final Map<String, GlobalKey>? cardKeys;
  final PlayerRole? yourRole;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          InkWell(
            onTap: () => onExpansionChanged(!expanded),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 8, 10),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(section.icon, color: context.worldAccentReadable),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          section.title,
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          GuideText.forDisplay(section.oneLine),
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: context.worldMuted,
                            height: 1.35,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    expanded ? Icons.expand_less : Icons.expand_more,
                    color: context.worldMuted,
                  ),
                ],
              ),
            ),
          ),
          if (expanded) ...[
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (section.sectionDiagram != null)
                    GuideDiagramSlot(data: section.sectionDiagram!),
                  for (final card in section.cards)
                    KeyedSubtree(
                      key: cardKeys?[card.id],
                      child: GuideCard(
                        data: card,
                        onOpenSpecCard: onOpenSpecCard,
                      ),
                    ),
                  if (section.id == 'roles')
                    _RoleBriefingsPanel(yourRole: yourRole),
                  if (section.details.isNotEmpty)
                    GuideDetailExpansion(
                      details: section.details,
                      onOpenSpecCard: onOpenSpecCard,
                    ),
                  GuideRelatedLinks(
                    relatedSectionIds: section.relatedSectionIds,
                    onSectionTap: onRelatedSectionTap,
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _RoleBriefingsPanel extends StatelessWidget {
  const _RoleBriefingsPanel({this.yourRole});

  final PlayerRole? yourRole;

  @override
  Widget build(BuildContext context) {
    final otherRoles = PlayerRole.values
        .where((r) => r != yourRole)
        .toList(growable: false);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 4),
        Text(
          'くわしい操作・スキル',
          style: Theme.of(context).textTheme.labelLarge,
        ),
        const SizedBox(height: 6),
        if (yourRole != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: roleBriefingBlock(
              context,
              yourRole!,
              emphasized: true,
            ),
          ),
        for (final role in yourRole != null ? otherRoles : PlayerRole.values)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: roleBriefingBlock(context, role),
          ),
      ],
    );
  }
}
